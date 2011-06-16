purpose: Compute a fixed-point sin table
\ See license at end of file

\ Calculate the sin function using fractional integer arithmetic
\ where the scale factor is 2^15.  1.0 is represented by 32767,
\ pi is 102943.  The argument to isin ( index -- frac ) is a
\ sample index from 0 to fs/freq/4 .

d# 16000 value fs
0 value theta
0 value thetasq

d#  32767 constant one
d# 102943 constant pi

0 value freq
0 value fstep
0 value #cycle
0 value #cycle/2
0 value #cycle/4

: set-freq  ( freq sample-rate -- )
   to fs             ( freq )
   dup to freq       ( freq )
   pi * to fstep
   fs freq /  dup  to #cycle
   2/         dup  to #cycle/2
   2/              to #cycle/4
;
: set-period  ( cycle/4 -- )
   dup to #cycle/4       ( cycle/4 )
   2* dup to #cycle/2       ( cycle/2 )
   2* dup to #cycle            ( cycle )
   fs over / to freq           ( period )
   pi fs rot */  to fstep      ( )
;

\ Multiply two fractional numbers where the scale factor is 2^15
\ : times  ( n1 n2 -- n3 )  d# 32767 */  ;   \ Insignificantly more accurate, but slower
: times  ( n1 n2 -- n3 )  *  d# 15 rshift   ;

\ Computes  (1 - (theta^2 / divisor) * last)
: sin-step  ( last divisor -- next )  thetasq  swap /  times  one min  one swap -  ;

[ifdef] notdef
\ Cos
\ 1 - t^2/(2) + t^4/(2..4) - t^6/2..6) + t^8/(2..8)
\ 1 - (t^2/(1*2)) * (1 - (t^2/(3*4)) * (1 - (t^2/(5*6)) * (1 - (t^2/(7*8))))

: icos  ( index -- frac )
   fstep fs 2/  */  to theta
   theta dup times  to thetasq
   one  d# 90 cos-step  d# 56 cos-step d# 30 cos-step  d# 12 cos-step  2 cos-step  one min
;
[then]

\ Taylor series expansion of sin, calculated as
\ t - t^3/(2*3) + t^5/(2*3*4*5) - t^7/(2..7) + t^9/(2...9)
\ theta * (1 - (theta^2/(2*3)) * (1 - (theta^2/(4*5)) * (1 - (theta^2/(6*7)) * (1 - (theta^2/(8*9))))))
\ This is good for the first quadrant only, i.e. 0 <= index <= fs / freq / 4
: calc-sin  ( index -- frac )
   fstep fs 2/  */  to theta
   theta dup times to thetasq
   one  d# 72 sin-step d# 42 sin-step  d# 20 sin-step  6 sin-step  theta times  one min
;

: one-cycle  ( adr -- )
   #cycle/4 1+  0  do   ( adr )
      i calc-sin
      2dup  swap  i wa+ w!                ( adr isin )
      2dup  swap  #cycle/2 i - wa+ w!     ( adr isin )
      negate                              ( adr -isin )
      2dup  swap  #cycle/2 i + wa+ w!     ( adr -isin )
      over  #cycle i - wa+ w!             ( adr )
   loop                                   ( adr )
   drop
;


[ifdef] notdef
: reduce-to-quarter-cycle  ( -- )
   \ Move a cycle/4 to the left until negative, then fix
   #cycle/4 -  dup 0<=  if  #cycle/4 +  (sin)          exit  then  ( theta' )  \ Quadrant 1
   #cycle/4 -  dup 0<=  if  negate      (sin)          exit  then  ( theta' )  \ Quadrant 2
   #cycle/4 -  dup 0<=  if  #cycle/4 +  (sin)  negate  exit  then  ( theta' )  \ Quadrant 3
   #cycle/4 -               negate      (sin)  negate                          \ Quadrant 4
;
[then]

\ For isin and icos we use a cosine table instead of a sine table.
\ Argument reduction is a bit easier for cos because it is an even function.
: one-cycle-cos  ( adr -- )
   #cycle/4 1+  0  do   ( adr )
      i calc-sin                           ( adr isin )
      2dup  swap  #cycle/4     i - wa+ w!  ( adr isin )  \ Quadrant 1
      2dup  swap  #cycle/4 3 * i + wa+ w!  ( adr isin )  \ Quadrant 4
      negate                               ( adr -isin )
      2dup  swap  #cycle/4     i + wa+ w!  ( adr -isin ) \ Quadrant 2
      over        #cycle/4 3 * i - wa+ w!  ( adr )       \ Quadrant 3
   loop                                    ( adr )
   drop
;

\ The scale factor for theta is such that h# 10000 is pi radians.
\ Binary 1 is therefore pi/2^16
0 value cos-table
: init-sincos  ( -- )
   cos-table  if  exit  then
   h# 20000 /w* alloc-mem  to cos-table
   1 h# 20000 set-freq
   cos-table one-cycle-cos
;
: release-cos-table  ( -- )  cos-table h# 20000 /w* free-mem  0 to cos-table  ;

: icos  ( theta -- cos )
   abs                                    ( theta' )
   dup #cycle  >=  if  #cycle mod  then   ( theta' )
   cos-table swap wa+ <w@                 ( cos )
;   
: isin  ( theta -- sin )  #cycle/4 -  icos  ;


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
