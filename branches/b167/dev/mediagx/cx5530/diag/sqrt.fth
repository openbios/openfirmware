\ See license at end of file
purpose: Sq and sqrt methods

headers
decimal

\ *********************************************************************************
\ Let N = the 64-bit radicand
\     r = the 32-bit root under construction, initially zero
\     b = the binary place value of the rot bit to be found (initially h# 8000.0000,
\         always a power of 2)
\ Then, for each value of b from h# 8000.0000 down to 1, do:
\     If  (r+b)**2 <= N  then  add b to r
\ In this approach, b is the only quantity that gets shifted.
\ Now, simple algebra rewrites the condition as:
\     b (2r+b)  <=  N - r**2
\ The changing value N - r**2 is our partial remainder.
\ *********************************************************************************

\ Compute easy bits
: easy-bits  ( d.rem proot count -- d.rem' proot' )
   0 do				( d.rem proot )
      >r d2* d2*		( d.rem' )  ( r: proot )
      r@ - dup 0<  if		( d.rem' )  ( r: proot )
         r@ + r> 2* 1-		( d.rem' proot' )	\ restore d.rem & set 0
      else
         r> 2* 3 +		( d.rem proot' )	\ set 1
      then
   loop
;

\ Compute 1 hard bit
: 2's-bit  ( d.rem proot -- d.rem' proot )
   >r d2* dup 0<  if		( d.rem' )  ( r: proot )
      d2* r@ - r> 1+		( d.rem' proot' )	\ set 1
   else				( d.rem' )  ( r: proot )
      d2* r@ 2dup u<  if	( d.rem' proot )  ( r: proot )
         drop  r> 1-		( d.rem proot' )	\ set 0
      else
         - r> 1+		( d.rem' proot' )	\ set 1
      then
   then
;

\ Compute last bit
: 1's-bit  ( d.rem proot -- fullroot )
   >r  dup 0<  if		( d.rem )  ( r: proot )
      2drop  r> 1+		( fullroot )
   else				( d.rem )  ( r: proot )
      d2* h# 8000.0000 r@ du<  if  0  else  1  then  r> +	( fullroot )
   then
;

\ Put it all together
: sqrt  ( ud -- uroot )
   0 1 16 easy-bits		( d.lo rem.hi rem.lo proot )
   rot drop 14 easy-bits	( rem.lo' rem.hi' proot' )
   2's-bit			( rem.lo' rem.hi' proot' )
   1's-bit			( uroot )
;

: sq  ( s -- d )  dup m*  ;

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
