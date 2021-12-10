********************************
*            REMOTE            *
*A REMOTE TERMINAL DRIVER      *
*FOR THE COCO                  *
*DAN DOWNARD  RAINBOW  11/83   *
********************************
        ORG     $7E00
*EQUATES FOR ROM AND RAM ADDRESSES
IHOOK   EQU     $016A
OHOOK   EQU     $0167
PIA     EQU     $FF22
POLCAT  EQU     $A000
RSOUT   EQU     $8E0C
BAUD    EQU     $E6
*BAUDR   EQU     $C9 * ORIGINAL INCORRECT
BAUDR   EQU     $B8 * 1984-11 CORRECTION
*BAUDR   EQU     $01CA * 120bps
#BAUDR   EQU     $BE * 300bps
*BAUDR   EQU     $57 * 600bps
*BAUDR   EQU     $29 * 1200bps
*BAUDR   EQU     $12 * 2400bps
DEV     EQU     $6F
FLAG    EQU     $70
*INITIALIZE RAM HOOKS
START   LDA     #BAUDR
        STA     <BAUD
        LDX     1+OHOOK
        STX     1+ORET2,PCR
        LDX     1+IHOOK
        STX     1+IRET2,PCR
        LDA     #$7E
        STA     IHOOK
        STA     OHOOK
        LEAX    OUT,PCR
        STX     1+OHOOK
        LEAX    IN,PCR
        STX     1+IHOOK
RET     RTS
*OUTPUT CHARACTER IF DEV=0
*INSERT LINE FEEDS TO REMOTE DEVICE
*USE ROM SUBROUTINE
OUT     PSHS    A
        TST     <DEV
        BNE     ORET1
        CMPA    #$0D
        BNE     REMOUT
        LDA     #$0A
        JSR     RSOUT
        LDA     #$0D
REMOUT  JSR     RSOUT
ORET1   PULS    A
ORET2   JMP     RET
*INPUT FROM KEYBOARD OR RS-232
*IF DEV=0
*USE RSIN FOR REMOTE INPUT
IN      CLR     <FLAG
        TST     <DEV
        BNE     IRET2
        LEAS    2,S
        PSHS    B,CC,X
IN1     JSR     [POLCAT]
        BEQ     REMIN
        BRA     IRET1
*CHECK FOR REMOTE INPUT
REMIN   LDB     $FF22
        RORB
        BCS     IN1
*RS-232 INPUT ROUTINE
*BYTE INTO A REGISTER
RSIN    BSR     HALF
        LDB     #1
        PSHS    B
        CLRA
RSIN1   BSR     FULL
        LDB     PIA
        RORB
        BCC     RSIN2
        ORA     0,S
RSIN2   ASL     0,S
        BCC     RSIN1
        LEAS    1,S
        ANDA    #$7F
IRET1   PULS    B,CC,X,PC
IRET2   JMP     RET
*BAUD RATE DELAYS
FULL    BSR     HALF
HALF    PSHS    A
        LDA     <BAUD
HALF1   BRN     HALF1
        DECA
        BNE     HALF1
        PULS    PC,A
        END     START
