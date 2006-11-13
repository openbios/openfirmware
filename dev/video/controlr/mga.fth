\ See license at end of file
purpose: Initialize Matrox Controller

hex
headerless

\ Controller code for Matrox STORM chips

0 instance value mga-ver
: .driver-info  ( -- )
   .driver-info
   mga-ver . ." MGA Code Version" cr
;

: map-mga-io-regs  ( -- )
   \ h# 0100.0010 means relocatable I/O space
   0 0 my-space h# 0100.0010 +   h# 4000  map-in
   h# 1c00 + to io-base

   \ Enable memory space response
   4 c-w@ 2 or 4 c-w!
;

: unmap-mga-io-regs  ( -- )
   io-base h# 1c00 -  h# 4000 map-out
   -1 to io-base	\ Don't disable memory access because fb needs them
;

: map-mga-frame-buffer  ( -- )
   0 0 my-space h# 200.0014 + /fb map-in
   to frame-buffer-adr
;

: unmap-mga-frame-buffer  ( -- )
   frame-buffer-adr /fb map-out
   -1 to frame-buffer-adr
   4 c-w@ 2 invert and 4 c-w!		\ Now we can disable memory access
;

: mga-rmr@  ( -- b )  2002 pc@  ;
: mga-rmr!  ( b -- )  2002 pc!  ;
: mga-rindex!  ( index -- )  2003 pc!  ;
: mga-windex!  ( index -- )  2000 pc!  ;
: mga-plt!  ( b -- )  2001 pc!  ;
: mga-plt@  ( -- b )  2001 pc@  ;

: mga-idac-setup  ( index -- adr )
   dac-index-adr 2000 + pc!  dac-data-adr 2000 +
;
: mga-idac@  ( index -- b )  mga-idac-setup pc@  ;
: mga-idac!  ( b index -- )  mga-idac-setup pc!  ;

: use-mga-dac-methods  ( -- )	\ Assigns mga version of DAC access words
   ['] mga-rmr@ to rmr@
   ['] mga-rmr! to rmr!
   ['] mga-plt@ to plt@
   ['] mga-plt! to plt!
   ['] mga-rindex! to rindex!
   ['] mga-windex! to windex!
   ['] noop    to rs@
   ['] 2drop   to rs!
   ['] mga-idac@ to idac@
   ['] mga-idac! to idac!
;

\ Sets or clears bit in mask of crt reg adr
: mga-crt-bit-fix  ( mask addr flag -- )
   swap					( mask flag adr )
   >r r@				( mask flag adr )
   crt@				( mask flag crt )
   swap					( mask crt flag )
   if  or  else  swap invert and  then	( crt' )
   r> crt!				(  )
;

: mga-crtx-setup  ( index -- data-adr )  3de pc! 3df  ;
: mga-crtx!  ( b index -- )  mga-crtx-setup pc!  ;
: mga-crtx@  ( index -- b )  mga-crtx-setup pc@  ;

\ Sets or clears bit in mask of crt reg adr
: mga-crtx-bit-fix  ( mask addr flag -- )
   swap					( mask flag adr )
   >r r@				( mask flag adr )
   mga-crtx@				( mask flag crtx )
   swap					( mask crtx flag )
   if  or  else  swap invert and  then	( crtx' )
   r> mga-crtx!				(  )
;

: option@  ( -- l )  40 c-l@  ;		\ Read the option regiser
: option!  ( l -- )  40 c-l!  ;		\ Write the option register
: reset@  ( -- b )  240 pc@  ;		\ Read the reset register
: reset!  ( b -- )  240 pc!  ;		\ Write the reset register

0 value hr		\ horizontal resolution
0 value hbp		\ sync back-porch
0 value hfp		\ sync front-porch
0 value hsw		\ sync sync width
8 value clock-div	\ clock divisor

: mga-horizontal-program  ( hr hfp hsw hbp -- )
   clock-div / to hbp
   clock-div / to hsw 
   clock-div / to hfp
   clock-div / to hr

   \ First we derive horizontal total which is horiz resolution
   \ plus blank time plus the two borders
   hr hfp + hsw + hbp +		( h-total )
   5 -				( h-total )	\ Chip magic...
   dup ff and 0 crt!		( hi-bits )	\ Write low bits to crt 0
   100 and 0 <> 1 1 rot mga-crtx-bit-fix

   \ Now we go after the display end register
   hr 1 -					\ Chip magic
   dup 1 crt!
   ff >  if
      ." Error: Horizontal Display Value too big" cr
   then

   \ Now we do the blanking registers...
   hr 1 - 2 crt!				\ hblnkstr = hdisplend + 1

   hr hfp + hsw + hbp + 1 -			\ Blank end calculation 
   7f and					\ Mask off low bits
   dup 1f and 3 crt!			\ Write low bits to crt3
   dup 20 and 0 > 80 5 rot mga-crt-bit-fix	\ Write higher bit to crt 5
   40 and 0 > 40 1 rot mga-crtx-bit-fix		\ Write highest bit to crtx 1

   storm2?  if  50  else  28  then
   13 crt!

   \ Now the Sync registers...
   hr hfp + 
   dup ff and 4 crt!			\ Write low bits to crt 4
   100 and 0 <> 4 1 rot mga-crtx-bit-fix	\ High bit to crtx 1

   4 crt@ 1 crt@ - 2 <=  if  \ Sync strt must be > 2 more than disp end
      4 crt@ 1 + 4 crt!
   then

   4 crt@					\ Now the sync end
   hsw + 1f and
   5 crt@ e0 and or 5 crt!		\ Bits go to crt 5
;

0 value vr
0 value vlb
0 value vrb
0 value vb
0 value vfp
0 value vsw

: mga-vertical-program ( vr lb rb vb fp sw -- )
   to vsw 
   to vfp 
   to vb 
   to vrb 
   to vlb 
   to vr

   \ First we do the vertical total
   vr vlb + vrb + vb + 2 -			\ Should be vertical total
   dup 6 crt!				\ Low 8 bits to crt 6
   dup 100 and 0 <>  1 7 rot mga-crt-bit-fix	\ Bit 8 to crt 7
   dup 200 and 0 <> 20 7 rot mga-crt-bit-fix	\ Bit 9 to crt 7
   dup 400 and 0 <>  1 2 rot mga-crtx-bit-fix	\ Bit 10 to crtx 2
       800 and 0 <>  2 2 rot mga-crtx-bit-fix	\ Bit 11 to crtx 2

   \ Now the sync signals
   vr vfp + dup ff and 10 crt!		\ High bits to crt 10
   dup 100 and 0 <>  4 7 rot mga-crt-bit-fix	\ Bit 8 to crt 7
   dup 200 and 0 <> 80 7 rot mga-crt-bit-fix	\ Bit 9 to crt 7
   dup 400 and 0 <> 20 2 rot mga-crtx-bit-fix	\ Bit 10 to crtx 2
       800 and 0 <> 40 2 rot mga-crtx-bit-fix	\ Bit 11 to crtx 2

   10 crt@ vsw + 0f and 11 crt!		\ Sync end to crt 11

   \ The vertical display end...

   vr						\ Get lines
   dup ff and 12 crt!			\ Low bits to crt 12
   dup 100 and 0 <>  2 7 rot mga-crt-bit-fix	\ Bit 8 to crt 7
   dup 200 and 0 <> 40 7 rot mga-crt-bit-fix	\ Bit 9 to crt 7
       400 and 0 <>  4 2 rot mga-crtx-bit-fix	\ Bit 10 to crtx 2

   \ And finally, the blank...

   vr 1 -					\ Get line total -1
   dup ff and 15 crt!			\ Low bits to crt 15
   dup 100 and 0 <>  8 7 rot mga-crt-bit-fix	\ Bit 8 to crt 7
   dup 200 and 0 <> 20 9 rot mga-crt-bit-fix	\ Bit 9 to crt 9
   dup 400 and 0 <>  8 2 rot mga-crtx-bit-fix	\ Bit 10 to crtx 2
       800 and 0 <> 10 2 rot mga-crtx-bit-fix	\ Bit 11 to crtx 2

   15 crt@ 1 - vb + ff and 16 crt!	\ Blank end to crt 16

   16 crt@ 11 + 16 crt!			\ Adjust vertcal blank end

   \ Two last details...

   \ First need to set line compare registers
   10 7 -1 mga-crt-bit-fix
   40 9 -1 mga-crt-bit-fix
   ff 18 crt!

   \ and Last to set the crtc mode cntl
   c3 17 crt!			\ c8 seems to work the best so far...
;

: init-wram-1  ( -- )			\ Initializes the WRAM

   option@ 20.0000 or option!		\ Set nogscale in OPTION
   storm2?  if  89  else  80  then	\ 80: MGA mode (XXX 0 for VGA)
					\ 18: video delay  7: dot clock scaler
   3 mga-crtx!
   screen-off			\ Turn off video
   option@ h# 1100 invert and
\ XXX Possibly turn off interleave for VGA text mode
   storm2?  if  h# 100  else  h# 1100  then \ 100: VGA I/O ena, 1000: interlv
   or option!
;

: vsync?  ( -- flag )			\ Reads status of vsync
   214 pc@
   8 and 0 <>
;

: wait-for-retrace  ( -- )		\ Stalls execution until retrace
   begin				\ BE CAREFULL USING THIS!!!!!!!!
      vsync?				\ DO NOT STEP INTO THIS WITH DEBUG!!!!
   until
;

: mga-textmode  ( -- )
   h# 80  3  false  mga-crtx-bit-fix	\ Turn off MGA mode
   option@  h# 1000 invert and  option!	\ Turn off interleave

   80 18 idac!    \ RAMDAC: Use palette (see TI TVP3026 spec)
   98 19 idac!	  \ RAMDAC: VGA mode

   0 4 mga-crtx!			\ Memory window; 0 for VGA modes

   4 c-l@  1 or  4 c-l!			\ Enable standard VGA I/O port access
;

: init-globals  ( -- )
   8280   8c pc!			\ Write the PITCH register
   0      94 pc!			\ Set YDSTORG to 0
   0      a0 pc!			\ Set CXLEFT
   d# 640 a4 pc!			\ Set CXRIGHT
   0      98 pl!			\ Set YTOP
   d# 480 9c pl!			\ Set YBOT
   -1     1c pl!			\ Set PLNWT
   0      0c pl!			\ Set ZORG
;

: init-rectangle  ( -- )
   d# 480 5c pw!			\ Set LEN to 480 lines
   0      90 pl!			\ Set YDST to 0
   00007844 100 pl!			\ Draw it...
;

: init-wram-2  ( -- )
   option@  f.0000 invert and		\ Pgm OPTION reg refresh count to 12
   c.0000 or  option!
   1 reset!				\ Assert soft reset bit
   1 ms
   0 reset!				\ De-assert soft reset bit
   1 ms
   wait-for-retrace
   video-on				\ Video on
   wait-for-retrace
   80 04 pc!				\ Set memreset in MACCESS
   1 ms
   init-globals				\ Init drawing engine
   init-rectangle   
;

0 instance value tmap

: map-temp  ( -- )
   0 0 my-space  h# 200.0014 +  h# 40.0000  map-in  to tmap
   4 c-l@  2 or  4 c-l!
;

: unmap-temp  ( -- )
   tmap  h# 40.0000  map-out
;

: probe-memory-size  ( -- )
   map-temp
   tmap 40.0000 0 fill
   h# a5a5a5a5 tmap l!
   tmap 4 + l@ 0 <>  if
      storm2 to variant
      option@  1000 xor  option!	\ Toggle interleave bit
      50 13 crt!
      89  3 mga-crtx!
   then
   unmap-temp
;

: init-mga-controller  ( -- )
   67 misc!
   unlock-crt-regs
   option@  100 invert and  option!	\ Disable access to VGA I/O addresses
;

: reinit-mga-controller  ( -- )
   d# 25175 set-pclk drop
   pclk-stable?
   8 misc!
   init-wram-1
   probe-memory-size
   unlock-crt-regs
   d# 640 d# 16 d# 96 d# 48  mga-horizontal-program
   d# 480 d#  8 d#  8 d# 45 d#  1 d#  2 mga-vertical-program
   seq-regs  start-seq
   high-attr-regs
   grf-regs
   init-wram-2
   2 4 seq!	\ extended memory
   graphics-memory
   palette-on
;

: use-mga-words  ( -- )			\ Turns on the mga specific words
   ['] map-mga-io-regs        to map-io-regs
   ['] unmap-mga-io-regs      to unmap-io-regs
   ['] map-mga-frame-buffer   to map-frame-buffer
   ['] unmap-mga-frame-buffer to unmap-frame-buffer
   ['] init-mga-controller    to init-controller
   ['] reinit-mga-controller  to reinit-controller
   ['] screen-on              to video-on
   ['] mga-textmode           to ext-textmode
   use-mga-dac-methods
;

: probe-dac  ( -- )			\ Chained word...sets the dac type
   mga?  if  use-tvp3026-dac exit  then
   probe-dac				\ Not us, try again...
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
