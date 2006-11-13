\ See license at end of file
purpose: Quadruple-number arithmetic

headers

/n 4 * constant /q

: q!  ( q a -- )  /q  bounds  do  i !  /n +loop  ;
: q@  ( a -- q )  0 3  do  dup i la+ @ swap  -1 +loop drop  ;

: q2*  ( q -- q*2 )
   d2*  2over  d0<  if  swap 1+ swap  then  2swap  d2*  2swap
;

: q+  ( q1 q2 -- q1+q2 )
					( d1.l d1.h d2.l d2.h )
   drot d+				( d1.l d2.l d2.h+d1.h )
   -drot 2dup 2>r d+ 2dup 2>r	( d2.h+d1.h d1.l+d2.l )  ( r: d2.l d1.l+d2.l )
   2swap			( d1.l+d2.l d2.h+d1.h )  ( r: d2.l d1.l+d2.l )
   2r> 2r> du<  if  1 0 d+  then	( d1.l+d2.l d2.h+d1.h' )
;

: qnegate  ( q -- -q )
					( d1.l d2.h )
   dinvert 2>r				( d1.l )  ( r: d2.hXORf )
   2dup d0=  if
      2r> 1 0 d+			( d1.l d2.hXORf+1 )
   else
      dinvert 1 0 d+ 2r>		( d1.lXORf+1 d2.hXORf )
   then
;

: q-  ( q1 q2 -- q1-q2 )  qnegate q+  ;  

\ Let b a d c on stack on entry
\     q_d1*d2 = z y x w on stack on exit
\ Then z = b*d.l
\      y = (b*d.h + a*d.l + c*b.l).l
\      x = (c*a.l + a*d.h + c*b.h + (b*d.h + a*d.l + c*b.l).h).l
\      w = c*a.h + (c*a.l + a*d.h + c*b.h + (b*d.h + a*d.l + c*b.l).h).h
: ud*  ( d1 d2 -- q_d1*d2 )
   2>r swap 2r> swap		( a b c d )
   2over			( a b c d a b )
   2 pick			( a b c d a b d )
   um* 2>r			( a b c d a )  ( r: z bd.h )
   um* >r >r			( a b c )  ( r: z bd.h ad.h ad.l )
   tuck				( a c b c )  ( r: z bd.h ad.h ad.l )
   um* >r >r			( a c )  ( r: z bd.h ad.h ad.l bc.h bc.l )
   um* swap			( ac.h ac.l ) ( r: z bd.h ad.h ad.l bc.h bc.l )
   2r> 2r> r>			( ac.h ac.l bc.h bc.l ad.h ad.l bd.h ) ( r: z )
   0 tuck d+			( ac.h ac.l bc.h bc.l ad.h ad.l+bd.h ) ( r: z )
   3 roll 0 d+ 2>r		( ac.h ac.l bc.h ad.h )  ( r: z y y.h )
   0 tuck d+ rot 0 d+ r> 0 d+	( ac.h x x.h )  ( r: z y )
   rot +			( x w )  ( r: z y )
   2r> 2swap			( z y x w )
;

: ?dsign-abs  ( d1 d2 -- |d1| |d2| negative? )
   2dup d0<  dup >r  if  dnegate  then  2swap
   2dup d0<  dup >r  if  dnegate  then  2swap
   2r> xor
;

: d*  ( d1 d2 -- q_d1*d2 )  ?dsign-abs >r  ud*  r>  if  qnegate  then  ;

\ Let b a c on stack on entry
\     q_d1*n2 = z y x w on stack on exit
\ Then z = b*c.l
\      y = (b*c.h + a*c.l).l
\      x = (a*c.h + (b*c.h + a*c.l).h).l
\      w = (a*c.h + (b*c.h + a*c.l).h).h
[ifndef] udn*
: udn*  ( d1 n2 -- q_d1*d2 )
				( b a c )
   rot over um*			( a c b*c.l b*c.h )
   2swap			( z b*c.h a c )
   um* -rot			( z a*c.h b*c.h a*c.l )
   0 tuck d+			( z a*c.h y y.h )
   rot 0 tuck d+		( z y x w )
;
[then]

: ?dnsign-abs  ( d1 n2 -- |d1| |n2| negative? )
   dup  0<  dup >r  if  negate  then  -rot
   2dup d0< dup >r  if  dnegate  then  rot
   2r> xor
;

: dn*  ( d1 n2 -- q_d1*n2 )  ?dnsign-abs >r  udn*  r>  if  qnegate  then  ;

0 [if]
: d/  ( d1 d2 -- d1/d2 )  ( to be implemented )  2drop  ;
[then]

headers
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
