\ See license at end of file
purpose: Initialize S3 Controllers

\ This file contains the S3 Controller specific code. As it turns out, 
\ these same methods work for Cirrus as well.

hex
headerless
/n /l - 8 * constant bitshift
: l->n   ( l -- n )
   bitshift  if
      bitshift lshift   bitshift >>a
   then
;

2 instance value s3-ver
: .driver-info  ( -- )
   .driver-info
   s3-ver . ." S3 Code Version" cr
;

\ Access functions for various register banks

: subsys-ctl!  ( w -- )  42e8 pw!  ;
: adv-func!    ( w -- )  4ae8 pw!  ;
: adv-func@    ( -- b )  4ae8 pw@  ;
: setup-vse!   ( b -- )  46e8 pc!  ;

: s3-unlock  ( -- )		\ Unlock all registers
   48 38 crt!  			\ Unlock S3 VGA regs
   a5 39 crt!	  		\ Unlock S3 sys ctl and sys ext regs
    1 40 crt-set		\ Unlock S3 enhanced graphics regs

   s3-968?  if
      6 8 seq!			\ Unlock the 968 extended sequence registers
   then

   unlock-crt-regs
;

: wakeup  ( -- )
   10  setup-vse!		\ Video system enable, in setup mode
   vga-wakeup
   08  setup-vse!		\ Out of setup mode

   0  adv-func!		\ Disable graphics engine

   \ Problem: none of the above will have worked if this is a "Z" version
   \ of the Trio-64. "Z" versions are those parts marked with an "X" after
   \ their part number. Hey, I didn't make this up, S3 did. Anyhow, if you
   \ have one of these beasties, you have to wake up the part differently.
   \ The catch is, you pretty much have to do this in the blind because
   \ until the chip is working, you can't tell which version it is for if
   \ you go poking at a chip that is not awake yet, you may hang the system.

   s3-trio64? s3-virge? or  if
      4 c-l@ 2 or 4 c-l!
      3cc io-base + cpeek  if  ff =  else  true  then  if  1 3c3 pc!  then
   then

   \ As it turns out, the Trio-64V+ (which at this point in the probe process
   \ is indistinguishable from all of the other versions of the Trio-64, also
   \ won't have initialized prior to the above command. So, that extra command
   \ is usefull for both the "Z" Trio-64 and the Trio-64V+ (also known as the
   \ '765 [all other Trios have a '764 part number]). Oh but wait, there is 
   \ more. The 765 does not respond to IO accesses unless the memory access 
   \ enable bit is also turned on. Which is why the above now includes this 
   \ "feature".

   \ And now back to our regularly scheduled programming...

   67 misc!
   
   s3-unlock

   8000 subsys-ctl!
   4000 subsys-ctl!			\ Pulse graphics engine reset
;

\ : low-power  ( -- )
\    ff  4 crt!				\ disable hsync for low monitor power
\    10 5d crt-set
\    20 56 crt-set			\ tri-state hsync
\ ;

\ Support words for kickstart-pll

: clksyn!  ( data -- )  h# 14 seq!  ;	\ clock synthesizer control

: running?  ( which -- flag )	\ which = c to test MCLK, 4 to test DCLK
   dup h# 10 or  clksyn!             ( regval )	\ Reset xCLK counter
   clksyn!                           ( )	\ Enable xCLK counter
   h# 17 seq@  h# 17 seq@  <>  ( flag )	\ Is it counting?
   0 clksyn!					\ Default value for clk synth.
;

: stopped?  ( which -- flag )
   h# 7 or clksyn!		( reg val )	\ Stop both clocks, enable cntr
   h# 17 seq@ h# 17 seq@	( cnt1 cnt2 )	\ Read twice
   =				( flag )	\ Is it stopped
;

\ kickstart-pll is necessary for the TrioV, because of a chip bug.
\ Start the MCLK and DCLK clock synthesizer PLLs by powering them off then on.
\ It may take several tries to get the clocks running; we start with a
\ 2 ms. power off interval and a 2 ms. delay from power on to clock test,
\ increasing both intervals by 1 ms. until we succeed or give up.

: kickstart-pll  ( -- )
   6 8 seq!				\ Must unlock the extended seq regs
   d# 100 d# 10  do			\ Increase time delay each time
      3 clksyn!				\ Stop the PLLs
      begin				\ Wait until they stop
         h# 8 stopped?	( flag1 )	\ Mclk
         h# 0 stopped?	( flag1 flag2 )	\ Dclk
         and		( flag )
      until		( )

      i ms  0 clksyn!  i ms		\ Turn MCLK&DCLK PLL power on

      h# c running?  if			\ Is MCLK running?
         4 running?  if			\ Is DCLK running?
            unloop exit 		\ Success if both are running
         then
      then
   loop
   true " The PLL refused to start" type abort
;

\ Standard VGA CRT Controller registers, indices 0-h#18
: s3-crt-table  ( -- adr len )  \ 72 Hz
   " "(5f 4f 50 82 51 80 0b 3e 00 40 00 00 00 00 ff 00 e2 0c df 50 60 e7 04 ab ff)"
;

: ecrt-regs  ( -- )
   \ The first line is the indices, the second is the data
   " "(42 3b 3c 31 3a 40 50 54 5d 60 61 62 58 33 43 13 5e 51 5c 34 55)" drop
   " "(0b 5e 40 89 15 01 40 00 00 0f 80 a1 12 00 00 50 00 00 00 00 00)"

                                        ( index-adr data-adr len )
   0  do                                ( index-adr data-adr )
      2dup i + c@  swap i + c@  crt!    ( index-adr data-adr )
   loop  2drop                          ( )
;

\ Ext registers, index/value index/value ...
: init-ext-regs-table  ( -- adr len )
   " "(3185 5000 5100 5300 5438 5813 5c00 5d00 5e00 6007 6180 62a1 3200 3300 3400 3500 3a05 3b5a 3c10 4009 4300 4500 4600 4700 4800 4900 4a00 4b00 4c07 4dfe 4e00 4f00 5500 6300 6400 6500 6a00)"
;

: ext-regs  ( -- )
   init-ext-regs-table  bounds ?do  i 1+ c@  i c@  crt!  2 +loop
;

: s3-ext-seq  ( -- )
   s3-trio64? s3-virge? or  if
      6   8 seq!		\ Unlock trio64 extended sequence registers
      0   9 seq!		\ now write all of them that there be except 17
      0   b seq!		\ which is read only.
      0   d seq!
      42 10 seq!

      2f crt@ 10 =  if		\ Y versions of TRIO-64 have 10 in cr2F
         42 1a seq!		\ S3 bug A-17 requires this for Y parts only
      then			\ Requirement being that 1a is set = to 10
 
      3e 11 seq!
      49 12 seq!
      55 13 seq!
      0  14 seq!
      3  15 seq!
      75 16 seq!
      40 18 seq!

      s3-trio64?  if  80  ( Trio )  else  c0  ( Virge )  then  a seq!    

   then
;

\ DAC definitions. This is where the DAC access methods get plugged for this
\ specific controller

0 value dactype
1 constant BT
2 constant TI


: s3-rs-setup  ( adr -- port )
   dup 2 rshift		( RSadr RS-high )	\ Copy it, shift out 2 low bits
   55 crt@		( RSadr RS-high CR55 )	\ Get Current CR55
   7 invert and  or	( RSadr 55-reg )	\ Put 2 high bits in CR55[1:0]
   55 crt!		( RSadr )		\ Put CR55 back
   3 and		( RSadr )		\ Now mask out high bits
   case						\ Now read data 
      0 of  03c8  endof
      1 of  03c9  endof
      2 of  03c6  endof
      3 of  03c7  endof
   endcase
;
: s3-rs-done  ( -- )  55 crt@ 3 invert and 55 crt!  ;  \ Reset CR55 RS[3:2]
: s3-rs@  ( adr -- b )  s3-rs-setup pc@  s3-rs-done  ;
: s3-rs!  ( b adr -- )  s3-rs-setup pc!  s3-rs-done  ;

: s3-idac-setup  ( index -- adr )  dac-index-adr s3-rs!	 dac-data-adr  ;
: s3-idac@  ( index -- b )  s3-idac-setup  s3-rs@  ;
: s3-idac!  ( b index -- )  s3-idac-setup  s3-rs!  ;

: use-s3-dac-methods  ( -- )	\ Assigns S3 version of DAC access words
   use-vga-dac
   ['] s3-rs@   to rs@
   ['] s3-rs!   to rs!
   ['] s3-idac@ to idac@
   ['] s3-idac! to idac!
;

: setup-middle  ( -- )
\   low-power
   vga-reset

   s3-unlock
   ext-regs
   9f 36 crt!			\ Init strapping options

   \ Apparently Trio chips don't always startup correctly...
   s3-trio64?  if  kickstart-pll  then

   seq-regs  s3-ext-seq  start-seq

   high-attr-regs  pixel-clock/2

   grf-regs graphics-memory crt-regs

   ecrt-regs

   s3-trio64?  if
      h# c running? 0=  if  kickstart-pll  then
   then

   s3-928? 0=  if	\ Only check S3 chips that are NOT the 928
      ff 37 crt!		\ Some boards like dual WE, others Dual CAS
      map-frame-buffer		\ We assume one, test the frame buffer to see
      -1 frame-buffer-adr l! d# 100 ms	  \ if it behaves properly. If not, 
      frame-buffer-adr l@ l->n -1 <>  if  \ we switch to other mode.
         f7 37 crt!
      then
      unmap-frame-buffer
   then

   s3-trio64? s3-virge? or  if
      7  22 crt!
      a0 24 crt!
   then

   4 feature-ctl!		\ Vertical sync ctl
;

: size-memory  ( -- )
   \ XXX should auto-size and create a property
   \ Set for 1 MByte
   \   36 crt@  1f and  3 6 << or  crt-data!
   \   58 crt@  3 invert and  1 or  crt-data!
   9f 36 crt!
   12 58 crt!
;

: drive-hsync  ( -- )  20 56 crt-clear  ;	\ Un-tri-state hsync

: init-s3-controller  ( -- )	\ This gets plugged into "init-controller"
   wakeup
   setup-middle
   size-memory
   hsync-on  drive-hsync
;

: reinit-s3-controller  ( -- )	\ This gets plugged into "reinit-controller"
   number9? invert s3-864? and if \ Diamond vs Number9 differences again....
      2 42 crt!		\ tweek extened reg for diamond 864 based board
      c 68 crt!		\ set Memory address depth to 512kx512k
   then

   s3-964? if			\ Diamond powers up in wrong mode, Orchid is OK
      dactype BT =  if		\ These two boards both use Brooktree DAC
         ff 68 crt!		\ Number9 has a 964 board too, with TI DAC and
      then			\ this reg powers up correctly (to a different
   then				\  value) on its own.
;

: use-s3-words  ( -- )			\ Turns on the S3 specific words
   ['] s3-crt-table             to crt-table
   ['] init-s3-controller       to init-controller
   ['] reinit-s3-controller     to reinit-controller
   use-s3-dac-methods
;

: probe-dac  ( -- )		\ Chained probing word...sets the dac type

   s3? 0=  if
      probe-dac				\ Try someone else's probe
   else
      s3-928?  if
         \ Some 928 boards (IBM) actually have a Brooktree in them. However,
         \ the att init sequence works OK so for now, not going to mess
         \  with it.
         use-att-dac
         exit
      then
   
      s3-868?  if  use-att-dac exit  then
      s3-trio64?  if  use-trio-dac exit  then
      s3-virge?  if  use-virge-dac exit  then

      s3-968?  if	\ We have to decide which dac to use if this is true

         \ Problem: Number-9 771 board uses an IBM DAC. Diamond uses both IBM
         \ and TI DACs. Diamond and Number-9 configure the 968 differently.
         \ Lets see if we can tell which is which...
         \
         \ Going to assume its a TI dac for now and see if we can find
         \ the ID register. It sould read back as 0x26 if its there.
         \ If we get something else, then we will go with IBM dac

         use-tvp3026-dac	\ Diamond uses 3026 or IBM
         3f idac@ 26 <>  if
            use-ibm-dac		\ Did not get what we want, so it could be IBM
               1 idac@ 2 <> if	\ 2 is what 524 DACs report (#9 uses the 524)
                  use-brooktree-dac	\ Last chance...Fahrenheit ProVideo64
               then
            then
         exit
      then
   
      s3-864?  if		\ We have a similar issue with the 864 boards

         \ We need to decide which DAC routine to use for 864 designs
         \ The Stealth 64 DRAM uses an S3 DAC while the number9 GXE uses
         \ an AT&T DAC
         \
   
         \ The idea here is to assume an S3 RAMDAC then prove it by reading
         \ the pixel mask register 4 times. The fourth read will return
         \ 70 or 73 if it is indeed an S3 RAMDAC.
   
         use-s3-dac
         0 windex!
         ff rmr!
         rmr@ drop
         rmr@ drop
         rmr@ drop
         rmr@ >r
         r@ 70 = r@ 73 = or  if
            diamond to board
         else
            use-att-dac
            number9 to board
         then
         r> drop
         exit   
      then
   
      s3-964?  if		\ Now we have to sort out these variants...

         \ We need to decide which DAC routine to use for 964 designs
         \ The GXE uses a TI DAC while the Paradise & Stealth 64 use
         \ Brooktree

         TI to dactype   
         use-tvp3025-dac
         3f idac@ 25 <>  if
            use-brooktree-dac	\ Did not get what we wanted, use Brooktree.
            BT to dactype
         then
         exit
      then
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
