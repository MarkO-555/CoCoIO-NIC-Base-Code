;*********************************************************************
;* Title: COCOIODRV-2A.asm
;*********************************************************************
;* Author: R. Allen Murphey, & MarkO
;*
;* License: Contributed 2021 by R. Allen Murphey to CoCoIO Development
;*
;* Description: CoCoIO with WIZnet W5100S driver code
;*
;* Documentation: https://www.wiznet.io/product-item/w5100s/
;*
;* Include Files: W5100SEQU.asm - W5100S Equates
;*                COCOIOEQU.asm - CoCoIO Equates
;*                COCOIOCFG.asm - CoCoIO Config Data
;*
;* Assembler: lwasm 1.4.2
;*
;* Revision History:
;* Rev #     Date      Who     Comments
;* -----  -----------  ------  ---------------------------------------
;* 00     2021         RAM     Initial Reset and Config functions
;*********************************************************************

            include "W5100SEQU.asm"
            include "COCOIOEQU.asm"

PIA0BD:     equ   $FF02       ; PIA 0 PORT B DATA
PIA0BC:     equ   $FF03       ; PIA 0 PORT B CONTROL

POLCAT:     equ   $A000
CHROUT:     equ   $A002


            org   $7E00
RESETP:     jmp   W5100_RST         ;$7E00
CONFIG:     jmp   W5100_CFG         ;$7E03
GATEWAY:    jmp   W5100_GATEWAY     ;$7E06
SUBNET:     jmp   W5100_SUBNET      ;$7E09
HARDWARE:   jmp   W5100_HARDWARE    ;$7E0C
IPADDR:     jmp   W5100_IPADDR      ;$7E0F
MPISLOT:    jmp   MPISLOT1          ;$7E12

DISPGW:     jmp   DISP_GATEWAY      ;$7E15
DISPSN:     jmp   DISP_SUBNET       ;$7E18
DISPHW:     jmp   DISP_HARDWARE     ;$7E1B
DISPIPADD:  jmp   DISP_IPADDR       ;$7E1E


W5100_RST:                    ; Reset the CoCoIO WIZnet 5100S
            jsr   MPISLOT1
;            jsr   DALLY
            lda   CIO0CMND    ; Read the current value of MR from CoCoIO Command
            ora   #%10000000  ; Flip bit 7 RST to 1 = init all W5100S registers - autoclear in 3 SYS_CLK
            sta   CIO0CMND    ; Trigger the reset
RSTDONE:    lda   CIO0CMND    ; Now read command register to check bit 7 clears when reset is done
            bmi   RSTDONE     ; if bit 7, then A was negative, keep checking bit
SETMODE:    ora   #%00000011  ; bit 7 cleared, setup Ping Block disabled, no PPPoE, AutoIncrement, and Indirect Bus Mode
            sta   CIO0CMND    ; configure the chip and done
            lda   CIO0CMND    ; readback mode
            cmpa  #3          ; is it what we want?
            bne   SETMODE     ; no, try again
            rts

W5100_CFG:                    ; Configure the CoCoIO WIZnet W5100S
            jsr   MPISLOT1
;            jsr   DALLY
            jsr   W5100_GATEWAY   ; Bring up layer 3 default route
            jsr   W5100_SUBNET    ; Bring up layer 3 network mask
            jsr   W5100_HARDWARE  ; Bring up layer 2 address
            jsr   W5100_IPADDR    ; Bring up layer 3 address
            rts

W5100_GATEWAY:                ; Configure the Gateway address
            ldd   #GAR0       ; W5100S Gateway Address Register 0
            sta   CIO0ADDR    ; CoCoIO Address Register MSB
            stb   CIO0ADDR+1  ; CoCoIO Address Register LSB
;            jsr   DALLY
            ldb   #4          ; Setup B for loop counting
            ldx   #MYGATEWAY  ; Get the location of the Gateway data 
GWRLOOP:    lda   ,X+         ; Load A with the next byte of Gateway
            sta   CIO0DATA    ; Store it to W5100S
;            jsr   DALLY
            decb              ; Decrement loop counter
            bne   GWRLOOP     ; No, go back and do more
;            jsr   DALLY
            rts

W5100_SUBNET:                 ; Next the Subnet Mask
            ldd   #SUBR0      ; W5100S Subnet Mask Address Register 0
            sta   CIO0ADDR    ; CoCoIO Address Register MSB
            stb   CIO0ADDR+1  ; CoCoIO Address Register LSB
;            jsr   DALLY
            ldb   #4          ; Setup B for loop counting
            ldx   #MYSUBNET   ; Get the location of the Subnet data
SUBRLOOP:   lda   ,X+         ; Load A with the next byte of Subnet
            sta   CIO0DATA    ; Store it to W5100S
;            jsr   DALLY
            decb              ; Decrement loop counter
            bne   SUBRLOOP    ; No, go back and do more
;            jsr   DALLY
            rts

W5100_HARDWARE:               ; Next the Source Hardware Address
            ldd   #SHAR0      ; W5100S Source Hardware Address Register 0
            sta   CIO0ADDR    ; CoCoIO Address Register MSB
            stb   CIO0ADDR+1  ; CoCoIO Address Register LSB
;            jsr   DALLY
            ldb   #6          ; Setup B for loop counting
            ldx   #MYMAC      ; Get the location of the MAC data
SHARLOOP:   lda   ,X+         ; Load A with the next byte of MAC data
            sta   CIO0DATA    ; Store it to W5100S
;            jsr   DALLY
            decb              ; Decrement loop counter
            bne   SHARLOOP    ; No, go back and do more
;            jsr   DALLY
            rts

W5100_IPADDR:                 ; Next the Source IP Address
            ldd   #SIPR0      ; W5100S Source IP Register 0
            sta   CIO0ADDR    ; CoCoIO Address Register MSB
            stb   CIO0ADDR+1  ; CoCoIO Address Register LSB
;            jsr   DALLY
            ldb   #4          ; Setup B for loop counting
            ldx   #MYIP       ; Get the location of the IP data
SIPRLOOP:   lda   ,X+         ; Load A with the next byte of IP data
            sta   CIO0DATA    ; Store it to W5100S
;            jsr   DALLY
            decb              ; Decrement loop counter
            bne   SIPRLOOP    ; No, go back and do more
;            jsr   DALLY
            rts

DISP_GATEWAY:
            ldd   #GAR0       ; W5100S Gateway Address Register 0
            sta   CIO0ADDR    ; CoCoIO Address Register MSB
            stb   CIO0ADDR+1  ; CoCoIO Address Register LSB
;            jsr   DALLY
            jsr   BIN2HEX
            jsr   DISPB2H
;            jsr   DALLY
            LDA   '+'
            JSR   [CHROUT]
;            jsr   DALLY
            jsr   BIN2HEX
            jsr   DISPB2H
;            jsr   DALLY
            LDA   '+'
            JSR   [CHROUT]
;            jsr   DALLY
            jsr   BIN2HEX
            jsr   DISPB2H
;            jsr   DALLY
            LDA   '+'
            JSR   [CHROUT]
;            jsr   DALLY
            jsr   BIN2HEX
            jsr   DISPB2H
;            jsr   DALLY

            rts

DISP_SUBNET:
            ldd   #SUBR0      ; W5100S Subnet Mask Address Register 0
            sta   CIO0ADDR    ; CoCoIO Address Register MSB
            stb   CIO0ADDR+1  ; CoCoIO Address Register LSB

            jsr   BIN2HEX
            jsr   DISPB2H
;            jsr   DALLY
            LDA   '+'
            JSR   [CHROUT]
;            jsr   DALLY
            jsr   BIN2HEX
            jsr   DISPB2H
;            jsr   DALLY
            LDA   '+'
            JSR   [CHROUT]
;            jsr   DALLY
            jsr   BIN2HEX
            jsr   DISPB2H
;            jsr   DALLY
            LDA   '+'
            JSR   [CHROUT]
;            jsr   DALLY
            jsr   BIN2HEX
            jsr   DISPB2H

            rts

DISP_HARDWARE:
            ldd   #SHAR0      ; W5100S Source Hardware Address Register 0
            sta   CIO0ADDR    ; CoCoIO Address Register MSB
            stb   CIO0ADDR+1  ; CoCoIO Address Register LSB

            jsr   BIN2HEX
            jsr   DISPB2H
;            jsr   DALLY
            LDA   '+'
            JSR   [CHROUT]
;            jsr   DALLY
            jsr   BIN2HEX
            jsr   DISPB2H
;            jsr   DALLY
            LDA   '+'
            JSR   [CHROUT]
;            jsr   DALLY
            jsr   BIN2HEX
            jsr   DISPB2H
;            jsr   DALLY
            LDA   '+'
            JSR   [CHROUT]
;            jsr   DALLY
            jsr   BIN2HEX
            jsr   DISPB2H
            LDA   '+'
            JSR   [CHROUT]
;            jsr   DALLY
            jsr   BIN2HEX
            jsr   DISPB2H
;            jsr   DALLY
            LDA   '+'
            JSR   [CHROUT]
;            jsr   DALLY
            jsr   BIN2HEX
            jsr   DISPB2H


            rts

DISP_IPADDR:
            ldd   #SIPR0      ; W5100S Source IP Register 0
            sta   CIO0ADDR    ; CoCoIO Address Register MSB
            stb   CIO0ADDR+1  ; CoCoIO Address Register LSB

            jsr   BIN2HEX
            jsr   DISPB2H
;            jsr   DALLY
            LDA   '+'
            JSR   [CHROUT]
;            jsr   DALLY
            jsr   BIN2HEX
            jsr   DISPB2H
;            jsr   DALLY
            LDA   '+'
            JSR   [CHROUT]
;            jsr   DALLY
            jsr   BIN2HEX
            jsr   DISPB2H
;            jsr   DALLY
            LDA   '+'
            JSR   [CHROUT]
;            jsr   DALLY
            jsr   BIN2HEX
            jsr   DISPB2H

            rts




MPISLOT1:                     ; Configure Multipack SCS to slot 1
            lda   $FF7F       ; Read the MPI slot control
            anda  #%11110000  ; zero out the SCS nybble for MPI slot 1
            sta   $FF7F       ; Write the updated SCS
            rts

DILLY:      lda   PIA0BD      ; clear any pending VSYNC interrupt on PIA0
DILLY1:     lda   PIA0BC      ; load up the current flags
            bpl   DILLY1      ; if bit 7 not set, keep checking flags
            lda   PIA0BD      ; clear the interrupt that just happened
            rts

DALLY:      pshs  X
            ldx   #$1000      ; A maximum delay loop 
DALLY1:     leax  -1,X        ; Decrement X
            bne   DALLY1      ; if X>0 not done yet
            puls  X
            rts




BIN2HEX:    ; W5100 Read DATA and Output HEX in ASCII

            LDA   CIO0DATA    ; GET DATA from W5100, ( or BINVAL )
            ;
            ; CONVERT MORE SIGNIFICANT DIGIT TO ASCII
            ;
            TFR   A,B         ; SAVE ORIGINAL BINARY VALUE MOVE HIGH DIGIT TO LOW DIGIT
            LSRA
            LSRA
            LSRA
            LSRA
            CMPA  #9
            BLS   AD30        ; BRANCH IF HIGH DIGIT IS DECIMAL
            ADDA  #7          ; ELSE ADD 7 S0 AFTER ADDING '0' THE 
                              ; CHARACTER WILL BE IN 'A'..'F'
AD30:       ADDA  #'0'        ; ADD ASCII 0 TO MAKE A CHARACTER
            STA HEX1VAL       ; STORE ASCII DATA

            ;
            ; CONVERT LESS SIGNIFICANT DIGIT TO ASCII
            ; 
            ANDB  #$0F        ; MASK OFF LOW DIGIT    
            CMPB  #9          ; BRANCH IF LOW DIGIT IS DECIMAL    
            BLS   AD30LD      ; ELSE ADD 7 SO AFTER ADDING '0' THE
            ADDB  #7          ; CHARACTER WILL BE IN 'A'..'F'
AD30LD:     ADDB  #'0'        ; ADD ASCII 0 TO MAKE A CHARACTER
            STB HEX2VAL       ; STORE ASCII DATA

            RTS  

BINVAL:     fcb   $00
HEX1VAL:    fcb   $00
HEX2VAL:    fcb   $00

DISPB2H:    LDA   HEX1VAL
            JSR   [CHROUT]
            LDA   HEX2VAL
            JSR   [CHROUT]
            RTS

DISPSTR0:   LDA   HEX1VAL



            include "COCOIOCFG.asm"

            end   RESET       ; End of driver
