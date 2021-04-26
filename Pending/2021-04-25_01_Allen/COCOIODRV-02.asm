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

            org   $7E00
RESET:      jmp   W5100_RST
CONFIG:     jmp   W5100_CFG

W5100_RST:                    ; Reset the CoCoIO WIZnet 5100S
            jsr   MPISLOT
            ldd   #MR         ; W5100S Mode Register 0x0000
            sta   CIO0ADDR    ; CoCoIO Address Register MSB
            stb   CIO0ADDR+1  ; CoCoIO Address Register LSB
            nop
            nop
            nop
            lda   CIO0DATA    ; Read the current value of MR
            ora   #%10000011  ; Flip bit 7 RST to 1 = init all W5100S registers - autoclear in 3 SYS_CLK
            pshs  A           ; Stash A for a few cycles
            ldd   #MR         ; Load D with W5100S MR Register
            sta   CIO0ADDR    ; CoCoIO Address Register MSB
            stb   CIO0ADDR+1  ; CoCoIO Address Register LSB
            nop
            nop
            nop
            puls  A           ; Now get A back
            sta   CIO0DATA    ; Stuff the modified register back to trigger reset
            nop
            nop
            nop
            rts

W5100_CFG:                    ; Configure the CoCoIO WIZnet W5100S
            jsr   MPISLOT
            ldd   #MR         ; W5100S Mode Register 0x0000
            sta   CIO0ADDR    ; CoCoIO Address Register MSB
            stb   CIO0ADDR+1  ; CoCoIO Address Register LSB
            nop
            nop
            nop
            lda   #%00000011  ; No Reset, Ping Block disabled, No PPPoE, AutoIncrement, Indirect Bus I/F
            sta   CIO0DATA    ; Setup the mode listed above
            nop
            nop
            nop

                              ; Mext configure the Gateway address
            ldd   #GAR0       ; W5100S Gateway Address Register 0
            sta   CIO0ADDR    ; CoCoIO Address Register MSB
            stb   CIO0ADDR+1  ; CoCoIO Address Register LSB
            nop
            nop
            nop
            ldx   #MYGATEWAY  ; Get the location of the Gateway data 
            clrb              ; Clear B for loop counting
GWRLOOP:    lda   ,X+         ; Load A with the next byte of Gateway
            sta   CIO0DATA    ; Store it to W5100S
            nop
            nop
            nop
            incb              ; Increment loop counter
            cmpb  #4          ; Are we past the end of the Gateway data?
            bne   GWRLOOP     ; No, go back and do more

                              ; Next the Subnet Mask
            ldd   #SUBR0      ; W5100S Subnet Mask Address Register 0
            sta   CIO0ADDR    ; CoCoIO Address Register MSB
            stb   CIO0ADDR+1  ; CoCoIO Address Register LSB
            nop
            nop
            nop
            ldx   #MYSUBNET   ; Get the location of the Subnet data
            clrb              ; Clear that loop counter
SUBRLOOP:   lda   ,X+         ; Load A with the next byte of Subnet
            sta   CIO0DATA    ; Store it to W5100S
            nop
            nop
            nop
            incb              ; Increment loop counter
            cmpb  #4          ; Are we past the end of the Subnet data?
            bne   SUBRLOOP    ; No, go back and do more

                              ; Next the Source Hardware Address
            ldd   #SHAR0      ; W5100S Source Hardware Address Register 0
            sta   CIO0ADDR    ; CoCoIO Address Register MSB
            stb   CIO0ADDR+1  ; CoCoIO Address Register LSB
            nop
            nop
            nop
            ldx   #MYMAC      ; Get the location of the MAC data
            clrb              ; Clear that loop counter
SHARLOOP:   lda   ,X+         ; Load A with the next byte of MAC data
            sta   CIO0DATA    ; Store it to W5100S
            nop
            nop
            nop
            incb              ; Increment loop counter
            cmpb  #6          ; Are we past the end of the MAC data?
            bne   SHARLOOP    ; No, go back and do more

                              ; Next the Source IP Address
            ldd   #SIPR0      ; W5100S Source IP Register 0
            sta   CIO0ADDR    ; CoCoIO Address Register MSB
            stb   CIO0ADDR+1  ; CoCoIO Address Register LSB
            nop
            nop
            nop
            ldx   #MYIP       ; Get the location of the IP data
            clrb              ; Clear the loop counter
SIPRLOOP:   lda   ,X+         ; Load A with the next byte of IP data
            sta   CIO0DATA    ; Store it to W5100S
            nop
            nop
            nop
            incb              ; Increment loop counter
            cmpb  #4          ; Are we past the end of the IP data?
            bne   SIPRLOOP    ; No, go back and do more
            rts

MPISLOT:    lda   $FF7F       ; Read the MPI slot control
            anda  #%11110000  ; zero out the SCS nybble for MPI slot 1
            sta   $FF7F       ; Write the updated SCS
            nop
            nop
            nop
            rts

            include "COCOIOCFG.asm"

            end   RESET       ; End of driver
