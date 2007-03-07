\ See license at end of file
purpose: Sin, cos and tan methods

headers
decimal

\ This version uses a scale factor of 2^30, i.e. 1 is represented 0x4000.0000
\ That is the optimum value for this calculation on a 32-bit system,
\ since the largest number that appears is (pi/2)**2, which is about 2.5

\ We represent angles from 0..360 with the numbers 0..0x4.0000, which
\ makes the angle reduction trivial - just throw away the high bits - and
\ quadrant calculation easy - bit 17 means to negate, bit 16 means to mirror.

\ The output value ranges from 0..3fffffff , representing numbers from
\ 0..1  .  This is easy to scale to whatever range you want.

\ *********************************************************************************
\ The Taylor-Maclaurin Series for the sine is:
\    sin(x) = x - x**3/3! + x**5/5! - x**7/7! + x**9/9! + ...
\ where x is some angle in radians ( 180 degrees = pi radians ).
\ The error, when x**9/9! is included is 0.0004%.  Therefore,
\ we factor out the above series into:
\    sin(x) ~ x ( 1 - x**2/6 ( 1 - x**2/20 ( 1 - x**2/42 ( 1 - x**2/72 ) ) ) )
\ The radians and results are 16-bit scaled.
\ *********************************************************************************

: udlshift  ( ud1 n -- ud2 )
   tuck lshift >r            ( low n r: uhh )
   2dup lshift -rot          ( ul low n r: uhh )
   bits/cell swap - rshift   ( ul uhl r: uhh )
   r> or
;
: umlshift  ( ud n -- u )  udlshift swap 0<  if  1+  then  ;

\ Compute y' = xs/divisor (1 - y)
\ using the algebraic equivalent
\              xs/divisor  - y*xs/divisor
: scl*  ( a b -- c )  m* 2 umlshift  ;
: taylor  ( xs y divisor -- xs y' )
\   2 pick swap u/mod nip  ( xs y xs/divisor )
\   tuck  scl*             ( xs xs/divisor y*xs/divisor )
\   -                      ( xs y' )
    >r  h# 3fff.ffff swap -  2 lshift  over um* nip  r> u/mod nip
;
: (sin)  ( x<<30 -- y<<30 )
   dup dup scl*		( x xs )
   0                    ( x xs y0 )
   156 taylor		( x xs y=x**2/156 )
   110 taylor           ( x xs y'=x**2/110[1-y] )
    72 taylor		( x xs y'=x**2/72[1-y] )
    42 taylor		( x xs y'=x**2/42[1-y] )
    20 taylor		( x xs y'=x**2/20[1-y] )
     6 taylor		( x xs y'=x**2/6[1-y] )
   nip                  ( x y'=x**2/6[1-y] )

   over scl* -          ( y )
   h# 4000.0000 min	( y )
;

h# 1.0000 constant pi/2-ticks
: reduce  ( ticks -- negate? ticks' )
   dup h# ffff and         ( ticks ticks/ )
   swap d# 16 rshift       ( ticks/ quadrant )
   dup 2 and 0<> -rot      ( negate? ticks/ quadrant )
   1 and   if  pi/2-ticks 1- swap -  then
;

d# 3,141,592,654 0 d# 29 udlshift d# 1,000,000,000 um/mod nip  ( n )
constant pi/2scl30
: ticks>rad  ( ticks -- scaled-radian )
   pi/2scl30 um*  d# 16 umlshift
;

: sin  ( ticks -- sin )  reduce  ticks>rad  (sin)  swap  if  negate  then  ;
: cos  ( ticks -- cos )  pi/2-ticks +  sin  ;
\  : tan  ( ticks -- tan )
\    dup sin  swap cos ?dup  if  100 swap */  else  drop maxint  then
\ ;

hex
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
