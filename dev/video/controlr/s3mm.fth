\ See license at end of file
purpose: Initialize S3 Controllers In Purely Memory Mapped Mode

\ This file contains the S3 Controller specific code. This version
\ is for chips that can have all registers accessed with memory
\ mapped accesses. So far as we know, this will only work for Rev F
\ and later versions of Trio64V+ chips.

hex
headers

1 instance value s3-ver
: .driver-info  ( -- )
   .driver-info
   s3-ver . ." S3 Code Version" cr
;

-1 value ibase
h# 400.0000 value io-size

-1 value itemp

: temp-map-io
   \ h# 8100.0000 means non-relocatable I/O space
   0 0 h# 8100.0000  h# 1.0000  map-in to itemp

   \ Enable I/O space response
   4 c-w@ 1 or 4 c-w!
;

: temp-unmap-io
   itemp h# 1.0000 map-out
   -1 to ibase
;

\ : map-in-broken?  ( -- flag )  true ;

: map-s3-io-regs  ( -- )

\ cr map-in-broken?  if  ." Busted"  else  ." Not Busted" then cr

   \ Enable I/O space response
   \ Compute entire phys.lo..hi address for base address register 10
   map-in-broken?  if
      my-space h# 8200.0010 +  get-base-address        ( phys.lo,mid,hi )
   else
      0 0  my-space h# 200.0010 +                      ( phys.lo,mid,hi )
   then                                                ( phys.lo,mid,hi )
   io-size map-in to ibase

   ibase h# 100.8000 + to io-base
   4 c-w@ 2 or 4 c-w!
;

: unmap-s3-io-regs  ( -- )
   \ Unmaps s3 io space and disables I/O space response, or at least
   \ it should. For you see, NT HALs expect the graphics adapters to 
   \ respond to I/O accesses when the HAL gets control, so alas, we
   \ must leave IO enabled.

   \ If the HAL ever gets fixed, uncomment the following two lines.
   \ my-space 4 +  dup   " config-w@" $call-parent  ( adr value )
   \ 1 invert and  swap  " config-w!" $call-parent

   ibase io-size map-out
   -1 to ibase
   -1 to io-base
;

: map-s3-frame-buffer  ( -- )

   \ Compute entire phys.lo..hi address for base address register 10
   map-in-broken?  if
      my-space h# 8200.0010 +  get-base-address        ( phys.lo,mid,hi )
   else
      0 0  my-space h# 200.0010 +                      ( phys.lo,mid,hi )
   then                                                ( phys.lo,mid,hi )

   /fb map-in to frame-buffer-adr

   \ Enable memory space access
   4 c-w@ 2 or 4 c-w!

   frame-buffer-adr encode-int " address" property
;

: unmap-s3-frame-buffer  ( -- )
   4 c-w@ 2 invert and  4 c-w!
   
   frame-buffer-adr /fb map-out
   -1 to frame-buffer-adr

   " address" delete-property
;

\ Access functions for various register banks

: s3b!  ( d index -- )  io-base + rb! ;
: s3b@  ( index -- d )  io-base + rb@ ;

\ reset attribute address flip-flop
: s3-reset-attr-addr  ( -- )  
   h# 3da  ( input-status1 )  s3b@ drop
;

: subsys-ctl!  ( w -- )  io-base h# 504 + rw!  ;	\ 42e8 reg
: adv-func!    ( w -- )  io-base h# 50c + rw!  ;
: adv-func@    ( -- b )  io-base h# 50c + rw@  ;

\ : setup-vse!  ( b -- )  46e8 pc!  ;

: s3-video-mode!  ( b -- )  s3-reset-attr-addr  h# 3c0 s3b! ;
: s3-attr!  ( b index -- )  h# 3c0 s3b!  h# 3c0 s3b!  ;
: s3-attr@  ( index -- b )
   s3-reset-attr-addr  h# 3c0 s3b!  h# 3c1 s3b@  s3-reset-attr-addr
;
: s3-grf!   ( b index -- )  h# 3ce s3b!  h# 3cf s3b!  ;
: s3-grf@   ( index -- b )  h# 3ce s3b!  h# 3cf s3b@  ;

: feature-ctl!  ( b -- )  h# 3da s3b!  ;

\ Misc output register bits:

\ 01: color/monochrome (00 - monochrome emulation, 01 - color)
\ 02: enable CPU access to video memory (0 - disable, 2 - enable)
\ 0c: clock source (00 - 25 MHz, 04 - 28 MHz, 08 - ?, 0c - extended)
\ 10: disable video drivers (00 - enable, 10 - disable)
\ 20: page for odd/even graphics modes(0,1,2,3,7) (00 - low page, 20 - high)
\ 40: horizontal sync polarity (00 - positive, 40 - negative)
\ 80: vertical sync polarity (00 - positive, 80 - negative)
\ Multi-sync monitors use the sync polarity to determine the display size:
\     00 - reserved, 40 - 400 lines, 80 - 350 lines, c0 - 480 lines

: s3-misc@  ( -- b )  h# 3cc s3b@  ;
: s3-misc!  ( b -- )  h# 3c2 s3b!  ;

: s3-crt-setup  ( index -- data-adr )  h# 3d4 s3b!  h# 3d5  ;
: s3-crt!  ( b index -- )  s3-crt-setup s3b!  ;
: s3-crt@  ( index -- b )  s3-crt-setup s3b@  ;
: s3-crt-data!  ( b -- )  h# 3d5 s3b!  ;
: s3-crt-set   ( bits index -- )  s3-crt@  or  s3-crt-data!  ;
: s3-crt-clear ( bits index -- )  s3-crt@  swap invert and  s3-crt-data!  ;

: s3-seq-setup  ( index -- data-adr )  h# 3c4 s3b!  h# 3c5  ;
: s3-seq!  ( b index -- )  s3-seq-setup s3b!  ;
: s3-seq@  ( index -- b )  s3-seq-setup s3b@  ;

: unlock  ( -- )		\ Unlock all registers

   48 38 s3-crt!  		\ Unlock S3 VGA regs
   a5 39 s3-crt!  		\ Unlock S3 sys ctl and sys ext regs
    1 40 s3-crt-set		\ Unlock S3 enhanced graphics regs
   80 11 s3-crt-clear		\ Unlock CRT regs
;

: cfg-w@  ( adr -- d )
   " config-w@" eval
;

: cfg-w!  ( adr -- d )
   " config-w!" eval
;

0 value me-handle

: bridge-on  ( -- )
   my-self to me-handle				\ Save current phandle
   my-parent to my-self				\ Switch into the parent node
   my-space h# 3e + dup		( adr adr )	\ Bridge control reg offset
   " config-w@" $call-parent	( adr data )
   8 or swap			( data' adr )	\ Set vga enable bit
   " config-w!" $call-parent	( )
   me-handle to my-self				\ Switch back to here
;

: bridge-off  ( -- )
   my-self to me-handle				\ Save current phandle
   my-parent to my-self				\ Switch into the parent node
   my-space h# 3e + dup		( adr adr )	\ Bridge control reg offset
   " config-w@" $call-parent	( adr data )
   8 invert and swap		( data' adr )	\ Set vga enable bit
   " config-w!" $call-parent	( )
   me-handle to my-self				\ Switch back to here
;
   
: jamit  ( -- )

   \ First we need to be sure VGA enable bit is set in the parent bridge
   bridge-on

   \ Now we hit the 3c3 register to wake this beast up
   temp-map-io					\ Map in VGA IO
   1 h# 3c3 itemp + rb!				\ Write the wakeup reg
   temp-unmap-io				\ Unmap the VGA IO

   \ Per STB request (3/21/97) They would like us to leave the VGA
   \ enable bit on in the bridge.
   \ Turn off vga bit in bridge
   \ bridge-off

;

: wakeup  ( -- )

   \ First we need to see if this thing is already awake. If not, then
   \ we do it the hard way...

   3cc io-base + cpeek  if  
      ff =  
   else  
      true  
   then  

   if  jamit  then	\ If card is not responding, go hit the 3c3 register

   67 s3-misc!
   
   unlock

\   8000 subsys-ctl!	\ Writes to this reg at this time cause config regs
			\ to disappear!
\ The following also now breaks the driver!
\   4000 subsys-ctl!	\ Pulse graphics engine reset
;

: low-power  ( -- )
   ff  4 s3-crt!			\ disable hsync for low monitor power
   10 5d s3-crt-set
   20 56 s3-crt-set			\ tri-state hsync
;

\ Support words for kickstart-pll

: clksyn!  ( data -- )  h# 14 s3-seq!  ;	\ clock synthesizer control

: running?  ( which -- flag )	\ which = c to test MCLK, 4 to test DCLK
   dup h# 10 or  clksyn!             ( regval )	\ Reset xCLK counter
   clksyn!                           ( )	\ Enable xCLK counter
   h# 17 s3-seq@  h# 17 s3-seq@  <>  ( flag )	\ Is it counting?
   0 clksyn!					\ Default value for clk synth.
;

\ kickstart-pll is necessary for the TrioV, because of a chip bug.
\ Start the MCLK and DCLK clock synthesizer PLLs by powering them off then on.
\ It may take several tries to get the clocks running; we start with a
\ 2 ms. power off interval and a 2 ms. delay from power on to clock test,
\ increasing both intervals by 1 ms. until we succeed or give up.

: kickstart-pll  ( -- )
   6 8 s3-seq!				\ Must unlock the extended seq regs
   d# 100 2  do				\ Increase time delay each time
      3 clksyn!  i ms  0 clksyn!  i ms	\ Turn MCLK&DCLK PLL power off then on

      h# c running?  if			\ Is MCLK running?
         4 running?  if			\ Is DCLK running?
            unloop exit 		\ Success if both are running
         then
      then
   loop
   true " The PLL refused to start" type abort
;

\ Standard VGA CRT Controller registers, indices 0-h#18
: crt-table  ( -- adr len )  \ 72 Hz

   " "(5f 4f 50 82 51 80 0b 3e 00 40 00 00 00 00 ff 00 e2 0c df 50 60 e7 04 ab ff)"

;

: crt-regs  ( -- )
   \ Don't program hsync (at offset 4) until later
   crt-table  0  ?do  i 4 <>  if  dup i + c@  i  s3-crt!  then  loop  drop
;

: ecrt-addrs  ( -- adr len )  \ Ecrt indices
   " "(42 3b 3c 31 3a 40 50 54 5d 60 61 62 58 33 43 13 5e 51 5c 34 55)"
;

: ecrt-table  ( -- adr len )  \ Ecrt values
   " "(0b 5e 40 89 15 01 40 00 00 0f 80 a1 12 00 00 50 00 00 00 00 00)"
;

: ecrt-regs  ( -- )
   ecrt-table  0  do  dup i + c@  ecrt-addrs drop i + c@  s3-crt!  loop  drop
;

\ Ext registers, index/value index/value ...
: init-ext-regs-table  ( -- adr len )
   " "(3185 5000 5100 5308 5438 5813 5c00 5d00 5e00 6007 6180 62a1 3200 3300 3400 3500 3a05 3b5a 3c10 4009 4300 4500 4600 4700 4800 4900 4a00 4b00 4c07 4dfe 4e00 4f00 5500 6300 6400 6500 6a00)"
;

: ext-regs  ( -- )
   init-ext-regs-table  bounds ?do  i 1+ c@  i c@  s3-crt!  2 +loop
;

: attr-table  ( -- adr len )	\ Attribute controller indices 0-14

   " "(00 01 02 03 04 05 06 07 10 11 12 13 14 15 16 17 41 00 0f 00 00)"
;

: attr-regs  ( -- )
   s3-reset-attr-addr
   attr-table swap 10 + swap 10 - 0  do  dup i + c@ i 10 + s3-attr! loop drop
;

: grf-table  ( -- adr len )	\ Graphics controller indices 0-8
   " "(00 00 00 00 00 40 05 0f ff)"
;

: grf-regs  ( -- )
   grf-table  0  do  dup i + c@  i s3-grf!   loop  drop
;

: seq-table  ( -- adr len )  
   " "(01 0f 00 0e)"
;

: seq-regs  ( -- )
   seq-table  0  ?do  dup i + c@  i 1+ s3-seq!  loop  drop

   6   8 s3-seq!		\ Unlock trio64 extended sequence registers
   0   9 s3-seq!		\ now write all of them that there be except 17
   0   b s3-seq!		\ which is read only.
   0   d s3-seq!
   42 10 s3-seq!

   2f s3-crt@ 10 = if	\ Y versions of TRIO-64 have 10 in cr2F
      42 1a s3-seq!		\ S3 bug A-17 requires this for Y parts only
   then			\ Requirement being that 1a is set = to 10
 
   3e 11 s3-seq!
   49 12 s3-seq!
   55 13 s3-seq!
   0  14 s3-seq!
   3  15 s3-seq!
   75 16 s3-seq!
   40 18 s3-seq!

   s3-trio64?  if
      80  a s3-seq!		\ Trio likes this
   else
      c0  a s3-seq!		\ ViRGE likes this
   then

   3 0 s3-seq!			\ Start sequencer
;

\ DAC definitions. This is where the DAC access methods get plugged for this
\ specific controller
\

0 value dactype
1 constant BT
2 constant TI

: s3-rmr@  ( -- b )  h# 3c6 s3b@ ;
: s3-rmr!  ( b -- )  h# 3c6 s3b! ;
: s3-plt@  ( -- b )  h# 3c9 s3b@ ;
: s3-plt!  ( b -- )  h# 3c9 s3b! ;
: s3-rindex!  ( index -- )  h# 3c7 s3b! ;
: s3-windex!  ( index -- )  h# 3c8 s3b! ;

: 7i-a  ( b -- b )
   7 invert and
;

: s3-rs@  ( adr -- b )
			( RSadr )
   dup 2 rshift		( RSadr RS-high )	\ Copy it, shift out 2 low bits
   55 s3-crt@		( RSadr RS-high CR55 )	\ Get Current CR55
   7i-a or		( RSadr 55-reg )	\ Put 2 high bits in CR55[1:0]
   55 s3-crt!		( RSadr )		\ Put CR55 back
   3 and		( RSadr )		\ Now mask out high bits
   case						\ Now read data 
      0 of
         h# 3c8 s3b@
      endof
      1 of
         h# 3c9 s3b@
      endof
      2 of
         h# 3c6 s3b@
      endof
      3 of
         h# 3c7 s3b@
      endof
   endcase
   55 s3-crt@ 3 invert and 55 s3-crt!		\ Reset CR55 RS[3:2]
;

: s3-rs!  ( b adr -- )
			( b RSadr )
   dup 2 rshift		( b RSadr RS-high )	\ Copy it, shift out 2 low bits
   55 s3-crt@		( b RSadr RS-high CR55 ) \ Get current CR55
   7i-a or		( b RSadr 55-reg )	\ Put 2 high bits in CR55[1:0]
   55 s3-crt!		( b RSadr )		\ Put CR55 back
   3 and		( b RSadr )		\ Now mask out high bits
   case						\ Now write data 
      0 of
         h# 3c8 s3b!
      endof
      1 of
         h# 3c9 s3b!
      endof
      2 of
         h# 3c6 s3b!
      endof
      3 of
         h# 3c7 s3b!
      endof
   endcase
   55 s3-crt@ 3 invert and 55 s3-crt!			\ Reset CR55 RS[3:2]
;

: s3-idac@  ( index -- b )
   dac-index-adr	( index adr )
   s3-rs!		( )
   dac-data-adr		( adr )
   s3-rs@		( b )
;

: s3-idac!  ( index -- b )
   dac-index-adr	( index adr )
   s3-rs!		( )
   dac-data-adr	( adr )
   s3-rs!		( b )
;

: use-s3-dac-methods  ( -- )	\ Assigns S3 version of DAC access words
   ['] s3-rmr@ to rmr@
   ['] s3-rmr! to rmr!
   ['] s3-plt@ to plt@
   ['] s3-plt! to plt!
   ['] s3-rindex! to rindex!
   ['] s3-windex! to windex!
   ['] s3-rs@ to rs@
   ['] s3-rs! to rs!
   ['] s3-idac@ to idac@
   ['] s3-idac! to idac!
;

: setup-middle  ( -- )
   vga-reset

   unlock
   ext-regs
   9f 36 s3-crt!		\ Init strapping options

   s3-trio64?  if		\ Apparently Trio chips don't always startup
      kickstart-pll		\ correctly...
   then

   seq-regs
   attr-regs
   grf-regs

   e 4 s3-seq!	\ memory mode
   
   crt-regs

   ecrt-regs

   s3-trio64?  if
      7  22 s3-crt!
      a0 24 s3-crt!
   then

   4 feature-ctl!		\ Vertical sync ctl
;

: size-memory  ( -- )
   \ XXX should auto-size and create a property
   \ Set for 1 MByte
   \   36 crt@  1f and  3 6 << or  crt-data!
   \   58 crt@  3 invert and  1 or  crt-data!
   9f 36 s3-crt!
   12 58 s3-crt!
;

: hsync-on  ( -- )
   crt-table drop 4 + c@ 4 s3-crt!		\ Set hsync position
   20 56 s3-crt-clear			\ Un-tri-state hsync
;

: setup-end  ( -- )
   size-memory
   hsync-on

;

: s3-video-on  ( -- )
   hsync-on
   20 s3-video-mode!
;

: setup-begin  ( -- )
   wakeup
;

: init-s3-controller  ( -- )	\ This gets plugged into "init-controller"
   setup-begin
   setup-middle
   setup-end
;

: reinit-s3-controller  ( -- )	\ This gets plugged into "reinit-controller"
;

: use-s3-words  ( -- )			\ Turns on the S3 specific words
   ['] map-s3-io-regs to map-io-regs
   ['] unmap-s3-io-regs to unmap-io-regs
   ['] map-s3-frame-buffer to map-frame-buffer
   ['] unmap-s3-frame-buffer to unmap-frame-buffer
   ['] init-s3-controller to init-controller
   ['] reinit-s3-controller to reinit-controller
   ['] s3-video-on to video-on
   use-s3-dac-methods
;

: probe-dac  ( -- )		\ Chained probing word...sets the dac type

   s3? 0=  if
      probe-dac				\ Try someone else's probe
   else
      s3-trio64?  if  use-trio-dac exit  then
   then
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
