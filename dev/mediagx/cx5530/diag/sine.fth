\ See license at end of file
purpose: Sin, cos and tan methods

headers
decimal

\ *********************************************************************************
\ The Taylor-Maclaurin Series for the sine is:
\    sin(x) = x - x**3/3! + x**5/5! - x**7/7! + x**9/9! + ...
\ where x is some angle in radians ( 180 degrees = pi radians ).
\ The error, when x**9/9! is included is 0.0004%.  Therefore,
\ we factor out the above series into:
\    sin(x) ~ x ( 1 - x**2/6 ( 1 - x**2/20 ( 1 - x**2/42 ( 1 - x**2/72 ) ) ) )
\ The radians and results are 16-bit scaled.
\ *********************************************************************************

10,000 constant 10k	\ The scaling constant
0 value xs		\ The square of the scaled angle

\ mixed-precision with rounding
: u16*r  ( a b -- c )
   m* 16 lshift  over 16 rshift or  swap  16 lshift 0<  if  1+  then
;

\ Compute y' = xs/divisor (1 - y)
\ using the algebraic equivalent
\              xs/divisor  - y*xs/divisor
: taylor  ( xs y divisor -- xs y' )
   2 pick swap /    ( xs y xs/divisor )
   tuck u16*r       ( xs xs/divisor y*xs/divisor )
   -                ( xs y' )
;
: (sin)  ( +x -- y )
   dup dup u16*r	( x xs )
   0                    ( x xs y0 )
   110 taylor           ( x xs y=x**2/110 )
    72 taylor		( x xs y'=x**2/72[1-y] )
    42 taylor		( x xs y'=x**2/42[1-y] )
    20 taylor		( x xs y'=x**2/20[1-y] )
     6 taylor		( x xs y'=x**2/6[1-y] )
   nip                  ( x y'=x**2/6[1-y] )

   \ Up to this point, we have always been operating on positive numbers,
   \ because x**2 is non-negative.  We want the result to be symmetrical
   \ about 0, but s16* truncates toward 0 for positive numbers and toward
   \ negative infinity for negative numbers, which introduces an asymmetry.
   \ We cope with that by doing the final operation on the absolute value
   \ of x, then negating the result if necessary.
   over 0<  if          ( x y' )
      swap negate       ( y' |x| )
      tuck u16*r -      ( |y| )
      negate            ( y )
   else                 ( x y' )
      over u16*r -      ( y )
   then                 ( y )
;

: ?mirror  ( 0-180 -- 0-90-0 )
   dup 90 >  if  180 swap -  then
;

: reduce  ( degree -- -90-90 )
   360 mod  dup 0<  if  360 +  then
   dup 180 <  if  ?mirror  else  180 - ?mirror negate  then
;

: deg>rad ( degree -- scaled-radian )  16 lshift  1,745,329 m* 100,000,000 sm/rem nip  ;
: sin  ( degree -- sin )  reduce  deg>rad  (sin)  ;
: cos  ( degree -- cos )  360 mod 90 swap -  sin  ;
: tan  ( degree -- tan )  dup sin swap cos ?dup  if  100 swap */  else 3 *  then  ;

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
