\ See license at end of file
purpose: Linear feedback shift register memory tests

[ifdef] arm-assembler
code lfsr-fill ( adr seed polynomial -- adr' )
   \ tos:polynomial
   ldmia  sp!,{r0,r1}   \ r0:seed r1:adr
   mov  r2,r0           \ r2:lfsr
   begin
      str   r2,[r1],#4
      movs  r2,r2,lsr #1
      eorcs r2,r2,tos
      cmp   r2,r0
   = until
   mov tos,r1
c;
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
[then]
: round-up-log2  ( n -- log2 )
   dup log2              ( n log2 )
   tuck  1 swap lshift   ( log2 n 2^log2 )
   > -                   ( log2' )
;

defer .lfsr-mem-error
: (.lfsr-mem-error)  ( adr len data index remain -- adr len data index remain )
   push-hex
   ." Error at address "  4 pick  2 pick la+  dup 8 u.r  ( adr len data index remain err-adr )
   ."  - expected " 3 pick 8 u.r  ( adr len data index remain err-adr )
   ."  got " l@ 8 u.r cr
   pop-base
;
' (.lfsr-mem-error) to .lfsr-mem-error

: random-test  ( adr len -- )
   dup /l <=  if  2drop exit  then ( adr len #bits )
   dup /l / round-up-log2          ( adr len #bits )
   polynomials swap la+ l@         ( adr len polynomial )

   3dup 1 1 rot random-fill        ( adr len polynomial )

   >r                              ( adr len  r: polynomial )
   1 1  third /l / 1-              ( adr len data index remain  r: polynomial )
   begin                           ( adr len data index remain  r: polynomial )
      r@ random-check              ( false | adr len data index remain true  r: polynomial )
   while                           ( adr len data index remain  r: polynomial )
      .lfsr-mem-error              ( adr len data index remain  r: polynomial )
   repeat                          ( r: polynomial )
   r> drop
;

\ LICENSE_BEGIN
\ Copyright (c) 2010 FirmWorks
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
