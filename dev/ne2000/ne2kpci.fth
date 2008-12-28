purpose: PCI variant of NE2000 network controller
\ See license at end of file

\ 0 0  " i300"  " /isa"  begin-package

\ NE2000 controller board offsets

" ethernet" device-name

h# 10 constant dataport		\  NE2000 Port Window.

[ifdef] ISA
my-address my-space h# 20 reg
my-address value chip-base
: 1us  ( -- )  h# 61 pc@ drop  ;  \ Touch timer port to pause
: reg!  ( b offset -- )  chip-base +  pc!  1us  ;
: reg@  ( offset -- b )  chip-base +  pc@  1us  ;
: data-out  ( adr -- )  le-w@ dataport chip-base +  pw!  ;
: data-in   ( adr -- )  dataport chip-base +  pw@  swap le-w!  ;
: map-regs ;  : unmap-regs ;
[else]
h# 100 constant /regs

\ Configuration space registers
my-address my-space              encode-phys
                             0     encode-int encode+ 0 encode-int encode+

\ I/O space registers
0 0        my-space  0100.0010 + encode-phys encode+
                             0 encode-int encode+  /regs encode-int encode+
 " reg" property

0 instance value chip-base

: my-w@  ( offset -- w )  my-space +  " config-w@" $call-parent  ;
: my-w!  ( w offset -- )  my-space +  " config-w!" $call-parent  ;
: unmap-regs  ( -- )
   4 my-w@  6 invert and  4 my-w!
   chip-base /regs " map-out" $call-parent
;
: map-regs  ( -- )
   0 0  my-space h# 0100.0010 +  /regs " map-in" $call-parent  to chip-base
   4 my-w@  5 or  4 my-w!
;
: reg!  ( b offset -- )  chip-base +  rb!  ;
: reg@  ( offset -- b )  chip-base +  rb@  ;
: data-out  ( adr -- )  w@ dataport chip-base +  rw!  ;
: data-in   ( adr -- )  dataport chip-base +  rw@  swap w!  ;

[then]

" network" device-type

headerless

[ifdef] 386-assembler
[ifndef] pseudo-dma-in
fload ${BP}/cpu/i386/inoutstr.fth
[then]
[then]

\ The EN registers - the DS8390 chip registers
\ There are two (really 3) pages of registers in the chip. You select
\ which page you want, then address them at offsets 00-0F from base.
\ The chip command register (CCMD; offset 0) appears in both pages.

\ Page 1

h# 001 constant PHYS	\ This board's physical enet addr RD WR
h# 007 constant CURPAG	\ Current memory page RD WR
h# 008 constant MULT	\ Multicast filter mask array (8 bytes) RD WR

\ Chip commands in command register
h# 001 constant STOP	\ Stop the chip
h# 002 constant START	\ Start the chip
h# 004 constant TRANS	\ Transmit a frame
h# 008 constant RREAD	\ remote read
h# 010 constant RWRITE	\ remote write
h# 020 constant NODMA	\ No remote DMA used on this card
h# 000 constant PAGE0	\ Select page 0 of chip registers
h# 040 constant PAGE1	\ Select page 1 of chip registers

\ Commands for RXCR - RX control reg
h# 001 constant RCRC	\ Save error pkts
h# 002 constant RUNT	\ Accept runt pkt
h# 004 constant BCST	\ Accept broadcasts
h# 008 constant MULTI	\ Multicast (if pass filter)
h# 010 constant PROMP	\ Promiscuous physical addresses
h# 020 constant MON	\ Monitor mode (no packets rcvd)

\ Bits in TXCR - transmit control reg
h# 001 constant TCRC	\ inhibit CRC, do not append crc
h# 002 constant LOOPB	\ Set loopback mode
h# 006 constant LB01	\ encoded loopback control
h# 008 constant ATD	\ auto tx disable
h# 010 constant OFST	\ collision offset enable

\ Bits in DCFG - Data config register
h# 001 constant WTS	\ word transfer mode selection
\ h# 002 constant BOS	\ byte order selection
\ h# 004 constant LAS	\ long addr selection
\ h# 008 constant BMS	\ burst mode selection
\ h# 010 constant ARM	\ autoinitialize remote
\ h# 000 constant FT00	\ burst length selection
\ h# 020 constant FT01	\ burst length selection
\ h# 040 constant FT10	\ burst length selection
\ h# 060 constant FT11	\ burst length selection

\ Bits in ISR - Interrupt status register
h# 001 constant RX	\ Receiver, no error
h# 002 constant TX	\ Transmitter, no error
h# 004 constant RX-ERR	\ Receiver, with error
h# 008 constant TX-ERR	\ Transmitter, with error
h# 010 constant OVR	\ Receiver overwrote the ring
h# 020 constant COUNTERS	\ Counters need emptying
h# 040 constant RDC	\ remote dma complete
h# 080 constant RESET	\ Reset completed

h# 03f constant ALL	\ Interrupts we will enable

\ Bits in received packet status byte and RSR
h# 001 constant RXOK	\ Received a good packet
h# 002 constant CRCE	\ CRC error
h# 004 constant FAE	\ frame alignment error
h# 008 constant FO	\ FIFO overrun
h# 010 constant MPA	\ missed pkt
h# 020 constant PHY	\ physical/multicase address
h# 040 constant DIS	\ receiver disable. set in monitor mode
h# 080 constant DEF	\ deferring

\ Bits in TSR -  TX status reg

h# 001 constant PTX	\ Packet transmitted without error
h# 002 constant DFR	\ non deferred tx
h# 004 constant COLL	\ Collided at least once
h# 008 constant COLL16	\ Collided 16 times and was dropped
h# 010 constant CRS	\ carrier sense lost
h# 020 constant FU	\ TX FIFO Underrun
h# 040 constant CDH	\ collision detect heartbeat
h# 080 constant OWC	\ out of window collision

\ Description of header of each packet in receive area of memory

h# 0 constant STAT	\ Received frame status
h# 1 constant NXT-PG	\ Page after this frame
h# 2 constant SIZE-LO	\ Length of this frame
h# 3 constant SIZE-HI	\ Length of this frame
h# 4 constant NHDR	\ Length of above header area


\ Shared memory management parameters

h# 040 constant TSTART-PG	\ First page of TX buffer
h# 046 constant RSTART-PG	\ Starting page of RX ring
h# 080 constant RSTOP-PG	\ Last page +1 of RX ring

: longpause  ( -- )  2 ms  ;	\ Should be 1.6 ms

0 instance value #crc-errors
0 instance value #alignment-errors
0 instance value #missed

\ Page 0 registers
: cmd!  ( b -- )  0 reg!  ;
: stat@  ( -- b )  0 reg@  ;
: startpg!   ( page# -- )  1 reg!  ;	\ Starting page of ring buffer
: stoppg!    ( page# -- )  2 reg!  ;	\ Ending page + 1 of ring buffer
: clda@      ( -- adr )  1 reg@  2 reg@  bwjoin  ;  \ Current local DMA address
: boundary@  ( -- page# )  3 reg@  ;	\ Boundary page of ring bfr
: boundary!  ( page# -- )  3 reg!  ;
: tsr@   ( -- bits )   4 reg@  ;	\ Transmit status reg
: tpsr!  ( page# -- )  4 reg!  ;	\ Transmit starting page
: ncr@   ( -- count )  5 reg@  ;	\ Number of collision reg
: fifo@  ( -- data )   6 reg@  ;	\ FIFO data
: rcnt!  ( cnt -- )  wbsplit swap  h# 0a reg!  h# 0b reg!  ;
: tcnt!  ( cnt -- )  wbsplit swap  5 reg!  6 reg!  ;
: isr@   ( -- mask )  7 reg@  ;		\ Interrupt status reg
: isr!   ( mask -- )  7 reg!  ;
: rsr@   ( -- mask )  h# c reg@  ;	\ Receive status reg
: imr!   ( mask -- )  h# f reg!  ;	\ Interrupt mask reg
: rxcr!  ( bits -- )  h# c reg!  ;	\ Receive control reg
: txcr!  ( bits -- )  h# d reg!  ;	\ Transmit control reg
: dcfg!  ( bits -- )  h# e reg!  ;	\ Data configuration reg
: counter0@  ( -- count )  h# d reg@  ;  \ Rcv alignment error counter
: counter1@  ( -- count )  h# e reg@  ;  \ Rcv CRC error counter
: counter2@  ( -- count )  h# f reg@  ;  \ Rcv missed frame error counter
: rda!  ( page# -- )  wbsplit swap  8 reg!  9 reg!  ;
: crda@  ( -- adr )  8 reg@  9 reg@  bwjoin  ;  \ Current remote DMA address

: set-page  ( page# -- old-cmd-reg )  6 lshift  stat@ tuck or cmd!  ;
: preg@  ( reg# page# -- b )  set-page >r  reg@  r> cmd!  ;
: preg!  ( b reg# page# -- )  set-page >r  reg!  r> cmd!  ;

: curpag@  ( -- page# )  7 1 preg@  ;
: curpag!  ( page# -- )  7 1 preg!  ;

: stop-chip  ( -- )  NODMA STOP or cmd!  ;
: reset-8390  ( -- )
   h# 1f reg@  longpause  h# 1f reg!   \ should set command 21, 80
;

0 value endcfg

\ Block input routine

: block-input  ( adr len offset -- )
   NODMA START or  cmd!
   rda!  dup rcnt!                      ( adr len )
   RREAD START or  cmd!		\ read and start

\ [ endcfg WTS and ]  [if]
   ( buf len )
[ifdef] pseudo-dma-in
   dataport chip-base +  pseudo-dma-in
[else]
   2dup  1 invert and  bounds  ?do	( adr len )
      i data-in				( adr len )
   /w +loop				( adr len )
   dup 1 and  if			( adr len )
      + 1- dataport reg@ swap c!
   else
      2drop
   then
[then]
\ [else]
\    bounds  ?do  dataport reg@  i c!  loop
\ [then]
;

: block-output  ( adr len offset -- error? )
   NODMA START or  cmd!	\ stop & clear the chip
   rda!  dup 1 and +  dup rcnt!     ( adr len )
   RWRITE START or  cmd!  \ write and start
   ( buf len )
[ifdef] pseudo-dma-out
   dataport chip-base +  pseudo-dma-out
[else]
   bounds  ?do  i data-out  /w +loop
[then]

   h# 10000 0  do
      isr@  RDC and  if  unloop false exit  then
   loop
   true
;

RSTOP-PG value sm-rstop-ptr

[ifdef] board-features
0 value is-overrun-690
[then]

\ a temp buffer for the received header
d# 4 constant RCV-HDR-SIZE
RCV-HDR-SIZE buffer: rcv-hdr

0 instance value #rx-errors
0 instance value #rx-overruns
0 instance value #tx-errors

\ Next Packet Pointer
\
\   Initialize to the same value as the current page pointer (start page 1).
\   Update after each reception to be the value of the next packet pointer
\   read from the NIC Header.
\   Copy value -1 to boundry register after each update.
\   Compare value with contents of current page pointer to verify that a
\   packet has been received (don't trust ISR RXE/PRX bits). If !=, one
\   or more packets have been received.

0 value next-page
0 value last-curpag

\ Added flags and temp storage for new receive overrun processing

: tx-wait  ( -- )
   d# 1024 7 *  0  do	\ max coll time in Ethernet slot units
      d# 51 0  do		\ Wait 1 time slot, assuming 1 usec I/O
         stat@  TRANS and  0=  if  \ transmitter still running?
            unloop unloop exit
         then
      loop
   loop
   #tx-errors 1+ to #tx-errors	\ count hard errors.
;

[ifdef] interrupt-driven
: tx-ack  ( -- )
   tsr@ drop	\ get state from prior TX

   \ Acknowledge the TX interrupt
   TX TX-ERR or isr! \ clr either possible TX int bit
;
[then]

headers
: write  ( adr len -- actual )
   stat@  TRANS  and  if
      tx-wait
[ifdef] interrupt-driven
      tx-ack
   else
      \ Check for recent TX completions in the interrupt status register
      isr@ TX TX-ERR  and  if
         tx-ack
      then
[then]
   then

   d# 1514 min  tuck			     ( len adr len' )
   d# 60 max				     ( len adr len' )

   RDC isr!	\ clear remote interrupt int.

   dup tcnt!                                 ( len adr len' )
   TSTART-PG 8 lshift  block-output          ( len error? )
   if  drop -1 exit  then		     ( len )

   TSTART-PG tpsr!		\ Transmit Page Start Register
   TRANS NODMA or START or  cmd!	\ Start the transmitter
;
headerless

: set-address  ( adr len -- )
   0  do  dup i + c@  PHYS i + 1 preg!  loop  drop
;

false value promiscuous?
false value loopback?
false value dma?
BCST value rx-mode

\ Set the multicast filter mask bits for promiscuous reception
: set-multicast  ( -- )
   NODMA PAGE1 or STOP or cmd!  \ Select page 1
   8 0  do  h# ff  MULT i + reg!  loop
   NODMA START or cmd!  \ Select page 0
;

: set-rx-mode  ( -- )	\ Set receiver to selected mode
   BCST  promiscuous?  if  MULTI or  PROMP or  then  rxcr!
;
: set-tx-mode  ( -- )  loopback?  if  LOOPB  else  0  then  txcr!  ;

: reset-board  ( -- )
   reset-8390
   stop-chip

   \ Wait 1.6ms for the NIC to stop transmitting or receiving a packet.
   \ National says monitoring the ISR RST bit is not reliable, so a wait
   \ of the maximum packet time (1.2ms) plus some padding is required.

   longpause
;

: reset-interface  ( -- )
   reset-board
   h# ff isr!		\ Clear all pending interrupts
   0 imr!		\ Turn off all interrupt enables
;
: rx-error  ( -- )
   #rx-errors 1+ to #rx-errors

   \ Error recovery:
   \ Copy the last known current page pointer into the next packet pointer
   \ which will result in skipping all the packets from the errored one to
   \ where the NIC was storing them when we entered this ISR, but prevents
   \ us from trying to follow totally bogus next packet pointers through
   \ the card RAM space.

   last-curpag to next-page
;

: +boundary  ( -- )
   next-page 1-  dup RSTART-PG  <  if  drop  sm-rstop-ptr 1-  then
   boundary!
;

: next-buffer  ( -- page# )  rcv-hdr NXT-PG + c@  ;
[ifndef] le-w@  : le-w@  ( adr -- w )  dup c@ swap 1+ c@ bwjoin  ;  [then]
: packet-ok?  ( -- len true | false )
   rcv-hdr  RCV-HDR-SIZE  next-page 8 lshift  block-input  ( )
   rcv-hdr STAT + c@  RXOK and   if                        ( )
      next-buffer  RSTART-PG sm-rstop-ptr within  if
         rcv-hdr SIZE-LO + le-w@  NHDR -                   ( len )
         true                                              ( len true )
         exit
      then
   then
   \ Bad packet or chip screwup
   rx-error +boundary  false                               ( false )
;

\ Do the work of copying out a receive frame.
: do-receive  ( adr len -- len )
   tuck  next-page 8 <<  NHDR +  block-input    ( len )
   next-buffer  to next-page			( len )
   +boundary                 			( len )
;

fload ${BP}/dev/ne2000/queue.fth

: pull-packets  ( -- )
   begin  last-curpag next-page <>  while    ( )
      packet-ok?  if                         ( length )
         new-buffer                          ( handle adr len )
         do-receive drop                     ( handle )
         enque-buffer                        ( )
      then                                   ( )
   repeat                                    ( )
;

0 value rcv-ovr-resend		\ flag to indicate resend needed
: overrun  ( mask -- )
   drop
[ifdef] board-features
   board-features BF-NIC-690 and  if
      1 to is-overrun-690
      exit
   then
[then]

   #rx-overruns 1+ to #rx-overruns

   \ Get the command register TXP bit to test for incomplete transmission later

   stat@  ( status )

   stop-chip

   \ Wait for the NIC to stop transmitting or receiving a packet.
   longpause

   \ Clear the remote byte count registers
   0 rcnt!

   \ check the saved state of the TXP bit in the command register
   0 to rcv-ovr-resend		 \ clear the resend flag
   ( status ) TRANS  and  if     \ Was transmitter still running?
      \ Transmitter was running, see if it finished or died
      isr@  TX TX-ERR  or  0=  if
         \ Transmitter did not complete, remember to resend the packet later.
	 true to rcv-ovr-resend
      then
   then

   \ Put the NIC chip into loopback so it won't keep trying to
   \ receive into a full ring

   LOOPB txcr!			\ Put transmitter in loopback mode
   START NODMA or  cmd!		\ Start the chip running again

   \ Verify that there is really a packet to receive by fetching the current
   \ page pointer and comparing it to the next packet pointer.

   curpag@ curpag!		\ Rewrite current page to fix SMC bug.

   pull-packets

   +boundary

   \ When we get here we have either removed one packet from the ring and
   \ updated the boundary register, or determined that there really were
   \ no new packets in the ring.

   OVER isr!		\ Clear the overrun interrupt bit
   set-tx-mode		\ Take the NIC out of loopback

   \ Resend any incomplete transmission
   rcv-ovr-resend  if
      TRANS NODMA or START or cmd!  \ Start the transmitter
   then
;

[ifdef] board-features
: recv-690-overrun  ( -- )
   false to is-overrun-690
   boundary@ boundary!		\ rewrite bndry with itself
   OVER isr!		\ Clear overrun interrupt bit
;
[then]

: empty-counters  ( -- )
   \ We have to read the counters to clear them and to clear the interrupt.
   counter0@ #alignment-errors + to #alignment-errors
   counter1@ #crc-errors       + to #crc-errors
   counter2@ #missed           + to #missed
;
: .errors  ( -- )
   isr@
   dup  RX-ERR    and  if  ." RX-ERR "    then
   dup  TX-ERR    and  if  ." TX-ERR "    then
   dup  OVR       and  if  ." OVR "  dup overrun  then
   dup  COUNTERS  and  if  ." COUNTERS "  empty-counters  then
   isr!
;

headers
: read  ( adr len -- -2 | actual )
   curpag@ to last-curpag            ( adr len )

   .errors                           ( adr len )

   ?return-queued  0=  if            ( adr len )
      last-curpag  next-page <>  if  ( adr len )
         packet-ok?  if              ( adr len actual )
            min do-receive           ( actual | -1 )     \ Good packet
         else                        ( adr len )
            2drop -1                 ( -1 )              \ Bad packet
         then                        ( actual | -1 )
      else                           ( adr len )
         2drop -2                    ( -2 )		 \ No packet
      then                           ( actual | -2 )
   then                              ( actual | -2 )

   pull-packets
;

headerless
h# 10 buffer: board-data
h# 6 buffer: rom-address
: init-card  ( -- okay? )
   \ Put the board data, which is 16 bytes starting at remote
   \ dma address 0, into a buffer called board-data.

\ [ base c@ base @ <> ]  [if]
   endcfg WTS or to endcfg
\ [then]
   endcfg dcfg!

   NODMA PAGE0 or  START or  cmd!

   0 rda!  h# 20 rcnt!			\ address is 0, byte count is 0x10*2
   RREAD START or  cmd!			\ read and start

   board-data  h# 10  bounds  do  dataport reg@  i c!  loop

   board-data rom-address 6 move
   rom-address 6 encode-bytes  " local-mac-address" property
   true
;

[ifndef] $=
: $=  ( $1 $2 -- equal? )
   rot tuck <>  if  3drop false exit  then  ( adr1 adr2 len1 )
   comp 0=
;
[then]

0 value tftp-args
0 value tftp-len
: parse-args  ( -- )
   my-args  begin                                               ( rem$ )
      2dup to tftp-len to tftp-args                             ( rem$ )
   dup  while                                                   ( rem$ )
      ascii , left-parse-string                                 ( rem$ head$ )
      2dup  " promiscuous" $=  if  true  to promiscuous?  else  ( rem$ head$ )
      2dup  " loopback"    $=  if  true  to loopback?     else  ( rem$ head$ )
      2dup  " pio"         $=  if  false to dma?          else  ( rem$ head$ )
      2dup  " dma"         $=  if  true  to dma?          else  ( rem$ head$ )
                                   2drop 2drop exit             ( )
      then then then then                                       ( rem$ head$ )
      2drop                                                     ( rem$ )
   repeat                                                       ( rem$ )
   2drop                                                        ( )
;

headers
\ Called once to initialize the card
: open  ( -- )
   map-regs
   parse-args

   \ Set burst mode, 8 deep FIFO, maybe big-endian
   h# 48  base c@ base @ <>  if  2 or  then  to endcfg

   reset-board				\ Reset and stop the 8390.
   endcfg dcfg!				\ Init the Data Config Reg.
   stop-chip				\ Stop chip and select page 0
   0 rcnt!				\ Clear Remote Byte Count Regs.
   MON rxcr!				\ Set receiver to monitor mode
   LOOPB txcr!				\ Put NIC in Loopback Mode 1.

   \ Do anything special that the card needs.
   \ Read the Ethernet address into rom-address.
   init-card  0=  if  false exit  then

   endcfg dcfg!				\ Re-init endcfg in case they
					\ put it into word mode.

   \ Init STARTPG to same value as BOUNDARY
   RSTART-PG dup startpg!  boundary!
   sm-rstop-ptr stoppg!

   h# ff isr!				\ Clear pending interrupts.

\  ALL imr!				\ Init IMR
   0 imr!				\ Init IMR

   \ Init the Ethernet address and multicast filters.
   mac-address set-address		\ Now set the address in the 8390 chip
   set-multicast  			\ Set the multicast masks

   \ Program the Current Page Register to Boundary Pointer + 1
   RSTART-PG 1+ dup  curpag!
   dup to last-curpag  to next-page

   set-rx-mode
   set-tx-mode

   NODMA START or  cmd!			\ Start chip

   init-queue

   true
;
: close  ( -- )
   NODMA STOP or  cmd!			\ Start chip
   drain-queue
   unmap-regs
;

: load  ( adr -- len )
   " obp-tftp" find-package  if      ( adr phandle )
      my-args rot  open-package      ( adr ihandle|0 )
   else                              ( adr )
      0                              ( adr 0 )
   then                              ( adr ihandle|0 )

   dup  0=  if  ." Can't open obp-tftp support package" abort  then
                                     ( adr ihandle )

   >r
   " load" r@ $call-method           ( len )
   r> close-package
;

\ LICENSE_BEGIN
\ Copyright (c) 2006 FirmWorks
\ 
\ Permission is hereby granted, free of charge, to any person obtaining
\ a copy of this software and associated documentation files (the
\ "Software"), to deal in the Software without restriction, including
\ without limitation the rights to use, copy, modify, merge, publish,
\ distribute, sublicense, and/or sell copies of the Software, and to
\ permit persons to whom the Software is furnished to do so, subject to
\ the following conditions:
\ 
\ The above copyright notice and this permission notice shall be
\ included in all copies or substantial portions of the Software.
\ 
\ THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
\ EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
\ MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
\ NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
\ LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
\ OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
\ WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
\
\ LICENSE_END
