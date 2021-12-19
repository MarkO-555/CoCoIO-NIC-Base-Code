
Percom's PSYMON 1.20B monitor program for 6809 

With original PDF, original assembly source code and modified versions of the 
Psymon code for CoCo 1/2 and CoCo3.

The original Psymon was used on Motorola EXORcisor boards in the 1970s and it 
loads and runs from FC00 with only the MPU vectors reserved.

The CoCo1 version loads and runs Psymon at $6C00 so its for a 32K coco - but 
could be moved much lower for 16K or 4K. It's probably best to run 
CLEAR 200,&H6C00 before LOADM so that its protected from BASIC itself.

The CoCo3 version is sneakier - it loads in at $FC0A and uses RAM at $FE69 so 
that it can be co-resident with Super Extended BASIC without conflict rather 
than taking away a bit of the BASIC workspace RAM.
