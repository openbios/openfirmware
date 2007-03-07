\ See license at end of file
purpose: Initialize GLINT Controller

\ Glint controller driver code

\ Power-up config info
\
\				LB mem-cntl	FB mem-cntl	FB mode-sel
\				(0x1000)	(0x1800)	(0x1808)
\
\	Fujitsu (large)		5a00800c	40000801	901
\	Fujitsu (small)		5a00800c	40000801	901
\	Omnicomp 3D

hex
headerless

0 instance value gl-ver
: .driver-info  ( -- )
   .driver-info
   gl-ver . ." Glint Code Version" cr
;

h# 2.0000 value /glint-regs

: map-glint-io-regs

   map-in-broken?  if
      my-space h# 8200.0010 + get-base-address		( phys.lo,mid,hi )
   else
      0 0 my-space h# 0200.0010 +			( phys.lo,mid,hi )
   then							( phys.lo,mid,hi )
   
   /glint-regs map-in to io-base

   4 c-w@ 2 or 4 c-w!
;

: unmap-glint-io-regs
   io-base /glint-regs map-out
   -1 to io-base		\ Not going to disable memory as frame-buffer
				\ needs it. unmap-frame-buffer will do it 
				\ later. Also, this is a relocateable mapping,
				\ so we don't have to worry about the 
				\ non-relocateable conflicts that older vga 
				\ controllers give us fits about
;

: v-offset  ( -- a )		\ Returns offset to video registers
   io-base h# 3000 +
;

: vid@  ( a -- l )		\ Reads a video timing register
   v-offset + rl@
;

: vid!  ( l a -- )		\ Writes a video timing register
   v-offset + rl!
;

: pos-hsync  ( -- )		\ Sets hsync positive
   h# 60 dup vid@       ( 60 reg )
   3 invert and         ( 60 reg' )
   swap vid!            ( )
;

: pos-vsync  ( -- )		\ Sets vsync positive
   h# 60 dup vid@       ( 60 reg )
   c invert and         ( 60 reg' )
   swap vid!            ( )
;

: neg-hsync  ( -- )		\ Sets hsync negative
   h# 60 dup vid@       ( 60 reg )
   3 invert and 2 or    ( 60 reg' )
   swap vid!            ( )
;

: neg-vsync  ( -- )		\ Sets vsync negative
   h# 60 dup vid@       ( 60 reg )
   c invert and 8 or    ( 60 reg' ) 
   swap vid!            ( )
;

\ Memory control register aids

: mem-base  ( -- a )		\ Returns offset to memory control register
   io-base h# 1800 +		
;				
				
: fb-cntl@  ( -- l )		\ Reads frame buffer control register
   mem-base rl@			
;				
				
: fb-cntl!  ( l -- )		\ Writes frame buffer control register
   mem-base rl!			
;				
				
: fb-mode@  ( -- l )		\ Reads frame buffer mode register
   mem-base 8 + rl@		
;				
				
: fb-mode!  ( l -- )		\ Writes frame buffer mode register
   mem-base 8 + rl!
;

\ DAC register aids		
				
: 3s  ( b -- b<3 )		\ Helper word, shifts byte left by 3
   3 lshift			
;				
				
: dac-offset  ( -- a )		\ Returns offset to dac registers
   io-base h# 4000 +		
;				
   				
: palette-address-w  ( -- a )	\ Returns offset to write palette address
   dac-offset			
;				
				
: palette-data  ( -- a )	\ Returns offset to pallete data
   dac-offset 1 3s +		
;				
				
: pixel-mask  ( -- a )		\ Returns offset to pixel mask
   dac-offset 2 3s +		
;				
				
: palette-address-r  ( -- a )	\ Returns offset to read palette address
   dac-offset 3 3s +		
;				
				
: index-low  ( -- a )		\ Returns offset to index low register
   dac-offset dac-index-adr 3s +		
;				
				
: index-high  ( -- a )		\ Returns offset to index high register
   dac-offset 5 3s +		
;				
				
: index-data  ( -- a )		\ Returns offset to index data register
   dac-offset dac-data-adr 3s +
;

\ The next several words get plugged into defered words. Depending
\ on what other types of dacs are used on other versions of GLINT boards,
\ different words may be needed and some probing to decide which words
\ to plug into the defered words.

: glint-idac@  ( i -- b )	\ Indexed read of dac
   0 index-high rb!		\ Set high byte of index
   index-low rb!		\ Set low index with i
   index-data rb@		\ Read indexed data
;				
				
: glint-idac!  ( b i -- )	\ Indexed write of dac
   0 index-high rb!		\ Set high byte of index
   index-low rb!		\ Set low index with i
   index-data rb!		\ Write indexed data
;				
				
: glint-rmr!  ( b -- )		\ Writes pixel mask register
   pixel-mask rl!
;

: glint-rmr@  ( -- b )		\ Reads pixel mask register
   pixel-mask rl@		
;				
				
: glint-plt!  ( b -- )		\ Writes to palette data register
   palette-data rl!		
;				
				
: glint-plt@  ( -- b )		\ Reads the palette data register
   palette-data rl@		
;				

: glint-windex!  ( i -- )	\ Sets the write index in DAC
   palette-address-w rb!	
;				
				
: glint-rindex!  ( i -- )	\ Sets the read index in DAC
   palette-address-r rb!
;

: use-glint-dac-methods  ( -- )	\ Assigns glint version of DAC access words
   ['] glint-rmr@ to rmr@
   ['] glint-rmr! to rmr!
   ['] glint-plt@ to plt@
   ['] glint-plt! to plt!
   ['] glint-rindex! to rindex!
   ['] glint-windex! to windex!
   ['] noop  to rs@
   ['] 2drop to rs!
   ['] glint-idac@ to idac@
   ['] glint-idac! to idac!
;

\ Now the major words for this part of the driver

\ As for the timing registers, there are only eight major registers
\ to worry about for timing. Horizontal total, HSync start, HSync end,
\ HBlank end, Vertical total, VSync start, VSync end & finaly, VBlank end.
\ The horizontal counter starts at 1 and counts up to Horizontal total.
\ HBlank starts at 1, and ends at HBlank end. The sync start and end 
\ are set between 1 and HBlank end. Same basic rules for Vertical. Just
\ like most other video cards, these numbers are in units of character
\ clocks or more correctly, pixel clock / 8. Unlike most other vga cards,
\ the blanking at sync signals come at the begining of the horizontal and
\ verticle swweps, not the end. Horizontal blank is asserted when the 
\ horizontal timer rolls over from the total value programmed into Htot to
\ 1. (there is no 0 count). You need only specify a blank end point (HBe).
\ The same is true for the vertical counter.

: timing-regs-640  ( -- adr len)
  " "(0069 0002 000a 0019 01f4 0001 0004 0014)"
    \ Htot HSs  HSe  HBe  Vtot VSs  VSe  VBe
;

: init-glint-controller  ( -- )
   timing-regs-640			\ The timing parameters...
   0 do					\ Ram them into chip
      dup i + c@ 8 lshift swap	   
      dup i + 1 + c@ rot or	   
      i 4 * vid!		   
   2 +loop			   
   drop				   
				   
   h# 18 vid@ 2- h# 40 vid!		\ Set HGate start = HBlank end - 2
   0     vid@ 2- h# 48 vid!		\ Set HGate end   = H total - 2
				   
   h# 38 vid@ 2- h# 50 vid!		\ Set VGate start = VBlank end - 2
   h# 50 vid@ 2+ h# 58 vid!		\ Set VGate end 2 later
   				   
   h# 0 h# 68 vid!			\ Make sure frame row address reg = 0
   h# d h# 78 vid!			\ Set Serial clock control
				   
   h# b0 h# 60 vid!			\ Init Csync and CBlank
   neg-hsync				\ Hysnc negative
   pos-vsync				\ Vsync positive
;


: map-glint-frame-buffer  ( -- )

   map-in-broken?  if
      my-space h# 8200.0018 + get-base-address		( phys.lo,mid,hi )
   else
      0 0 my-space h# 200.0018 +			( phys.lo,mid,hi )
   then							( phys.lo,mid,hi )

   /fb " map-in" $call-parent to frame-buffer-adr

   \ We don't worry about the mem enable bit in pci reg because map-regs
   \ will have done that already.
;

: unmap-glint-frame-buffer  ( -- )
   frame-buffer-adr /fb " map-out" $call-parent
   -1 to frame-buffer-adr
   4 c-w@ 2 invert and 4 c-w!
;

: use-glint-words  ( -- )		\ Turns on the glint specific words
   ['] map-glint-io-regs to map-io-regs
   ['] unmap-glint-io-regs to unmap-io-regs
   ['] map-glint-frame-buffer to map-frame-buffer
   ['] unmap-glint-frame-buffer to unmap-frame-buffer
   ['] init-glint-controller to init-controller
   ['] noop to video-on
   use-glint-dac-methods
;

: probe-dac  ( -- )			\ Chained probing
   glint? if
      use-ibm-dac
   else
      probe-dac				\ Not us, try again...
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
