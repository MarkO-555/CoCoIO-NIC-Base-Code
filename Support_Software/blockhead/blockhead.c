/* 

   A Blockhead Server Reference.

 * daemonization?
 * file system manipulation: cd, rm, ls, etc.
 * crap-tons of protocol parameter checking
 * access cntrol (read only and/or copied and writeable volumes?)

 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <errno.h>
#include <signal.h>

#include <unistd.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netinet/ip.h>
#include <arpa/inet.h>
#include <net/if.h>

#include <linux/if_packet.h>

// #define DEBUG             // uncomment to debug

#define SEC_PER_MIN    60    // number of seconds in a minute
#define SIZE_MASK       7    // mask of sector size exponent in flags
#define PADDATA         0    // data to pad packets with
#define MAX_BUF       768    // maximum size in/out buffer


/* offsets to data in packets */
#define OFF_TYPE        0
#define OFF_SEQ         1
#define OFF_FLAGS       2
#define OFF_SESID       2
#define OFF_ERROR       2
#define OFF_FILENAME    3
#define OFF_RDDATA      4
#define OFF_OPCODE      4
#define OFF_LSN         5
#define OFF_WRDATA      10

/* the network layer which we're running on */
#define LAYER_ETH 0
#define LAYER_UDP 1
#define LAYER_IP  2

/* compiled defaults */
#define DEF_TIMEOUT SEC_PER_MIN * 60
#define DEF_IMAGE "test.img"
#define DEF_DIR    "./"
#define DEF_PORTNO 4444
#define DEF_BADDR  INADDR_ANY
#define DEF_MAXCON 16
#define DEF_LAYER  LAYER_ETH
#define DEF_IFACE_BOGUS 0

/* configure file and/or commandline */
time_t conf_timeout = DEF_TIMEOUT; // default timeout for a session
int conf_deflayer = DEF_LAYER;     // layor to work at
int conf_portno = DEF_PORTNO;      // udp port or ethernet type
int conf_maxcon = DEF_MAXCON;      // max number of sessions
struct in_addr conf_baddr = {DEF_BADDR}; // bind address for UDP
char *conf_image = DEF_IMAGE;      // if no filename specified
char *conf_dir = DEF_DIR;          // serve files out of this dir
int conf_iface = DEF_IFACE_BOGUS;  // bind interface for ethernet

int sock; // socket for coms

volatile int alarm_flag = 0;

/* this is set at init(), also after last mount is closed */
uint16_t server_session_id;

/* packet types */
#define TYPE_CONNECT 0
#define TYPE_COMMAND 1
#define TYPE_REPLY   2
#define TYPE_DISCON  3
#define TYPE_KEEP    4

/* command packet opcodes */
#define OP_READ    0
#define OP_WRITE   1

/* reply codes */
#define REPLY_OK     0     // ok
#define REPLY_EOM    1     // out of sessions
#define REPLY_NOI    2     // no such image
#define REPLY_FORMAT 3     // bad packet format
#define REPLY_BADID  4     // bad session no
#define REPLY_SEEK   5     // image seek error (bad lsn?)
#define REPLY_SHORT  6     // read/write error
#define REPLY_BADFLG 7     // bad flags or sector size

/* fixme: rename? this is not really a connection as a
   server "mount" or image resource or session */
struct connection {
    int flags;
#define FLG_UNUSED 0
#define FLG_USED   1
    int fd;        // file descriptor of image
    int secsize;   // sector size in bytes
    time_t time;   // time since last access
};

struct connection *cons;  // array of sessions


/* message IO buffers */
struct sockaddr *src = NULL;  // source address of in-buffer
int src_size;                 // source address struct size
char ibuf[MAX_BUF];           // in-data
int ilen;                     // size of in-data
char obuf[MAX_BUF];           // out-data
int olen;                     // size of out-data (see append funcs)

void sig_handler(int sig) {
    if (sig == SIGALRM) {
	signal(SIGALRM, sig_handler);
	alarm(SEC_PER_MIN);
	alarm_flag = 1;
    }
    if (sig == SIGHUP) {
	signal(SIGHUP, sig_handler);
	printf("sighup\n");
    }
}

void printusage(void) {
    printf("Usage: blockhead [OPTION]...\n");
    printf("Serve file blocks via ethernet/udp\n");
    printf("(C) 2021 Brett M Gordon, GPLv2\n\n");
    printf("-p #     portno/ethertype (%d)\n", DEF_PORTNO);
    printf("-t #     session timeout in minutes (%d)\n", DEF_TIMEOUT/SEC_PER_MIN);
    printf("-e       listen at ethernet layer\n");
    printf("-u       listen at UDP layer\n");
    printf("-i iface ethernet interface / udp bind address\n");
    printf("-d dir   directory to serve from (%s)\n", DEF_DIR);
    printf("-m #     maximum number of sessions (%d)\n", DEF_MAXCON);
    printf("-x file  file default image to serve (%s)\n", DEF_IMAGE);
    printf("-h       this help\n");
}


int tonum(char *s) {
    int ret;
    char *end;
    
    ret = strtol(s, &end, 0);
    if (*end == 0) return ret;
    printf("param %s not a number\n", s);
    exit(1);
}

void proc_params(int argc, char **argv) {
    char *iface = NULL;
    int ret;
    char *end;
    while (1) {
	ret = getopt(argc, argv, "p:t:eui:d:m:x:h");
	if (ret == -1) break;
	switch (ret) {
	default:
	case 'h':
	case '?': printusage(); exit(0);
	case 'p': conf_portno = tonum(optarg); break;
	case 't': conf_timeout = tonum(optarg) * SEC_PER_MIN; break;
	case 'e': conf_deflayer = LAYER_ETH; break;
	case 'u': conf_deflayer = LAYER_UDP; break;
	case 'i': iface = strdup(optarg); break;
	case 'd': conf_dir = strdup(optarg); break;
	case 'm': conf_maxcon = tonum(optarg); break;
	case 'x': conf_image = strdup(optarg); break;
	}
    }
    if (iface && conf_deflayer == LAYER_UDP) {
	ret = inet_aton(iface, &conf_baddr);
	if (ret == 0) {
	    printf("-i: invalid bind address\n");
	    exit(1);
	}
    }
    if (iface && conf_deflayer == LAYER_ETH) {
	char *end = NULL;
	struct if_nameindex *ifs = NULL;

	/* if a number - its an interface number */
	ret = strtol(iface, &end,0);
	if (*end == 0) {
	    conf_iface = ret;
	}
	/* else is a text name of interface */
	else {
	    ifs = if_nameindex();
	    if (ifs == NULL) {
		perror("if_nameindex");
		exit(1);
	    }
	    while(ifs->if_name) {
		if (!strcmp(ifs->if_name, iface)) {
		    conf_iface = ifs->if_index;
		    break;
		}
		ifs++;
	    }
	}
	if (conf_iface == 0) {
	    printf("bad interface: %s\nreported interfaces: ", iface);
	    ifs = if_nameindex();
	    while(ifs->if_name) {
		printf("[%d]%s ", ifs->if_index, ifs->if_name);
		ifs++;
	    }
	    printf("\n");
	    exit(1);
	}
    }
}

void init(int argc, char **argv) {
    int ret;
    struct sockaddr_in addr;
    struct sockaddr_ll laddr;
    struct stat temp_stat;

    proc_params(argc, argv);

    ret = chroot(conf_dir);
    if (ret < 0) {
	perror("chroot");
	exit(1);
    }

    ret = chdir("/");
    if (ret < 0) {
	perror("chdir");
	exit(1);
    }

    /* warn if default file is not there*/
    ret = stat(conf_image, &temp_stat);
    if (ret < 0) {
	perror("warning: default image");
    }

    printf("blockhead server\n");
    
    /* reset output buffer */
    olen  = 0;

    /* make a random server_id */
    srandom(time(NULL));
#ifdef DEBUG
    server_session_id = 0x42;
#else
    server_session_id = random();
#endif

    /* allocate connection array */
    cons = calloc(conf_maxcon, sizeof(struct connection));
    if (cons == NULL) {
	perror("calloc");
	exit(1);
    }

    /* open socket */
    switch (conf_deflayer) {
    case LAYER_ETH:
	src_size = sizeof(struct sockaddr_ll);
	sock = socket(AF_PACKET, SOCK_DGRAM, htons(conf_portno));
	break;
    case LAYER_UDP:
	src_size = sizeof(struct sockaddr_in);
	sock = socket(AF_INET, SOCK_DGRAM, 0);
	break;
    }
    if (sock < 0) {
	perror("socket");
	exit(1);
    }

    /* alloc a source address struct */
    src = calloc(1, src_size);
    if (src == NULL) {
	perror("calloc");
	exit(1);
    }


    /* if udp bind new socket to a port */
    if (conf_deflayer == LAYER_UDP) {
	memset(&addr, 0, sizeof(struct sockaddr_in));
	addr.sin_family = AF_INET;
	addr.sin_addr.s_addr = conf_baddr.s_addr;
	addr.sin_port = htons(conf_portno);
	ret = bind(sock, (struct sockaddr *)&addr, sizeof(struct sockaddr_in));
	if (ret < 0) {
	    perror("bind");
	    exit(1);
	}
    }
    /* if ethernet and iface is specified, then bind to it */
    if (conf_deflayer == LAYER_ETH) {
	memset(&laddr, 0, sizeof(struct sockaddr_ll));
	laddr.sll_family = AF_PACKET;
	laddr.sll_ifindex = conf_iface;
	ret = bind(sock, (struct sockaddr *)&laddr, sizeof(struct sockaddr_ll));
	if (ret < 0) {
	    perror("bind");
	    exit(1);
	}
    }
    
    /* set up initial timer */
    alarm(SEC_PER_MIN);
    signal(SIGALRM, sig_handler);
    signal(SIGHUP, sig_handler);
}


/* append functions append data to the output buffer.
   and send functions send and reset the output buffer */

void append_byte(char c) {
    obuf[olen++] = c;
}

void append_word(uint16_t word) {
    obuf[olen++] = word >> 8;
    obuf[olen++] = word & 0xff;
}

/* unused, for now */
void append_buffer(char *buf, int len) {
    memcpy(obuf + olen, buf, len);
    olen += len;
}

void send_packet(void) {
    int ret;
    ret = sendto(sock, obuf, olen, 0, src, src_size);
    if (ret != olen) {
	perror("sendto");
    }
    olen = 0;
}

/* start a reply packet */
void build_reply(void) {
    olen = 0;
    append_byte(TYPE_REPLY);
    append_byte(ibuf[OFF_SEQ]);
    append_byte(REPLY_OK);
}

/* send a reply with error */
void send_error(int error) {
    build_reply();
    obuf[OFF_ERROR] = error;
    send_packet();
}

/* common session ID check code */
int proc_sessionid() {
    uint16_t no = 0;
    no = ntohs( *(uint16_t *)(ibuf + OFF_SESID) ) - server_session_id;
    /* nonsense id check here */
    if (no > conf_maxcon || cons[no].flags == FLG_UNUSED) {
	send_error(REPLY_BADID);
	return -1;
    }
    cons[no].time = time(NULL);
    return no;
}

void bh_connect(void) {
    int no;
    int ret;
    int fd;
    char *vol;
    int len;

    /* we may have some mutually dependent resource allocations here */

    /* find a free connection id*/
    for (no = 0; no < conf_maxcon; no++) {
	if (cons[no].flags == FLG_UNUSED)
	    break;
    }
    if (no == conf_maxcon) {
	printf("out of sessions\n");
	send_error(REPLY_EOM);
	return;
    }

    /* this server can only do 128,256,512 byte sector sizes */
    cons[no].secsize = 0x80 << (ibuf[OFF_FLAGS] & SIZE_MASK);
    if (cons[no].secsize > 512) {
	send_error(REPLY_BADFLG);
	return;
    }
    
    /* open file or default */
    vol = ibuf + OFF_FILENAME;
    len = strlen(vol);
    if (len > 255) {
	send_error(REPLY_FORMAT);
	return;
    }

    fd = open(len ? vol : conf_image, O_RDWR);
    if (fd < 0) {
	perror("open");
	send_error(REPLY_NOI);
	return;
    }

    /* send reply */
    build_reply();
    append_word(server_session_id + no);
    send_packet();

    /* now safe to allocate */
    cons[no].flags = FLG_USED;
    cons[no].fd = fd;
}


/* We recieved a command, do it and report back */
void bh_command(void) {
    int ret;
    uint16_t no = 0;
    uint32_t lsn = 0;

    no = proc_sessionid();
    if (no < 0) return;

    lsn = ntohl( *(uint32_t *)(ibuf + OFF_LSN) );

    /* seek to file  according to LSN and block size, fixme: offset too? */
    ret = lseek(cons[no].fd, lsn * cons[no].secsize, SEEK_SET);
    if (ret < 0) {
	send_error(REPLY_SEEK);
	return;
    }

    build_reply();

    /* transfer to/from file */
    if (ibuf[OFF_OPCODE] == OP_WRITE) {
	ret = write(cons[no].fd, ibuf + OFF_WRDATA, cons[no].secsize);
    }

    else {
	append_byte(PADDATA);
	ret = read(cons[no].fd, obuf + OFF_RDDATA, cons[no].secsize);
	olen += cons[no].secsize;
    }
    if (ret != cons[no].secsize) {
	send_error(REPLY_SHORT);
	return;
    }

    send_packet();
}


/* hopefully not the rarest packet in here */
void bh_disconnect(void) {
    uint16_t no;

    no = proc_sessionid();
    if (no < 0) return;

    build_reply();
    send_packet();

    close(cons[no].fd);
    cons[no].flags = FLG_UNUSED;
}


/* received a keep, so just send one back.  not sure what this is for
   yet: a watchdog timer or maybe meanlingless cannon fodder for
   network hole-punching.
*/
void bh_keep(void) {
    append_byte(TYPE_KEEP);
    send_packet();
}


/* fixme: probably need a timeout in here, maybe SIGALRM */
void loop(void) {
    int len = src_size;
    time_t now;
    int x;

    while (1) {
	/* check for expired sessions */
	if (alarm_flag) {
	    alarm_flag = 0;
	    now = time(NULL);
	    for (x = 0; x < conf_maxcon; x++) {
		if (cons[x].flags == FLG_USED &&
		    now - cons[x].time > conf_timeout) {
		    cons[x].flags = FLG_UNUSED;
		    close(cons[x].fd);
		}
	    }
	}
	/* wait for a packet */
	ilen = recvfrom(sock, ibuf, MAX_BUF, 0, src, &len);
	if (ilen < 0) {
	    if (errno == EINTR) continue;
	    perror("recvfrom");
	    exit(1);
	}
	switch (ibuf[OFF_TYPE]) {
	case TYPE_CONNECT: bh_connect(); break;
	case TYPE_COMMAND: bh_command(); break;
	case TYPE_DISCON:  bh_disconnect(); break;
	case TYPE_KEEP:    bh_keep(); break;
	default:
	    printf("warning bad packet type 0x%x\n", ibuf[0]);
	    break;
	}
    }
}


int main(int argc, char **argv) {
    init(argc, argv);
    loop();
    exit(0);
}
