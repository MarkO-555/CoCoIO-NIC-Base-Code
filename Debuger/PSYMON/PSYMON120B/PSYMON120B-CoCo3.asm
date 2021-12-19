       NAM   PSYMON


*************************************************
* PSYMON VERSION 1.20                           *
* A 6809 ROM MONITOR                            *
*                                               *
* THE PERCOM SYSTEM MONITOR (PSYMON) WAS        *
* WRITTEN BY A TEAM OF PROGRAMMERS USING        *
* STRUCTURED TECHNIQUES.  THE TEAM MEMBERS      *
* ARE AS FOLLOWS:                               *
*     HAROLD A MAUCH - PRESIDENT, PERCOM DATA   *
*     MIKE FOREMAN - 6809 PROJECT LEADER        *
*     BYRON SEASTRUNK - DESIGN ENGINEER         *
*     CLIFF RUSHING - PROGRAMMER                *
*     JIM STUTSMAN - CHIEF PROGRAMMER           *
*                                               *
* COPYRIGHT (c) 1979 PERCOM DATA COMPANY, INC.  *
* USE OF THIS SOFTWARE IS GRANTED ROYALTY-FREE  *
* AS LONG AS THE USER CLEARLY ACKNOWLEDGES ITS  *
* ORIGIN.                                       *
*                                               *
* WHILE THIS MONITOR IS VERY SIMPLE, ITS TRUE   *
* POWER LIES IN ITS EXTENSIBILITY AND IN THE    *
* TOOLS THAT IT PROVIDES FOR OTHER SOFTWARE     *
* TO USE.  THIS OPERATING SYSTEM IS DEDICATED   *
* TO HAROLD MAUCH AND HIS LEGENDARY 512 BYTE    *
* OPERATING SYSTEM.                             *
*                                               *
* COMMANDS:                                     *
*   M <ADDRESS> - MEMORY EXAMINE/CHANGE         *
*   G <ADDRESS> - GO TO ADDRESS                 *
*   R <REGISTER> - REGISTER EXAMINE/CHANGE      *
*   L - LOAD PROGRAM FROM TAPE                  *
*   S <START> <END> - SAVE PROGRAM TO TAPE      *
*   B <ADDRESS> - SET/LIST BREAKPOINTS          *
*   U <ADDRESS> - UNSET BREAKPOINTS             *
*   Z - JUMP TO PROM AT ADDRESS C000 HEX        *
*                                               *
* CALLABLE SUBROUTINES:                         *
*   INCHR - INPUT CHARACTER FROM CONSOLE        *
*   OUTCHR - OUTPUT CHARACTER TO CONSOLE        *
*   REQIO - PERFORM I/O TO PERIPHERAL           *
*   GETHEX - INPUT HEX NUMBER FROM CONSOLE      *
*   INHEX - INPUT HEX DIGIT FROM CONSOLE        *
*   DSPSBY - DISPLAY SINGLE BYTE & SPACE        *
*   DSPDBY - DISPLAY DOUBLE BYTE & SPACE        *
*   OUTHEX - DISPLAY 2 HEX DIGIST               *
*   PSTRNG - DIPLAY STRING ON CONSOLE           *
*   LOAD - LOAD HEX PROGRAM FROM CONSOLE        *
*   SAVE - SAVE HEX PROGRAM TO CONSOLE          *
*   CRLF - BEGIN NEW LINE ON CONSOLE            *
*   OUTS - OUTPUT SPACE TO CONSOLE              *
*                                               *
* ALL I/O WITHIN PSYMON IS DONE THROUGH THE     *
* USE OF DEVICE CONTROL BLOCKS.  THIS ALLOWS    *
* EASY MODIFICATION BY THE USER.  PSYMON HAS    *
* FOUR DCB POINTERS INITIALIZED TO POINT TO THE *
* CONSOLE (ACIA) DCB.  THEY ARE USED AS         *
* FOLLOWS:                                      *
*   CIDCB - POINTS TO DCB USED FOR CONSOLE      *
*           INPUT (CHARACTER I/O).              *
*   CEDCB - POINTS TO DCB USED FOR ECHO OF      *
*           CHARACTERS RECEIVED USING CIDCB.    *
*           ECHO MAY BE SUPPRESSED BY SETTING   *
*           THIS POINTER TO ZERO.               *
*   CODCB - POINTS TO DCB USED FOR CONSOLE      *
*           OUTPUT (CHARACTER I/O).             *
*   TPDCB - POINTS TO DCB USED FOR PSYMON       *
*           TAPE LOAD & SAVE COMMANDS           *
*                                               *
* THE PSYMON COMMAND TABLE MAY BE EXTENDED      *
* OR CHANGED BY SETTING THE POINTER 'USRTBL'    *
* TO THE ADDRESS OF A USER COMMAND TABLE.  IT   *
* IS INITIALIZED TO ZERO, INDICATING NO USER    *
* TABLE EXISTS.                                 *
*                                               *
* ADDITIONAL INFORMATION REGARDING THE USE OF   *
* 'PSYMON' MAY BE OBTAINED FROM:                *
*     PERCOM DATA COMPANY, INC.                 *
*     211 NORTH KIRBY                           *
*     GARLAND, TEXAS  75042                     *
*                                               *
* REVISION A - 11/23/79                         *
*   ADDITION OF A VECTOR FOR SCRATCHPAD RAM     *
*                                               *
* REVISION B - 02/08/80                         *
*   ADDITIONAL OF A VECTOR FOR FREE RAM         *
*                                               *
*************************************************

* SYSTEM ADDRESS CONSTANTS
ROM1   EQU   $FA0C    BASE ADDRESS OF PSYMON ROM
ROM2   EQU   $D7DD    BASE ADDRESS OF EXTENSION ROM
RAM    EQU   $FE69    BASE ADDRESS OF SCRATCHPAD RAM
FREE   EQU   $1E00    ADDRESS OF FREE RAM
TERMNL EQU   $FF00    SYSTEM TERMINAL PIA
POLCAT EQU   $A000    POLL COCO KEYBOARD FOR A CHARACTER
CHROUT EQU   $A002    OUTPUT A CHARACTER TO DEVICE

* ASCII CHARACTER CONSTANTS
CR     EQU   $0D      CARRIAGE RETURN
LF     EQU   $0A      LINE FEED
SP     EQU   $20      SPACE

* ACIA CONTROL CONFIGURATIONS
RESET  EQU   $03      RESET ACIA
CONFIG EQU   $51      SET FOR 8 DATA, 2 STOP, NO PARITY
RDRON  EQU   CONFIG-$40  READER ON (RTS ON)
RDROFF EQU   CONFIG   READER OFF (RTS OFF)

* PSYMON DCB OFFSETS
DCBLNK EQU   0        POINTER TO NEXT DCB IN CHAIN
DCBDID EQU   2        ASCII 2 CHARACTER DEVICE ID
DCBDVR EQU   4        DEVICE DRIVER ADDRESS
DCBIOA EQU   6        DEVICE I/O ADDRESS
DCBERR EQU   8        ERROR STATUS CODE
DCBEXT EQU   9        NUMBER OF EXTENSION BYTES IN DCB
DCBAPP EQU   10       DCB APPENDAGE FOR DRIVER USE

* PSYMON DCB FUNCTION CODES
READFN EQU   $01      READ FUNCTION CODE
WRITFN EQU   $02      WRITE FUNCTION CODE
STATFN EQU   $04      STATUS FUNCTION CODE
CNTLFN EQU   $08      DEVICE CONTROL FUNCTION CODE

* PSYMON RAM DEFINITIONS
       ORG   RAM

* PSYMON INTERNAL STACK & REGISTER SPACE
*   OFFSETS TO RAM BASE IN PARENTHESES
       RMB   55       STACK SPACE
STACK  EQU   *        (55) TOP OF STACK
REGC   RMB   1        (55) CONDITION CODE REGISTER
REGA   RMB   1        (56) A REGISTER
REGB   RMB   1        (57) B REGISTER
REGD   RMB   1        (58) DIRECT PAGE REGISTER
REGX   RMB   2        (59) X REGISTER
REGY   RMB   2        (61) Y REGISTER
REGU   RMB   2        (63) U STACK POINTER
REGP   RMB   2        (65) PROGRAM COUNTER

* PSYMON BREAKPOINT TABLE
BPTABL RMB   15       (67) SPACE FOR 5 BREAKPOINTS
BPTEND EQU   *        (82) END OF BREAKPOINT TABLE

* PSYMON WORK AREAS
MEMPTR RMB   2        (82) MEMORY POINTER FOR 'M' COMMAND
USRTBL RMB   2        (84) ADDRESS OF USER COMMAND TABLE
COMAND RMB   1        (86) COMMAND CHARACTER STORAGE
CKSUM  RMB   1        (87) CHECKSUM FOR LOAD AND SAVE
BEGADD RMB   2        (88) BEGIN ADDRESS FOR SAVE
ENDADD RMB   2        (90) END ADDRESS FOR SAVE
STKPTR RMB   2        (92) CONTENTS OF STACK POINTER

* THE PSYMON CONSOLE DCB
CONDCB RMB   10       (94) STANDARD DCB

* PSYMON DCB POINTERS
DCBCHN RMB   2        (104) BASE OF DCB CHAIN
CIDCB  RMB   2        (106) CONSOLE INPUT DCB
CEDCB  RMB   2        (108) CONSOLE ECHO DCB
CODCB  RMB   2        (110) CONSOLE OUTPUT DCB
TPDCB  RMB   2        (112) CASSETTE TAPE DCB

* PSYMON VECTORS
SWI3V  RMB   2        (114) SOFTWARE INTERRUPT 3
SWI2V  RMB   2        (116) SOFTWARE INTERRUPT 2
FIRQV  RMB   2        (118) FAST INTERRUPT REQUEST
IRQV   RMB   2        (120) INTERRUPT REQUEST
SWIV   RMB   2        (122) SOFTWARE INTERRUPT
NMIV   RMB   2        (124) NON-MASKABLE INTERRUPT
FRERAM RMB   2        (126) ADDRESS OF FREE RAM

* PSYMON ROM CODING
       ORG   ROM1
*************************************************
* PSYMON INITIALIZATION                         *
*************************************************
INIT   LDS   #STACK   SET UP STACK POINTER
       TFR   S,X      POINT X AT STACK
INIT1  CLR   ,X+      CLEAR A BYTE
       CMPX  #CONDCB+2  ALL FIELDS CLEAR?
       BNE   INIT1    LOOP IF NOT
       LDY   #RAMINT  POINT TO RAM DATA
INIT2  LDD   ,Y++     MOVE 2 BYTES
       STD   ,X++
       CMPX  #FRERAM+2  END OF RAM?
       BNE   INIT2    LOOP IF NOT
       * LDX   #CONDCB  POINT TO DCB
       * LDD   #RESET*256+CNTLFN  A=RESET, B=CNTLFN
       * JSR   REQIO    RESET ACIA
       * LDA   #CONFIG  CONFIGURE ACIA
       * JSR   REQIO
       LDA   ROM2     CHECK FOR SECOND ROM
       CMPA  #$7E     IS THERE A JUMP THERE?
       BNE   MONENT   GO IF NOT
       JSR   ROM2     CALL SECOND ROM

*************************************************
* PSYMON USER ENTRY                             *
*************************************************
MONENT STS   STKPTR   SAVE STACK POINTER

*************************************************
* GET COMMAND                                   *
*************************************************
GETCMD LDX   #PROMPT  DISPLAY PROMPT
       JSR   PSTRNG
       JSR   INCHR    INPUT COMMAND CHARACTER
       BSR   LOOKUP   LOOK IT UP
       BNE   GETCMD   LOOP IF NOT FOUND
       JSR   OUTSP    OUTPUT A SPACE
       JSR   [,X]     CALL COMMAND ROUTINE
       BRA   GETCMD   GO BACK FOR MORE

PROMPT FCB   CR,LF
       FCC   'CMD'
       FCB   '?+$80   END OF STRING

*************************************************
* LOOK UP COMMAND IN TABLE                      *
*************************************************
LOOKUP LDY   #COMAND  POINT Y TO COMMAND
       STA   ,Y       SAVE COMMAND CHARACTER
       LDX   USRTBL   GET USER TABLE ADDRESS
       BEQ   LOOK1    GO IF NONE
       BSR   SEARCH   SEARCH USER TABLE
       BEQ   SERCHX   GO IF FOUND
LOOK1  LDX   #CMDTBL  SEARCH INTERNAL TABLE

*************************************************
* GENERAL TABLE SEARCH                          *
*                                               *
* ENTRY REQUIREMENTS:  X - POINTS TO TABLE      *
*                      Y - POINTS TO ITEM       *
*                      FIRST BYTE OF TABLE MUST *
*                      CONTAIN ITEM LENGTH      *
*                      LAST BYTE MUST BE FF     *
*                                               *
* EXIT CONDITIONS:  C - Z SET IF FOUND, CLEAR   *
*                       IF NOT FOUND            *
*                   X - POINTS TO ADDRESS OF    *
*                       ROUTINE FOR MATCH       *
*                   A,B - CHANGED               *
*                                               *
*************************************************
SEARCH LDB   ,X+      GET ITEM LENGTH
SERCH1 BSR   COMPAR   COMPARE CURRENT ITEM
       ABX            ADVANCE TO NEXT ITEM
       BEQ   SERCHX   EXIT IF MATCH
       LEAX  2,X      STEP OVER ADDRESS
       TST   ,X       END OF TABLE?
       BPL   SERCH1   LOOP IF NOT
SERCHX RTS

*************************************************
* GENERAL STRING COMPARE                        *
*                                               *
* ENTRY REQUIREMENTS:  X - ADDRESS OF STRING 1  *
*                      Y - ADDRESS OF STRING 2  *
*                      B - LENGTH OF STRINGS    *
*                                               *
* EXIT CONDITIONS:  C - SET PER COMPARE 1:2     *
*                   B,X,Y - UNCHANGED           *
*                   A - CHANGED                 *
*                                               *
*************************************************
COMPAR PSHS  B,X,Y    SAVE REGISTERS
COMP1  LDA   ,X+      GET NEXT CHARACTER
       CMPA  ,Y+      COMPARE IT
       BNE   COMP2    EXIT IF UNMATCHED
       DECB           DECREMENT LOOP COUNT
       BNE   COMP1
COMP2  PULS  B,X,Y,PC RESTORE REGISTERS & EXIT

*************************************************
* LOAD PROGRAM FROM TAPE                        *
*************************************************
TLOAD  LDD   CIDCB    SAVE CONSOLE DCBS
       LDX   CEDCB
       PSHS  A,B,X
       LDX   TPDCB    POINT TO TAPE DCB
       CLRA           SET D TO 0
       CLRB
       STX   CIDCB    SET TAPE IN, NO ECHO
       STD   CEDCB
       LDD   #RDRON*256+CNTLFN  RAISE READER CONTROL
       JSR   REQIO
       BSR   LOAD     LOAD THE TAPE
       LDD   #RDROFF*256+CNTLFN  DROP READ CONTROL
       LDX   TPDCB
       JSR   REQIO
       PULS  A,B,X    RESTORE CONSOLE DCBS
       STD   CIDCB
       STX   CEDCB
       TST   CKSUM    ANY ERRORS?
       BEQ   LOADX    GO IF NOT

*************************************************
* DISPLAY ERROR INDICATOR OF '?'                *
*************************************************
ERROR  LDA   #'?      DISPLAY ERROR INDICATOR
       JMP   OUTCHR

*************************************************
* LOAD PROGRAM IN HEX FORMAT                    *
*                                               *
* ENTRY REQUIREMENTS:  NONE                     *
*                                               *
* EXIT CONDITIONS:  ALL REGISTERS CHANGED       *
*                   CKSUM NON-ZERO IF ERROR     *
*                                               *
*************************************************
LOAD   TFR   S,Y      MARK STACK FOR ERROR RECOVERY
LOAD1  JSR   INCHR    GET A CHARACTER
LOAD2  CMPA  #'S      START OF RECORD?
       BNE   LOAD1    LOOP IF NOT
       JSR   INCHR    GET ANOTHER CHARACTER
       CMPA  #'9      END OF LOAD?
       BEQ   LOADX    GO IF YES
       CMPA  #'1      START OF RECORD?
       BNE   LOAD2    LOOP IF NOT
       CLR   CKSUM    INIT CHECKSUM
       BSR   INBYTE   READ LENGTH
       SUBA  #2       ADJUST IT
       TFR   A,B      SAVE IN B
       BSR   INBYTE   GET ADDRESS HI
       STA   ,--S     SAVE ON STACK
       BSR   INBYTE   GET ADDRESS LO
       STA   1,S      PUT ON STACK
       PULS  X        ADDRESS NOW IN X
LOAD3  BSR   INBYTE   READ A BYTE 
       DECB           DECREMENT COUNT
       BEQ   LOAD4    GO IF DONE
       STA   ,X       STORE BYTE
       CMPA  ,X+      VERIFY GOOD STORE
       BNE   LOAD5    GO IF ERROR
       BRA   LOAD3
LOAD4  INC   CKSUM    CHECK CHECKSUM
       BEQ   LOAD1    LOOP IF GOOD
LOAD5  LDA   #$FF     SET ERROR FLAG
       STA   CKSUM
       TFR   Y,S      RESTORE STACK
LOADX  RTS

*************************************************
* INPUT BYTE                                    *
*************************************************
INBYTE BSR   INHEX    GET HEX DIGIT
       BEQ   LOAD4    GO IF ERROR
       ASLA           SHIFT TO MS HALF
       ASLA
       ASLA
       ASLA
       PSHS  A        SAVE DIGIT
       BSR   INHEX    GET ANOTHER DIGIT
       BEQ   LOAD4    GO IF ERROR
       ADDA  ,S       COMBINE HALVES
       STA   ,S       SAVE ON STACK
       ADDA  CKSUM    ADD TO CHECKSUM
       STA   CKSUM
       PULS  A,PC     GET RESULT & RETURN

*************************************************
* GET HEX NUMBER FROM CONSOLE                   *
*                                               *
* ENTRY REQUIREMENTS:  NONE                     *
*                                               *
* EXIT CONDITIONS:  A - LAST CHAR INPUT         *
*                   B - HEX DIGIT COUNT         *
*                   X - HEX NUMBER              *
*                   C - SET ACCORDING TO B      *
*                                               *
*************************************************
GETHEX CLRB           INITIALIZE DIGIT COUNT, RESULT
       LDX   #0
GETHX1 BSR   INHEX    GET A DIGIT
       BEQ   GETHX2   GO IF NOT HEX
       EXG   D,X      OLD RESULT TO A,B
       ASLB           SHIFT LEFT 1 DIGIT
       ROLA
       ASLB
       ROLA
       ASLB
       ROLA
       ASLB
       ROLA
       EXG   D,X      REPLACE RESULT
       LEAX  A,X      ADD IN NEW DIGIT
       INCB           ADD TO DIGIT COUNT
       BRA   GETHX1   LOOP FOR MORE
GETHX2 TSTB           SET/RESET Z FLAG
       RTS

*************************************************
* GET HEX DIGIT FROM CONSOLE                    *
*                                               *
* ENTRY REQUIREMENTS:  NONE                     *
*                                               *
* EXIT CONDITIONS:  A - HEX DIGIT OR NON-HEX    *
*                   C - Z FLAG SET IF A NOT HEX *
*                   ALL OTHER REGS PRESERVED    *
*                                               *
*************************************************
INHEX  BSR   INCHR    GET A CHARACTER
       PSHS  A        SAVE IT
       SUBA  #$30     CONVERT TO BINARY
       BMI   INHEX2   GO IF NOT A NUMBER
       CMPA  #$09     GREATER THAN 9?
       BLS   INHEX1   GO IF NOT
       SUBA  #$07     CONVERT LETTER
       CMPA  #$0A     LEGAL VALUE?
       BLO   INHEX2   GO IF NOT
INHEX1 CMPA  #$0F     GREATER THAN 15?
       BLS   INHEX3   GO IF NOT
INHEX2 LDA   ,S       GET ORIGINAL CHAR BACK
INHEX3 CMPA  ,S+      SET/RESET Z FLAG
       RTS

*************************************************
* CONSOLE INPUT ROUTINE                         *
*                                               *
* ENTRY REQUIREMENTS:  NONE                     *
*                                               *
* EXIT CONDITIONS:  A - CHARACTER WITH PARITY   *
*                       REMOVED                 *
*                   ALL OTHER REGS PRESERVED    *
*                   EXCEPT C                    *
*                                               *
*************************************************
INCHR  PSHS  B,X      SAVE REGISTERS
       LDX   CIDCB    POINT TO INPUT DCB
       LDB   #READFN  SET UP FOR READ
       BSR   REQIO    READ A CHARACTER
       ANDA  #$7F     REMOVE PARITY
       LDX   CEDCB    POINT TO ECHO DCB
       PSHS  A        SAVE CHARACTER
       BNE   OUTCH1   GO IF ECHO
       PULS  A,B,X,PC RESTORE & RETURN

*************************************************
* CONSOLE OUTPUT ROUTINE                        *
*                                               *
* ENTRY REQUIREMENTS:  A - CHARACTER TO BE      *
*                          OUTPUT TO CONSOLE    *
*                                               *
* EXIT CONDITIONS:  ALL REGISTERS PRESERVED     *
*                   EXCEPT C                    *
*                                               *
*************************************************
OUTCHR PSHS  A,B,X    SAVE REGISTERS
       LDX   CODCB    POINT TO OUTPUT DCB
OUTCH1 LDB   #WRITFN  SET FUNCTION
       BSR   REQIO    OUTPUT THE CHARACTER
       PULS  A,B,X,PC RESTORE REGISTERS & RETURN

*************************************************
* PERFORM I/O REQUESTS                          *
*                                               *
* ENTRY REQUIREMENTS:  A - DRIVER PARAMETER     *
*                      B - FUNCTION CODE        *
*                      X - DCB ADDRESS          *
*                                               *
* EXIT CONDITIONS:  A - DRIVER RESULT           *
*                   ALL OTHERS PRESERVED        *
*                   EXCEPT C                    *
*                                               *
*************************************************
REQIO  PSHS  B,DP,X,Y,U  SAVE REGISTERS
       JSR   [DCBDVR,X]  CALL DRIVER
       PULS  B,DP,X,Y,U,PC  RESTORE REGISTERS & EXIT

*************************************************
* DISPLAY DOUBLE BYTE                           *
*                                               *
* ENTRY REQUIREMENTS:  A,B - DOUBLE BYTE        *
*                            TO BE PRINTED      *
*                                               *
* EXIT CONDITIONS:  ALL REGISTERS PRESERVED     *
*                   EXCEPT C                    *
*                                               *
*************************************************
DSPDBY BSR   OUTHEX   DISPLAY A AS 2 HEX DIGITS
       EXG   A,B      LS BYTE TO A
       BSR   DSPSBY   DISPLAY AS 2 DIGITS, SPACE
       EXG   A,B      RESTORE A & B
       RTS

*************************************************
* DISPLAY A BYTE AND SPACE                      *
*                                               *
* ENTRY REQUIREMENTS:  A - BYTE TO BE DISPLAYED *
*                                               *
* EXIT CONDITIONS:  ALL REGISTERS PRESERVED     *
*                   EXCEPT C                    *
*                                               *
*************************************************
DSPSBY BSR   OUTHEX   DISPLAY BYTE IN A

*************************************************
* OUTPUT A SPACE TO THE CONSOLE                 *
*                                               *
* ENTRY REQUIREMENTS:  NONE                     *
*                                               *
* EXIT CONDITIONS:  ALL REGISTERS PRESERVED     *
*                   EXCEPT C                    *
*                                               *
*************************************************
OUTSP  PSHS  A        SAVE A REGISTER
       LDA   #SP      OUTPUT A SPACE

*************************************************
* OUTPUT CHARACTER, RESTORE A, & RETURN         *
*************************************************
OUTCHX BSR   OUTCHR   DISPLAY CHARACTER
       PULS  A,PC     RESTORE & EXIT

*************************************************
* DISPLAY A REGISTER AS 2 HEX DIGITS            *
*                                               *
* ENTRY REQUIREMENTS:  A - BYTE TO DISPLAY      *
*                                               *
* EXIT CONDITIONS: ALL REGISTERS PRESERVED      *
*                  EXCEPT C                     *
*                                               * 
*************************************************
OUTHEX PSHS  A       SAVE THE BYTE
       LSRA
       LSRA
       LSRA
       LSRA
       BSR   OUTDIG  DISPLAY IT
       LDA   ,S      GET LS DIGIT
       BSR   OUTDIG  DISPLAY IT
       PULS  A,PC    RESTORE A & RETURN

*************************************************
* DISPLAY A HEX DIGIT                           *
*************************************************
OUTDIG ANDA  #$0F     MASK OFF DIGIT
       ADDA  #$30     CONVERT TO ASCII
       CMPA  #$39     BIGGER THAN 9?
       BLS   OUTCHR   GO IF NOT
       ADDA  #$07     CONVERT TO LETTER
       BRA   OUTCHR   PRINT AND EXIT

*************************************************
* PRINT A STRING TO THE CONSOLE                 *
*                                               *
* ENTRY CONDITIONS:  X - POINTS TO STRING       *
*                    LAST BYTE HAS BIT 7 ON     *
*                                               *
* EXIT CONDITIONS:  X - POINTS 1 BYTE PAST END  *
*                   A,C - CHANGED               *
*                                               *
*************************************************
PSTRNG LDA   ,X       GET A CHARACTER
       ANDA  #$7F     MASK OFF
       BSR   OUTCHR   DISPLAY IT
       TST   ,X+      WAS IT LAST?
       BPL   PSTRNG   LOOP IF NOT
       RTS

*************************************************
* PRINT CR/LF ON CONSOLE                        *
*                                               *
* ENTRY REQUIREMENTS:  NONE                     *
*                                               *
* EXIT CONDITIONS:  ALL REGISTERS PRESERVED     *
*                   EXCEPT C                    *
*                                               *
*************************************************
CRLF   PSHS  A        SAVE A REGISTER
       LDA   #CR      OUTPUT CR
       BSR   OUTCHR
       LDA   #LF      OUTPUT LF & EXIT
       BRA   OUTCHX

*************************************************
* SAVE PROGRAM ON TAPE                          *
*************************************************
TSAVE  BSR   GETHX    GET START ADDRESS
       BEQ   TSAVE2   GO IF NONE
       STX   BEGADD   SAVE START
       BSR   GETHX    GET END ADDRESS
       BNE   TSAVE1   GO IF ENTERED
       LDX   BEGADD   DUPLICATE ADDRESS
       INCB           SET ADDRESS INDICATOR
TSAVE1 STX   ENDADD   SAVE END
TSAVE2 LDX   CODCB    SAVE CONSOLE DCB
       PSHS  A,X      SAVE TERMINATOR TOO
       LDX   TPDCB    SET UP FOR TAPE
       STX   CODCB
       TSTB           ANY ADDRESS ENTERED?
       BEQ   TSAVE3   GO IF NOT
       BSR   SAVE     SAVE THE PROGRAM
TSAVE3 PULS  A        GET TERMINATOR
       CMPA  #CR      WAS IT RETURN?
       BNE   TSAVE4   GO IF NOT
       LDB   #'9      OUTPUT S9 RECORD
       BSR   OUTSN
TSAVE4 PULS  X        RESTORE DCB POINTER
       STX   CODCB
       RTS

*************************************************
* GET HEX NUMBER IN X                           *
*************************************************
GETHX  JMP   GETHEX   RELATIVE BRANCH BOOSTER

*************************************************
* SAVE A PROGRAM IN HEX                         *
*                                               *
* ENTRY REQUIREMENTS:  SAVE ADDRESSES ARE IN    *
*                      BEGADDR & ENDADDR        *
*                                               *
* EXIT CONDITIONS:  ALL REGISTERS CHANGED       *
*                                               *
*************************************************
SAVE   LDX   BEGADD   POINT AT FIRST BYTE
SAVE1  LDB   #'1      BEGIN NEW S1 RECORD
       BSR   OUTSN
       CLR   CKSUM    INIT CHECKSUM
       LDD   ENDADD   CALCULATE BYTES TO SAVE
       PSHS  X
       SUBD  ,S++
       TSTA           GREATER THAN 255?
       BNE   SAVE2    GO IF YES
       CMPB  #16      LESS THAN FULL RECORD?
       BLO   SAVE3    GO IF YES
SAVE2  LDB   #15      SET FULL RECORD SIZE
SAVE3  INCB           CORRECT RECORD SIZE
       TFR   B,A      OUTPUT RECORD SIZE
       ADDA  #3       ADJUST FOR ADDRESS,COUNT
       BSR   OUTBYT
       PSHS  X        ADDRESS TO STACK
       PULS  A        OUTPUT ADDRESS HI
       BSR   OUTBYT
       PULS  A        OUTPUT ADDRESS LO
       BSR   OUTBYT
SAVE4  LDA   ,X+      SAVE A DATA BYTE
       BSR   OUTBYT
       DECB           LOOP UNTIL 0
       BNE   SAVE4
       LDA   CKSUM    GET CHECKSUM
       COMA           COMPLIMENT IT
       BSR   OUTBYT   OUTPUT IT
       LEAY  -1,X     CHECK FOR END
       CMPY  ENDADD
       BNE   SAVE1    LOOP IF NOT
       RTS

*************************************************
* OUTPUT BYTE AS HEX AND ADD TO CHECKSUM        *
*************************************************
OUTBYT JSR   OUTHEX   OUTPUT BYTE AS HEX
       ADDA  CKSUM    ADD TO CHECKSUM
       STA   CKSUM
       RTS

*************************************************
* OUTPUT 'S' TAPE RECORD HEADERS                *
*************************************************
OUTSN  JSR   CRLF     BEGIN NEW LINE
       LDA   #'S      OUTPUT 'S' HEADER
       BSR   OUTC
       TFR   B,A      RECORD TYPE TO A

*************************************************
* OUTPUT CHARACTER TO CONSOLE                   *
*************************************************
OUTC   JMP   OUTCHR   RELATIVE BRANCH BOOSTER

*************************************************
* MEMORY EXAMINE AND CHANGE                     *
*************************************************
MEMEC  BSR   GETHX    GET ADDRESS
       BNE   MEMEC1   GO IF GOOD
       LDX   MEMPTR   USE PREVIOUS
MEMEC1 STX   MEMPTR   UPDATE RAM POINTER
       JSR   CRLF     BEGIN NEW LINE
       TFR   X,D      DISPLAY ADDRESS
       JSR   DSPDBY
       LDA   ,X+      GET CONTENTS
       JSR   DSPSBY   DISPLAY THEM
       TFR   X,Y      SAVE ADDRESS IN Y
       BSR   GETHX    GET CHANGE DATA
       EXG   D,X      SAVE DELIM, GET NEW
       BEQ   MEMEC2   GO IF NO CHANGE
       STB   -1,Y     UPDATE MEMORY
       CMPB  -1,Y     VERIFY GOOD STORE
       BEQ   MEMEC2   GO IF NO CHANGE
       JSR   ERROR    DISPLAY ERROR
MEMEC2 TFR   X,D      GET DELIMITER IN A
       TFR   Y,X      GET NEXT ADDRESS IN X
       CMPA  #CR      END OF UPDATE?
       BEQ   MEMEC3   GO IF YES
       CMPA  #'^      BACKING UP?
       BNE   MEMEC1   LOOP IF NOT
       LEAX  ,--X     BACK UP 2
       BRA   MEMEC1   CONTINUE
MEMEC3 RTS

*************************************************
* GO TO ADDRESS                                 *
*************************************************
GO     LDS   STKPTR   SET UP STACK
       JSR   GETHEX   GET TARGET ADDRESS
       BEQ   GO1      GO IF NONE
       STX   10,S     STORE IN PC ON STACK
GO1    LDA   ,S       SET 'E' FLAG IN CC
       ORA   #$80
       STA   ,S
INTRET RTI            LOAD REGISTERS AND GO

*************************************************
* BREAKPOINT (SOFTWARE INTERRUPT) TRAP          *
*************************************************
BRKPNT LDX   10,S     GET PROGRAM COUNTER
       LEAX  -1,X     DECREMENT BY 1
       STX   10,S     REPLACE ON STACK
       LDB   #$FF     FLAG FOR SINGLE REMOVAL
       JSR   REMBK    REMOVE BREAKPOINT

*************************************************
* INTERRUPT (HARDWARE/SOFTWARE) TRAP            *
*************************************************
TRAP   STS   STKPTR   SAVE STACK POINTER
       JSR   CRLF     BEGIN NEW LINE
       BSR   REGDMP   DUMP REGISTERS
       JMP   GETCMD   GET NEXT COMMAND

*************************************************
* REGISTER EXAMINE AND CHANGE                   *
*************************************************
REGEC  JSR   INCHR    GET REGISTER TO EXAMINE
       JSR   CRLF     BEGIN NEW LINE
       CLRB           CLEAR OFFSET COUNT
       LDX   #REGIDS  POINT TO REGISTER ID STRING
REGEC1 CMPA  B,X      CHECK REGISTER NAME
       BEQ   REGEC2   GO IF FOUND
       INCB           ADVANCE COUNTER
       CMPB  #11      END OF LIST?
       BLS   REGEC1   LOOP IF NOT
       BRA   REGDMP   BAD ID - DUMP ALL
REGEC2 PSHS  B        SAVE OFFSET
       BSR   RDUMP    DISPLAY THE REG & CONTENTS
       JSR   GETHEX   GET NEW VALUE
       PULS  B        RESTORE OFFSET
       BEQ   REGECX   GO IF NO CHANGE
       LEAY  B,Y      POINT TO REG ON STACK
       CMPB  #3       SINGLE BYTE REG?
       TFR   X,D      GET NEW DATA IN A,B
       BLS   REGEC3   GO IF SINGLE
       STA   ,Y+      STORE MS BYTE
REGEC3 STB   ,Y       STORE LS BYTE
REGECX RTS

REGIDS FCC   'CABDXXYYUUPP'

*************************************************
* COMPLETE REGISTER DUMP                        *
*************************************************
REGDMP LDX   #REGIDS  POINT TO ID STRING
       CLRB           CLEAR OFFSET COUNTER
RGDMP1 LDA   B,X      GET REG NAME
       BSR   RDUMP    DISPLAY IT
       INCB           BUMP TO NEXT REG
       CMPB  #11      ALL PRINTED?
       BLS   RGDMP1   LOOP IF NOT
       LDA   #'S      DISPLAY STACK ID
       BSR   DSPID
       LDY   #STKPTR-12  Y+B=>STKPTR
       BRA   RDUMP1

*************************************************
* DISPLAY REGISTER CONTENTS                     *
*************************************************
RDUMP  BSR   DSPID    DISPLAY REGISTER ID
       LDY   STKPTR   POINT Y AT STACK
       CMPB  #3       SINGLE BYTE REG?
       BLS   RDUMP2   GO IF YES
RDUMP1 LDA   B,Y      DISPLAY MS BYTE
       JSR   OUTHEX
       INCB           ADVANCE OFFSET
RDUMP2 LDA   B,Y      DISPLAY A BYTE
       JMP   DSPSBY

*************************************************
* DISPLAY REGISTER ID                           *
*************************************************
DSPID  BSR   OUTCH    DISPLAY REG NAME
       LDA   #'=      DISPLAY '='

*************************************************
* OUTPUT CHARACTER TO CONSOLE                   *
*************************************************
OUTCH  JMP   OUTCHR   RELATIVE BRANCH BOOSTER

*************************************************
* SET A BREAKPOINT                              *
*************************************************
SETBK  JSR   GETHEX   GET ADDRESS
       BEQ   DSPBK    GO IF NONE ENTERED
       BSR   INITBP   POINT Y AT BP TABLE
SETBK1 LDD   ,Y       EMPTY SLOT?
       BEQ   SETBK2   GO IF YES
       BSR   NEXTBP   ADVANCE TO NEXT SLOT
       BNE   SETBK1   LOOP IF NOT END
       BRA   DSPBK    EXIT
SETBK2 STX   ,Y       SAVE ADDRESS
       BEQ   DSPBK    GO IF ADDRESS = 0
       LDA   ,X       GET CONTENTS
       STA   2,Y      SAVE IN TABLE
       LDA   #$3F     SWI OP CODE
       STA   ,X       SET BREAK

*************************************************
* DISPLAY ALL BREAKPOINTS                       *
*************************************************
DSPBK  JSR   CRLF     BEGIN NEW LINE
       BSR   INITBP   POINT Y AT BP TABLE
DSPBK1 LDD   ,Y       GET ADDRESS OF BP
       BEQ   DSPBK2   GO IF INACTIVE
       JSR   DSPDBY   DISPLAY ADDRESS
DSPBK2 BSR   NEXTBP   ADVANCE POINTER
       BNE   DSPBK1   LOOP IF NOT END
       RTS

*************************************************
* INITIALIZE BREAKPOINT TABLE POINTER           *
*************************************************
INITBP LDY   #BPTABL  POINT Y AT BP TABLE
       RTS

*************************************************
* ADVANCE BREAKPOINT TABLE POINTER              *
*************************************************
NEXTBP LEAY  3,Y      ADVANCE TO NEXT ENTRY
       CMPY  #BPTEND  CHECK FOR END OF TABLE
       RTS

*************************************************
* UNSET A BREAKPOINT                            *
*************************************************
UNSBK  JSR   GETHEX   GET ADDRESS

*************************************************
* REMOVE ONE OR MORE BREAKPOINTS                *
*************************************************
REMBK  BSR   INITBP   POINT Y AT BP TABLE
REMBK1 TSTB           REMOVE ALL?
       BEQ   REMBK2   GO IF YES
       CMPX  ,Y       FIND ADDRESS?
       BEQ   UNSET    GO IF YES
       BRA   REMBK3   LOOP IF NO
REMBK2 BSR   UNSET    UNSET IT
REMBK3 BSR   NEXTBP   ADVANCE POINTER
       BNE   REMBK1   LOOP IF NOT END
       RTS

*************************************************
* REMOVE A BREAKPOINT                           *
*************************************************
UNSET  LDX   ,Y       GET ADDRESS OF BP
       BEQ   UNSET1   GO IF INACTIVE
       LDA   2,Y      GET CONTENTS
       STA   ,X       REPLACE BP
       CLR   0,Y      MARK BP INACTIVE
       CLR   1,Y
UNSET1 RTS

*************************************************
* TERMINAL DRIVER (ACIA)                        *
*************************************************
TERMDR CLR   DCBERR,X NO ERRORS POSSIBLE
       LDX   DCBIOA,X GET I/O ADDRESS
       LSRB           READ FUNCTION?
       BCS   TERMRD   GO IF YES
       LSRB           WRITE FUNCTION?
       BCS   TERMWT   GO IF YES
       LSRB           STATUS FUNCTION?
       BCS   TERMST   GO IF YES
       LSRB           CONTROL FUNCTION?
       BCC   TERM1    GO IF NOT
       STA   ,X       STORE CONTROL CODE
TERM1  RTS

* TERMRD LDB   ,X       GET STATUS
*        LSRB           INPUT BIT TO C
*        BCC   TERMRD   LOOP IF NO INPUT
*        LDA   1,X      GET CHARACTER
*        RTS
TERMRD   JSR   [POLCAT] GET A KEY
         CMPA  #$08     A KEY?
         BLO   TERMRD
         RTS

* TERMWT LDB   ,X       GET STATUS
*        BITB  #2       READY FOR OUTPUT?
*        BEQ   TERMWT   LOOP IF NOT
*        STA   1,X      OUTPUT CHARACTER
*        RTS
TERMWT   JSR   [CHROUT] OUTPUT CHARACTER TO DEVICE
         RTS

* TERMST LDA   ,X       GET STATUS
*        ANDA  #3       MASK OFF READY BITS
*        RTS
TERMST   RTS            NO STATUS
 
*************************************************
* INTERRUPT HANDLERS                            *
*************************************************
SWI3   JMP   [SWI3V]  SOFTWARE INTERRUPT 3
SWI2   JMP   [SWI2V]  SOFTWARE INTERRUPT 2
FIRQ   JMP   [FIRQV]  FAST INTERRUPT REQUEST
IRQ    JMP   [IRQV]   INTERRUPT REQUEST
SWI    JMP   [SWIV]   SOFTWARE INTERRUPT
NMI    JMP   [NMIV]   NON-MASKABLE INTERRUPT

*************************************************
* PSYMON COMMAND TABLE                          *
*************************************************
CMDTBL FCB   1        ITEM LENGTH
       FCB   'M       MEMORY EXAMINE/CHANGE
       FDB   MEMEC
       FCB   'G       GOTO ADDRESS
       FDB   GO
       FCB   'L       PROGRAM LOAD
       FDB   TLOAD
       FCB   'S       PROGRAM SAVE
       FDB   TSAVE
       FCB   'R       REGISTER EXAMINE/CHANGE
       FDB   REGEC
       FCB   'B       SET/PRINT BREAKPOINTS
       FDB   SETBK
       FCB   'U       UNSET BREAKPOINTS
       FDB   UNSBK
       FCB   $FF      END SENTINEL

*************************************************
* RAM INITIALIZATION DATA                       *
*************************************************
RAMINT FCC   'CN'     CONSOLE DCB ID
       FDB   TERMDR   CONSOLE DRIVER
       FDB   TERMNL   CONSOLE I/O ADDRESS
       FDB   0        ERROR STATUS, EXT
       FDB   CONDCB   DCB CHAIN POINTER
       FDB   CONDCB   DCB POINTERS
       FDB   CONDCB
       FDB   CONDCB
       FDB   CONDCB
       FDB   TRAP     INTERRUPT VECTORS
       FDB   TRAP
       FDB   INTRET
       FDB   TRAP
       FDB   BRKPNT
       FDB   TRAP
       FDB   FREE

       FCB   $FF,$FF,$FF,$FF  RESERVED SPACE

*************************************************
* SOFTWARE VECTORS                              *
*************************************************
       FDB   RAM      BASE OF PSYMON RAM
       FDB   DSPSBY   DISPLAY SINGLE BYTE ON CONSOLE
       FDB   DSPDBY   DISPLAY DOUBLE BYTE ON CONSOLE
       FDB   GETHEX   GET HEX NUMBER FROM CONSOLE
       FDB   PSTRNG   PRINT STRING TO CONSOLE
       FDB   INCHR    INPUT CHARACTER FROM CONSOLE
       FDB   OUTCHR   OUTPUT CHARACTER TO CONSOLE
       FDB   REQIO    PERFORM I/O REQUEST
       FDB   MONENT   MONITOR RE-ENTRY

*************************************************
* HARDWARE VECTORS                              *
*************************************************
*       FDB   INIT     RESERVED BY MOTOROLA
*       FDB   SWI3     SOFTWARE INTERRUPT 3
*       FDB   SWI2     SOFTWARE INTERRUPT 2
*       FDB   FIRQ     FAST INTERRUPT REQUEST
*       FDB   IRQ      INTERRUPT REQUEST
*       FDB   SWI      SOFTWARE INTERRUPT
*       FDB   NMI      NON-MASKABLE INTERRUPT
*       FDB   INIT     RESTART

       END   INIT
