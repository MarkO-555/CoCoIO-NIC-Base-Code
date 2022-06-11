10 PRINT "Percom's PSYMON 1.20B" : PRINT "monitor program for 6809"

20 PRINT : PRINT "modified versions for" : PRINT "CoCo 1/2 and CoCo3"

30 PRINT : PRINT "The CoCo1 version loads and" : PRINT "runs Psymon at $6C00"

40 PRINT : PRINT "It's probably best to run" : PRINT "'CLEAR 200,&H6C00' before LOADM"

50 PRINT : PRINT "The CoCo3 version is sneakier -" : PRINT "it loads in at $FC0A and uses RAM at $FE69"

60 PRINT : PRINT "so that it can be co-resident with" : PRINT "Super Extended BASIC without conflict rather"

70 PRINT : PRINT "than taking away a bit of" : PRINT "the BASIC workspace RAM."

  
 