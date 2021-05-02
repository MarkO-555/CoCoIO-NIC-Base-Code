;*********************************************************************
;* Title: W5100SDRV08.asm
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
            jsr   MPISLOT
            jsr   SWTIMER
            lda   #%10000000  ; WizNet5100 RESET 0x80
            sta   CIO0CMND    ; W5100S Mode Register 0xFF68
            jsr   SWTIMER

            rts

W5100_CFG:                    ; Configure the CoCoIO WIZnet W5100S
            jsr   MPISLOT
            jsr   SWTIMER
            lda   #%00000011  ; No Reset, Ping Block disabled, No PPPoE, AutoIncrement, Indirect Bus I/F
            sta   CIO0CMND    ; W5100S Mode Register 0xFF68
            jsr   SWTIMER

            ldy   #0          ; Counter Value
            sty   GWAYCNT
            sty   SNETCNT


            rts

W5100_GW:   jsr   SWTIMER

GWLOOP:     inc   GWAYCNT
            ldx   #GAR0       ; W5100S Gateway Address Register 0
            stx   CIO0ADDR    ; CoCoIO Address Register MSB
            ldd   CIO0ADDR
            cmpd  #GAR0
            bne   GWLOOP

            inc   GWAYCNT
            lda   MYGATEWAY
            sta   CIO0DATA
            jsr   SWTIMER

            lda   MYGATEWAY+1
            sta   CIO0DATA
            jsr   SWTIMER

            lda   MYGATEWAY+2
            sta   CIO0DATA
            jsr   SWTIMER

            lda   MYGATEWAY+3
            sta   CIO0DATA
            jsr   SWTIMER
;
            rts
;            
                              ; Now the Subnet Mask
W5100_SNM:  jsr   SWTIMER
            ldx   #SUBR0      ; W5100S Subnet Mask Address Register 0
            stx   CIO0ADDR    ; CoCoIO Address Register MSB
            jsr   SWTIMER

            lda   MYSUBNET
            sta   CIO0DATA
            jsr   SWTIMER

            lda   MYSUBNET+1
            sta   CIO0DATA
            jsr   SWTIMER

            lda   MYSUBNET+2
            sta   CIO0DATA
            jsr   SWTIMER

            lda   MYSUBNET+3
            sta   CIO0DATA
            jsr   SWTIMER
;
            rts
;            
                              ; Now the Source Hardware Address
W5100_MAC:  ldx   #SHAR0      ; W5100S Source Hardware Address Register 0
            stx   CIO0ADDR    ; CoCoIO Address Register MSB
            lda   MYMAC
            sta   CIO0DATA
            lda   MYMAC+1
            sta   CIO0DATA
            lda   MYMAC+2
            sta   CIO0DATA
            lda   MYMAC+3
            sta   CIO0DATA
;
            rts
;            
                              ; Now the Source IP Address
W5100_LIP:  ldx   #SIPR0      ; W5100S Source IP Register 0
            stx   CIO0ADDR    ; CoCoIO Address Register MSB
            lda   MYIP
            sta   CIO0DATA
            lda   MYIP+1
            sta   CIO0DATA
            lda   MYIP+2
            sta   CIO0DATA
            lda   MYIP+3
            sta   CIO0DATA
;
            rts
;            

MPISLOT:    lda   $FF7F       ; Read the MPI slot control
            anda  #%11110000  ; zero out the SCS nybble for MPI slot 1
            sta   $FF7F       ; Write the updated SCS
            rts

SWTIMER:    ldd   #0          ; 16 Bit Zero
            
SWT0LOOP:   decd              ; Decrement D
            bne SWT0LOOP
            rts 

GWAYCNT:                    ; Gateway Write Count
            fcb   0,0

SNETCNT:                    ; Subnet Mask Write Count
            fcb   0,0 


            include "COCOIOCFG.asm"

            end   RESET       ; End of driver
