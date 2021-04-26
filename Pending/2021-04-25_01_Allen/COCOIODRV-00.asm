;*********************************************************************
;* Title: W5100SDRV.asm
;*********************************************************************
;* Author: R. Allen Murphey
;*
;* License: Contributed 2021 by R. Allen Murphey to CoCoIO Development
;*
;* Description: WIZnet W5100S driver code
;*
;* Documentation: https://www.wiznet.io/product-item/w5100s/
;*
;* Include Files: W5100SEQU.asm
;*
;* Assembler: lwasm 1.4.2
;*
;* Revision History:
;* Rev #     Date      Who     Comments
;* -----  -----------  ------  ---------------------------------------
;* 00     2021         RAM     Initial equates from Data Sheet
;*********************************************************************

            include "W5100SEQU.asm"
            include "COCOIOEQU.asm"

            org   $4000
RESET:      jmp   W5100_RST
CONFIG:     jmp   W5100_CFG

W5100_RST:                    ; Reset the CoCoIO WIZnet 5100S
            bsr   MPISLOT
            ldx   #MR         ; W5100S Mode Register 0x0000
            stx   CIO0ADDR    ; CoCoIO Address Register MSB
            lda   CIO0DATA    ; Read the current value of MR
            ora   #%10000000  ; Flip bit 7 RST to 1 = init all W5100S registers - autoclear in 3 SYS_CLK
            stx   CIO0ADDR    ; CoCoIO Address Register MSB
            sta   CIO0DATA    ; Stuff the modified register back to trigger reset
            rts

W5100_CFG:                    ; Configure the CoCoIO WIZnet W5100S
            bsr   MPISLOT
            ldx   #MR         ; W5100S Mode Register 0x0000
            stx   CIO0ADDR    ; CoCoIO Address Register MSB
            lda   #%00000011  ; No Reset, Ping Block disabled, No PPPoE, AutoIncrement, Indirect Bus I/F
            sta   CIO0DATA     ; Setup the mode listed above

            ldx   #GAR0       ; W5100S Gateway Address Register 0
            stx   CIO0ADDR    ; CoCoIO Address Register MSB
            ldx   GWR
            clrb
GWRLOOP:    lda   ,X+
            sta   CIO0DATA
            stx   CIO0ADDR
            incb
            cmpb  #4
            bne   GWRLOOP
                              ; Now the Subnet Mask
            ldx   #SUBR0      ; W5100S Subnet Mask Address Register 0
            stx   CIO0ADDR    ; CoCoIO Address Register MSB
            ldx   SUBR
            clrb
SUBRLOOP:   lda   ,X+
            sta   CIO0DATA
            stx   CIO0ADDR
            incb
            cmpb  #4
            bne   SUBRLOOP
                              ; Now the Source Hardware Address
            ldx   #SHAR0      ; W5100S Source Hardware Address Register 0
            stx   CIO0ADDR    ; CoCoIO Address Register MSB
            ldx   SHAR
            clrb
SHARLOOP:   lda   ,X+
            sta   CIO0DATA
            stx   CIO0ADDR
            incb
            cmpb  #6
            bne   SHARLOOP

                              ; Now the Source IP Address
            ldx   #SIPR0      ; W5100S Source IP Register 0
            stx   CIO0ADDR    ; CoCoIO Address Register MSB
            ldx   SIPR
            clrb
SIPRLOOP:   lda   ,X+
            sta   CIO0DATA
            stx   CIO0ADDR
            incb
            cmpb  #4
            bne   SIPRLOOP
            rts

MPISLOT:    lda   $FF7F       ; Read the MPI slot control
            anda  #%11110000  ; zero out the SCS nybble for MPI slot 1
            sta   $FF7F       ; Write the updated SCS
            rts

            include "COCOIOCFG.asm"

            end   RESET       ; End of driver
