\ See license at end of file
purpose: Calibrate Time Stamp Counter against ISA timer using interrupts

\ This code works only for processors that have a Time Stamp Counter register

label tick-handler ( <entered-via-calibrate-loop> -- count )
   h# f c,  h# 31 c,	\ Get time-stamp counter value into DX,AX
   ax cx sub		\ Compute difference

   h# fb #  al  mov   al  h# 21 #  out		\ Disable timer 0 interrupt
   h# 20 #  al  mov   al  h# 20 #  out		\ Perform non-specific EOI

   h# c #  sp   add	\ Discard EIP, CS, and EFLAGS

   cx neg  cx push	\ Push count value
c;

code calibrate-loop  ( -- <returns via tick-handler> )
   h# ff #  al  mov   al  h# a1 #  out	\ Disable high timer interrupts
   h# fb #  al  mov   al  h# 21 #  out	\ Disable low timer interrupts

   h# 20 #  al  mov   al  h# 20 #  out	\ Perform non-specific EOI

   \ setup timer 0 to interrupt when the count goes to 0

   \ TTRR.MMMB Timer 0, r/w=lsb,msb, mode 0, binary
   h# 30 #  al  mov   al  h# 43 #  out	\ Start setting timer

   0 wbsplit      ( tick-cnt-low tick-cnt-high )
   swap  #  al  mov   al  h# 40 #  out	\ Set tick limit low  ( tick-cnt-high )
					\ The timer should now be stopped

   h# fe #  al  mov   al  h# 21 #  out	\ Enable low timer interrupts

   h# f c,  h# 31 c,	\ Get time-stamp counter value into DX,AX
   ax cx mov		\ Save the low part in CX; the high part is not needed

         #  al  mov   al  h# 40 #  out	\ Set tick limit high to start timer

   sti			\ Enable interrupts
   begin  again		\ Loop, awaiting a tick

   \ We shouldn't get here because a tick should happen, invoking tick-handler
   -1 # cx mov  cx push
c;

\needs ms-factor -1 value ms-factor
\needs us-factor -1 value us-factor
\needs irq-vector-base h# 20 constant irq-vector-base
: calibrate-ms  ( -- )
   disable-interrupts
   [ also hidden ]
   tick-handler cs@  irq-vector-base  pm-vector!
   [ previous ]
   calibrate-loop    ( count-value )
   dup d# 10 d# 549 */ to ms-factor
   d# 54926 / to us-factor   \ Divide by 1000 with rounding
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
