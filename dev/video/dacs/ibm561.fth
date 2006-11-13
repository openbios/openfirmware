\ See license at end of file
purpose: Initialize IBM RGB561 RAMDAC

hex
headers

\ IBM RGB561 setup

\ The IBM RGB561 RAMDAC has only two address lines (c0/c1)
\ used for addressing. The basic addresses we are interested in are:
\
\	Address		Register
\	   0		Index Address Low
\	   1		Index Address High
\	   2		Data Address
\	   3		LUT Address
\
\ This DAC has a zillion indexed registers (hence two address registers) 

0 instance value target-f		\ Desired output frequency
0 instance value vco-div		\ VCO divide count
0 instance value df			\ Post scaler
					
: 561-calc-ref  ( target-f -- error? )	\ Calculates vco & ref counts, DF
					
   to target-f				\ Its easier to just save it...
   0 to vco-div				\ Clear this so error test at end will
					\ work if word is used more than once

   \ Note: The reference div count must be greater than or equal to 2

   \ First we need to calculate DF. This is a post divide value that
   \ ranges from 0 to 3.

   3
   target-f d# 128000 min target-f = if
      1-
      target-f d# 64000 min target-f = if
         1-
         target-f d# 32000 min target-f = if
            1-
         then
      then
   then
   to df

   \ Now we calculate an intermediate value for the equations:
   \ (target-f / 1Mhz)

   target-f d# 1000 /		( intermediate )
   df case
      0 of  4 *  endof
      1 of  2 *  endof
      2 of  1 *  endof
      3 of  2 /  endof
   endcase
   d# 65 -
   h# 3f and			( intermediate' )

   \ And now the final high bits to be or'd into the vco reg
   df case
      0 of  h#  0  endof
      1 of  h# 40  endof
      2 of  h# 80  endof
      3 of  h# c0  endof
   endcase
   or				( pll-div )
;

: ibm561-ref-clk  ( -- val )
   d# 14318180 d# 2000000 /
   h# ff and
;

: set-ibm561-pclk  ( freq -- )	\ Programs the pixel PLL in a 561 DAC
   561-calc-ref		( pll-div )
   h# 21 idac!		( )
   ibm561-ref-clk	( ref )
   h# 22 idac!		( )
   h# 39 h# 2 idac!		\ Set DTG, NOBLANK, VMASK, PLL in config2
;

: 0-reg!  ( index -- )		\ Zeros out a reg
   0 swap idac!
;

: g-index!  ( index color -- )		\ Color= 0|1|2 == red|green|blue
   h# 400 *	( index offset )	\ Calculate color offset
   +		( index' )		\ Add index to color offset
   h# 3000 +	( index'' )		\ Add GAMMA LUT offset
   index!	( )			\ Write it
;

: gamma!  ( gamma index color -- )	\ Writes a gamma table
   g-index!		( gamma )

   dup 3 and 6 lshift	( gamma gamma[1:0] )
   swap			( gamma[1:0] gamma )
   2 rshift h# ff and	( gamma[1:0] gamma[9:2] )
   plt!			( gamma[1:0] )
   plt!			( )
;

: gamma@  ( index color -- gamma )	\ Reads a gamma table
   g-index!		( )
   plt@			( gamma[9:2] )
   2 lshift		( gamma[9:2]' )
   plt@			( gamma[9:2]' gamma[1:0] )
   6 rshift 3 and	( gamma[9:2]' gamma[1:0]' )
   or			( gamma )
;

: w-index!   ( index -- )  h# 1000 + index! ;
: ow-index!  ( index -- )  h# 1400 + index! ;
: wat!   ( lo hi index )   w-index! plt! plt! ;
: owat!  ( lo hi index )  ow-index! plt! plt! ;

: init-ibm561-dac ( -- )

   d# 62000 set-ibm561-pclk	\ Pixel clock must be running before LUT access

   h# 40 h#  3 idac!	\ Config3
   h# 20 h# 20 idac!	\ DTG
   h#  0 h# 30 idac!	\ Cursor
   h# 90 h# 80 idac!	\ DTG_TREF
   h#  4 h# 5f idac!	\ DAC_CTL
   h# 3f h# 5e idac!	\ VCO_WAT_CTL

   \ Now to init the Gamma tables
   3 0 do					\ 3 times, R G & B
      h# ff 0 do				\ 256 entries per table
         i 2 lshift		( i' )
         i j			( i' index color )
         gamma!			( )
      loop   
   loop

   \ The above is sub-optimal. The gamma table addresses auto-increment so
   \ we could just write the first index address (0) then just slam the
   \ the data. 

   \ Now the WATs
   6 0-reg!
   7 0-reg!
   8 0-reg!
   9 0-reg!

   \ Now Chroma Stuff
   h# 10 0-reg!
   h# 11 0-reg!
   h# 12 0-reg!
   h# 13 0-reg!

   \ Pixel format (8bpp)
   h# e0 h# 1 idac!
   h# 4 0-reg!

   \ Init WATs to 0
   ff 0 do
      0 0 i wat!
   loop

   \ Init Overlay Wats to 4000
   ff 0 do
      0 40 i owat!
   loop

   \ Init 16 AUX WATs
   10 0 do
      1 h# f00 i + idac!
   loop

   \ Init 16 AUX WATs
   10 0 do
      0 h# e00 i + idac!
   loop

   \ Disable overlay bitplanes
   h# 56 0-reg!

   \ VRAM masks
   h# ff h# 50 idac!
   h# ff h# 51 idac!
   h# ff h# 52 idac!
   h# ff h# 53 idac!
   h# ff h# 54 idac!
   h# ff h# 55 idac!
;

: use-ibm561-dac  ( -- )
   ['] init-ibm561-dac to init-dac
   h# 10 to dac-index-adr
   h# 18 to dac-data-adr
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
