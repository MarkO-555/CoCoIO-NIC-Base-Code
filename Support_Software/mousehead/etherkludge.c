/*
   A quick and dirty packet builder
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

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

int sd;
char obuf[256];

int conf_iface = 0;


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


int main(int argc, char **argv) {
    int ret;
    struct sockaddr_ll laddr;

    if (argc < 2) {
	fprintf(stderr,"usage: etherkludge <iface> [hex] ...\n");
	exit(1);
    }

    get_interface(argv[1]);

    sd =  socket(AF_PACKET, SOCK_RAW, htons(4445));
    if (sd < 0) {
	perror("socket");
	exit(1);
    }

    memset(&laddr, 0, sizeof(struct sockaddr_ll));
    laddr.sll_family = AF_PACKET;
    laddr.sll_protocol = htons(4445);
    laddr.sll_ifindex = conf_iface;

    ret = bind(sd, (struct sockaddr *)&laddr, sizeof(struct sockaddr_ll));
    if (ret < 0) {
	perror("bind");
	exit(1);
    }

    int i;
    char *p = obuf;
    long int n;
    char *end;

    for (i = 2; i < argc; i++) {
	n = strtol(argv[i],&end, 16);
	if (*end == 0) {
	    if (n < 0x100) {
		*p++ = n;
		continue;
	    }
	    if (n < 0x10000) {
		*p++ = n >> 8;
		*p++ = n & 255;
		continue;
	    }
	    if (n < 0x1000000) {
		*p++ = n >> 16;
		*p++ = (n >> 8) & 255;
		*p++ = n & 255;
		continue;
	    }
	    if (n < 0x100000000) {
		*p++ = n >> 24;
		*p++ = (n >> 16) & 255;
		*p++ = (n >> 8) & 255;
		*p++ = n & 255;
		continue;
	    }
	}
	else {
	    fprintf(stderr,"bad hex value conversion");
	    exit(1);
	}
    }
    if (p-obuf < 14) {
	fprintf(stderr,"error: need at least 14 bytes for valid ethernet\n");
	exit(1);
    }
    ret = write(sd, obuf, p-obuf);
    if (ret < 0) {
	perror("write");
	exit(1);
    }
    printf("%d bytes written\n", ret);
    exit(0);
}
