\ See license at end of file
purpose: Initialize Cyrix MediaGX video Controller

hex
headers

2 value bytes/pixel

d# 1024 value /scanline		\ Frame buffer line width
d# 1024 value /displine		\ Displayed line width
d#  768 value #scanlines	\ Screen height

: declare-props  ( -- )		\ Instantiate screen properties
   " width" get-my-property  if  
      /displine bytes/pixel /  encode-int " width"     property
      #scanlines               encode-int " height"    property
      bytes/pixel 8 *          encode-int " depth"     property
      /scanline                encode-int " linebytes" property
   else
      2drop
   then
;

: /fb  ( -- )  /scanline #scanlines * bytes/pixel *  ;	\ Size of framebuffer

0 instance value dc-base
0 instance value gp-base
0 instance value vp-base

: map-io-regs  ( -- )
   dc-base  if  exit  then
   (map-io-regs)  to vp-base  to dc-base  to gp-base
;

: dc!  ( value offset -- )  dc-base + rl!  ;
: dc@  ( offset -- value )  dc-base + rl@  ;
: vp!  ( value offset -- )  vp-base + rl!  ;
: vp@  ( offset -- value )  vp-base + rl@  ;

: iand  ( value mask -- )  invert and  ;

: map-frame-buffer  ( -- )
   (map-frame-buffer)  to frame-buffer-adr
   frame-buffer-adr encode-int " address" property
;

\ Access functions for various register banks

\ DAC definitions. This is where the DAC access methods get plugged for this
\ specific controller

\ Register dump.
: reg-dump  ( base #words -- )  bounds do  i u. i rl@ u. cr 4 +loop  ;

: unlock  ( -- ) 4758 0 dc!  ;
: lock    ( -- )  0 0 dc!  ;

: video-off ( -- )
   unlock  0000.0000 8 vp!  lock	\ disable syncs, etc
;
: video-on  ( -- )
   unlock
   0 h# 50 vp!          \ Power on for DACs, enable gamma correction 
   \ Supposed to be 1.030f but the scope says otherwise
   h# 0001.000f 8 vp!  \ SYNC_SKEW_DFL, -HSYNC, -VSYNC, enable DAC_BL,HS,VS,CRT
   lock
;

\ 1024x768-75 VESA
\  refr xres yres pixclk Lmar Rmar Tmar Bmar Hslen Vslen  SyncPol
\   75, 1024, 768, 12690, 176,  16,  28,   1,   96,    3, +h +v, noninterlaced
\ OPLC-1 DCON      
\   50, 1200, 900, 17460,  24,   8,   4,   5,    8,    3, +h +v, noninterlaced

create timing-1024x768
\   h#  52 , 0 ,             \ dotpll, rstpll, (refr=75, pixclk= d# 12690)
[ifdef] lx-devel
   \ The development board uses a 48 MHz refclk
   \ M=0  N=3  P=2  (N+1)/((M+1)*(P+1)) = 4/(1*3) = 4/3
   \ 48 MHz * 4 / 3 = 64 MHz
   \ We can't get much closer because the PLL doesn't seem to lock
   \ if the multiplier is much above 48 with DOTREF = 48 MHz
   h#  95e , 0 ,  h# 0032 ,  \ dotpll, rstpll, lxdotpll, (refr=60, pixclk= d# 15625)
[else]
   \ The OLPC board uses a 14.318 MHz refclk
   \ M=4  N=0x57=87  P=3  (N+1)/((M+1)*(P+1)) = 88/(5*4) = 58/20
   \ 14.318 MHz * 88 / 20 = 63 MHz
   h#  95e , 0 ,  h# 4573 ,  \ dotpll, rstpll, lxdotpll, (refr=60, pixclk= d# 15384)
[then]
   d# 1024 , d# 1024 ,   \ linelen, graphics pitch
   h# 051f.03ff , h# 051f.03ff , h# 046f.040f , ( h# 046f.040f , ) \ htiming 1,2,3,fp
   h# 031f.02ff , h# 031f.02ff , h# 0309.0300 , ( h# 03b1.03ae , ) \ vtiming 1,2,3,fp

\ dotclk = htotal * hfreq    or hfreq = dotclk / htotal
\ htotal = 1240, vtotal = 912
\ vfreq = hfreq / vtotal
\ sync width = 8
\ 1200 active, 8 border , 8 sync , 24 border
\ 57b  101.0111.1011  - table says 56.6444
\ b7b is good for 28.3220
\    MMMMn.nnnn.nnPP
\ M = 0010 = 2
\ N = 10111 = d# 25
\ p = 11 = 3
\ (N+1)/(M+1)*2^p
\ 1 is to

create timing-dcon
[ifdef] lx-devel
   \ The development board uses a 48 MHz refclk
   \ M=2  N=0x1f=31  P=8  (N+1)/((M+1)*(P+1)) = 32/(3*9) = 32/27
   \ 48 MHz * 32 / 27 = 56.9 MHz
   h# 57b , 0 ,  h# 21f8 , \ dotpll, rstpll, lxdotpll, (refr=50, pixclk=d# 17460)
[else]
   \ The OLPC board uses a 14.318 MHz refclk
   \ M=2  N=0x5e=94  P=7  (N+1)/((M+1)*(P+1)) = 95/(3*8) = 95/24
   \ 14.318 MHz * 94 / 24 = 56.7 MHz
   h# 57b , 0 ,  h# 25e7 , \ dotpll, rstpll, lxdotpll, (refr=50, pixclk=d# 17460)
[then]
   d# 1200 , d# 1200 ,     \ linelen, graphics pitch
   h# 04d7.04af , h# 04d7.04af , h# 04bf.04b7 , ( h# 04bf.04b7 , )  \ htiming 1,2,3,fp
   h# 038f.0383 , h# 038f.0383 , h# 038b.0388 , ( h# 038a.0387 , )  \ vtiming 1,2,3,fp 

[ifdef] notdef
ok 60 30 do i 10 bounds do i dc@ 9 u.r 4 +loop cr 10 +loop
      12e      12c effa9fa4 5de57bff
  4d704af  4d704af  4bf04b7 5feffba9
  38f0383  38f0383  38b0388 dfffffdf
[then]


true value dcon?

: timing  ( -- adr )
   dcon?  if  timing-dcon  else  timing-1024x768  then
;
: @+  ( adr -- adr' value )  dup la1+ swap @  ;

: set-timing  ( -- )
   timing  3 na+  ( adr )
   @+ bytes/pixel *  3 rshift       h# 34 dc!  \ Graphics pitch  ( adr )
   @+ bytes/pixel *  3 rshift  2 +  h# 30 dc!  \ Line size       ( adr )

   @+ h# 40 dc!   \ H_ACTIVE
   @+ h# 44 dc!   \ H_BLANK
   @+ h# 48 dc!   \ H_SYNC

   @+ h# 50 dc!   \ V_ACTIVE
   @+ h# 54 dc!   \ V_BLANK
   @+ h# 58 dc!   \ V_SYNC

   ( adr ) drop
;

h# 4c00.0014 constant rstpll
h# 4c00.0015 constant dotpll

: set-dclk  ( -- )
[ifdef] use-lx
   dotpll msr@  drop             ( dotpll.low )
   1 or  h# c000 invert and      ( dotpll.low' )  \ DOTRESET on, PD and BYPASS off
   timing 2 na+ @                ( d.dotpll )
   dotpll msr!                   ( )

   \ Wait for lock bit
   d# 1000 0  do 
      dotpll msr@  drop  h# 2000000  and  ?leave
   loop

   dotpll msr@                   ( d.dotpll )
   swap  1 invert and  swap      ( d.dotpll' )    \ Release reset bit
   dotpll msr!                   ( )
[else]
   dotpll msr@  drop             ( dotpll.low )
\ DCON  0200.0000 57b
   1 or  h# c000 invert and      ( dotpll.low' )  \ DOTRESET on, PD and BYPASS off
   timing @                      ( d.dotpll )
\ DCON this value is good if dcon? is set correctly
   dotpll msr!                   ( )

   rstpll msr@                   ( d.rstpll )
\ DCON  06de.0170 209
   swap  h# e invert and  timing na1+ @ or   swap  ( d.rstpll )
\ DCON this value is good if dcon? is set correctly
   rstpll msr!                   ( )

   dotpll msr@                   ( d.dotpll )
   swap  1 invert and  swap      ( d.dotpll' )    \ Clear reset bit
   dotpll msr!                   ( )              \ thus starting PLL

   \ Wait for lock bit
   d# 1000 0  do 
      dotpll msr@  drop  h# 2000000  and  ?leave
   loop
[then]
;

[ifndef] dcon-init
false to dcon?
false constant atest?
\ : tft-mode?  ( -- flag )  h# c000.2001 msr@  drop h# 40 and  0<>  ;
false constant tft-mode?
[then]

\ This compensates for a PCB miswiring between the GX and the DCON
: set-gamma  ( -- )
   0 h# 38 vp!

   dcon?  atest? 0=  and                    ( shift? )
   h# 100 0  do
     \   blue       green        red
     dup  if                                ( s? )
        i 2 rshift  i 1 rshift  i 2 rshift  ( s? b g r )
     else                                   ( s? )
        i i i                               ( s? b g r )
     then                                   ( s? b g r )
     0  bljoin  h# 40 vp!                   ( s? )
   loop                                     ( s? )
   drop
   0 h# 50 vp!              \ DACs powered on, gamma enabled
;

: configure-display  ( -- )
   set-gamma
   8 vp@  6 iand  8 vp!  \ Disable h and v syncs - Try 0 8 vp!

   \ According to data sheet, this should be 1030f, but according
   \ to the scope, 1000f gives active low syncs.
   h# 1000f 8 vp!        \ Active low syncs.
   \ DCON value 1030f  300 is sync's active high
;

h# c0002001 constant gld_msr_config
: configure-vga  ( -- )
   gld_msr_config msr@  swap 8 invert and swap  gld_msr_config msr!
;

d# 900 value yres
true value vsync-low?
true value hsync-low?
: configure-tft  ( -- )
   gld_msr_config msr@  swap 8 or swap  gld_msr_config msr!

   \ Set up the DF pad select MSR
   \ (reserved register in spec, but the Linux driver does this)
   \ Jordan Crouse says that this number was dialed in through validation
   h# c0002011 msr@
   swap  h# 3fff.ffff invert and  h# 1fff.ffff or  swap
   h# c0002011 msr!

   \ Panel off  - FP_PM register, GX_FP_PM_P bit
   h# 410 vp@  h# 100.0000 invert and  h# 410 vp!

   \ Set timing 1  FP_PT1
   h# 400 vp@  h# 7ff0000 and  yres d# 16 lshift or  h# 400 vp!

   \ Timing 2  Set bits that are always on for TFT
   h# f10.0000
   vsync-low?  if  h# 80.0000 or  then  \ Add vsync polarity
   hsync-low?  if  h# 40.0000 or  then  \ Add hsync polarity
   h# 408 vp!

   h# 70 h# 418 vp!  \  Set the dither control GX_FP_DFC

   \ Enable the FP data and power - 40 is FP_PWR_EN, 80 is FP_DATA_EN
   \ but these are reserved in the Geode datasheet.
   \ Jordan Crouse says that they are necessary for ordinary TFT
   \ panels, but probably irrelevant for OLPC with its outboard DCON.
   8 vp@  h# c0 or  8 vp!

   \ Unblank the panel
   h# 410 vp@  h# 100.0000 or  h# 410 vp!
;

: set-mode  ( -- )
   8 dc@  1 iand  8 dc!  \ Disable timing generator

   1 ms       \ Wait for pending memory requests

   4 dc@  h# e1 iand  4 dc!  \ Disable VGA, compression, and FIFO load

   set-dclk        \ Setup DCLK and its divisor

   0 h# 10 dc!     \ Clear frame buffer offset
   0 h# 14 dc!     \ Clear compression buffer offset
   0 h# 18 dc!     \ Clear cursor buffer offset
   0 h# 1c dc!     \ Clear icon buffer offset

   set-timing

   \ Turn on timing generator
   \ TGEN, GDEN, VDEN, PALB, A20M, A18M, (8BPP=0  16BPP=100)
   \ The "c" part (A20M, A18M) is unnecessary for LX, but harmless
   \ The "2" part (PALB) is unnecessary for GX, but harmless
   h# c200.0019  bytes/pixel 2 =  if  h# 0100 or  then  8 dc!

   \ Turn on FIFO
   4 dc@  h# 180000 invert and  h# 6501 or  4 dc!
   configure-display
   tft-mode?  if  configure-tft  else  configure-vga  then
;

: display-on  ( -- )
   unlock
   8 dc@  1 or  8 dc!      \ Enable timing generator
   4 dc@  1 or  4 dc!      \ Enable FIFO
   lock
;

: display-off  ( -- )
    unlock
    4 dc@  1 invert and  4 dc!  \ DC_GENERAL_CFG - disable FIFO load
    8 dc@  1 invert and  8 dc!  \ DC_DISPLAY_CFG - disable timing generator
    lock
;

h# 300 /n* buffer: video-state

: l!+  ( adr l -- adr' )  over l!  la1+  ;
: l@+  ( adr -- adr' l )  dup la1+  swap l@  ;

: video-save
   0 set-source  \ Freeze image
   video-state
   h# 10 dc@ l!+
   h# 14 dc@ l!+
   h# 18 dc@ l!+
   h# 1c dc@ l!+

   h# 20 dc@ l!+
   h# 24 dc@ l!+
   h# 28 dc@ l!+
   h# 30 dc@ l!+
   h# 34 dc@ l!+
   h# 38 dc@ l!+
   h# 40 dc@ l!+
   h# 44 dc@ l!+
   h# 48 dc@ l!+
   h# 50 dc@ l!+
   h# 54 dc@ l!+
   h# 58 dc@ l!+
   h# 60 dc@ l!+
   h# 64 dc@ l!+
   h# 68 dc@ l!+
   0 h# 70 dc!  h# 100 0 do  h# 74 dc@ l!+  loop
   h# 80 dc@ l!+
   h# 84 dc@ l!+
   h#  8 dc@ l!+
   h#  4 dc@ l!+

   h# 400 vp@ l!+
   h# 408 vp@ l!+
   h# 418 vp@ l!+
   h#   8 vp@ l!+
   0 h# 38 vp!  h# 100 0  do  h# 40 vp@  l!+  loop  \ Gamma
   h# 410 vp@ l!+

\   h# 3c 0  do  i gp@ l!+  4 +loop
\   h# 4c gp@ l!+

   drop
   \ video-state - /l / . cr

   unlock
   0 4 dc!  \ Turn off video memory access
;

: video-restore
   h# 4758 0 dc!  \ Unlock

   video-state
   l@+ h# 10 dc!
   l@+ h# 14 dc!
   l@+ h# 18 dc!
   l@+ h# 1c dc!

   l@+ h# 20 dc!
   l@+ h# 24 dc!
   l@+ h# 28 dc!
   l@+ h# 30 dc!
   l@+ h# 34 dc!
   l@+ h# 38 dc!
   l@+ h# 40 dc!
   l@+ h# 44 dc!
   l@+ h# 48 dc!
   l@+ h# 50 dc!
   l@+ h# 54 dc!
   l@+ h# 58 dc!
   l@+ h# 60 dc!
   l@+ h# 64 dc!
   l@+ h# 68 dc!
   0 h# 70 dc!  h# 100 0 do  l@+ h# 74 dc!  loop
   l@+ h# 80 dc!
   l@+ h# 84 dc!
   l@+ h#  8 dc!
   l@+ h#  4 dc!

   0 h# 50 vp!  \ Power on for DACs, enable gamma correction 
   l@+ h# 400 vp!
   l@+ h# 408 vp!
   l@+ h# 418 vp!
   l@+ h#   8 vp!
   0 h# 38 vp!  h# 100 0  do  l@+ h# 40 vp!  loop  \ Gamma
   l@+ h# 410 vp!

\   h# 3c 0  do  l@+ i gp!  4 +loop
\   l@+ h# 4c gp! 

   0 0 dc!  \ Lock
   drop
\   video-state - /l / . cr
   1 set-source  \ Unfreeze image
;


\ fload ${BP}/dev/mediagx/video/bitblt.fth

[ifdef] dcon-init

\ This is a horrible hack to get the DCON PLL started.
\ What is going on is that you have to start the video timing
\ generator assuming that the DCON is present, i.e. with 1200x900
\ timing parameters.  Then you try to turn on the DCON, and check
\ to see if you get a DCON interrupt at the right video scan line.
\ If not, you try again.  And again.  Eventually you give up.

\ Each iteration of the loop below takes 2.5 us (measured).
\ A frame is 1/50 sec, or 20 ms.  If we spin for 25 ms, we are
\ sure to see scanline 905.  So we use a little longer than 25 ms,
\ just to be safe.
d# 12,000  constant scanline-spins

: irq@905?  ( -- dcon? )
   lock[
   false
   scanline-spins 0 do
      h# 6e dc-base + w@ h# 7ff and d# 905 =  if
         gpio-data@  dconirq and  0<>       ( false dcon? )
         nip
         leave
      then
   loop
   ]unlock
;

: good-dcon?  ( -- flag )
   atest?  if    \ A-test boards don't need this PLL kick
      0 ['] dcon@ catch  if  drop  smb-init  false exit  then
      wbsplit nip  h# dc =    ( flag )
      exit  
   then

   dcon2?  if  true exit  then

   \ Scan line enable (100), color swizzling (20),
   \ blanking (10), pass thru disable (1)
   h# 131    1 ['] dcon! catch  if  2drop smb-init  false exit  then  \ Mode
   h#   0    9 ['] dcon! catch  if  2drop smb-init  false exit  then  \ Mode
   d# 19 0  do
      h# cc h# 4b ['] dcon! catch  if  2drop smb-init  then  \ PLL
   loop
   h# cc h# 4b ['] dcon! catch  if  2drop smb-init  false exit  then  \ PLL

   irq@905?                     ( flag )
;

: probe-dcon  ( -- )
   true to dcon?  set-mode
   dcon-init   \ GPIO stuff
   d# 50 0  do
      good-dcon?  if  dcon-enable  maybe-set-cmos  unloop exit  then
   loop
   
   0 dcon-flag cmos!
   false to dcon?
;
[else]
: probe-dcon  ( -- ) ;
: smb-init ;
: smb-off ;
[then]

: init-controller  ( -- )
\   " dcon-present?" evaluate to dcon?
   video-off
   unlock
   
   probe-dcon

   \ If we have decided that the DCON is not present, we have to
   \ change the mode back to VGA timing and resolution

   dcon? tft-mode? and  if
      d# 1200 bytes/pixel * to /displine
      d# 1200 bytes/pixel * to /scanline
      d# 900 to #scanlines
   else
      set-mode                \ Redo the mode for VGA

      d# 1024 bytes/pixel * to /displine
      d# 1024 bytes/pixel * to /scanline
      d#  768 to #scanlines
   then

   lock
;

: init-hook  ( -- )
   /displine " emu-bytes/line" eval - 2/ to window-left
;

external

: default-colors  ( -- adr index #indices )
   " "(00 00 00  00 00 aa  00 aa 00  00 aa aa  aa 00 00  aa 00 aa  aa 55 00  aa aa aa  55 55 55  55 55 ff  55 ff 55  55 ff ff  ff 55 55  ff 55 ff  ff ff 55  ff ff ff)"
   0 swap 3 /
;

: pindex!  ( index -- )  h# 70 dc!  ;
: plt!  ( color -- )  h# 74 dc!  ;
: plt@  ( color -- )  h# 74 dc@  ;
: rgb>color  ( r g b -- l )  swap rot 0 bljoin  ;
: color>rgb  ( l -- r g b )  lbsplit drop swap rot  ;
: color@  ( index -- r g b )  pindex! plt@  color>rgb  ;
: color!  ( r g b index -- )  >r  rgb>color  r> pindex! plt!  ;

: set-colors  ( adr index #indices -- )
   swap pindex!
   3 *  bounds  ?do
      i c@ i 1+ c@ i 2+ c@
      rgb>color plt!
   3 +loop
;

: get-colors  ( adr index #indices -- )
   swap pindex!
   3 *  bounds  ?do
      plt@ color>rgb
      i 2+ c! i 1+ c! i c!
   3 +loop
;

headers

: set-dac-colors  ( -- )	\ Sets the DAC colors
   default-colors		\ Pull up colors
   set-colors			\ Stuff LUT in DAC
   h# 0f color@  h# ff color!	\ Set color ff to white (same as 15)
;

: init  ( -- )			\ Initializes the controller
   smb-init
   map-io-regs			\ Enable IO registers
   init-controller		\ Setup the video controller
   declare-props		\ Setup properites
   set-dac-colors		\ Set up initial color map
   video-on			\ Turn on video

   map-frame-buffer
   bytes/pixel case
      1 of  frame-buffer-adr /fb h#        0f  fill  endof
      2 of  frame-buffer-adr /fb h#      ffff wfill  endof
      4 of  frame-buffer-adr /fb h# ffff.ffff lfill  endof
   endcase
;

: display-remove  ( -- )
   smb-off
;

" display"                      device-type
" ISO8859-1" encode-string    " character-set" property
0 0  encode-bytes  " iso6429-1983-colors"  property

: display-install  ( -- )
   init
   default-font set-font
   /scanline bytes/pixel /  #scanlines     ( width height )
   over char-width / over char-height /    ( width height rows cols )
   bytes/pixel  case                       ( width height rows cols )
      1 of  fb8-install   endof            ( )
      2 of  fb16-install  endof            ( )
   endcase                                 ( )
   init-hook
;

: display-selftest  ( -- failed? )  false  ;

' display-install  is-install
' display-remove   is-remove
' display-selftest is-selftest

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
