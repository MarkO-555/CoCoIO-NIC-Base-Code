
3 DIM IN$(16) : DIM OUT$(16) : REM BUFFERS 16 * 128 = 2048
4 IH=0 : IT=0 : OH=0 : OT=0 : ' IN HEAD/IN TAIL & OUT HEAD/OUT TAIL
6 X=0 : Y=0 : Z=0 : A$="" : B$="" : C$=""
7 S1=0 : S2=0 : S3=0 : S4=0 : P1=0 : P2=0 : P3=0 : P4=0
9 WH=0 : WL=0
11 H0=0 : H1=0 : H2=0 : H3=0 : T0=0 : T1=0 : T2=0 : T3=0
13 H4=0 : H5=0 : H6=0 : H7=0 : T4=0 : T5=0 : T6=0 : T7=0
20 CLS : PRINT "  TWIZNET 5100 V.01  " : PRINT
110 POKE &HFF68,&H80 : 'RESET 5100
120 POKE &HFF68,&H03 : 'AUTO INC, INDRECT MODE, PING RESPOND 
130 REM
900 'POKE &HFF69,&H00 : POKE &HFF6A,&H01   'START OF CONFIG
995 REM
1000 ' ** GATEWAY **
1010 POKE &HFF69,&H00 : POKE &HFF6A,&H01
1020 POKE &HFF6B,192 : POKE &HFF6B,168 : POKE &HFF6B,253 : POKE &HFF6B,254
1030 REM

1100 POKE &HFF69,0 : POKE &HFF6A,01
1200 PRINT " GATEWAY"; PEEK(&HFF6B); PEEK(&HFF6B); PEEK(&HFF6B); PEEK(&HFF6B)

2000 ' ** SUBNET **
2010 POKE &HFF69,&H00 : POKE &HFF6A,&H05
2020 POKE &HFF6B,255 : POKE &HFF6B,255 : POKE &HFF6B,255 : POKE &HFF6B,0
2030 REM
2040 POKE &HFF69,&H00 : POKE &HFF6A,&H05
2050 PRINT "  SUBNET"; PEEK(&HFF6B); PEEK(&HFF6B); PEEK(&HFF6B); PEEK(&HFF6B)

2090 REM
3000 ' ** MAC ADDR **
3010 POKE &HFF69,&H00 : POKE &HFF6A,&H09
3020 POKE &HFF6B,&HAA : POKE &HFF6B,&H55 : POKE &HFF6B,&HAA : POKE &HFF6B,&H55 : POKE &HFF6B,&HAA : POKE &HFF6B,&H55
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
4100 ' ** RESET I/O BUFFERS TO 8KB EACH **
4110 POKE &HFF69,&H00 : POKE &HFF6A,&H1A
4120 POKE &HFF6B,&H03 : POKE &HFF6B,&H03 : ' ** 8KB TO SOCKET 0, I & O **
4130 PRINT "   BUFFER IS 8KB" 



5000 PRINT "SETUP FOREIGN CONNECTION"
5100 ' ** TCP MODE **
5110 POKE &HFF69,&H04 : POKE &HFF6A,&H00
5120 POKE &HFF6B,&H01 
5130 '
5150 ' ** LOCAL PORT **
5160 POKE &HFF69,&H04 : POKE &HFF6A,&H04
5170 POKE &HFF6B,&HC0 : POKE &HFF6B,&H00 : ' ** &HC000 (49152) ** 
5180 '
5200 ' ** FOREIGN ADDRESS **
5210 POKE &HFF69,&H04 : POKE &HFF6A,&H0C
5220 POKE &HFF6B,&HC0 :  POKE &HFF6B,&HA8 : POKE &HFF6B,&HFD : POKE &HFF6B,&H64 : ' ** 192.168.253.100 **
5230 '
5250 ' ** FOREIGN PORT **
5260 'POKE &HFF69,&H04 : POKE &HFF6A,&H10
5270 'POKE &HFF6B,&H1B : POKE &HFF6B,&H62 : ' ** &H1B62 (7010) ** 
5280 POKE &HFF6B,&H4E : POKE &HFF6B,&H20 : ' ** &H4E20 (20000) ** 
5290 '
5300 ' ** TCP OPEN SOCKET **
5310 POKE &HFF69,&H04 : POKE &HFF6A,&H01
5320 POKE &HFF6B,&H01
5330 '
5350 ' ** CHECK STATUS **
5360 POKE &HFF69,&H04 : POKE &HFF6A,&H03
5370 S1=PEEK (&HFF6B) : IF S1<>&H13 THEN 60000 : ' ** &H13 IS SOCKET OPEN **
5380 '
5400 ' ** TCP CONNECT SOCKET **
5410 POKE &HFF69,&H04 : POKE &HFF6A,&H01
5420 POKE &HFF6B,&H04
5430 '
5450 ' ** CHECK STATUS **
5460 POKE &HFF69,&H04 : POKE &HFF6A,&H03
5470 S1=PEEK (&HFF6B) : IF S1=&H00 THEN 60010 : ' ** &H00 IS SOCKET CLOSED **
5480 IF S1<>&H17 THEN 5450 : ' ** &H17 IS SOCKET ESTABLISHED **
5490 '
5500 '
5510 '
5510 '
5900 H0=&H4000 : T0=&H4000 : H4=&H6000 : T4=&H6000
6000 ' ** START MAIN LOOP FOR I/O **
6010 INPUT "ENTER SOMETHING:"; OUT$(1)
6020 IF LEN(OUT$(1)) = &H00 THEN 9990
6100 ' ** SET BUFFER AND WRITE **
6110 PRINT "SENDING YOUR 'SOMETHING'-->"
6120 POKE &HFF69,&H40 : POKE &HFF6A,&H00
6140 FOR X = 1 TO LEN(OUT$(1)) 
6150 POKE &HFF6B,ASC(LEFT$(OUT$(1),X))
6160 NEXT X
6170 ' ** SEND SOCKET SEND COMMAND **
6180 POKE &HFF69,&H04 : POKE &HFF6A,&H01 : POKE &HFF6B,&H20
6190 FOR X=0 TO 200 : NEXT X
6990 '
7000 ' ** CHECK STATUS FOR INCOMMING **
7010 POKE &HFF69,&H04 : POKE &HFF6A,&H26
7020 S1=PEEK (&HFF6B)*&HFF : S1=S1+PEEK (&HFF6B)
7030 IF S1=&H00 THEN 60000 : ' ** &H00 IS NO DATA **
7040 POKE &HFF69,&H60 : POKE &HFF6A,&H00
7050 FOR X = 1 TO S1 
7060 IN$(X)=CHR$(PEEK (&HFF6B))
7070 NEXT X
7080 PRINT IN$
7090 FOR X=0 TO 200 : NEXT X
7000 '
7010 '
7020 GOTO 6000
8000 '
8010 '
8020 '
8030 '
9990 PRINT : PRINT "END OF RUN..." : PRINT :PRINT "    COMMENCE DUMP...." 
10000 PRINT : PRINT : PRINT "** RESULTS (CHECK) **"
10010 POKE &HFF69,0 : POKE &HFF6A,01
10020 PRINT " GATEWAY"; PEEK(&HFF6B); PEEK(&HFF6B); PEEK(&HFF6B); PEEK(&HFF6B)
10030 POKE &HFF69,&H00 : POKE &HFF6A,&H05
10040 PRINT "  SUBNET"; PEEK(&HFF6B); PEEK(&HFF6B); PEEK(&HFF6B); PEEK(&HFF6B)
10050 POKE &HFF69,&H00 : POKE &HFF6A,&H09
10060 PRINT "MAC ADDR"; PEEK(&HFF6B); PEEK(&HFF6B); PEEK(&HFF6B); PEEK(&HFF6B); PEEK(&HFF6B); PEEK(&HFF6B)
10070 POKE &HFF69,&H00 : POKE &HFF6A,&H0F
10080 PRINT "   MY IP"; PEEK(&HFF6B); PEEK(&HFF6B); PEEK(&HFF6B); PEEK(&HFF6B)
20000 REM
20010 GOTO 60020
59000 END
60000 ' ** TCP CLOSE SOCKET **
60002 POKE &HFF69,&H04 : POKE &HFF6A,&H01
60004 POKE &HFF6B,&H10
60006 PRINT : PRINT "FOREIGN HOST OPEN FAIL..." : END
60008 '
60010 ' ** TCP CLOSE SOCKET **
60012 POKE &HFF69,&H04 : POKE &HFF6A,&H01
60014 POKE &HFF6B,&H10
60016 PRINT : PRINT "SOCKET OPEN FAIL..." : END
60018 '
60020 ' ** TCP CLOSE SOCKET **
60022 POKE &HFF69,&H04 : POKE &HFF6A,&H01
60024 POKE &HFF6B,&H10
60026 PRINT : PRINT "YOUR DONE..." : END
60028 '
