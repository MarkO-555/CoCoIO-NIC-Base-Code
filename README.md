# CoCoIO-NIC-Base-Code
Base Code for WizNet5100 on Rick Ulland's CoCoIO card.

Current contributers are Rick Ulland, Robert Allen Murphey, and myself Mark D. Overholser


We are all working from Linux, so the Scripts to build code are BASH orented.   
Intial Code is in EXTENDED BASIC..  With LWASM or GCC-6809 or CMOC to follow.
As we add features, the Tool Chain will grow.

Figure you will need a system setup like Bret Gordon does for build FIP 
and Add In CMOC, and a more standard DriveWire setup.

Read the 'build_fuzix-mod.txt' instructions to get a fairly complete Build System

These are Linux/Mac based tools, but since Windows versions of all these tools exsist, a Build Chain will be possible.


10-DEC-2021
New to the CoCoIO this Week are Ron Klein, John W. Linville and Boisy Pitre...



The initial testing with the CoCoIO cards found that the Interface is "tempormental"..   

Rick was eventually able to get a Card to Init, and those settings worked for me too.
Allen has not been able to get any CoCoIO to Init for him.  
Ron's CoCo 2 is working, but with limited Add-Ons.  His CoCo 3 is not working.



Most of the Code here is for getting a CoCoIO to Init properly..   If you have the parameters setup for your Network, you can then PING the CoCoIO from another Node on the Network.

Directories Allen, MarkO and Rick hold our various Test Code.. 

Rick's own GitHub is here: https://github.com/rickulland/CoCoIO

My Directory, 'MarkO' is a collecton of Allen's code, with my own additions..

There is very likely to have some Duplication of Code, I'm in the Process of Cleaning this up..  ( Directory 'Pending' comes to mind.. )


The Support_Software directory hold various Windows and Linux source code for Web Servers and Clients and Servers that can be used as a starting point for building a complete Network.
It is very likely that some Linux Executibles are in the Repo, most likely you will need to rebuild it for your system..

Source Code is to be compiled under GCC or some of the projects for a Windows host are in Open Watcom..

Get Open Watcom here: http://ftp.openwatcom.com/download.php 


