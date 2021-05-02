;*********************************************************************
;* Title: COCOIOCFG.asm
;*********************************************************************
;* Author: R. Allen Murphey
;*
;* License: Contributed 2021 by R. Allen Murphey to CoCoIO Development
;*
;* Description: CoCoIO for Color Computer Configuration
;*
;* Documentation: https://www.wiznet.io/product-item/w5100s/
;*
;* Include Files: none
;*
;* Assembler: lwasm 1.4.2
;*
;* Revision History:
;* Rev #     Date      Who     Comments
;* -----  -----------  ------  ---------------------------------------
;* 00     2021         RAM     Initial equates from Rick Ulland's Notes
;*********************************************************************

MYGATEWAY:                    ; My Gateway IP Address
            fcb   192,168,253,254

MYSUBNET:                     ; My Subnet Mask
            fcb   255,255,255,0 

MYMAC:                        ; My Source Hardware Address
            fcb   $00,$08,$DC,$00,$00,$01

MYIP:                         ; My Source IP Address
            fcb   192,168,253,10
                              ; End of My CoCoIO configuration
