purpose: Driver for Motorola Embedded Programmable Interrupt Controller
\ See license at end of file

h# fdf0.0000 constant eu-pa
0 value eu-va
: map-eu  ( -- )
   eu-pa h# 78 config-l!
   eu-pa h# 10.0000 root-map-in to eu-va   
;
: +eu  ( offset -- adr )  eu-va +  ;
: eu!  ( l offset -- )  +eu rl!  ;
: eu@  ( offset -- l )  +eu rl@  ;

: priority!  ( pri -- )    h# 60080 eu!  ;
: vector@   ( -- vector )  h# 600a0 eu@  ;
: eoi  ( -- )  0  h# 600b0 eu!  ;
: gcr!  ( l -- )  h# 41020 eu!  ;
: gcr@  ( -- l )  h# 41020 eu@  ;

: pi!  ( l -- )  h# 41090 eu!  ;
: pi@  ( -- l )  h# 41090 eu@  ;

: spurious!  ( n -- )  h# 410e0 eu!  ;
: eicr!  ( l -- )  h# 41030 eu!  ;
: eicr@  ( -- l )  h# 41030 eu@  ;

: >irq  ( channel -- adr )  h# 20 *  h# 50200 +  ;
: vec/pri!  ( l channel -- )  >irq  eu!  ;
: vec/pri@  ( channel -- l )  >irq  eu@  ;
: dest!  ( l channel -- )  >irq h# 10 +  eu!  ;
: dest@  ( channel -- l )  >irq h# 10 +  eu@  ;

\ Other channels:  I2C - 0x71, DMA0 - 0x72, DMA1 - 0x73, Message unit - 0x76

: reset-epic  ( -- )
   gcr@  h# a000.0000 or  gcr!
   h# 2000.0000 gcr!
   \ XXX should configure it for the correct mode - direct, pass-thru, etc.

   \ Eat any pending interrupts
   h# 20 0  do
      vector@  h# ff =  if  unloop exit  then
      eoi
   loop
   ." The EPIC won't stop interrupting" cr
;
stand-init: Initializing EPIC
   map-eu
   reset-epic
;
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
