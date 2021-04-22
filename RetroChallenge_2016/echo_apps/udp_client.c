/*************************************************************************/
/* udp_client.c                                                          */
/*************************************************************************/
/* Simple UDP Echo Client Example                                        */
/* Sends a single message to the server                                  */
/* Obtains the message from the command-line arguments                   */
/*                                                                       */
/* Usage: udp_client <Server IP> <Echo Message> [<Echo Port>]            */
/*      Server IP must be in dotted-decimal format                       */
/*              does not do DNS                                          */
/*      Echo Message is the message to be sent.  Enclose in quotes if    */
/*              it consists of multiple words                            */
/*      Echo Port is optional; will default to 7 if not included         */
/*                                                                       */
/* Based on and modified from code examples from                         */
/*      "The Pocket Guide to TCP/IP Sockets: C Version"                  */
/*                 by Michael J. Donahoo and Kenneth L. Calvert:         */
/*         UDPEchoClient.c                                               */
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


#define ECHOMAX 255     /* Longest string to echo */
#define ECHO_PORT   7    /* Default standard port number for echo   */

void ReportError(char *errorMessage);   /* Error handling function (no exit) */
void DieWithError(char *errorMessage);  /* Fatal Error handling function     */

/********************************************************************/
/* main -- like opinions, every program has one.                    */
/********************************************************************/
int main(int argc, char *argv[])
{
    int sock;                        /* Socket descriptor */
    struct sockaddr_in echoServAddr; /* Echo server address */
    struct sockaddr_in fromAddr;     /* Source address of echo */
    unsigned short echoServPort;     /* Echo server port */
    unsigned int fromSize;           /* In-out of address size for recvfrom() */
    char *servIP;                    /* IP address of server */
    char *echoString;                /* String to send to echo server */
    char echoBuffer[ECHOMAX];        /* Buffer for echo string */
    int echoStringLen;               /* Length of string to echo */
    int respStringLen;               /* Length of response string */
#ifdef WINSOCK_EXAMPLE
    WORD wVersionRequested;          /* Version of Winsock to load */
    WSADATA wsaData;                 /* Winsock implementation details */ 
#endif    

    /* First process the command-line arguments. */
    if ((argc < 3) || (argc > 4))    /* Test for correct number of arguments */
    {
        fprintf(stderr,"Usage: %s <Server IP> <Echo Message> [<Echo Port>]\n", argv[0]);
        exit(1);
    }

    servIP = argv[1];           /* first arg: server IP address (dotted quad)*/
    echoString = argv[2];       /* second arg: string to echo */

    if ((echoStringLen = strlen(echoString) + 1) > ECHOMAX)  /* Check input length */
        DieWithError("Echo word too long");

    if (argc == 4)
        echoServPort = atoi(argv[3]);  /* Use given port, if any */
    else
        echoServPort = ECHO_PORT;  /* otherwise, use the default port number */

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
    /* Create a best-effort datagram socket using UDP */
    if ((sock = socket(PF_INET, SOCK_DGRAM, IPPROTO_UDP)) < 0)
        DieWithError("socket() failed");

    /* Construct the server address structure */
    memset(&echoServAddr, 0, sizeof(echoServAddr));    /* Zero out structure */
    echoServAddr.sin_family = AF_INET;                 /* Internet address family */
    echoServAddr.sin_addr.s_addr = inet_addr(servIP);  /* Server IP address */
    echoServAddr.sin_port   = htons(echoServPort);     /* Server port */

/* 2. Send (sendto()) the message to the server. */
    /* Send the string, including the null terminator, to the server */
    if (sendto(sock, echoString, echoStringLen, 0, (struct sockaddr *)
               &echoServAddr, sizeof(echoServAddr)) != echoStringLen)
        DieWithError("sendto() sent a different number of bytes than expected");
  
    /* Recv a response */
    
/* 3. Receive (recvfrom()) the server's response. */
    fromSize = sizeof(fromAddr);
    if ((respStringLen = recvfrom(sock, echoBuffer, ECHOMAX, 0, (struct sockaddr *) &fromAddr, 
                 &fromSize)) != echoStringLen)
        DieWithError("recvfrom() failed");

    if (echoServAddr.sin_addr.s_addr != fromAddr.sin_addr.s_addr)
    {
        fprintf(stderr,"Error: received a packet from unknown source.\n");
        exit(1);
    }

    if (echoBuffer[respStringLen-1])  /* Do not printf unless it is terminated */
        printf("Received an unterminated string\n");
    else
        printf("Received: %s\n", echoBuffer);    /* Print the echoed arg */

/* 4. Repeat the send and receive as required.<BR> (each of which will be seen by the server as a separate communication) */
/* Step 4 does not happen in the case of an echo client */


/* 5. Close the socket. */
#ifdef WINSOCK_EXAMPLE
    /* Winsock requires a special function for sockets */
    closesocket(sock);    /* Close client socket */

    WSACleanup();  /* Cleanup Winsock */
#else
    close(sock);    /* Close client socket */
#endif    

    return 0;
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
