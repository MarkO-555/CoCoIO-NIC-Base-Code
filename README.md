# CoCoIO-NIC-Base-Code
Base Code for WizNet5100 on Rick Ulland's CoCoIO card.

Current contributers are Rick Ulland, Robert Allen Murphey, and myself Mark D. Overholser


We are "mostly" working from Linux, so the Scripts to build code are BASH orented.
Intial Code is in EXTENDED BASIC..  With LWASM or GCC-6809 or CMOC to follow.
As we add features, the Tool Chain will grow.

Figure you will need a system setup like Bret Gordon does to build FIP for FUZIX 
and Add In CMOC, and a standard DriveWire setup.
At the very least, the current Code needs Extended Color BASIC, LWASM, and ToolShed to build a usable disk.

Read the 'build_fuzix-mod.txt' instructions to get a fairly complete Build System

These are Linux/Mac based tools, but since there are Windows versions of all these tools exsist, a Build Chain will be possible.


10-DEC-2021
New to the CoCoIO this Week are Ron Klein, John W. Linville, Boisy Pitre, Sloopy Malibu, L. Curtis Boyle, Bill Nobel and Henry Strickland...



The initial testing with the CoCoIO cards found that the Interface is "tempormental"..

Rick was eventually able to get a Card to Init, and those settings worked for me too.
Allen has not been able to get any CoCoIO to Init for him.
Ron's CoCo 2 is working, but with limited Add-Ons.  His CoCo 3 is not working.


Ron has setup a Google Doc for Tracking Machines and their Add-Ons and a Disk with a simple Extended BASIC Program and Machine Langauge program to Init and Setup the NIC and Display the Values, and then Displaying the NIC's values from BASIC.

SpreadSheet is here :
https://docs.google.com/spreadsheets/d/1NyhPcjeDkag4ztnvjJlQ0qJuosNgvWtPiBxzlAa89Ig/edit?usp=sharing

Disk is here :
https://drive.google.com/open?id=1h1LBVB2m-scQsk751tAnixlZzu2jyACo



Most of the Code here is for getting a CoCoIO to Init properly..   If you have the NIC setup for your Network, you can then PING the CoCoIO from another Node on the Network.  The Ping Response, ( ICMP ) is done in the Hardware of the WizNet5100.

Directories Allen, MarkO and Rick hold our various Test Code.. 

Rick's own GitHub is here: https://github.com/rickulland/CoCoIO

My Directory, 'MarkO' is a collecton of Allen's code, with my own additions..

There is very likely to have some Duplication of Code, I'm in the Process of Cleaning this up..  ( Directory 'Pending' comes to mind.. )


The Support_Software directory hold various Windows and Linux source code for Web Servers and Clients and Servers that can be used as a starting point for building a complete Network.
It is very likely that some Linux Executibles are in the Repo, most likely you will need to rebuild it for your system..

Source Code is to be compiled under GCC or some of the projects for a Windows host are in Open Watcom..

Get Open Watcom here: http://ftp.openwatcom.com/download.php 


