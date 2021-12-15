		           * WizNet 5100 register defines       *
		           * COMMON REGISTERS                   *
		           * labels per WizNet minus trailing R *
		           * trailing 0 =  multibyte data       *
		           **************************************
		   		         
M	EQU	$0000	Mode 
GA0	EQU	$0001	Gateway Address (4)
SUB0	EQU	$0005	Subnet Mask Address (4)
SHA0	EQU	$0009	Source Hardware Address (6)
SIP0	EQU	$000F	Source IP Address (4)
INTPTM0	EQU	$0013	Interrupt Pending Time (2)
I	EQU	$0015	Interrupt
IM	EQU	$0016	Interrupt Mask
RT0	EQU	$0017	Retransmission Time (2)
RC	EQU	$0019	Retransmission Time ???
RMS	EQU	$001A	RX Memory Size
TMS	EQU	$001B	TX Memory Size
I2	EQU	$0020	Interrupt2
IM2	EQU	$0021	Interrupt Mask2
PTIME	EQU	$0028	PPP LCP Request Timer
PMAGIC	EQU	$0029	PPP LCP Magic Number
UIP0	EQU	$002A	Unreachable IP Address (4)
UPORT0	EQU	$002E	Unreachable Port (2)
M2	EQU	$0030	Mode2
PHA0	EQU	$0032	Destination Hardware Addr on PPoE (6)
PSID0	EQU	$0038	Session ID on PPPoE 	
PMRU0	EQU	$003A	Maximum Receive Unit on PPPoE (2)	
PHYS0	EQU	$003C	PHY Status
PHYDI0	EQU	$0040	PHY Data Input (2)
PHYDO0	EQU	$0042	PHY Data Output (2)
PHYAC	EQU	$0044	PHY Access
PHYDIV	EQU	$0045	PHY Division
PHYC0	EQU	$0046	PHY Control (2)	
SLC	EQU	$004C	SOCKET-less Command
SLRT0	EQU	$004D	SOCKET-less Retransmission Time (2)
SLRC	EQU	$004F	SOCKET-less Retransmission Count
SLPIP0	EQU	$0050	SOCKET-less Peer IP Address (3)
SLPHA0	EQU	$0054	SOCKET-less Peer Hardware Addr (6)
PNGSEQ0	EQU	$005A	PING Sequence Number (2)
PINGID0	EQU	$005C	PING ID (1)
SLIM	EQU	$005E	SOCKET-less Interrupt Mask
SLI	EQU	$005F	SOCKET-less Interrupt
CLKLCK	EQU	$0070	Clock Lock
NETLCK	EQU	$0071	Network Lock
PHYLCK	EQU	$0072	PHY Lock
VER	EQU	$0080	Chip Version
TCNT0	EQU	$0082	100us Tick Counter (2)	
TCNTCL	EQU	$0088	

		           **************************************
		           * SOCKET REGISTERS                   *
		           * only LSB is defined here           *
		           * set MSB to $00, $01, $02, $03      *
		           **************************************
		           
_M	EQU	$00	Mode
_C	EQU	$01	Command
_I	EQU	$02	Interrupt
_S	EQU	$03	Status
_PORT0	EQU	$04	Source Port (2)	
_DHA0	EQU	$06	Dest Hrdw Addr (6)
_DIP0	EQU	$0C	Dest IP Addr (4)	
_DPORT0	EQU	$10	Dest Port (2)
_MSS0	EQU	$12	Max Seg Size (2)
_PROTO	EQU	$14	IP Protocol
_TOS	EQU	$15	IP Type Of Srvc
_TTL	EQU	$16	IP Time To Live
_RXBUFSZ	EQU	$1E	RX Buffer Size
_TXBUFSZ	EQU	$1F	TX Buffer Size
_TX_FS0	EQU	$20	TX Free Size (2)	
_TX_RD0	EQU	$22	TX Read Pntr (2)	 
_TX_WR0	EQU	$24	TX Write Pntr (2)	 
_RX_RS0	EQU	$26	RX Rcvd Size (2)
_RX_RD0	EQU	$28	RX Read Pntr (2)	
_RX_WR0	EQU	$2A	RX Write Pntr (2)
_IMR	EQU	$2C	Interrupt Mask
_FRAG0	EQU	$2D	Fragment Offset (2)	
_MR2	EQU	$2F	Mode 2
_KPALVT	EQU	$30	Keepalive Timer
_RTR0	EQU	$32	Retrans Time (2)	
_RCR	EQU	$34	Retrans Cnt

		           **************************************
		           * SOCKET REGISTERS                   *
		           * only socket 0 is defined here      *
		           * add $100 for 1, $200=2, $300=3     *
		           **************************************
		           
S0_M	EQU	$0400	Mode
S0_C	EQU	$0401	Command
S0_I	EQU	$0402	Interrupt
S0_S	EQU	$0403	Status
S0_PORT0	EQU	$0404	Source Port (2)	
S0_DHA0	EQU	$0406	Dest Hrdw Addr (6)
S0_DIP0	EQU	$040C	Dest IP Addr (4)	
S0_DPORT0	EQU	$0410	Dest Port (2)
S0_MSS0	EQU	$0412	Max Seg Size (2)
S0_PROTO	EQU	$0414	IP Protocol
S0_TOS	EQU	$0415	IP Type Of Srvc
S0_TTL	EQU	$0416	IP Time To Live
S0_RXBUFSZ	EQU	$041E	RX Buffer Size
S0_TXBUFSZ	EQU	$041F	TX Buffer Size
S0_TX_FS0	EQU	$0420	TX Free Size (2)	
S0_TX_RD0	EQU	$0422	TX Read Pntr (2)	 
S0_TX_WR0	EQU	$0424	TX Write Pntr (2)	 
S0_RX_RS0	EQU	$0426	RX Rcvd Size (2)
S0_RX_RD0	EQU	$0428	RX Read Pntr (2)	
S0_RX_WR0	EQU	$042A	RX Write Pntr (2)
S0_IMR	EQU	$042C	Interrupt Mask
S0_FRAG0	EQU	$042D	Fragment Offset (2)	
S0_MR2	EQU	$042F	Mode 2
S0_KPALVT	EQU	$0430	Keepalive Timer
S0_RTR0	EQU	$0432	Retrans Time (2)	
S0_RCR	EQU	$0434	Retrans Cnt

		           **************************************
		           * SOCKET REGISTERS                   *
		           * only socket 1 is defined here      *
		           * add $100 for 1, $200=2, $300=3     *
		           **************************************

		           **************************************
		           * SOCKET REGISTERS                   *
		           * only socket 2 is defined here      *
		           * add $100 for 1, $200=2, $300=3     *
		           **************************************

		           **************************************
		           * SOCKET REGISTERS                   *
		           * only socket 3 is defined here      *
		           * add $100 for 1, $200=2, $300=3     *
		           **************************************

		           **************************************
		           * TX/RX MEMORY BLOCKS                *
		           * 8KB for TX TOTAL, 8KB for RX TOTAL *
		           * BUFFERS are 1KB, 2KB, 4KB or 8KB   *
		           **************************************
TX_BASE	EQU	$4000	
RX_BASE	EQU	$6000	
