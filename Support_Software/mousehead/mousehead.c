#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <errno.h>
#include <signal.h>

#include <unistd.h>
#include <fcntl.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netinet/ip.h>
#include <arpa/inet.h>
#include <net/if.h>



#include <linux/if_packet.h>


/*

references

[1] http://www-ug.eecg.utoronto.ca/desl/nios_devices_SoC/datasheets/PS2%20Mouse%20Protocol.htm

[2] https://wiki.osdev.org/Mouse_Input#Mouse_Packet_Info

TODO:
* intellimouse mouse for scroll wheels
* deal with movement overflow? should we bother?
*/


#define DEF_PORTNO 4445
#define DEF_IFACE_BOGUS 0
#define DEF_MOUSEDEV "/dev/input/mice"
#define DEF_MAX_PACKET 10
#define DEF_BUF_SIZE 256
#define DEV_MAXX 256
#define DEV_MAXY 192
#define DEF_FREQ (1000000/60)
#define DEF_PROTOPORT 0
#define DEF_TIMEOUT 30

/* protocol offsets define */
#define PROTO_FAM  0
#define PROTO_FAM_MOUSE 0
#define PROTO_PORT 1
#define PROTO_TYPE 2
#define PROTO_TYPE_CONNECT  0
#define PROTO_TYPE_DATA     1
#define PROTO_TYPE_CANCEL   2
#define PROTO_MAXX 3
#define PROTO_MAXY 5
#define PROTO_TIME 7
#define PROTO_TO   9

#define PROTO_CONNECT_SZ 10
#define PROTO_CANCEL_SZ 3


int sock;                           // socket for coms
int mfd;                            // open mouse device file
int conf_iface = DEF_IFACE_BOGUS;   // bind interface for ethernet
int conf_portno = DEF_PORTNO;       // udp port or ethernet type
char *conf_mousedev = DEF_MOUSEDEV; // mouse device
int conf_freq = DEF_FREQ;     // usecs to wait between reports
int conf_protoport = DEF_PROTOPORT; // port number
int conf_timeout = DEF_TIMEOUT;     // default timeout if no connection
unsigned char mbuf[DEF_MAX_PACKET]; // mouse packet buffer
unsigned char inbuf[DEF_BUF_SIZE];  // input socket  buffer
unsigned char obuf[DEF_BUF_SIZE];   // output socket buffer
int mx = 0;                         // mouse x
int my = 0;                         // mouse y
int maxx = DEV_MAXX - 1;            // maximum x coord
int maxy = DEV_MAXY - 1;            // maximum y coord
int buttons = 0;                    // mouse buttons: mid:right:left
int send_flg = 0;                   // flag for triggering a send
int locked_flg = 0;                 // if caddr is a valid client
struct sockaddr_ll caddr;           // address of client
time_t nexttime = 0;                // when to cancel connection


// tries to find a linux net interface by the name or number of iface
void get_interface(char *iface) {
    int ret;
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

int tonum(char *s) {
    int ret;
    char *end;

    ret = strtol(s, &end, 0);
    if (*end == 0) return ret;
    printf("param %s not a number\n", s);
    exit(1);
}


void printusage(void) {
    printf("Usage: mousehead [OPTIONS] mouse_device_file\n"
	   "Serve mouse packets via ethernet\n"
	   "(C) 2023 Brett M Gordon, GPLv2\n"
	   "\n"
	   "-i name/#  eth interface\n"
	   "-h         this help\n"
	   "-t #       frequency in msec (default %d)\n"
	   "-e #       ethertype (default %d)\n",
	   conf_freq/1000,
	   conf_portno
	   );
}

void parse_params(int argc, char **argv) {
    int ret;
    while(1) {
	ret = getopt(argc, argv, "hi:e:t:");
	if (ret == -1) break;
	switch (ret) {
	default:
	case 'i': get_interface(optarg); break;
	case 't': conf_freq = tonum(optarg) * 1000; break;
	case 'h':
	case '?': printusage(); exit(0);
	}
    }
    if (argv[optind]) conf_mousedev = strdup(argv[optind]);
    if (conf_freq < 0 && conf_freq > 1000000) {
	fprintf(stderr, "frequency out of range 1 - 1000\n");
	exit(1);
    }
    if (conf_iface < 1) {
	get_interface("0");
	exit(1);
    }
#ifdef DEBUG
    printf("conf_mousedev = %s\n", conf_mousedev);
    printf("conf_iface = %d\n", conf_iface);
    printf("conf_freq = %d\n", conf_freq);
#endif
}

void init(int argc, char **argv) {
    int ret;
    struct sockaddr_ll laddr;

    parse_params(argc, argv);

    sock = socket(AF_PACKET, SOCK_DGRAM, htons(conf_portno));
    if (sock < 0) {
	perror("socket");
	exit(1);
    }

    memset(&laddr, 0, sizeof(struct sockaddr_ll));
    laddr.sll_family = AF_PACKET;
    laddr.sll_ifindex = conf_iface;
    ret = bind(sock, (struct sockaddr *)&laddr, sizeof(struct sockaddr_ll));
    if (ret < 0) {
	perror("bind");
	exit(1);
    }

    mfd = open(conf_mousedev, O_RDWR);
    if (mfd == -1) {
	perror("open");
	exit(1);
    }
}

void proc_sock(void) {
    int ret;
    struct sockaddr_ll raddr;
    socklen_t len = sizeof(raddr);

    ret = recvfrom(sock, inbuf, DEF_BUF_SIZE, 0,
		   (struct sockaddr *)&raddr, &len);
#ifdef DEBUG
    printf("recv: %d\n", ret);
#endif
    if (ret < 0) {
	perror("recvfrom");
	exit(1);
    }
    if (ret < 3) {
	return;
    }
    if (inbuf[PROTO_TYPE] == PROTO_TYPE_CONNECT &&
	ret == PROTO_CONNECT_SZ) {
	locked_flg = 1;
	send_flg = 1;
	memcpy(&caddr, &raddr, sizeof(struct sockaddr_ll));
	// get settings
	maxx = inbuf[PROTO_MAXX] * 0x100 + inbuf[PROTO_MAXX+1] - 1;
	maxy = inbuf[PROTO_MAXY] * 0x100 + inbuf[PROTO_MAXY+1] - 1;
	conf_freq = (inbuf[PROTO_TIME] * 0x100 + inbuf[PROTO_TIME+1]) * 1000;
	conf_timeout = inbuf[PROTO_TO];
    }
    if (inbuf[PROTO_TYPE] == PROTO_TYPE_CANCEL) {
	locked_flg = 0;
    }
    nexttime = time(NULL) + conf_timeout;
}

void proc_mouse(void) {
    int ret;
    int dx;
    int dy;
    int mx_new;
    int my_new;
    int b_new;

    ret = read(mfd, mbuf, DEF_MAX_PACKET);
    if (ret != 3 || !(mbuf[0] & 8) || mbuf[0] & 192) return;
    dx = mbuf[0]&16 ? -(256-mbuf[1]) : mbuf[1];
    /* y movement is flipped [2] */
    dy = -(mbuf[0]&32 ? -(256-mbuf[2]) : mbuf[2]);
    /* accumulate to set screen size */
    mx_new = mx + dx;
    my_new = my + dy;
    /* contrain to size */
    if (mx_new > maxx) mx_new = maxx;
    if (mx_new < 0) mx_new = 0;
    if (my_new > maxy) my_new = maxy;
    if (my_new < 0) my_new = 0;
    /* get buttons */
    b_new = mbuf[0] & 7;
    /* if state changed send a packet */
    if (mx != mx_new || my != my_new || b_new != buttons) {
	send_flg = 1;
	mx = mx_new;
	my = my_new;
	buttons = b_new;
#ifdef DEBUG
	printf("%d %d %x\n", mx, my, buttons);
#endif
    }
}

void except_mouse(void) {
    perror("mouse exception");
    exit(1);
}

void except_sock(void) {
    perror("socket exeception");
    exit(1);
}

void send_state(void) {
    int ret;
    unsigned char *p = obuf;

    *p++ = conf_protoport;
    *p++ = PROTO_TYPE_DATA;
    *p++ = mx >> 8;
    *p++ = mx & 255;
    *p++ = my >> 8;
    *p++ = my & 255;
    *p++ = buttons & 255;
    ret = sendto(sock, obuf, p-obuf, 0, (struct sockaddr *)&caddr,
	   sizeof (struct sockaddr_ll));
    if (ret < 0) {
	perror("sendto");
	exit(1);
    }
    send_flg = 0;
}

void loop(void) {
    int ret;
    fd_set reads;
    fd_set excepts;
    struct timeval t;

    FD_ZERO(&reads);
    FD_ZERO(&excepts);
    t.tv_sec = 0;
    t.tv_usec = conf_freq;
    while(1) {
	FD_SET(sock, &reads);
	FD_SET(mfd, &reads);
	FD_SET(sock, &excepts);
	FD_SET(mfd, &excepts);
	/* fixme: this depends on linux's behavior of
	   returning unused sleep time in select() */
	ret = select(mfd+1, &reads, NULL, &excepts, &t);
	if (ret < 0) {
	    perror("select");
	    exit(1);
	}
	if (FD_ISSET(mfd, &reads))
	    proc_mouse();
	if (FD_ISSET(sock, &reads))
	    proc_sock();
	if (FD_ISSET(mfd, &excepts))
	    except_mouse();
	if (FD_ISSET(sock, &excepts))
	    except_sock();
	if (ret == 0) {
	    t.tv_sec = 0;
	    t.tv_usec = conf_freq;
	    if (locked_flg) {
		if (time(NULL) > nexttime) {
		    locked_flg = 0;
#ifdef DEBUG
		    printf("timeout!\n");
#endif
		}
		if (send_flg) send_state();
	    }
	}
    }
}

int main(int argc, char **argv) {
    init(argc, argv);
    loop();
    exit(0);
}
