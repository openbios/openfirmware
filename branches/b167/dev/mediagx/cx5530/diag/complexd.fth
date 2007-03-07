\ See license at end of file
purpose: Complex data types and operations

headers
decimal

\ *********************************************************************************
\ Each complex number is composed of two distinct parts, real and imaginary.
\ In this implementation, the real part is always on the top of the stack and
\ the imaginary part underneath  ( d.i d.r ).  Each part is a double word.
\
\ Methods are defined to add, subtract, multiply and divide complex numbers:
\    x+  x-  x* x/
\ Other methods unique to complex numbers are magnitude and conjugation:
\    |x|  x'
\ The complex arithmetic functions x* and x/ operates on scaled numbers.
\ The scaling factor here is 2**16.
\ *********************************************************************************

4 /n* constant /x

alias xh@ 2@
alias xh! 2!
alias xhvariable 2variable

: xvariable  /x ualloc user  ;
: /x*  ( n -- n*/x )  /x *  ;
: xa+  ( a i -- 'a[i] )  /x* +  ;
: d>x  ( r.lo r.hi -- x )  0 0 2swap  ;

: x@  ( a -- x )  dup 2 na+ 2@ rot 2@  ;
: x!  ( x a -- )  dup >r 2!  r> 2 na+ 2!  ;

alias xdup 4dup
alias xdrop 4drop

: xswap  ( x1 x2 -- x2 x1 )  drot  2>r drot 2r>  ;
: xover  ( x1 x2 -- x1 x2 x1 )  xswap xdup 2>r 2>r xswap 2r> 2r>  ;
: xtuck  ( x1 x2 -- x2 x1 x2 )  xswap xover  ;
: x2dup  ( x1 x2 -- x1 x2 x1 x2 )  xover xover  ;

: x+  ( i1 r1 i2 r2 -- i1+i2 r1+r2 )  drot d+  2>r d+  2r>  ;
: x-  ( i1 r1 i2 r2 -- i1-i2 r1-r2 )  drot 2swap d-  2>r d-  2r>  ;
: x2/  ( i r -- i/2 r/2 )  2swap d2/ 2swap d2/  ;

\ The following functions are simplified and assumed that i and r can be
\ represented as 32.f.
: d**2   ( d.f -- q**2.f2 )        2dup d*  ;
: |x|^2  ( i r -- d.i**2+r**2.0 )  2>r d**2 2r> d**2 q+  q.f2>d.0  ;
: |x|    ( x -- n.mag_x.0 )        |x|^2 sqrt  ;

: x'   ( x -- x_conjugate )  2swap negate 2swap  ;
: xh'  ( xh -- xh_conjugate )  swap negate swap  ;

\ new=x1*x2  where new.i=r1*i2+i1*r2  new.r=r1*r2-i1*i2
: x*  ( x1 x2 -- scaled_x1*x2 )
   x2dup			( i1 r1 i2 r2 i1 r1 i2 r2 )
   drot d* q.f2>d.f	        ( i1 r1 i2 r2 i1 i2 r1*r2 )
   -drot d* q.f2>d.f d- 2>r	( i1 r1 i2 r2 )  ( r: r1*r2-i1*i2 )
   -drot d* q.f2>d.f		( i1 r2 r1*i2 )  ( r: r1*r2-i1*i2 )
   -drot d* q.f2>d.f d+ 2r>	( r1*i2+i1*r2 r1*r2-i1*i2 )
;
: xh*  ( xh1 xh2 -- scaled_xh1*xh2 )
   4dup				( i1 r1 i2 r2 i1 r1 i2 r2 )
   rot m*		        ( i1 r1 i2 r2 i1 i2 d.r1*r2 )
   2swap m* d- d.f2>n.f >r	( i1 r1 i2 r2 )  ( r: r1*r2-i1*i2 )
   -rot m*			( i1 r2 d.r1*i2 )  ( r: r1*r2-i1*i2 )
   2swap m* d+ d.f2>n.f r>	( r1*i2+i1*r2 r1*r2-i1*i2 )
;
: x*xh  ( x1 xh2 -- scaled_x1*xh2 )
   2>r xdup 2swap			( i1 r1 r1 i1 )  ( r: i2 r2 )
   r@ dn*				( i1 r1 r1 q.i1*r2 )  ( r: i2 r2 )
   drot 2r@ drop dn* q+ q.f2>d.f	( i1 r1 d.i1*r2+r1*i2 )  ( r: i2 r2 )
   -drot				( d.i1*r2+r1*i2 i1 r1 )  ( r: i2 r2 )
   r> dn*				( d.i1*r2+r1*i2 i1 q.r1*r2 )  ( r: i2 )
   drot r> dn* q- q.f2>d.f		( d.i1*r2+r1*i2 d.r1*r2-i1*i2 )
;

\ adrs x@ adrd x@ x* adrd x!
: x*!  ( adrs adrd -- )  tuck x@ rot x@ x* rot x!  ;

0 [if]
\ x1/x2 = (x1*x2')/(x2*x2')
\       = (x1*x2')/(x2.r**2+x2.i**2)
: x/  ( x1 x2 -- scaled_x1/x2 )
   xtuck x' x*			( i2 r2 x1*x2' )
   xswap |x|^2			( x1*x2' |x2|**2 )
   rot over d/			( x1*x2'.r |x2|**2 imaginary )
   -rot d/			( imaginary real )
;
[then]

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
