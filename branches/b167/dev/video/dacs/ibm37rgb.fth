\ See license at end of file
purpose: Initialize IBM RAMDAC

hex
headerless

\ IBM RGB524 setup

\ The IBM RGB524 (&525) RAMDACs have only three address lines (RS[2:0])
\ used for addressing. The basic addresses we are interested in are:
\
\	Address		Register
\	   0		Palette Address (write)
\	   1		Palette Data
\	   2		Pixel Mask
\	   3		Palette Address (read)
\	   4		Index Addres (low)
\	   5		Index Address (high)
\	   6		Index Data
\
\ This DAC has a zillion indexed registers (hence two address registers) however
\ we are only concerned with a few of them, all addressable with just the low
\ byte (index address high == 0) so idac@ & idac! don't need to get weird.
\

d# 50000 instance value ref-freq	\ Reference frequency in KHz
					
0 instance value target-f		\ Desired output frequency
0 instance value vco-div		\ VCO divide count
0 instance value ref-div		\ Refernece divide count
0 instance value df			\ Post scaler
					
: ibm-calc-ref  ( target-f -- error? )	\ Calculates vco & ref counts, DF
					
   to target-f				\ Its easier to just save it...
   0 to vco-div				\ Clear this so error test at end will
					\ work if word is used more than once

   \ Note: The reference div count must be greater than or equal to 2

   \ First we need to calculate DF. This is a post divide value that
   \ ranges from 0 to 3. Also note that there are two speeds of DACs
   \ available, a 170 MHz version and a 220 Mhz version. The current
   \ algorythm assumes 170 Mhz version. The calulated number will work
   \ in a 220 Mhz version too. But if you need to generate numbers for
   \ a target frequency higher than 170 Mhz, then you will need the high
   \ speed DAC and to change the numbers as indicated below.

   3
   target-f d# 170000 min target-f = if	     \ If 220 Mhz DAC, can change
					     \ this to 220000
      1-
      target-f d# 85000 min target-f = if    \ If 220 Mhz DAC, can change
					     \ this to 110000
         1-
         target-f d# 42500 min target-f = if \ If 220 Mhz DAC, can change
					     \ this to 55000
            1-
         then
      then
   then
   to df

   \ This algorythm goes through all possible combinatins and simply
   \ leaves the *last* good set stuffed into vco- and ref-div. The
   \ values are considered *good* if the delta between the target
   \ frequency and the calculated frequency is less than 100 Khz.

   \ The equations that all of this is based on is from the IBM data sheet
   \ and look something like:
   \
   \	DF	Output Freq		VRF			Max outout F
   \								170Mhz	220 Mhz
   \
   \	00	fref * (vco-div + 65)	fref/(ref-div*2)	42.5	55.0
   \            ---------------------
   \		ref-div * 8
   \
   \	01	fref * (vco-div + 65)	fref/(ref-div*2)	85	110
   \		---------------------
   \		ref-div * 4
   \
   \	10	fref * (vco-div + 65)	fref/(ref-div*2)	170	220
   \		---------------------
   \		ref-div * 2
   \

   1 3 df - lshift		( div )		\ Generate 2, 4 or 8 for
						\ the output F calc

   20 2 do					\ Ref div count, must be >= 2
      40 0 do					\ VCO div count
         dup			( div div )
         ref-freq i d# 65 + *	( div div Num )
         swap			( div Num div )
         j *			( div Num Den )
         /			( div fout )
         target-f - abs		( div delta )
         d# 100 < if				\ Compare against 100 KHz
            dup ref-freq swap   ( div ref div )
            / 2 /		( div vrf )
            d# 1000 > if			\ Vrf must be > 1 Mhz
               i to vco-div	( div )		\ Save vco-div
               j to ref-div	( div )		\ Sace ref-div
            then
         then
      loop			( div )
   loop
   drop				( )

   vco-div 0=					\ Look for errors...
   df 3 =
   or				( error-flag )	\ Return error (true) if
						\ nothing worked
;

: set-ibm-pclk  ( freq -- error? )	\ Programs the pixel PLL in a 525 DAC
   ibm-calc-ref
   df 6 lshift
   vco-div or
   20 idac!
   ref-div
   21 idac!
;

: init-ibm-dac ( -- )

   weitek? if
      01 02 idac!			\ Pixel PLL programming enabled
      03 0a idac!			\ 8-bit per pixel mode
      19 14 idac!			\ PLL reference divider
      24 20 idac!			\ VCO divide count M value
      30 21 idac!			\ VCO divide count N value
   
      00 0b idac!			\ Use LUT for 8bpp mode
      00 0c idac!		 	\ set undefined reg (16 bpp)
      00 0d idac!			\ set undefined reg (24 bpp)
      00 0e idac!			\ set undefined reg (32 bpp)
   		
      02 06 idac!			\ set for fast slew rate DAC
      01 70 idac!			\ init misc control 1 -- 64 Bit data path
      45 71 idac!			\ init misc control 2 -- Internal PLL, 8-bit color, VRAM port
      07 02 idac!			\ init misc clock control -- ddotclk out/8, PLL enabled
   
      00 20 idac!			\ Set M value
      0f 21 idac!			\ set N value
      03 10 idac!			\ PLL control 1 -- use MN register
   else
      1   2 idac!			\ Misc Clock Control: Enable Pixel PLL
      1   6 idac!			\ DAC operation: Blanking pedestal enabled
      1  10 idac!			\ Pixel PLL control: External FS[1:0]
      77 16 idac!			\ System PLL VCO divider
      a  20 idac!			\ F0 value
      6  21 idac!			\ F1 value
      6  22 idac!			\ F2 value
      5  23 idac!			\ F3 value
      41 70 idac!			\ Misc Control 1: Pixel bus | 64b data path
      4  71 idac!			\ Misc Control 2: 8 bit color
      3  90 idac!			\ VRAM control:			<== is this needed?
   then

   glint? if
      7   2 idac!	\ Misc clk control: /8 clock out, enable PLL
      1   6 idac!	\ DAC operation: Blanking pedestal enabled
      3   a idac!	\ Pixel Presentaion: 8 BPP
      0   b idac!	\ 8 BPP cntl: Indirect color
      1  10 idac!	\ Pixel PLL cntl: 4 value M/N programming
      1  70 idac!	\ Misc control: 64 bit data path
      45 71 idac!	\ Misc cntl 2: Intern Pll, 8 bit color, Pixel port
      d# 38500 set-ibm-pclk drop
   then

   ff rmr!
;

: use-ibm-dac  ( -- )
   ['] init-ibm-dac to init-dac
   4 to dac-index-adr
   6 to dac-data-adr
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
