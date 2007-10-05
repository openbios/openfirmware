\ CAFE NAND error correction
\ See license at end of file.

hex

: array!  ( value index adr -- )  swap wa+ w!  ;
: array@  ( index adr -- value )  swap wa+ w@  ;

\ Split or join a number, size of low half is n bits.
: #split ( x n -- x.lo x.hi )
   2dup rshift    ( x n x.hi )
   tuck >r        ( x x.hi n r: x.hi )
   lshift xor     ( x.lo r: x.hi )
   r>             ( x.lo x.hi )
;
: #join  ( x.lo x.hi n -- x )  lshift or  ;


\ The fields we use.  0 represents 0, 1 represents 1.

\ Finite field of 64 elements: K := F_2[X]/(X**6+X+1)
\ X**n is represented by bit value 2**n
[ifdef] 386-assembler
code K*  ( a b -- a*b )
   dx dx xor          \ Result in DX
   bx pop  ax pop     \ b in BX, a in AX

   6 # cx mov         \ Loop count in CX
   begin
      \ Accumulate B if low bit of a is set
      1 # al test  0<>  if  bx dx xor  then

      \ Square B to give B'
      bx bx add  h# 40 # bx test  0<>  if  h# 43 # bx xor  then

      \ Shift out low bit of A
      1 # ax shr
   loopne
   dx push
c;
[then]

[ifndef] k*
\ This is "bit banging multiplication" with GF arithmetic
: K*  ( a b -- a*b )
   0 -rot   6 0  do                            ( res a b )
      \ Accumulate B if low bit of A is set
      over 1 and  if  rot over xor -rot  then  ( res' a b )
      swap 2/ swap                             ( res a' b )  \ Next A bit
      2*  dup h# 40 and  if  h# 43 xor  then   ( res a' b' ) \ "Square" B
   loop                                        ( res a b )
   2drop                                       ( a*b )
;
[then]

[ifdef] notdef  \ Segher's original version
: KX*  ( a -- aX )  2*  dup h# 40 and  if  h# 43 xor  then  ;

: K*  ( a b -- a*b )
   0  6 0  do         ( a b res )
      >r tuck         ( b a b       r: res )
      KX* >r          ( b a         r: res bX )
      1 #split >r     ( b a.lobit   r: res bX a.hi )
      0<> and         ( b'          r: res bX a.hi )
      r> r> rot       ( a.hi bX b'  r: res )
      r> xor          ( a.hi bX res' )
   loop               ( a.hi bX res )
   nip nip            ( a*b )
;
[then]

\ Finite field of 4096 elements: L := K[X]/(X**2+X+A**-1)
\ with A the generator of K; aX+b is represented as 64a+b
\ This is place-value multiplication, GF style
: L*  ( a b -- a*b )
   over 6 #split xor       ( a b a' )
   over 6 #split xor       ( a b a' b' )
   K* >r >r                ( a r: a'*b' b )
   6 #split                ( a.lo a.hi  r: a'*b' b )
   r> 6 #split             ( a.lo a.hi  b.lo b.hi  r: a'*b' )
   rot K*                  ( a.lo b.lo  a.hi*b.hi  r: a'*b' )
   h# 21 K* >r             ( a.lo b.lo  r: a'*b' a.hi*b.hi*21 )
   K* dup r>               ( a.lo*b.lo  a.lo*b.lo  a.hi*b.hi*21  r: a'*b' )
   xor swap                ( hi a.lo*b.lo  r: a'*b' )
   r> xor                  ( hi a.lo*b.lo^a'*b' )
   6 #join                 ( a*b )
;

\ Inverse of 0 gives 0; this simplifies some algorithms
: Linv  ( a -- a**-1 )  dup  d# 10 0  do  2dup L*  L*  loop  dup L*  nip  ;


\ Polynomials.  Element i represents the X**i term, there are always 9 terms.

\ Find the degree of a polynomial.  The degree of the 0 polynomial is 0.
: poly-deg  ( poly -- )
   0  9 1  do                           ( 'poly degree )
      over i wa+ w@  if  drop i  then   ( 'poly degree' )
   loop                                 ( 'poly degree )
   nip                                  ( degree )
;

\ Set poly to multiplicative identity.
: poly-set-unity  ( poly -- )  dup 9 /w* erase  1 swap !  ;


\
\ Find the error locator polynomial by using the Berlekamp-Massey algorithm.
\

9 /w* buffer: _l   \ Error locator polynomial - Lambda
9 /w* buffer: _b   \ BM b polynomial

: discrepancy  ( syndrome len -- discr )
   tuck                   ( len syndrome len )
   1- wa+                 ( len end-adr )
   0                      ( len end-adr  acc )
   rot  0  do             ( end-adr  acc )
      over i /w* - @      ( end-adr  acc  syndrome-data )
      i _l array@ L*      ( end-adr  acc  syndrome*locator )
      xor                 ( end-adr  acc' )
   loop                   ( end-adr  acc )
   nip                    ( discr )
;

: bm-step-even  ( discr r -- )
   0  swap 1+  0  do                 ( discr acc  )
      2dup L*                        ( discr acc  discr*acc )
      i _l array@  xor  i _l array!  ( discr acc )
      i _b array@  swap i _b array!  ( discr acc' )
   loop 2drop                        ( )
;
: bm-step-odd  ( discr r -- )
   0  swap 1+  0  do                       ( discr acc )
      over L*                              ( discr acc' )
      i _l array@ tuck xor   i _l array!   ( discr acc' )
      over Linv L*                         ( discr acc' )
      i _b array@  swap i _b array!        ( discr acc' )
   loop 2drop                              ( )
;
: bm-step  ( discr r -- )
   dup  1 and  if  bm-step-odd  else  bm-step-even  then
;

: berlekamp-massey  ( syndrome -- )  \ Leaves the result in _l
   _l poly-set-unity           ( syndrome )
   _b poly-set-unity           ( syndrome )
   9 1  do                     ( syndrome )
      dup i discrepancy        ( syndrome discrepancy )
      i bm-step                ( syndrome )
   loop drop                   ( )
;

\ Solving the error locator polynomial

\ The roots of the locator polynomial.
variable nroots
4 /w* buffer: roots

\ Evaluate the locator polynomial at given point.
: eval-l  ( x -- l )
   0  9 0  do            ( x acc )
      over L*            ( x acc' )
      8 i - _l array@    ( x acc locator )
      xor                ( x acc' )
   loop nip              ( l )
;

: solve-locator ( -- unsolvable? )
   _l poly-deg   dup nroots !      ( degree )
   dup 0=  if  drop true exit  then   \ paranoia

   \ special case for degree one polynomials
   1 =  if  1 _l array@ Linv  roots !  0 exit  then

   \ Otherwise we use the brute force approach of evaluating at every
   \ possible point; the ones that evaluate to 0 are roots.
   \ This is slow, but should happen extremely rarely in practice.
   0   h# 1000 0  do             ( root# )
      i eval-l  0=  if           ( root# )
         i  over roots array!    ( root# )
         1+                      ( root#' )
      then                       ( root# )
   loop                          ( root# )
   nroots @ <>                   ( unsolvable? )
;

\ Finding the errors.

\ Error evaluator polynomial.
4 /w* buffer: _o  \ Omega
: compute-evaluator  ( syndrome -- )
   4 0  do                     ( syndrome )
      dup  i 1+  discrepancy   ( syndrome discrepancy )
      i _o array!              ( syndrome )
   loop  drop                  ( )
;

\ Error values per root.
: compute-num  ( root -- num )
   dup Linv                       ( root root**-1 )
   0   4 0  do                    ( root root**n  num )
      over  i _o array@  L*       ( root root**n  num  _o*root**n )
      xor                         ( root root**n  num' )
      >r  over L*  r>             ( root root**n' num' )
   loop                           ( root root**n' num' )
   nip nip                        ( num )
;
: compute-den  ( root -- den )
   dup L*                         ( r )  \ r is root**2
   1 0                            ( r 1 den=0 )
   4 0  do                        ( r r**n  den )
      \ Accumulate the odd elements of the locator array
      over  i 2* 1+ _l array@ L*  ( r r**n  den locator*r**n )
      xor                         ( r r**n  den' )
      >r   over L*   r>           ( r r**n' den' )
   loop                           ( r r**n  den )
   nip nip                        ( den )
;
: compute-error  ( root -- error )
   dup compute-num   ( root num )
   swap compute-den  ( num den )
   Linv L*           ( num/den )
;

h# e01 constant alpha
\ Error location.
: compute-location  ( root -- loc )
   >r 1  alpha                 ( loc  alpha**n  r: root )
   begin  dup r@ <>  while     ( loc  alpha**n  r: root )
      swap 1+  swap alpha L*   ( loc' alpha**n' r: root )
   repeat                      ( loc' alpha**n' r: root )

   \ Segher says:
   \ aa1 is a fudge factor to make the code indices line up with
   \ the data block.  The data is actually numbered from the
   \ right, including the parity data.  The roots of the locator
   \ polynomial are the inverse of the data locations, so their
   \ logarithm (computed just above) is the negative of element
   \ inidces.  The leftmost byte of the data is index h# 555,
   \ so "h# aa1 -" does the whole mapping.
   r> 2drop  h# aa1 -          ( loc )
;

[ifdef] later
: compute-location  ( root -- loc )
   alpha  0  h# aa0  do                       ( root alpha**n )
      2dup =  if  2drop i unloop exit  then   ( root alpha**n )
      alpha L*                                ( root alpha**n' )
   -1 +loop                                   ( root alpha**n' )
   2drop  -1   
;
[then]

\ Correct the errors.
: xor-it  ( x c-addr -- )  tuck c@  xor  swap c!  ;

\ The "locs" below are indices into an array of 12-bit numbers.
\ The "values" below are 12-bit masks telling which bits to flip.

\ (fix-error) 
: (fix-error)  ( data-adr value loc -- )
   rot over 3 * 2 / +  >r     ( value loc  r: byte-adr )

   \ If loc is 0, XOR the low 8 bits of the 12-bit value with the first byte
   \ The other 4 bits (which are 0) would be for the nibble before start-of-buffer

   dup 0=  if                 ( value loc  r: byte-adr )
      drop r>  xor-it  exit
   then                       ( value loc  r: byte-adr )

   \ If loc is 555, XOR the high 8 bit of the 12-bit value with the last byte
   \ The other 4 bits would be for the nibble after end-of-buffer (in the
   \ parity data).
   dup  h# 555 =  if
      drop  4 rshift r> xor-it  exit
   then                       ( value loc  r: byte-adr )

   1 and  if                  ( value  r: byte-adr )
      \ XOR with the bytes at adr and adr+1
      dup 4 rshift            ( value value.hi  r: byte-adr )
      r@ xor-it               ( value  r: byte-adr )
      4 lshift                ( value.lo  r: byte-adr )
      r> 1+ xor-it            ( )
   else                       ( value loc  r: byte-adr )
      \ XOR with the bytes at adr and adr-1
      dup 8 rshift            ( value value.hi  r: byte-adr )
      r@ 1- xor-it            ( value  r: byte-adr )
      r> xor-it               ( )
   then                       ( )
;

: fix-error  ( data value loc -- uncorrectable? )
   \ Impossible locations or values mean uncorrectable errors happened.
   dup h# 55e u>  if  3drop true exit  then       ( data value loc )

\ The use of "u>" above takes care of this possibility
\  dup 0<  if  3drop true exit  then              ( data value loc )

   dup 0=  if                                     ( data value loc )
      over h# f00 and  if  3drop true exit  then  ( data value loc )
   then                                           ( data value loc )

   \ If the error is in out-of-band data, there is nothing to do.
   dup h# 555 >  if  3drop false exit  then       ( data value loc )

   (fix-error) false                              ( uncorrectable? )
;

: fix-errors  ( data -- uncorrectable? )
   nroots @  0  do              ( data )
      dup  i roots array@       ( data  data root )
      dup compute-error         ( data  data root value )
      swap compute-location     ( data  data value loc )
      fix-error  if             ( data )
         drop true unloop exit
      then                      ( data )
   loop                         ( data )
   drop  false                  ( uncorrectable? )
;

\ The only entry point for the whole thing.  Syndromes is an array of cells,
\ data is at 2048 byte block.
: correct-ecc  ( data syndrome -- uncorrectable? )
   dup berlekamp-massey                       ( data syndrome )
   solve-locator  if  2drop true exit  then   ( data syndrome )
   compute-evaluator                          ( data )
   fix-errors                                 ( uncorrectable? )
;

[ifdef] notdef
\ Test vectors
CREATE s1  001 w, 6c6 w, 291 w, d91 w, 1ef w, e26 w, a19 w, 8c0 w,
CREATE s2  0f8 w, de1 w, 5e5 w, 287 w, 566 w, 756 w, f5f w, 253 w,
CREATE s3  001 w, 001 w, 001 w, 001 w, 001 w, 001 w, 001 w, 001 w,
CREATE s4  41e w, b7a w, 37c w, 885 w, c32 w, a87 w, 218 w, b08 w,


: #aligned negate swap negate and negate ;
: #align here swap #aligned here - allot ; 

1000 #align  here 800 allot CONSTANT data


\ Testing utility stuff -- only used for debug, remove...

: 0.r  0 swap <# 0 ?DO # LOOP #> 2dup lower type ;
: .L  3 0.r space ;

\ Print terms, dropping leading zeroes.
: .poly ( poly -- )  dup poly-deg 1+ 0 DO  i over array@ .L LOOP drop  ;

: tt
  cr ." syn: " dup .poly
  dup berlekamp-massey
  cr ." locator: " _l .poly
  solve-locator if cr ." unsolvable" exit then
  cr nroots ? ." roots: " nroots @ 0 do  i roots array@ .  loop
  compute-evaluator
  cr ." omega: " 4 0 do i _o array@ .l loop
  cr ." errors: " nroots @ 0 do  i roots array@ dup compute-error 3 0.r
  compute-location ." @" u. loop
;

: t  ( syndrome -- )
  data 800 erase  data swap correct-ecc if cr ." Uncorrectable!"
  else data 800 dump then
;
\ Expected results:

ok s1 tt
syn: 001 6c6 291 d91 1ef e26 a19 8c0 3aa
locator: 001 6c6
1 roots: 2db
omega: 001 000 000 000
errors: 001@0 

ok s2 tt
syn: 0f8 de1 5e5 287 566 756 f5f 253 ???
locator: 001 6c6
1 roots: 2db
omega: 0f8 000 000 000
errors: 0f8@0

ok s3 tt
syn: 001 001 001 001 001 001 001 001 ???
locator: 001 001
1 roots: 1
omega: 001 000 000 000
errors: 001@55e

ok s4 tt
syn: 41e b7a 37c 885 c32 a87 218 b08 ???
locator: 001 ade e67 e84 e7c
4 roots: 1fa 3e1 913 b11
omega: 41e b36 321 7f2
errors: 00e@48e e00@3c8 010@1a5 a00@fa

ok s1 t
01 at offset 0, all else 0

ok s2 t
f8 at offset 0, all else 0

ok s3 t
all 0 (error is in the check bytes)

ok s4 t
0a at 176, 01 at 277, 0e at 5ab, 0e at 6d5

[then]

\ LICENSE_BEGIN
\ Copyright 2007  Segher Boessenkool  <segher@kernel.crashing.org>
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
