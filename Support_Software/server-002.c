/* A simple server in the internet domain using TCP
   The port number is passed as an argument */
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h> 
#include <sys/socket.h>
#include <netinet/in.h>


#define NUM_THREADS 5


char functions_list[NUM_THREADS][21] = 
    {
        "Maze_Generator",
        "Game_Space_Main",
        "Game_AI",
        "NetWork_Interface",
        "PrintHello"
    };


void error(const char *msg)
{
    perror(msg);
    exit(1);
}

void *Maze_Generator(void *threadid)
{
   long tid;
   tid = (long)threadid;
   printf("Hello World! It's me, %s ( #%ld! )\n", functions_list[tid], tid);
   pthread_exit(NULL);
}

void *Game_Space_Main(void *threadid)
{
   long tid;
   tid = (long)threadid;
   printf("Hello World! It's me, %s ( #%ld! )\n", functions_list[tid], tid);
   pthread_exit(NULL);
}

void *Game_AI(void *threadid)
{
   long tid;
   tid = (long)threadid;
   printf("Hello World! It's me, %s ( #%ld! )\n", functions_list[tid], tid);
   pthread_exit(NULL);
}

void *NetWork_Interface(void *threadid)
{
   long tid;
   tid = (long)threadid;
   printf("Hello World! It's me, %s ( #%ld! )\n", functions_list[tid], tid);
   pthread_exit(NULL);
}

void *PrintHello(void *threadid)
{
   long tid;
   tid = (long)threadid;
   printf("Hello World! It's me, %s ( #%ld! )\n", functions_list[tid], tid);
   pthread_exit(NULL);
}


int main(int argc, char *argv[])
{
     int sockfd, newsockfd, portno;
     socklen_t clilen;
     char buffer[256];
     struct sockaddr_in serv_addr, cli_addr;
     int n;

     pthread_t threads[NUM_THREADS];
     int rc;
     long t;


     if (argc < 2) {
         fprintf(stderr,"ERROR, no port provided\n");
         exit(1);
     }

     sockfd = socket(AF_INET, SOCK_STREAM, 0);
     if (sockfd < 0) 
        error("ERROR opening socket");
     

     bzero((char *) &serv_addr, sizeof(serv_addr));
     portno = atoi(argv[1]);
     serv_addr.sin_family = AF_INET;
     serv_addr.sin_addr.s_addr = INADDR_ANY;
     serv_addr.sin_port = htons(portno);
     
     if (bind(sockfd, (struct sockaddr *) &serv_addr,
               sizeof(serv_addr)) < 0) 
              error("ERROR on binding");

     
     for(t=0;t<NUM_THREADS;t++){
      printf("In main: creating thread %ld\n", t);
      rc = pthread_create(&threads[t], NULL, ( void * )functions_list[t], (void *)t);
      if (rc){
       printf("ERROR; return code from pthread_create() is %d\n", rc);
       exit(-1);
      }
     }

     
     listen(sockfd,5);
     

     clilen = sizeof(cli_addr);
     newsockfd = accept(sockfd, 
                 (struct sockaddr *) &cli_addr, 
                 &clilen);
     if (newsockfd < 0) 
          error("ERROR on accept");



     bzero(buffer,256);


     n = read(newsockfd,buffer,255);
     if (n < 0) error("ERROR reading from socket");
     printf("Here is the message: %s\n",buffer);
     n = write(newsockfd,"I got your message",18);
     if (n < 0) error("ERROR writing to socket");

     close(newsockfd);
     close(sockfd);

     /* Last thing that main() should do */
     pthread_exit(NULL);

     return 0; 
}
