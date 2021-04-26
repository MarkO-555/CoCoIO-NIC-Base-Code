;*********************************************************************
;* Title: COCOIOCFG.asm
;*********************************************************************
;* Author: R. Allen Murphey
;*
;* License: Contributed 2021 by R. Allen Murphey to CoCoIO Development
;*
;* Description: CoCoIO for Color Computer Configuration
;*
;* Documentation: none
;*
;* Include Files: none
;*
;* Assembler: lwasm 1.4.2
;*
;* Revision History:
;* Rev #     Date      Who     Comments
;* -----  -----------  ------  ---------------------------------------
;* 00     2021         RAM     Initial data to config for testing
;*********************************************************************

MYGATEWAY:                    ; My Gateway IP Address
            fcb   10,39,128,1

MYSUBNET:                     ; My Subnet Mask
            fcb   255,255,255,0 

MYMAC:                        ; My Source Hardware Address
            fcb   $00,$08,$DC,$00,$00,$01

MYIP:                         ; My Source IP Address
            fcb   10,39,128,68
                              ; End of My CoCoIO configuration
