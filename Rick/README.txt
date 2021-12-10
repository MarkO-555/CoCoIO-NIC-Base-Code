A couple things I have thrown together, plus the datasheets I am working from. 

CoCoIO.rtf            Will eventually be the manual. Ends at buffer wraparound until I get that debugged

5100Registers.ASM     extracted the addresses so you don't have to. EDTASM style, sed is your friend.

5100SOCKtest.ASC      fix all the hardcoded addresses, this will open a socket if the target has the 
                      appropriate server running (so telnet, because it's easy)

5100HTTPtest.ASC      NOT WORKING - once I can ping a web server, will have plenty of data to play with
                      buffer wraparound

