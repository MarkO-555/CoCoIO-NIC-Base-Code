;*********************************************************************
;* Title: W5100SDRV05.asm
;*********************************************************************
;* Author: R. Allen Murphey, MarkO
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

            org   $7E00
RESET:      jmp   W5100_RST   ; 0x7E00
CONFIG:     jmp   W5100_CFG   ; 0x7E03
GATEWY:     jmp   W5100_GW    ; 0x7E06
SUBNM:      jmp   W5100_SNM   ; 0x7E09
MACADRS:    jmp   W5100_MAC   ; 0x7E0C
LOCIP:      jmp   W5100_LIP   ; 0x7E0F


W5100_RST:                    ; Reset the CoCoIO WIZnet 5100S
            bsr   MPISLOT
            lda   #%10000000  ; WizNet5100 RESET 0x80
            sta   CIO0CMND    ; W5100S Mode Register 0xFF68

            rts

W5100_CFG:                    ; Configure the CoCoIO WIZnet W5100S
            bsr   MPISLOT
            lda   #%00000011  ; No Reset, Ping Block disabled, No PPPoE, AutoIncrement, Indirect Bus I/F
            sta   CIO0CMND    ; W5100S Mode Register 0xFF68

            rts

W5100_GW:   ldx   #GAR0       ; W5100S Gateway Address Register 0
            stx   CIO0ADDR    ; CoCoIO Address Register MSB
            ldx   MYGATEWAY
            clrb
GWRLOOP:    lda   ,X+
            sta   CIO0DATA
            incb
            cmpb  #4
            bne   GWRLOOP
;
            rts
;            
                              ; Now the Subnet Mask
W5100_SNM:  ldx   #SUBR0      ; W5100S Subnet Mask Address Register 0
            stx   CIO0ADDR    ; CoCoIO Address Register MSB
            ldx   MYSUBNET
            clrb
SUBRLOOP:   lda   ,X+
            sta   CIO0DATA
            incb
            cmpb  #4
            bne   SUBRLOOP
;
            rts
;            
                              ; Now the Source Hardware Address
W5100_MAC:  ldx   #SHAR0      ; W5100S Source Hardware Address Register 0
            stx   CIO0ADDR    ; CoCoIO Address Register MSB
            ldx   MYMAC
            clrb
SHARLOOP:   lda   ,X+
            sta   CIO0DATA
            incb
            cmpb  #6
            bne   SHARLOOP
;
            rts
;            
                              ; Now the Source IP Address
W5100_LIP:  ldx   #SIPR0      ; W5100S Source IP Register 0
            stx   CIO0ADDR    ; CoCoIO Address Register MSB
            ldx   MYIP
            clrb
SIPRLOOP:   lda   ,X+
            sta   CIO0DATA
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
