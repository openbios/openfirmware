\ See license at end of file
purpose: Complex data types and operations

headers
decimal

\ *********************************************************************************
\ Each complex number is composed of two distinct parts, real and imaginary.
\ In this implementation, the real part is always on the top of the stack and
\ the imaginary part underneath  ( x.i x.r ).  Each part is /n in size.
\
\ Methods are defined to add, subtract, multiply and divide complex numbers:
\    x+  x-  x* x/
\ Other methods unique to complex numbers are magnitude and conjugation:
\    |x|  x'
\ The complex arithmetic functions x* and x/ operates on scaled numbers.
\ The scaling factor here is 2**16.
\ *********************************************************************************

2 /n* constant /x
: /x*  ( n -- n*/x )  /x *  ;
: xa+  ( a i -- 'a[i] )  /x* +  ;

alias x@ 2@
alias x! 2!
alias xh@ x@
alias xh! x!

alias xvariable 2variable
alias xhvariable xvariable

alias xdup 2dup
alias xswap 2swap
alias xdrop 2drop
alias xover 2over
alias x2dup 4dup
: xtuck  ( x1 x2 -- x2 x1 x2 )  xswap xover  ;

: n>x  ( r -- x )  0 swap  ;
: x+  ( i1 r1 i2 r2 -- i1+i2 r1+r2 )  >r rot + swap r> +  ;
: x-  ( i1 r1 i2 r2 -- i1-i2 r1-r2 )  >r swap -rot - swap r> -  ;
: x2/  ( i r -- i/2 r/2 )  swap 2/ swap 2/  ;

: |x|^2  ( x - x.i**2+x.r**2.0 )  sq rot sq d+ nip 0  ;
: |x|    ( x -- mag_x.0 )         |x|^2 sqrt  ;

: x'  ( x -- x_conjugate )  swap negate swap  ;
alias xh' x'

\ new=x1*x2  where new.i=r1*i2+i1*r2  new.r=r1*r2-i1*r2
: x*  ( x1 x2 -- scaled_x1*x2 )
   4dup				( i1 r1 i2 r2 i1 r1 i2 r2 )
   rot s16*		        ( i1 r1 i2 r2 i1 i2 r1*r2 )
   -rot s16* - >r		( i1 r1 i2 r2 )  ( r: r1*r2-i1*i2 )
   -rot s16*			( i1 r2 r1*i2 )  ( r: r1*r2-i1*i2 )
   -rot s16* + r>		( r1*i2+i1*r2 r1*r2-i1*i2 )
;
alias xh* x*
alias x*xh x*

\ adrs x@ adrd x@ x* adrd x!
: x*!  ( adrs adrd -- )  tuck x@ rot x@ x* rot x!  ;

\ x1/x2 = (x1*x2')/(x2*x2')
\       = (x1*x2')/(x2.r**2+x2.i**2)
: x/  ( x1 x2 -- scaled_x1/x2 )
   xtuck x' x*			( i2 r2 x1*x2' )
   xswap |x|^2			( x1*x2' |x2|**2 )
   rot over /			( x1*x2'.r |x2|**2 imaginary )
   -rot /			( imaginary real )
;

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
