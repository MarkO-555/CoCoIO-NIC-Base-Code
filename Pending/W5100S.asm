;*********************************************************************
;* Title: W5100S.asm
;*********************************************************************
;* Author: R. Allen Murphey
;*
;* License: Copyright (c) 2021 R. Allen Murphey. All Rights Reserved.
;*
;* Description: WIZnet W5100S driver
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
;* 00     2021         RAM     Initial equates from Data Sheet
;*********************************************************************

                              ; W5100S REGISTER / MEMORY MAP
                              ; 0x0000 - 0x002F Common Registers W5100 compatible
                              ; 0x0030 - 0x0088 Common Registers New W5100S
                              ; 0x0089 - 0x03FF -- Reserved --
                              ; 0x0400 - 0x04FF Socket 0 Registers
                              ; 0x0500 - 0x05FF Socket 1 Registers
                              ; 0x0600 - 0x06FF Socket 2 Registers
                              ; 0x0700 - 0x07FF Socket 3 Registers
                              ; 0x0800 - 0x3FFF -- Reserved --
                              ; 0x4000 - 0x5FFF TX Memory - default 2KB per socket
                              ; 0x6000 - 0x7FFF RX Memory - default 2KB per socket

                              ; COMMON REGISTERS
MR:         rmb   1           ; 0x0000        Mode (MR)
GAR:        rmb   4           ; 0x0001-0x0004 Gateway Address (GAR0-3)
SUBR:       rmb   4           ; 0x0005-0x0008 Subnet Mask Address (SUBR0-3)
SHAR:       rmb   6           ; 0x0009-0x000E Source Hardware Address (SHAR0-5)
SIPR:       rmb   4           ; 0x000F-0x0012 Source IP Address (SIPR0-3)
INTPRMR:    rmb   2           ; 0x0013-0x0014 Interrupt Pending Time (INPTMR0-1)
IR:         rmb   1           ; 0x0015        Interrupt (IR)
IMR:        rmb   1           ; 0x0016        Interrupt Mask (IMR)
RTR:        rmb   2           ; 0x0017-0x0018 Retransmission Time (RTR0-1)
RCR:        rmb   1           ; 0x0019        Retransmission Count (RCR)
RMSR:       rmb   1           ; 0x001A        RX Memory Size (RMSR)
TMSR:       rmb   1           ; 0x001B        TX Memory Size (TMSR)
IR2:        rmb   1           ; 0x0020        Interrupt2 (IR2)
IMR2:       rmb   1           ; 0x0021        Interrupt2 Mask (IMR2)
PTIMER:     rmb   1           ; 0x0028        PPP LCP Request Timer (PTIMER)
PMAGIC:     rmb   1           ; 0x0029        PPP LCP Magic Number (PMAGIC)
UIPR:       rmb   4           ; 0x002A-0x002D Unreachable IP Address (UIPR0-3)
UPORTR:     rmb   2           ; 0x002E-0x002F Unreachable Port (UPORTR0-1)
MR2:        rmb   1           ; 0x0030        Mode2 (MR2)
PHAR:       rmb   6           ; 0x0032-0x0037 Destination Hardware Address on PPPoE (PHAR0-5)
PSIDR:      rmb   2           ; 0x0038-0x0039 Session ID on PPPoE (PSIDR0-1)
PMRUR:      rmb   2           ; 0x003A-0x003B Maximum Receive Unit on PPPoE (PMRUR0-1)
PHYSR:      rmb   1           ; 0x003C        PHY Status (PHYSR0)
PHYAR:      rmb   1           ; 0x003E        PHY Address Value (PHYAR)
PHYRAR:     rmb   1           ; 0x003F        PHY Register Address (PHYRAR)
PHYDIR:     rmb   2           ; 0x0040-0x0041 PHY Data Input (PHYDIR0-1)
PHYDOR:     rmb   2           ; 0x0042-0x0043 PHY Data Output (PHYDOR0-1)
PHYACR:     rmb   1           ; 0x0044        PHY Access (PHYACR)
PHYDIVR:    rmb   1           ; 0x0045        PHY Division (PHYDIVR)
PHYCR:      rmb   2           ; 0x0046-0x0047 PHY Control (PHYCR0-1)
SLCR:       rmb   1           ; 0x004C        SOCKET-less Command (SLCR)
SLRTR:      rmb   2           ; 0x004D-0x004E SOCKET-less Retransmission Time (SLRTR0-1)
SLRCR:      rmb   1           ; 0x004F        SOCKET-less Retransmission Count (SLRCR)
SLPIPR:     rmb   4           ; 0x0050-0x0053 SOCKET-less Peer IP Address (SLPIPR0-3)
SLPHAR:     rmb   6           ; 0x0054-0x0059 SOCKET-less Peer Hardware Address (SLPHAR0-5)
PINGSEQR:   rmb   2           ; 0x005A-0x005B PING Sequence Number (PINGSEQR0-1)
PINGIDR:    rmb   2           ; 0x005C-0x005D PING ID (PINGIRDR0-1)
SLIMR:      rmb   1           ; 0x005E        SOCKET-less Interrupt Mask (SLIMR)
SLIR:       rmb   1           ; 0x005F        SOCKET-less Interrupt (SLIR)
CLKLCKR:    rmb   1           ; 0x0070        Clock Lock (CLKLCKR)
NETLCKR:    rmb   1           ; 0x0071        Network Lock (NETLCKR)
PHYLCKR:    rmb   1           ; 0x0072        PHY Lock (PHYLCKR)
VERR:       rmb   1           ; 0x0080        Chip Version (VERR)
TCNTR:      rmb   2           ; 0x0082-0x0083 100us Tick Counter (TCNTR0-1)
TCNTCLR:    rmb   1           ; 0x0088        (TCNTCLR)

W5100SINIT:                   ; Initialize the W5100S

