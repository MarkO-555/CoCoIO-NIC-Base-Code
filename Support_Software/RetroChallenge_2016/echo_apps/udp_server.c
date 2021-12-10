/*************************************************************************/
/* udp_server.c                                                          */
/*************************************************************************/
/* Simple UDP Echo Server Example                                        */
/* Receives and echos a single message                                   */
/* Services any number of clients, one at a time; never exits            */
/*                                                                       */
/* Usage: udp_server [<Server Port>]                                     */
/*      Server Port is optional; will default to 7 if not included       */
/* NOTE: for security reasons, on many systems (eg, Linux) only a        */
/*      privileged program or user is allowed to bind to a well-known    */
/*      port.  Therefore, it will probably be necessary for you pick a   */
/*      port from outside the well-known range; ie from 1024 to 65536.   */
/*                                                                       */
/* Based on and modified from code examples from                         */
/*      "The Pocket Guide to TCP/IP Sockets: C Version"                  */
/*                 by Michael J. Donahoo and Kenneth L. Calvert:         */
/*         UDPEchoServer.c                                               */
/*         DieWithError.c                                                */
/*                                                                       */
/* The original UNIX source code is freely available from their web site */
/*      at http://cs.baylor.edu/~donahoo/PocketSocket/textcode.html      */
/*      and the Winsock version of the code at                           */
/*          http://cs.baylor.edu/~donahoo/PocketSocket/winsock.html      */
/*                                                                       */
/* Will compile under Windows or UNIX/Linux depending on the setting     */
/*      of the WINSOCK_EXAMPLE define                                    */
/*                                                                       */
/*************************************************************************/

/* #define for Windows; #undef for UNIX/Linux */
#undef WINSOCK_EXAMPLE

#include <stdlib.h>     /* for exit() */
#include <stdio.h>      /* for printf(), fprintf() */
#include <string.h>     /* for string functions  */
#ifdef WINSOCK_EXAMPLE
#include <winsock.h>    /* for socket(),... */
#else
#include <unistd.h>     /* for close() */
#include <sys/socket.h> /* for socket(),... */
#include <netinet/in.h> /* for socket(),... */
#include <arpa/inet.h>  /* for inet_addr() */
#endif    

#define ECHO_PORT  7    /* Default standard port number for echo   */
#define ECHOMAX   255   /* Longest string to echo */

void ReportError(char *errorMessage);   /* Error handling function (no exit) */
void DieWithError(char *errorMessage);  /* Fatal Error handling function     */

/********************************************************************/
/* main -- like opinions, every program has one.                    */
/********************************************************************/
int main(int argc, char *argv[])
{
    int sock;                        /* Socket */
    struct sockaddr_in echoServAddr; /* Local address */
    struct sockaddr_in echoClntAddr; /* Client address */
    char echoBuffer[ECHOMAX];        /* Buffer for echo string */
    unsigned short echoServPort;     /* Server port */
    int cliLen;                      /* Length of incoming message */
    int recvMsgSize;                 /* Size of received message */
#ifdef WINSOCK_EXAMPLE
    WORD wVersionRequested;          /* Version of Winsock to load */
    WSADATA wsaData;                 /* Winsock implementation details */ 
#endif    

    /* First process the command-line arguments. */
    /* NOTE: for security reasons, on many systems only a privileged program or user 
        is allowed to bind to a well-known port.  
        Therefore, it will probably be necessary for you pick a high-numbered one.  */
    if (argc > 2)     /* Test for correct number of arguments */
    {
        fprintf(stderr,"Usage:  %s [<UDP SERVER PORT>]\n", argv[0]);
        exit(1);
    } 
    else if (argc == 2)
        echoServPort = atoi(argv[1]);  /* first arg:  Local port */
    else
        echoServPort = ECHO_PORT;      /* set to default port, 7 */

#ifdef WINSOCK_EXAMPLE
    /* Winsock DLL and library initialization  */
    wVersionRequested = MAKEWORD(2, 0);   /* Request Winsock v2.0 */
    if (WSAStartup(wVersionRequested, &wsaData) != 0) /* Load Winsock DLL */
    {
        fprintf(stderr,"WSAStartup() failed");
        exit(1);
    }
#endif    

/* 1. Create a socket. */
    /* Create socket for sending/receiving datagrams */
    if ((sock = socket(PF_INET, SOCK_DGRAM, IPPROTO_UDP)) < 0)
        DieWithError("socket() failed");

/* 2. Bind the socket to a specific port with the bind() function. */
    /* Construct local address structure */
    memset(&echoServAddr, 0, sizeof(echoServAddr));   /* Zero out structure */
    echoServAddr.sin_family = AF_INET;                /* Internet address family */
    echoServAddr.sin_addr.s_addr = htonl(INADDR_ANY); /* Any incoming interface */
    echoServAddr.sin_port = htons(echoServPort);      /* Local port */

    /* Bind to the local address */
    if (bind(sock, (struct sockaddr *) &echoServAddr, sizeof(echoServAddr)) < 0)
        DieWithError("bind() failed");
  
/* 6. Wait for the next message from a client<BR> (could be the same client or a different one). */
    for (;;) /* Run forever */
    {
        /* Set the size of the in-out parameter */
        cliLen = sizeof(echoClntAddr);

/* 3. Wait for a message from a client. */
/* 4. Receive (recvfrom()) the client's message. */
        /* Block until receive message from a client */
        if ((recvMsgSize = recvfrom(sock, echoBuffer, ECHOMAX, 0,
                (struct sockaddr *) &echoClntAddr, &cliLen)) < 0)
            DieWithError("recvfrom() failed");

        printf("Handling client %s\n", inet_ntoa(echoClntAddr.sin_addr));

/* 5. Send (sendto()) a response, if required. */
         /* Send received datagram back to the client */
         if (sendto(sock, echoBuffer, recvMsgSize, 0, (struct sockaddr *) &echoClntAddr, 
                     sizeof(echoClntAddr)) != recvMsgSize)
             DieWithError("sendto() sent a different number of bytes than expected");
    }
    /* NOT REACHED */
    
    /* return an error if we reach here */    
    return 1;
}


/********************************************************/
/* DieWithError                                         */
/*    Separate function for handling errors             */
/*    Reports an error and then terminates the program  */
/********************************************************/
void DieWithError(char *errorMessage)
{
    ReportError(errorMessage);
    exit(1);
}

/**************************************************************************/
/* ReportError                                                            */
/*    Displays a message that reports the error                           */
/*    Encapsulates the difference between UNIX and Winsock error handling */
/* Winsock Note:                                                          */
/*    WSAGetLastError() only returns the error code number without        */
/*    explaining what it means.  A list of the Winsock error codes        */
/*    is available from various sources, including Microsoft's            */
/*    on-line developer's network library at                              */
/*  http://msdn.microsoft.com/library/default.asp?url=/library/en-us/winsock/winsock/windows_sockets_error_codes_2.asp */
/**************************************************************************/
void ReportError(char *errorMessage)
{
#ifdef WINSOCK_EXAMPLE
    fprintf(stderr,"%s: %d\n", errorMessage, WSAGetLastError());
#else
    perror(errorMessage);
#endif    
}

/* End of File */
