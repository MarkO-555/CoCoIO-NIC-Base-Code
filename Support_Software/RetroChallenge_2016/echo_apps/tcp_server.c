/*************************************************************************/
/* tcp_server.c                                                          */
/*************************************************************************/
/* Simple TCP Echo Server Example                                        */
/* Receives and echos messages until the client shuts down               */
/* Services any number of clients, one at a time; never exits            */
/*                                                                       */
/* Usage: tcp_server [<Server Port>]                                     */
/*      Server Port is optional; will default to 7 if not included       */
/* NOTE: for security reasons, on many systems (eg, Linux) only a        */
/*      privileged program or user is allowed to bind to a well-known    */
/*      port.  Therefore, it will probably be necessary for you pick a   */
/*      port from outside the well-known range; ie from 1024 to 65536.   */
/*                                                                       */
/* Based on and modified from code examples from                         */
/*      "The Pocket Guide to TCP/IP Sockets: C Version"                  */
/*                 by Michael J. Donahoo and Kenneth L. Calvert:         */
/*         TCPEchoServer.c                                               */
/*         HandleTCPClient.c                                             */
/*         DieWithError.c                                                */
/*         TCPEchoServer.h                                               */
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
#include <string.h>     /* for memset() */
#ifdef WINSOCK_EXAMPLE
#include <winsock.h>    /* for socket(),... */
#else
#include <unistd.h>     /* for close() */
#include <sys/socket.h> /* for socket(),... */
#include <netinet/in.h> /* for socket(),... */
#include <arpa/inet.h>  /* for inet_addr() */
#endif    

#define MAXPENDING  5    /* Maximum outstanding connection requests */
#define ECHO_PORT   7    /* Default standard port number for echo   */
#define RCVBUFSIZE 32   /* Size of receive buffer */

void ReportError(char *errorMessage);   /* Error handling function (no exit) */
void DieWithError(char *errorMessage);  /* Fatal Error handling function     */
void HandleTCPClient(int clntSocket, struct sockaddr_in *clntAddr);   /* TCP client handling function */

/********************************************************************/
/* main -- like opinions, every program has one.                    */
/********************************************************************/
int main(int argc, char *argv[])
{
    int servSock;                    /* Socket descriptor for server */
    int clntSock;                    /* Socket descriptor for client */
    struct sockaddr_in echoServAddr; /* Local address */
    struct sockaddr_in echoClntAddr; /* Client address */
    unsigned short echoServPort;     /* Server port */
    unsigned int clntLen;            /* Length of client address data structure */
#ifdef WINSOCK_EXAMPLE
    WORD wVersionRequested;          /* Version of Winsock to load */
    WSADATA wsaData;                 /* Winsock implementation details */ 
#endif    

    /* First process the command-line arguments. */
    /* NOTE: for security reasons, on many systems only a privileged program or user 
        is allowed to bind to a well-known port.  
        Therefore, it will probably be necessary for you pick a high-numbered one.  */
    
    /* Test for correct number of arguments and read in parameter (if any) */
    if (argc > 2)    
    {
        fprintf(stderr, "Usage:  %s [<Server Port>]\n", argv[0]);
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

/* 1. Create a socket.  */
    /* Create socket for incoming connections */
    if ((servSock = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP)) < 0)
        DieWithError("socket() failed");

/* 2. Bind the socket to a specific port with the bind() function.  */
    /* First we construct local address structure containing that port we will bind to*/
    memset(&echoServAddr, 0, sizeof(echoServAddr));   /* Zero out structure */
    echoServAddr.sin_family = AF_INET;                /* Internet address family */
    echoServAddr.sin_addr.s_addr = htonl(INADDR_ANY); /* Any incoming interface */
    echoServAddr.sin_port = htons(echoServPort);      /* Local port */

    /* Then we perform the actual binding operation */
    if (bind(servSock, (struct sockaddr *) &echoServAddr, sizeof(echoServAddr)) < 0)
        DieWithError("bind() failed");

/* 3. Listen on that port for a client trying to connect to it.  */
    /* Mark the socket so it will listen for incoming connections */
    if (listen(servSock, MAXPENDING) < 0)
        DieWithError("listen() failed");

    /* Wait for and handle one client at a time                       */
    /* Because of this infinite loop, the only way to stop the server */
    /*    is with a Ctrl-C from the command line.                     */
    /* A production-quality server would need a more elegant way to   */
    /*    be stopped.                                                 */
    for (;;) /* Run forever */
    {
        /* Set the size of the client-address parameter */
        clntLen = sizeof(echoClntAddr);

/* 4. Accept the connection, which creates a client socket and starts the actual session.  */
        /* Wait for a client to connect                                  */
        /* NOTE:                                                         */ 
        /*   This operation will block until a client connects, causing  */
        /*       the server to "freeze" during that wait.                */
        /*   While that makes no difference in this simple application,  */
        /*       you would want to work around this in a production app. */
        if ((clntSock = accept(servSock, (struct sockaddr *) &echoClntAddr, &clntLen)) < 0)
            DieWithError("accept() failed");

        /* clntSock is connected to a client! */
        /* Report the connection to stdout    */
        printf("Handling client %s\n", inet_ntoa(echoClntAddr.sin_addr));

        /* Actual servicing of the client moved off to a separate function      */
        /* In a multithreaded server, a new worker thread would be created here */
        /* Will perform the calls to send(), recv(), shutdown, and close */
        HandleTCPClient(clntSock, &echoClntAddr);
    }
    /* NOT REACHED */

    /* return an error if we reach here */    
    return 1;
}


/********************************************************************/
/* HandleTCPClient                                                  */
/*    Function for servicing the client                             */
/*    Spun off as a separate function in order to simplify the main */
/*        function and to separate the echo protocol from the basic */
/*        sockets operations as much as possible.                   */
/********************************************************************/
void HandleTCPClient(int clntSocket, struct sockaddr_in *clntAddr)
{
    char echoBuffer[RCVBUFSIZE];        /* Buffer for echo string */
    int  recvMsgSize;                   /* Size of received message */
    int  send_failed;                   /* flag that the send() call failed */

/* 7. Repeat the receive and send as required.  */
    /* Send received string and receive again until end of transmission */
    do
    {
/* 5. Receive (recv()) the client's request.  */
        /* Receive message from client */
        /* NOTE:                        */ 
        /*   This operation will block until it receives a message from the  */
        /*       client, causing  the server to "freeze" during that wait.   */
        /*   While that makes no difference in this simple application,      */
        /*       you would want to work around this in a production app.     */
        recvMsgSize = recv(clntSocket, echoBuffer, RCVBUFSIZE,0);
        if (recvMsgSize < 0)
            ReportError("recv() failed");
        else if (!recvMsgSize)  /* zero means the client is disconnecting */
            /* Report the client's shutdown to stdout    */
            printf("Client %s shutting down\n", inet_ntoa(clntAddr->sin_addr));

        /* Only if we actually received a message do we echo it back */
        if (recvMsgSize > 0)
        {
/* 6. Send (send()) a response.  */
            /* Echo message back to client */
            /* NOTE:  blocks until the message is sent  */
            /*    Not normally a problem.               */
            if (send(clntSocket, echoBuffer, recvMsgSize, 0) != recvMsgSize)
            {
                ReportError("send() failed");
                send_failed = 1;  /* break out of while loop and close socket */
            }
            else
                send_failed = 0;
        }
    } while (! send_failed && recvMsgSize > 0);

/* 8. Close the connection when informed of the client's shutdown action.  */
    shutdown(clntSocket,1);    /* signal that we're done sending  */

/* 9. Close the client socket.  */
#ifdef WINSOCK_EXAMPLE
    /* Winsock requires a special function for sockets */
    closesocket(clntSocket);    /* Close client socket */
#else
    close(clntSocket);    /* Close client socket */
#endif    

    /* Report the client's shutdown to stdout    */
    printf("Closing client %s\n", inet_ntoa(clntAddr->sin_addr));
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
