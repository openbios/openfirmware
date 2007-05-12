purpose: Compute a fixed-point sin table
\ See license at end of file

\ Calculate the sin function using fractional integer arithmetic
\ where the scale factor is 2^15.  1.0 is represented by 32767,
\ pi is 102943.  The argument to isin ( index -- frac ) is a
\ sample index from 0 to fs/freq/4 .

d# 16000 value fs
0 value x
0 value xsq

d#  32767 constant one
d# 102943 constant pi

0 value freq
0 value fstep
0 value #cycle
0 value #half-cycle
0 value #quarter-cycle

: set-freq  ( freq -- )
   dup to freq
   pi * to fstep
   fs freq /  dup  to #cycle
   2/         dup  to #half-cycle
   2/              to #quarter-cycle
;
: set-period  ( quarter-cycle -- )
   dup to #quarter-cycle       ( quarter-cycle )
   2* dup to #half-cycle       ( half-cycle )
   2* dup to #cycle            ( cycle )
   fs over / to freq           ( period )
   pi swap /  fs *  to fstep   ( )
;

\ Multiply two fractional numbers where the scale factor is 2^15
\ : times  ( n1 n2 -- n3 )  d# 32767 */  ;   \ Insignificantly more accurate, but slower
: times  ( n1 n2 -- n3 )  *  d# 15 rshift   ;

\ Computes  (1 - (x^2 / divisor) * last)
: sin-step  ( last divisor -- next )  xsq  swap /  times  one min  one swap -  ;

\ Taylor series expansion of sin, calculated as
\ x * (1 - (x^2/(2*3)) * (1 - (x^2/(4*5)) * (1 - (x^2/(6*7)) * (1 - (x^2/(8*9))))))
\ This is good for the first quadrant only, i.e. 0 <= index <= fs / freq / 4
: isin  ( index -- frac )
   fstep *  fs 2/  /  to x
   x dup times to xsq
   one  d# 72 sin-step d# 42 sin-step  d# 20 sin-step  6 sin-step  x times  one max
;

: one-cycle  ( adr -- )
   #quarter-cycle 1+  0  do   ( adr )
      i isin
      2dup  swap  i wa+ w!                ( adr isin )
      2dup  swap  #half-cycle i - wa+ w!  ( adr isin )
      negate                              ( adr -isin )
      2dup  swap  #half-cycle i + wa+ w!  ( adr -isin )
      over  #cycle i - wa+ w!             ( adr )
   loop                                   ( adr )
   drop
;

\ d# 16000 to fs
\ d# 150 set-freq
\ here one-cycle
\ here #cycle 2*  wdump

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
