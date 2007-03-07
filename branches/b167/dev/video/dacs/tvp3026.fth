\ See license at end of file
purpose: Initialize ATT RAMDAC

hex 
headerless


\ The tvp3026 DAC has four RS address lines. The calling method must
\ define idac@ and idac! so that indexed reads and writes work properly.

\ For the 3026, the basic addresses are:
\	Address (RS=)	Port
\		0	Palette address (write) / Index address register
\		1	Palette data
\		2	Pixel Read Mask
\		3	Palette address (read)
\		a	Index data register

\ TI DAC Setup for tvp3026

: ti3026-mclk!  ( P M N -- )	\ Write M N and P to mclk PLL
   00 2c idac!	( P M N )	\ setup index
      2e idac!	( P M )		\ write N
      2e idac!	( P )		\ write M
      2e idac!	( - )		\ write P
   ff 2c idac!			\ reset index
;

: ti3026-mclk-stable?  ( -- )	\ waits for mclk PLL to stableize
   3f 2c idac!			\ Set address
   begin
      2e idac@ 40 and 40 =	\ Read status reg
   until
;

: ti3026-pclk!  ( P M N -- )	\ Write M N and P to pixel clock
   00 2c idac!	( P M N )	\ setup index
      2d idac!	( P M )		\ write N
      2d idac!	( P )		\ write M
      2d idac!	( - )		\ write P
   ff 2c idac!			\ reset index
;

: ti3026-pclk-stable?  ( -- )	\ Wait for pixel PLL to stableize
   3f 2c idac!			\ Set address
   begin
      2d idac@ 40 and 40 =	\ Read status reg
   until
;

0 value fr
0 value p
0 value fvco

: ti3026-find-fvco  ( target-f -- )	\ Sets p and fvco variables.
					\ Not sure I need to save f either...
					\ but its easier if I do.
   to fr
   0 to p

   4 0 do

      1 i lshift			\ 2 to the power of i

      \ 2 to the power of p is now on stack

      fr *	( Fvco )

      dup
      d# 110000 d# 220000 between  if	\ The Vco frequency must be between 
         to fvco			\ 110 and 220 Mhz
         i f0 or to p			\ This is the "P" value which sets 
      else				\ the final divide.
         drop
      then

   loop
;

0 value n-min

: ti3026-set-start-n  ( -- )	\ Finds a minumin value for N (max is 63)
   14318 500 / 65 swap - to n-min
;

0 value m
0 value n
0 value delta
false value cont?
 
: ti3026-set-m-n  ( target-f -- flag )	\ Calculates M, N & P for pll

   ti3026-find-fvco		\ Now have P and VCO frequency
   ti3026-set-start-n		\ There is a lower limit to N, so set it now
   true to cont?

   begin
      d# 64 n-min do		\ Increment N looking for M values that work
   
         d# 64 1 do
   
            ( loop counter j is n )
            ( loop counter i is m )

            \ The following assumes a 14.318Mhz reference, fairly standard,
            \ but an enhancement might be to pass the reference into this
            \ routine.
   
            d# 65 i - d# 14318 * 8 *	\ (65 - N)*Vco now on stack
            
            fvco d# 65 j - * - abs delta <=  if

               cont?  if
                  false to cont?     \ Stop after finding first match. Future
                  i to m	     \ enhancement would be to find multiple
                  j 80 or to n	     \ matches and then return the ones that
               then		     \ give the least error.
            then
   
         loop
   
      loop
      delta d# 500 + to delta	\ If search failed, make delta bigger 
   cont? 0= until		\ and try again
   
   cont? 0=		\ Return true if it worked... this is broken...
			\ The way it is now, this should never fail
			\ as we keep increasing the delta until it works.
			\ A future enhancement would be to define some
			\ error conditions and test accordingly.
;

: ti3026-set-pclk ( freq -- flag )	\ Target frequency in , set pixel PLL
   ti3026-set-m-n
   p m n ti3026-pclk!
;

: ti3026-set-mclk ( freq -- flag )	\ Target frequency, set the MCLK PLL
   ti3026-set-m-n
   p m n ti3026-mclk!
;

: init-tvp3026-dac ( -- )

   ff  rmr!           \ Pixel read mask register - unmask all pixel bits

   mga?  if
      1e 6 idac!
   else
      10  6 idac!		\ Set cursor control register
   then

    6  f idac!			\ Set latch control register
    c 1e idac!			\ Set miscelaneous control reg
    0 2b idac!			\ Set general purpose control reg
   ff 2c idac!			\ Set PLL address
   7c 2d idac!			\ Set pixel clock pll data
   70 2e idac!			\ Set memory clock pll data
   74 2f idac!			\ Set load clock pll data

   mga?  if
      storm2?  if  4b  else  4c  then  19 idac!  \ 8bpp, 32 or 64 bit pixel bus
      75 1a idac!
      storm2?  if  39  else  3a  then  39 idac!
   then

   ff 30 idac!			\ Set overlay key low
   ff 31 idac!			\ Set overlay key high
   ff 32 idac!			\ Set red key low
   ff 33 idac!			\ Set red key high
   ff 34 idac!			\ Set green key low
   ff 35 idac!			\ Set green key high
   ff 36 idac!			\ Set blue key low
   ff 37 idac!			\ Set blue key high

   mga?  if		\ Programs RCLK Loop Pll for MGA Millenium boards.
       0 2c idac!
      storm2?  if  f1  else  e1  then  2f idac!
      3d 2f idac!
      f3 2f idac!
   then
;

: reinit-tvp3026-dac  ( -- )  
   mga? storm2? and  if
      init-tvp3026-dac
   then
;

: use-tvp3026-dac
   ['] init-tvp3026-dac to init-dac
   ['] reinit-tvp3026-dac to reinit-dac
   ['] ti3026-set-pclk to set-pclk
   ['] ti3026-set-mclk to set-mclk
   ['] ti3026-pclk-stable? to pclk-stable?
   ['] ti3026-mclk-stable? to mclk-stable?
   0 to dac-index-adr
   a to dac-data-adr
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
