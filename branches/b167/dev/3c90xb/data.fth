\ See license at end of file
purpose: Register access methods for 3COM90xB

hex
headers

: cmd!     ( w -- )  e reg-w!  ;  \ Write the cmd/status register (write only)
: status@  ( -- w )  e reg-w@  ;  \ Read the status register (read only)

\ Stalls until previous command (cmd!) is completed
\ The only command that require this wait period are:
\ global-reset, Rx-reset, Tx-done, Rx discard, Tx-reset
: cmd-wait  ( -- )  begin  status@  1000 and 0=  until  ;

: cmdw!  ( w -- )  cmd!  cmd-wait  ;	\ Send command, wait for completion

\ Returns the current active window
: get-window  ( -- b )  status@  d# 13 rshift 7 and  ;
: select-window  ( b -- )   0800 + cmd!  ;	\ Selects register window

: win@  ( reg# window -- w )  select-window reg-w@  ;
: win!  ( w reg# window -- )  select-window reg-w!  ;

: rx-disable  ( -- )  1800 cmd!   ;	\ Disable the receiver
: rx-enable   ( -- )  2000 cmd!   ;	\ Enable the receiver
: rx-reset    ( mask -- )  2800 or cmdw!  ;	\ Reset the receiver
					\ (Use only after FIFO underruns)

: rx-filter!  ( w -- )  1f and 8000 or cmd!  ;	\ Sets the receiver filter

: up-stall    ( -- )  3000 cmdw!  ;	\ Stall the upload engine
: up-unstall  ( -- )  3001 cmd!   ;	\ Unstall the upload engine
: dn-stall    ( -- )  3002 cmdw!  ;	\ Stall the download engine
: dn-unstall  ( -- )  3003 cmd!   ;	\ Unstall the download engine
: tx-enable   ( -- )  4800 cmd!   ;	\ Enable transmitter
: tx-disable  ( -- )  5000 cmd!   ;	\ Disable transmitter
: tx-reset    ( mask -- )  5800 or cmdw!  ;	\ Reset transmitter

: tx-status@  ( -- b )  1b reg-b@  ;	\ Reads the transmit status
: tx-clear    ( -- )  0 1b reg-b!  ;	\ Clears transmit status bits

: txfree@     ( -- w )  c 3 win@   ;	\ Returns free space in fifo

: indicate-enable!  ( b -- )  7800 or cmd!  ;	\ Set interrupt indicate enable
: int-ack  ( -- )    6fff cmd!  ;		\ Acknowledge interupt

\ Enables the dc-dc converter used for 10Base-2 and lets it settle
: enable-dc  ( -- )  1000 cmd!  1 ms  ;

\ Disables dc-dc converter and lets it settle before using AUI
: disable-dc  ( -- )  b800 cmd!  1 ms  ;

: global-reset  ( -- )  0 cmdw!  ;		\ Overall reset of NIC

: eeprom@  ( a -- w )		\ Reads data from EEPROM
   0 select-window		\ First set window 0
   3f and 0080 or		\ Form the address
   a reg-w!
   begin  a reg-w@  8000 and 0=  until	\ Wait until not busy
   1 ms				\ Wait for 162us before data is available
   c reg-w@			\ Read data
;

: full-duplex  ( -- )  6 3 win@  20 or          6 3 win!  ;
: half-duplex  ( -- )  6 3 win@  20 invert and  6 3 win!  ;

: int-config@  ( -- l )	 3 select-window  0 reg-l@  ;  \ Internal config reg.
: int-config!  ( l -- )	 3 select-window  0 reg-l!  ;  \ Internal config reg.

: auto-select-on   ( -- )  int-config@  100.0000 or          int-config!  ;
: auto-select-off  ( -- )  int-config@  100.0000 invert and  int-config!  ;

: media-option  ( -- b )  8 3 win@  ;  \ Bitmap of supported media types

: /string  ( adr len n -- adr' len' )  tuck - -rot + swap  ;

: decode-bytes  ( adr len n -- adr' len' $ )
   >r over swap r@ /string rot r>
;

: set-address  ( adr len -- )			\ Sets the adapters address
   2 select-window				\ Address stored in window 2
   dup decode-bytes		( adr2 len2 adr1 len1 )
   0 do				( adr2 len2 adr1 )
      dup i + c@		( adr2 len2 adr1 h )
      swap dup			( adr2 len2 h adr1 adr1 )
      i + 1 + c@		( adr2 len2 h adr1 l )
      rot			( adr2 len2 adr1 l h )
      swap bwjoin		( adr2 len2 adr1 w )
      i reg-w!			( adr2 len2 adr1 )
   2 +loop
   3drop
;

: promiscuous-mode   ( -- )  f rx-filter!  ;		\ Receive all packets
: link-beat-enable   ( -- )  a 4 win@  80 or          a 4 win!  ;
: link-beat-disable  ( -- )  a 4 win@  80 invert and  a 4 win!  ;
: max-frame-size     ( -- )  4 3 win@  ;		\ Max packet size

: dnlistptr!  ( l -- )  24 reg-l!  ;
: dnlistptr@  ( -- l )  24 reg-l@  ;

: uplistptr!    ( l -- )  38 reg-l!  ;
: uplistptr@    ( -- l )  38 reg-l@  ;
: uppktstatus@  ( -- l )  30 reg-l@  ;

\ MII interface.  Window 4 has be selected
0 value mii-dir
: mii-reg!  ( w -- )  8 reg-w!  ;	\ Control various PHY functions
: mii-reg@  ( -- w )  8 reg-w@  ;
: mii-clk0  ( -- )  mii-dir mii-reg!  ;
: mii-clk1  ( -- )  mii-dir 1 or mii-reg!  ;
: mii-dir0  ( -- )  0 dup to mii-dir mii-reg!  ;
: mii-dir1  ( -- )  4 dup to mii-dir mii-reg!  ;
: mii-bit!  ( b -- )  1 and 1 << mii-dir or  mii-clk0  1 or mii-reg!  ;
: mii-bit@  ( -- b )  0 to mii-dir mii-clk0 mii-clk1 mii-reg@ 2 and 1 >>  ;
: mii-z     ( -- )  mii-clk0  0 to mii-dir mii-clk1  ;

: mii-cmd  ( reg phy op -- )	\ Common setup for MII read and write
   4 select-window
   4 to mii-dir
   d# 32 0 do  1 mii-bit!  loop				\ PRE
   0 mii-bit!  1 mii-bit!				\ ST
   dup 1 >> mii-bit!  mii-bit!				\ OP
   d# 5 0 do  dup 4 i - >> mii-bit!  loop  drop		\ PHYAD
   d# 5 0 do  dup 4 i - >> mii-bit!  loop  drop		\ REGAD
;
: mii@  ( reg phyad -- w )
   2 mii-cmd						\ PRE, ST, OP, PHY, REG
   mii-z						\ TA
   mii-bit@  0=  if
      0  d# 16 0  do  1 <<  mii-bit@ or  loop		\ DATA
      mii-z						\ IDLE
   else
      0 ." mii failed." cr
   then
;
: mii!  ( w reg phyad-- )
   1 mii-cmd						\ PRE, ST, OP, PHY, REG
   1 mii-bit!  0 mii-bit!				\ TA
   d# 16 0  do  dup d# 15 i - >> mii-bit!  loop  drop	\ DATA
   mii-z						\ IDLE
;

: auto-neg-status   ( -- w )  1 18 mii@  ;
: auto-neg-advert   ( -- w )  4 18 mii@  ;
: auto-neg-ability  ( -- w )  5 18 mii@  ;  
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
