;*********************************************************************
;* Title: COCOIODRV.asm
;*********************************************************************
;* Author: R. Allen Murphey
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

            org   $7E00
RESET:      jmp   W5100_RST
CONFIG:     jmp   W5100_CFG
GATEWAY:    jmp   W5100_GATEWAY
SUBNET:     jmp   W5100_SUBNET
HARDWARE:   jmp   W5100_HARDWARE
IPADDR:     jmp   W5100_IPADDR
MPISLOT:    jmp   MPISLOT1

W5100_RST:                    ; Reset the CoCoIO WIZnet 5100S
            jsr   MPISLOT1
            jsr   DALLY
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
            jsr   DALLY
            jsr   W5100_GATEWAY   ; Bring up layer 3 default route
            jsr   W5100_SUBNET    ; Bring up layer 3 network mask
            jsr   W5100_HARDWARE  ; Bring up layer 2 address
            jsr   W5100_IPADDR    ; Bring up layer 3 address
            rts

W5100_GATEWAY:                ; Configure the Gateway address
            ldd   #GAR0       ; W5100S Gateway Address Register 0
            sta   CIO0ADDR    ; CoCoIO Address Register MSB
            stb   CIO0ADDR+1  ; CoCoIO Address Register LSB
            jsr   DALLY
            ldb   #4          ; Setup B for loop counting
            ldx   #MYGATEWAY  ; Get the location of the Gateway data 
GWRLOOP:    lda   ,X+         ; Load A with the next byte of Gateway
            sta   CIO0DATA    ; Store it to W5100S
            jsr   DALLY
            decb              ; Decrement loop counter
            bne   GWRLOOP     ; No, go back and do more
            jsr   DALLY
            rts

W5100_SUBNET:                 ; Next the Subnet Mask
            ldd   #SUBR0      ; W5100S Subnet Mask Address Register 0
            sta   CIO0ADDR    ; CoCoIO Address Register MSB
            stb   CIO0ADDR+1  ; CoCoIO Address Register LSB
            jsr   DALLY
            ldb   #4          ; Setup B for loop counting
            ldx   #MYSUBNET   ; Get the location of the Subnet data
SUBRLOOP:   lda   ,X+         ; Load A with the next byte of Subnet
            sta   CIO0DATA    ; Store it to W5100S
            jsr   DALLY
            decb              ; Decrement loop counter
            bne   SUBRLOOP    ; No, go back and do more
            jsr   DALLY
            rts

W5100_HARDWARE:               ; Next the Source Hardware Address
            ldd   #SHAR0      ; W5100S Source Hardware Address Register 0
            sta   CIO0ADDR    ; CoCoIO Address Register MSB
            stb   CIO0ADDR+1  ; CoCoIO Address Register LSB
            jsr   DALLY
            ldb   #6          ; Setup B for loop counting
            ldx   #MYMAC      ; Get the location of the MAC data
SHARLOOP:   lda   ,X+         ; Load A with the next byte of MAC data
            sta   CIO0DATA    ; Store it to W5100S
            jsr   DALLY
            decb              ; Decrement loop counter
            bne   SHARLOOP    ; No, go back and do more
            jsr   DALLY
            rts

W5100_IPADDR:                 ; Next the Source IP Address
            ldd   #SIPR0      ; W5100S Source IP Register 0
            sta   CIO0ADDR    ; CoCoIO Address Register MSB
            stb   CIO0ADDR+1  ; CoCoIO Address Register LSB
            jsr   DALLY
            ldb   #4          ; Setup B for loop counting
            ldx   #MYIP       ; Get the location of the IP data
SIPRLOOP:   lda   ,X+         ; Load A with the next byte of IP data
            sta   CIO0DATA    ; Store it to W5100S
            jsr   DALLY
            decb              ; Decrement loop counter
            bne   SIPRLOOP    ; No, go back and do more
            jsr   DALLY
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

            include "COCOIOCFG.asm"

            end   RESET       ; End of driver
