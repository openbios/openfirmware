\ See license at end of file
purpose: Initialize Diamond Viper-SE graphics board

hex 
headerless

1 instance value vip-ver
: .driver-info  ( -- )
   .driver-info
   vip-ver . ." Viper Code Version" cr
;

-1 instance value clk-base

: map-clk-reg  ( -- )
   0 0 h# 8100.0000 h# 1.0000 map-in to clk-base
   4 c-w@ 1 or 4 c-w!
;

: unmap-clk-reg  ( -- )
   clk-base 1.0000 map-out
   -1 to clk-base
   4 c-w@ 1 invert and 4 c-w!
;
   
0 value ckadr
false instance value frame-buffer-mapped?
false instance value io-mapped?

: map-viper-io-regs ( -- )	\ Maps in 9100 and frame buffer

   frame-buffer-mapped? if exit then	\ Don't do this if already mapped...

   \ All Native registers (including frame-buffer) are addressed relative 
   \ to io-base which must map to a physical address which is 16M aligned.
   \
   \ The frame-buffer-adr must map to a physical address which has the 
   \ 0x0080.0000 bit set.

   0 0 my-space h# 200.0010 + 100.0000  map-in to io-base
   io-base h# 80.0000 +
   to frame-buffer-adr

   \ Enable memory space access
   4 c-w@ 2 or 4 c-w!
   
   frame-buffer-adr encode-int " address" property
   true to io-mapped?
;

: forced-unmap  ( -- )
   4 c-w@ 2 invert and 4 c-w!
   io-base 100.0000 map-out
   -1 to io-base
   -1 to frame-buffer-adr
   false to io-mapped?
;

: unmap-viper-io-regs  ( -- )
   frame-buffer-mapped?  if  exit then
   forced-unmap
;

: map-viper-frame-buffer  ( -- )
   map-viper-io-regs
   true to frame-buffer-mapped?
;

: unmap-viper-frame-buffer  ( -- )	\ Closes the thing out
   false to frame-buffer-mapped?
   forced-unmap
;

: native-reg-l! ( w index )		\ Write to native mode register
   io-base + rl!
;

: native-reg-l@ ( index w  )		\ Read from native mode register
   io-base + rl@
;

: mem@   184 native-reg-l@ ;		\ This is memory config register
: mem!   184 native-reg-l! ;

: ckadr@	( -- b )		\ Reads the clock reg
   ckadr c-b@
;

: ckadr!	( b -- )			\ Writes the clock reg,
				( b )		\ Preserves the 0 bit.
   ckadr@ 1 and			( b old )	\ Wipe except for 0 bit
   or 				( new )
   ckadr c-b!
;

\ Starting with the following, you will see lots of apparently meaningless 
\ reads from the frame buffer that are simply dropped. This is done per the
\ Weitek manuals to maintain synchronization within the chip. 

: fb-sync  ( -- )  frame-buffer-adr rl@ drop ;

: ckcp-data-assert  ( -- )	\ Asserts the data pin to the clock chip
   clk-base 3cc + rb@
   8 or
   clk-base 3c2 + rb!
;

: ckcp-data-kill  ( -- )	\ De-asserts the data pin to the clock chip
   clk-base 3cc + rb@
   8 invert and
   clk-base 3c2 + rb!
;

: ckcp-clk-assert  ( -- )	\ Asserts the clock pin to the clock chip
   clk-base 3cc + rb@
   4 or 
   clk-base 3c2 + rb!
;

: ckcp-clk-kill  ( -- )		\ De-asserts the clock pin to the clock chip
   clk-base 3cc + rb@
   4 invert and
   clk-base 3c2 + rb!
;

: byte-repl  ( b -- w )		\ Replicates a byte into bits 31:15
   dup 8 lshift or dup 10 lshift or
;

: viper-plt!  ( b -- )			\ Pallette write
   byte-repl				\ Replicate byte 3x
   204 native-reg-l!			\ Write color
;

: viper-plt@  ( -- b )			\ Pallette read
   204 native-reg-l@			\ Read color
   10 rshift ff and			\ Clean it up
;

: viper-windex!  ( index -- )		\ Sets write index
   byte-repl				\ Replicate byte
   fb-sync				\ Re-sync
   200 native-reg-l!			\ Store index
;

: viper-rindex!  ( index -- )		\ Sets read index
   byte-repl				\ Replicate byte
   fb-sync
   20c native-reg-l!
;

: viper-idac@ ( index -- b )			\ Indexed read of dac entry
   
   fb-sync
   0 214 native-reg-l!				\ First set index high to 0
   byte-repl					\ Replicate index byte
   fb-sync
   dac-index-adr 2 lshift 200 + native-reg-l!	\ Index is on top, write it
   dac-data-adr  2 lshift 200 + native-reg-l@	\ Read data
   10 rshift ff and				\ Clean it up
;

: viper-idac! ( b index -- )			\ Indexed write to dac entry
   
   fb-sync
   0 214 native-reg-l!				\ First set index high to 0
   byte-repl					\ Replicate index byte
   fb-sync
   dac-index-adr 2 lshift 200 + native-reg-l!	\ Write index byte
   byte-repl					\ Now data on top, replicate it
   fb-sync
   dac-data-adr  2 lshift 200 + native-reg-l!	\ Now write it
;

: viper-rmr! ( b -- )				\ Writes a pixel mask
   byte-repl			 
   fb-sync
   208 native-reg-l!
;

: viper-rmr@  ( -- b )
   fb-sync
   208 native-reg-l@
   ff and
;

: viper-rs@  ( -- )  ;		\ Not needed so far
: viper-rs!  ( -- )  ;		\ Not needed so far

: use-viper-dac-methods  ( -- )	\ Assigns viper version of DAC access words
   ['] viper-rmr@ to rmr@
   ['] viper-rmr! to rmr!
   ['] viper-plt@ to plt@
   ['] viper-plt! to plt!
   ['] viper-rindex! to rindex!
   ['] viper-windex! to windex!
   ['] viper-rs@ to rs@
   ['] viper-rs! to rs!
   ['] viper-idac@ to idac@
   ['] viper-idac! to idac!
;

\ Thats it for the dac defers, now for the controller itself
: set-icd206 ( w -- )			\ This routine rams a magic number into
					\ the icd clock chip to tell it what
					\ frequency to generate

   \ First we have to unlock the chip
   \ We have to hold the data high and clock the chip 5 times

   ckcp-data-assert
   5 0 do 
      ckcp-clk-assert
      ckcp-clk-kill
   loop

   \ Now kill the data and re-assert the clock
   ckcp-data-kill
   ckcp-clk-assert

   \ Now send the start bit
   ckcp-clk-kill
   ckcp-clk-assert

   d# 24 0 do			\ Write 24 bits...

      \ Now get the low bit
      dup 			( w w )
      1 and			( w b )

      1 = if			( w )		\ Check lowest bit and pgm
         ckcp-data-kill				\ Drop data (invert)
         ckcp-clk-kill				\ Now drop clock
         ckcp-data-assert			\ Now assert clock
         ckcp-clk-assert			\ Assert clock
      else
         ckcp-data-assert			\ Assert data (invert)
         ckcp-clk-kill				\ Drop clock
         ckcp-data-kill				\ Drop data
         ckcp-clk-assert			\ Assert clock
      then

      1 rshift			( w )		\ Rotate the data down

   loop

   drop						\ Drop last 8 bits

   \ now we finish up
   \ clock should be high after the do loop above
   ckcp-data-assert				\ Raise the data bit
   ckcp-clk-kill				\ Drop the clock
   ckcp-clk-assert				\ Rasie the clock

   d# 10 ms				\ Wait before letting anyone use it
;

: set-weitek-native				\ Puts 9100 into native mode
   82 4 c-b!					\ Enable memory
   41 c-b@ drop
   0 41 c-b!					\ Set CONFIG[65] native
   42 c-b@ c or 42 c-b!				\ Set clock select bits
						\ to something besides 0
   42 to ckadr
; 

: program-icd2061  ( -- )			\ sets up the icd clock chip
   01c841  set-icd206   \ Set Video CLock Reg 0 to 50.00 MHz
   21c841  set-icd206   \ Set Video CLock Reg 1 to 50.00 MHz
   41c841  set-icd206   \ Set Video CLock Reg 2 to 50.00 MHz
   779d1f  set-icd206   \ Set Memory Clock to 23.00MHz
;

: viper-low-power  ( -- )	\ Disable video and hsync for low power mode
   138 native-reg-l@ 80 invert and 20 invert and 138 native-reg-l!
;

: viper-video-on ( -- )		\ Enable video and hsync
   138 native-reg-l@ 80 or 20 or 138 native-reg-l!
;

: weitek-middle  ( -- )

   viper-low-power				\ Make sure this beast is off

   \ this is weitek programming section...
 
   08563000  io-base 4 + rl!	\ Init control register
   1a io-base 8 + rl!		\ Init interrupt reg
   aa io-base c + rl!		\ Init interrupt enable reg
 
   \ Program Video Control Registers
  
   frame-buffer-adr rl@ drop
 
   d# 100 108 native-reg-l!	\ hrzt          Set horizontal length
   d#   5 10c native-reg-l!	\ hrzsr         Set horizontal sync assert
   d#  10 110 native-reg-l!	\ hrzbr         Set horizontal blank deassert
   d#  90 114 native-reg-l!	\ hrzbf         Set horizontal blank assert
       00 118 native-reg-l!	\ prehrzc       Set horizontal counter preload
   d# 520 120 native-reg-l!	\ vrtt          Set vertical length
   d#   5 124 native-reg-l!	\ vrtsr         Set vertical sync assert
   d#  20 128 native-reg-l!	\ vrtbr         Set vertical blank deassert
   d# 500 12c native-reg-l!	\ vrtbf         Set vertical blank assert
       00 130 native-reg-l!	\ prevrtc       Set vertical counter preload

   138 native-reg-l@ 700 invert and 100 or 1f invert and 2 or 138 native-reg-l!
 
        0 140 native-reg-l!	\ srtctl        Set non-inverted h-sync

   3ff 188 native-reg-l!	\ rfperiod      Set screen refresh period
   3ff 190 native-reg-l!	\ rfmax         Set screen refresh max
   c820.007d 184 native-reg-l!	\ mem_config    Set memory configuration

      186 188 native-reg-l!	\ rfcount	Set refresh period
       fa 190 native-reg-l!	\ rlmax		Set ras low max
 
   \ this part does the drawing engine control...
 
    20 2200 native-reg-l!        \ color[0]      Set forground
    d0 2204 native-reg-l!        \ color[1]      Set background
    -1 2208 native-reg-l!        \ plane mask    Set pmask
    00 220c native-reg-l!        \ set drawmode
     0 2218 native-reg-l!        \ set raster
     0 2220 native-reg-l!        \ set pixel window min
     
   d# 640 16 lshift d# 480 or 2224 native-reg-l!

    -1 2280 native-reg-l!        \ set pattern 0
    -1 2284 native-reg-l!        \ set pattern 1
    -1 2288 native-reg-l!        \ set pattern 2
    -1 228c native-reg-l!        \ set pattern 3
    -1 2290 native-reg-l!        \ set user 0
    -1 2294 native-reg-l!        \ set user 1
    -1 2298 native-reg-l!        \ set user 2
    -1 229c native-reg-l!        \ set user 3
     0 2210 native-reg-l!        \ set pattern origin x
     0 2214 native-reg-l!        \ set pattern origin y
     0 22a0 native-reg-l!        \ set 
    d# 640 8 / 16 lshift d# 480 or 22a4 native-reg-l!
 
   \ now the paramter engine control
 
     0 218c native-reg-l!        \ set cindex
     0 2190 native-reg-l!        \ set w_off.xy
 
;

: weitek-end  ( -- )
\    program-icd2061			\ Setup the clock generator;
;

: init-viper-controller  ( -- )		\ Gets and sets the mappings we need

   map-clk-reg				\ Temporarily map-in VGA Regs

   h# 11 clk-base h# 3c4 + rb!		\ Wake up VGA regs
   h# 11 clk-base h# 3c5 + rb!
   h# 11 clk-base h# 3c5 + rb!
   clk-base h# 3c5 + rb@
   h# 0df and
   clk-base h# 3c5 + rb!

   8 clk-base h# 46e8 + rb!	\ Enable VGA
   1 clk-base h# 102 + rb!	\ Enable VGA
   program-icd2061		\ Program ICD chip through VGA interface
   unmap-clk-reg		\ Unmap the non-relocateable

   set-weitek-native
   weitek-middle
   weitek-end
;

: use-weitek-words  ( -- )		\ Turns on the Weitek specific words
   ['] map-viper-io-regs to map-io-regs
   ['] unmap-viper-io-regs to unmap-io-regs
   ['] map-viper-frame-buffer to map-frame-buffer
   ['] unmap-viper-frame-buffer to unmap-frame-buffer
   ['] init-viper-controller to init-controller
   ['] viper-video-on to video-on
   use-viper-dac-methods
;

: probe-dac  ( -- )				\ Chained dac prober
   weitek? if
      use-ibm-dac
   else
      probe-dac
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
