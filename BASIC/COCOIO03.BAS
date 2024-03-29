10 CLS
20 PRINT "  TESTING WIZNET 5100 SETUP  " : PRINT
50 GOTO 20000
100 REM SETUP WIZNET 5100
110 POKE &HFF68,&H80   'RESET 5100
120 POKE &HFF68,&H13   'AUTO:INC, INDRECT MODE, PING RESPOND 
130 REM
140 RETURN
150 REM

800 REM RESET WIZNET REGISTERS TO &H01
850 POKE &HFF69,&H00 : POKE &HFF6A,&H01   'START OF CONFIG
900 RETURN
995 REM

1000 ' ** GATEWAY **
1010 POKE &HFF69,&H00 : POKE &HFF6A,&H01
1020 POKE &HFF6B,192 : POKE &HFF6B,168 : POKE &HFF6B,253 : POKE &HFF6B,254
1030 REM
1040 RETURN

1100 POKE &HFF69,0 : POKE &HFF6A,01
1200 PRINT " GATEWAY"; PEEK(&HFF6B); PEEK(&HFF6B); PEEK(&HFF6B); PEEK(&HFF6B)
1300 REM
1400 RETURN

2000 ' ** SUBNET **
2010 POKE &HFF69,&H00 : POKE &HFF6A,&H05
2020 POKE &HFF6B,255 : POKE &HFF6B,255 : POKE &HFF6B,255 : POKE &HFF6B,0
2030 REM
2040 POKE &HFF69,&H00 : POKE &HFF6A,&H05
2050 PRINT "  SUBNET"; PEEK(&HFF6B); PEEK(&HFF6B); PEEK(&HFF6B); PEEK(&HFF6B)

2090 REM
3000 ' ** MAC ADDR **
3010 POKE &HFF69,&H00 : POKE &HFF6A,&H09
3020 POKE &HFF6B,1 : POKE &HFF6B,2 : POKE &HFF6B,3 : POKE &HFF6B,4 : POKE &HFF6B,5 : POKE &HFF6B,6
3030 REM
3050 POKE &HFF69,&H00 : POKE &HFF6A,&H09
3060 PRINT "MAC ADDR"; PEEK(&HFF6B); PEEK(&HFF6B); PEEK(&HFF6B); PEEK(&HFF6B); PEEK(&HFF6B); PEEK(&HFF6B)

3090 REM
4000 ' ** MY IP **
4010 POKE &HFF69,&H00 : POKE &HFF6A,&H0F
4020 POKE &HFF6B,192 : POKE &HFF6B,168 : POKE &HFF6B,253 : POKE &HFF6B,10
4030 REM
4070 POKE &HFF69,&H00 : POKE &HFF6A,&H0F
4080 PRINT "   MY IP"; PEEK(&HFF6B); PEEK(&HFF6B); PEEK(&HFF6B); PEEK(&HFF6B)

4090 REM
5000 PRINT : PRINT 
10000 '** RESULTS **
10010 POKE &HFF69,0 : POKE &HFF6A,01
10020 PRINT " GATEWAY"; PEEK(&HFF6B); PEEK(&HFF6B); PEEK(&HFF6B); PEEK(&HFF6B)
10030 POKE &HFF69,&H00 : POKE &HFF6A,&H05
10040 PRINT "  SUBNET"; PEEK(&HFF6B); PEEK(&HFF6B); PEEK(&HFF6B); PEEK(&HFF6B)
10050 POKE &HFF69,&H00 : POKE &HFF6A,&H09
10060 PRINT "MAC ADDR"; PEEK(&HFF6B); PEEK(&HFF6B); PEEK(&HFF6B); PEEK(&HFF6B); PEEK(&HFF6B); PEEK(&HFF6B)
10070 POKE &HFF69,&H00 : POKE &HFF6A,&H0F
10080 PRINT "   MY IP"; PEEK(&HFF6B); PEEK(&HFF6B); PEEK(&HFF6B); PEEK(&HFF6B)

