purpose: Controls for the microphone input mode (AC vs. DC coupling)
\ See license at end of file

\ This uses an undocumented register in the AD1888 codec.
\ It turns off the DC offset compensator.

: post-b1?   ( -- flag )
   atest?  if  false exit  then  \ atest is detected via EC type
   board-revision 0 6 between    \ b1 is board revision 7
;

: ac-mode  ( -- )
   post-b1?  if
      2 >clr GPIOx_OUT_VAL gpio!     \ 5536 GPIO01
   else
      2 ec-cmd drop                  \ EC GPIO18
   then
;
: dc-mode  ( -- )
   post-b1?  if
      2 GPIOx_OUT_VAL gpio!          \ 5536 GPIO01
   else
      1 ec-cmd drop                  \ EC GPIO18
   then
;

warning @ warning off
: stand-init
   stand-init
   post-b1?  if
      \ Configure GPIO as output for controlling MIC input AC/DC coupling
      2 GPIOx_OUT_EN gpio!
      2 >clr GPIOx_OUT_AUX1 gpio!   \ GPIO, not AUX1 function
      2 >clr GPIOx_OUT_AUX2 gpio!   \ GPIO, not AUX2 function
      2 >clr GPIOL_PU_EN    gpio!   \ GPIO, not pull up
      2 >clr GPIOL_PD_EN    gpio!   \ GPIO, not pull down
   then
   ac-mode
;
warning !

\ LICENSE_BEGIN
\ Copyright (c) 2007 FirmWorks
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
