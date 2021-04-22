/*************************************************************************/
/* tcp_client.c                                                          */
/*************************************************************************/
/* Simple TCP Echo Client Example                                        */
/* Sends any number of messages to the server                            */
/* Prompts the user for each message                                     */
/*                                                                       */
/* Usage: tcp_client <Server IP> [<Echo Port>]                           */
/*      Server IP must be in dotted-decimal format                       */
/*              does not do DNS                                          */
/*      Echo Port is optional; will default to 7 if not included         */
/*                                                                       */
/* Based on and modified from code examples from                         */
/*      "The Pocket Guide to TCP/IP Sockets: C Version"                  */
/*                 by Michael J. Donahoo and Kenneth L. Calvert:         */
/*         TCPEchoClient.c                                               */
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

#define RCVBUFSIZE 256   /* Size of receive buffer */
#define ECHO_PORT   7    /* Default standard port number for echo   */

void ConductEchoSession(int sock);       /* split echo protocol off from basic sockets */
void ReportError(char *errorMessage);   /* Error handling function (no exit) */
void DieWithError(char *errorMessage);  /* Fatal Error handling function     */
void chomp(char *str);                  /* remove newline character(s)       */

/********************************************************************/
/* main -- like opinions, every program has one.                    */
/********************************************************************/
int main(int argc, char *argv[])
{
    int sock;                        /* Socket descriptor */
    struct sockaddr_in echoServAddr; /* Echo server address */
    unsigned short echoServPort;     /* Echo server port */
    char *servIP;                    /* Server IP address (dotted quad) */
#ifdef WINSOCK_EXAMPLE
    WORD wVersionRequested;          /* Version of Winsock to load */
    WSADATA wsaData;                 /* Winsock implementation details */ 
#endif    

    /* First process the command-line arguments. */
    
    /* Test for correct number of arguments */
    if ((argc < 2) || (argc > 3))    
    {
        fprintf(stderr, "Usage: %s <Server IP> [<Echo Port>]\n", argv[0]);
        exit(1);
    }

    /* first arg: server IP address (dotted quad) */
    servIP = argv[1];             

    /* second arg, if any: port number */
    if (argc == 3)
        echoServPort = atoi(argv[2]);   /* Use given port */
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
    /* Create a reliable, stream socket using TCP */
    if ((sock = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP)) < 0)
        DieWithError("socket() failed");

/* 2. Connect to the server. */
    /* Construct the server address structure */
    memset(&echoServAddr, 0, sizeof(echoServAddr));     /* Zero out structure */
    echoServAddr.sin_family      = AF_INET;             /* Internet address family */
    echoServAddr.sin_addr.s_addr = inet_addr(servIP);   /* Server IP address */
    echoServAddr.sin_port        = htons(echoServPort); /* Server port */

    /* Establish the connection to the echo server */
    if (connect(sock, (struct sockaddr *) &echoServAddr, sizeof(echoServAddr)) < 0)
        DieWithError("connect() failed");
    else
        printf("Connected to Server %s\n",servIP);

    /* connected, so perform the echo session */
    /* Will perform the calls to send(), recv(), shutdown, and close */
    ConductEchoSession(sock);

#ifdef WINSOCK_EXAMPLE
    /* Clean up Winsock */
    WSACleanup();  
#endif    

    return 0;
}


/********************************************************************/
/* ConductEchoSession                                               */
/*    Conduct an echo session with the server.                      */
/*    Spun off as a separate function in order to simplify the main */
/*        function and to separate the echo protocol from the basic */
/*        sockets operations as much as possible.                   */
/********************************************************************/
void ConductEchoSession(int sock)
{
    int echoStringLen;               /* Length of string to echo */
    char echoBuffer[RCVBUFSIZE];     /* Buffer for echo string */
    char msgBuffer[RCVBUFSIZE];      /* Buffer for input string */
    int bytesRcvd, totalBytesRcvd;   /* Bytes read in single recv() and total bytes read */

/* 5. Repeat the send and receive as required. */
    do
    {
        /* input the message string from the user */
        
        /* use fgets on stdin instead of gets to prevent buffer overflow */
        printf("Enter Message: ");
        fgets(msgBuffer,RCVBUFSIZE,stdin);

        /* Remove newline char(s) from end of input string */
        /*    (is necessary with fgets())                  */
        chomp(msgBuffer);       
        
        /* Determine input-string length, plus one for null-terminator */
        echoStringLen = strlen(msgBuffer) + 1;          

        /* Inputting an empty string (length == 1) quits, so proceed   */
        /*      if input string was not empty                          */        
        if (echoStringLen > 1)
        {
/* 3. Send (send()) the request. */
            /* Send the string, including the null terminator, to the server */
            if (send(sock, msgBuffer, echoStringLen, 0) != echoStringLen)
                DieWithError("send() sent a different number of bytes than expected");

/* 4. Receive (recv()) the server's response. */
            /* Receive the same string back from the server                 */
            /* The return message might not all come back in one piece,     */
            /*      especially if the message was long.                     */
            /* Therefore, loop as long as we haven't gotten the entire      */
            /*      message back; ie while (totalBytesRcvd < echoStringLen) */
            totalBytesRcvd = 0;
            do
            {
                /* Receive up to the buffer size (minus 1 to leave space for 
                   a null terminator) bytes from the sender */
                bytesRcvd = recv(sock, &echoBuffer[totalBytesRcvd], 
                                    (RCVBUFSIZE - 1 - totalBytesRcvd), 0);
                if (bytesRcvd < 0)
                    DieWithError("recv() failed");
                else if (!bytesRcvd)
                    ReportError("recv() connection closed prematurely");
                else
                {
                    totalBytesRcvd += bytesRcvd;   /* Keep tally of total bytes */
                    echoBuffer[totalBytesRcvd] = '\0';  /* Add \0 so printf knows where to stop */
                }
            } while (bytesRcvd && (totalBytesRcvd < echoStringLen));

            /* If message received back, print it */
            if (bytesRcvd)
                printf("Received: %s\n",echoBuffer);    
                
        }   /* end if (echoStringLen > 1) */
    } while (bytesRcvd && (echoStringLen > 1)); /* repeat loop if server  */
                                                /*   hasn't disconnected  */
                                                /*   and user hasn't quit */
  
/* 6. Shut down (shutdown()) the connection. */
    /* Quitting, so shut down the connection */
    shutdown(sock,1);   /* "done sending" */

    /* watch for signal that server has shut down this socket */
    totalBytesRcvd = 0;
    while (bytesRcvd > 0)
    {
        bytesRcvd = recv(sock, echoBuffer, RCVBUFSIZE - 1, 0);
        if (bytesRcvd < 0)
            DieWithError("recv() failed");
        else if (!bytesRcvd)
            printf("Detected Server shutting down\n");
        else
        {
            /* unlikely, but if we're still receiving data, then process it */
            totalBytesRcvd += bytesRcvd;   /* Keep tally of total bytes */
            echoBuffer[totalBytesRcvd] = '\0';  /* Add \0 so printf knows where to stop */
        }
    }

    /* In the unlikely event that any data was received, then print it */
    if (totalBytesRcvd)
        printf("%s\n",echoBuffer); 
    
/* 7. Close the socket. */
    /* Close the socket   */
#ifdef WINSOCK_EXAMPLE
    /* Winsock requires a special function for sockets */
    closesocket(sock);
#else
    close(sock);
#endif    
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


/***********************************************************************/
/* chomp -- removes newline characters from the end of a string        */
/*      Unlike the Perl function it's derived from, this chomp does    */
/*          not return the number of characters removed, nor does it   */
/*          restrict itself to the system's specific end-of-line       */
/*          sequence ($/).                                             */
/*      This function considers any number or combination of the       */
/*          characters CR ('\x0d') and LF ('\x0a') to be part of       */
/*          an end-of-line sequence and so removes them.               */
/***********************************************************************/
void chomp(char *str)  
{
    int i, len;
    
    len = strlen(str);
    for (i=len-1; (i>=0) && ( (str[i]=='\x0a') || (str[i]=='\x0d') ); i--)
        str[i] = '\0';
}

/* End of File */
