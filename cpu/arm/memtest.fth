purpose: Memory test primitives in assembly language
\ See license at end of file

headers
\needs mask  nuser mask  mask on
headerless

\ Report the progress through low-level tests
0 0 2value test-name
: (quiet-show-status)  ( adr len -- )  to test-name  ;

defer show-status
' type to show-status

code lfill  ( adr len l -- )
				\ tos: pattern
   ldmia   sp!,{r0,r1}		\ r0: len, r1: adr

   ahead begin			\ Fill
      str     tos,[r0,r1]
   but then
      decs    r0,1cell
   0< until

   pop   tos,sp
c;

code masked-ltest  ( adr len l mask -- error? )
   mov     r4,tos		\ r4: mask
   ldmia   sp!,{r0,r1,r2}	\ r0: l, r1: len, r2: adr
   and     r0,r0,r4		\ Mask l
   mvn     tos,#0		\ tos: failure code (in case of mismatch)

   ahead begin			\ Test
      ldr     r3,[r2,r1]		\ Get data from memory
      and     r3,r3,r4		\ mask memory data
      cmp     r3,r0		\ Test under mask
      nxtne			\ Exit if mismatch
   but then
      decs    r1,1cell
   0< until

   mov  tos,#0
c;

: mem-bits-test  ( membase memsize -- fail-status )
   "     Data bits test" show-status
   2dup  h# 5a5a5a5a  lfill
   2dup  h# 5a5a5a5a  mask @  masked-ltest  if  2drop true  exit  then

   2dup  h# a5a5a5a5  lfill
         h# a5a5a5a5  mask @  masked-ltest
;

code afill  ( adr len -- )
   pop    r0,sp			\ tos: len, r0: adr

   ahead begin			\ Fill
      add     r1,r0,tos		\ Compute address
      str     r1,[r0,tos]	\ Store it at the location
   but then
      decs    tos,1cell		\ Decrement index
   0< until

   pop   tos,sp
c;

code masked-atest  ( adr len mask -- mismatch? )
   mov     r4,tos		\ r4: mask
   ldmia   sp!,{r0,r1}		\ r0: len, r1: adr
   mvn     tos,#0		\ tos: failure code (in case of mismatch)

   ahead begin			\ Check
      add     r2,r0,r1		\ Compute pattern
      and     r2,r2,r4		\ under mask
      ldr     r3,[r0,r1]	\ Get data from memory
      and     r3,r3,r4		\ under mask
      cmp     r3,r2		\ Compare
      nxtne			\ Exit if mismatch
   but then
      decs    r0,1cell
   0< until

   mov     tos,#0
c;

: address=data-test  ( membase memsize -- status )
   "     Address=data test" show-status

   2dup afill  mask @ masked-atest
;

code random-fill  ( adr len data index polynomial -- )
   ldmia sp!,{r1,r2,r3,r4}  \ tos:poly r1:index r2:data r3:len r4:adr

   movs  r3,r3,lsr #2    \ Convert to longword count
   nxteq

   sub   r0,r3,#1         \ r0:remaining count
   
   \ r3:address-lfsr r4:data-lfsr r5:data-poly
   set r5,#0x80200003  \ 32-bit polynomial

   begin
      \ Compute new data value with an LFSR step
      movs  r2,r2,lsr #1
      eorcs r2,r2,r5

      \ Compute new address index, discarding values >= len
      begin
	 movs  r1,r1,lsr #1
	 eorcs r1,r1,tos
         cmp   r1,r3
      u< until

      \ Write the "random" value to the "random" address (adr[index])
      str  r2,[r4,r1,lsl #2]

      decs  r0,#1
   0= until   

   pop tos,sp
c;
code random-check  ( adr len data index remain polynomial -- false | adr len data index remain true )
   ldmia sp!,{r0,r1,r2,r3,r4}  \ tos:poly r0:remain  r1:index r2:data r3:len r4:adr

   cmp     r0,#0
   moveq   tos,#0  \ Return false
   nxteq

   mov   r7,r3,lsr #2    \ Convert to longword count

   set r5,#0x80200003  \ 32-bit polynomial

   begin
      \ Compute new data value with an LFSR step
      movs  r2,r2,lsr #1
      eorcs r2,r2,r5

      \ Compute new address index, discarding values >= len
      begin
	 movs  r1,r1,lsr #1
	 eorcs r1,r1,tos
         cmp   r1,r7
      u< until

      \ Read the value at the "random" address (adr[index])
      ldr  r6,[r4,r1,lsl #2]

      \ Compare it to the calculated value
      cmp  r6,r2

      decne   r0,#1
      stmnedb sp!,{r0,r1,r2,r3,r4}  \ Push results
      mvnne   tos,#0    \ True on top of stack
      nxtne

      decs  r0,#1
   0= until   

   mov tos,#0
c;

\ Polynomials for maximal length LFSRs for different bit lengths
\ The values come from the Wikipedia article for Linear Feedback Shift Register and from
\ http://www.xilinx.com/support/documentation/application_notes/xapp052.pdf
create polynomials \ #bits   period
h#        0 ,      \     0        0
h#        1 ,      \     1        1
h#        3 ,      \     2        3
h#        6 ,      \     3        7
h#        c ,      \     4        f
h#       14 ,      \     5       1f
h#       30 ,      \     6       3f
h#       60 ,      \     7       7f
h#       b8 ,      \     8       ff
h#      110 ,      \     9      1ff
h#      240 ,      \    10      3ff
h#      500 ,      \    11      7ff
h#      e08 ,      \    12      fff
h#     1c80 ,      \    13     1fff
h#     3802 ,      \    14     3fff
h#     6000 ,      \    15     7fff
h#     b400 ,      \    16     ffff
h#    12000 ,      \    17    1ffff
h#    20400 ,      \    18    3ffff
h#    72000 ,      \    19    7ffff
h#    90000 ,      \    20    fffff
h#   140000 ,      \    21   1fffff
h#   300000 ,      \    22   3fffff
h#   420000 ,      \    23   7fffff
h#   e10000 ,      \    24   ffffff
h#  1200000 ,      \    25  1ffffff
h#  2000023 ,      \    26  3ffffff
h#  4000013 ,      \    27  7ffffff
h#  9000000 ,      \    28  fffffff
h# 14000000 ,      \    29 1fffffff
h# 20000029 ,      \    30 3fffffff
h# 48000000 ,      \    31 7fffffff
h# 80200003 ,      \    32 ffffffff

: round-up-log2  ( n -- log2 )
   dup log2              ( n log2 )
   tuck  1 swap lshift   ( log2 n 2^log2 )
   > -                   ( log2' )
;

defer .lfsr-mem-error
: (.lfsr-mem-error)  ( adr len data index remain -- adr len data index remain )
   push-hex
   ??cr
   ." Error at address "  4 pick  2 pick la+  dup 8 u.r  ( adr len data index remain err-adr )
   ."  - expected " 3 pick 8 u.r  ( adr len data index remain err-adr )
   ."  got " l@ 8 u.r cr
   pop-base
;
' (.lfsr-mem-error) to .lfsr-mem-error
: throw-lfsr-error  ( adr len data index remain -- <thrown> )
   (.lfsr-mem-error)  -1 throw
;

: (random-test)  ( adr len -- )
   dup /l <=  if  2drop exit  then ( adr len #bits )
   dup /l / round-up-log2          ( adr len #bits )
   polynomials swap la+ l@         ( adr len polynomial )

   3dup 1 1 rot random-fill        ( adr len polynomial )

   >r                              ( adr len  r: polynomial )
   1 1  2 pick /l / 1-             ( adr len data index remain  r: polynomial )
   begin                           ( adr len data index remain  r: polynomial )
      r@ random-check              ( false | adr len data index remain true  r: polynomial )
   while                           ( adr len data index remain  r: polynomial )
      .lfsr-mem-error              ( adr len data index remain  r: polynomial )
   repeat                          ( r: polynomial )
   r> drop
;

\ Not truly random - uses LFSR sequences
: random-test  ( adr len -- error? )
   "     Random address and data test" show-status

   ['] throw-lfsr-error to .lfsr-mem-error
   ['] (random-test) catch  if
      2drop true
   else
      false
   then
;

\ LICENSE_BEGIN
\ Copyright (c) 1997 FirmWorks
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
