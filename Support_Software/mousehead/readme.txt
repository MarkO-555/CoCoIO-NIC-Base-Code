Mousehead

A network mouse server


This server sits on an link layer (LL) device in linux.  It formulates
mouse packets from a standardardize linux mouse device, and transmits
them over the the link to a client.  Also, this server translates the
delta x/y values into a coco friendly absoluted address and contrains
them axis to a client specified size before tranmission.  The client
also specifies the max frequency of transmitted packets to avoid
wasting link-layer bandwidth and the coco's (and underlaying NIC)
bandwidth.

The protocol:

There are three packet types: A connection packet (from client to
server (broadcasted)), data packets (from server to client), and a
cancel packet (from client to server).  The connect packet is
broadcast on the LL, the servers makes note of the sender's address
and pulls settings from this packet.  The client closes connection
with a cancel type message.  The client maintains the connection by
sending more connect messages to the server.  If no new connect
packets are received by the server in time, the server go back to
disconnected, and listening, *not* sending data packets to anyone.


Packet Descriptions (sans link layer addressing)


Connect (client to server)

offset size
     0    1   Family   unused
     1    1   Port     unused
     2    1   Type     PROTO_TYPE_CONNECT  (0)
     3    2   max X    screen x size
     5    2   max Y    screen y size
     7    2   time     minimum time between packets in milli seconds
     9    1   timeout  timeout in seconds



Data (server to client)

offset size
     0    1   Family   unused
     1    1   Port     unused
     2    1   Type     PROTO_TYPE_DATA  (1)
     3    2   X coord
     5    2   Y coord
     7    1   button state (right : middle : left)



Cancel (client to server)

offset size
     0    1   Family   unused
     1    1   Port     unused
     2    1   Type     PROTO_TYPE_CANEL  (2)
