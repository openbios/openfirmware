\ See license at end of file
purpose: FFT and IFFT operations  (scale 16-bits)

headers
hex

bit/fraction d# 16 =  [if]
h# 3.243f constant pi		\ pi scaled 16 bits
h# 1.921f constant pi/2		\ pi/2 scaled 16 bits
[else]
h# c90f.daa3 constant pi	\ pi scaled 30 bits
h# 6487.ed51 constant pi/2	\ pi/2 scaled 30 bits
[then]
0 value #xvect			\ number of entries in xvect
0 value xvect			\ vector base address
xhvariable u			\ complex angle counter
xhvariable w	        	\ complex angle increment
false value ifft?		\ FFT direction

: 'xvect  ( idx -- adr )  /x* xvect +  ;

\ Swap the two complex numbers in xvect indexed by i and j.
: xswapv  ( i j -- )
   'xvect swap 'xvect		( 'j 'i )
   2dup 2>r swap >r		( 'i )  ( r: 'j 'i 'j )
   x@ r> x@			( [i] [j] )  ( r: 'j 'i )
   r> x! r> x!			( )
;

\ Reorder the complex vector in preparation for the FFT.
: bit-reverse  ( -- )
   0 #xvect 0 do			( idx )
      dup i >  if  dup i xswapv  then	( idx )
      #xvect 2/ swap			( inc idx )
      begin
         2dup 2dup <= -rot + 0<> and  while	( inc idx )
         over - swap 2/ swap		( inc' idx' )
      repeat +				( idx' )
   loop drop				( )
;

\ Perform a butterfly computation on elements i and j of xvect.
\ The butterfly is in the form of:
\    x[j]=x[i]-x[j]*u
\    x[i]=x[i]+x[j]*u
\ If the direction is inverse, then the results are divided by 2.
: bfly  ( i j -- )
   'xvect swap 'xvect over >r >r	( 'j )  ( r: 'j 'i )
   x@ u xh@ x*xh			( [j]*[u] )  ( r: 'j 'i )
   r@ x@ xswap x2dup			( [i] [j]*[u] [i] [j]*[u] )  ( r: 'j 'i )
   x+  ifft?  if  x2/  then  r> x!	( [i] [j]*[u] )  ( r: 'j )
   x-  ifft?  if  x2/  then  r> x!	( )
;

\ Perform butterflies on xvect beginning at index start and adding
\ incr each time.  The butterfly is performed between index i and
\ i+incr/2, where i is the loop counter.
: inner-loop  ( start incr -- )
   tuck 2* -rot			( incr*2 incr start )
   #xvect swap ?do		( incr*2 incr )
      i 2dup +			( incr*2 incr i i+incr )
      bfly			( incr*2 incr )
   over +loop  2drop		( )
;

bits/cell 1- constant bits/cell-1
: 2**  ( n -- 2**n )
   0 max  bits/cell-1 min		\ limit n
   1 swap <<
;

\ Compute x = e**-i*pi/n, where x.i = -sin(pi/n)
\                               x.r = cos (pi/n) = sin(pi/2-pi/n)
: e-ipi/n  ( n -- xh )
   dup 1 =  if  drop 0 scaled-1  exit  then
   2/
   pi/2 over 1- + over / >r	( r: pi/n )
   pi/2 swap / 			( pi/n )  ( r: pi/n )
   (sin) negate			( -sin[pi/n] )  ( r: pi/n )
   pi/2 r> - (sin)	 	( -sin[pi/n] cos[pi/n] )
;

\ Outer loop of the FFT program.  Each loop sets the value of w and u
\ and controls the action of the inner loop.
: fft-kernel  ( -- )
   #xvect log2 0 do			\ For i=0 to log2[n]
      0 scaled-1 u xh!			\ Init u=1+0j
      i 2** dup e-ipi/n			\ Compute e**-i*pi/n, where n is 2**i
      ifft?  if  xh'  then  w xh!	\ If IFFT, take conjugate
      dup 0 ?do	    		   	( incr=2**i )
         i over inner-loop		( incr )
         w xh@ u xh@ xh* u xh!		( incr )
      loop drop				( )
   loop					( )
;

: init-fft  ( #xvect xvect ifft? -- )  to ifft?  to xvect  to #xvect  ;
: fft  ( #xvect xvect ifft? -- )  init-fft  bit-reverse  fft-kernel  ;


headers
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
