\ See license at end of file
purpose: Calibrate Time Stamp Counter against ISA timer - without interrupts

\ This code works only for processors that have a Time Stamp Counter register

code calibrate-loop  ( -- tscdelta )
   \ setup timer 0 to interrupt when the count goes to 0

   \ TTRR.MMMB Timer 0, r/w=lsb,msb, mode 0, binary
   h# 30 #  al  mov   al  h# 43 #  out	\ Start setting timer

   d# 11932 wbsplit swap     ( tick-cnt-high tick-cnt-low )
   #  al  mov   al  h# 40 #  out	\ Set tick limit low  ( tick-cnt-high )
					\ The timer should now be stopped

   h# f c,  h# 31 c,	\ Get time-stamp counter value into DX,AX
   ax cx mov		\ Save the low part in CX; the high part is not needed

   #  al  mov   al  h# 40 #  out	\ Set tick limit high to start timer

   begin
      ax ax xor  al  h# 43 #  out	\ Latch timer
      h# 40 # al in
      al ah mov
      h# 40 # al in
      al ah xchg
      d# 5 #  ax  cmp
   < until
   
   h# f c,  h# 31 c,	\ Get time-stamp counter value into DX,AX
   cx ax sub		\ Subtract the low parts
   
   ax push
c;


\needs ms-factor -1 value ms-factor
\needs us-factor -1 value us-factor
: calibrate-ms  ( -- )
   disable-interrupts
   calibrate-loop   dup d# 10 / to ms-factor  ( count-value )
   d# 10000 / to us-factor   \ Divide by 1000 with rounding
;
stand-init: Calibrating millisecond timer
   calibrate-ms
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
