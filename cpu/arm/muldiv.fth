purpose: Multiply and divide
\ See license at end of file

[ifdef] fixme
0 value StrongARM?
[else]
0 value arm4?
[then]

hex
code *   ( n1 n2 -- n3 )  pop r0,sp  mul tos,r0,tos  c;
code u*	 ( u1 u2 -- u3 )  pop r0,sp  mul tos,r0,tos  c;

code um*  ( u1 u2 -- ud )
[ifdef] fixme
   ldr     r0,'user StrongARM?
[else]
   ldr     r0,'user arm4?
[then]
   cmp     r0,#0
   <> if
      pop     r4,sp
      umull   r1,r0,tos,r4
      psh     r1,sp
      mov     tos,r0
      next
   then
   mov     r6,#0xff
   orr     r6,r6,#0xff00
   and     r0,r6,tos		\ r0: lu2
   and     r1,r6,tos,lsr #0x10	\ r1: tu2
   ldr     tos,[sp]
   and     r2,r6,tos		\ r2: lu1
   and     r3,r6,tos,lsr #0x10 	\ r3: tu1

   mul     r4,r0,r2		\ low
   mul     r6,r0,r3		\ interm
   mul     tos,r1,r3		\ upper
   mul     r0,r1,r2		\ interm

   adds    r0,r0,r6
   inccs   tos#0x10000
   adds    r4,r4,r0,lsl #0x10
   adc     tos,tos,r0,lsr #0x10 		\ adding CARRY
   str     r4,[sp]
c;

code m*	 ( n1 n2 -- d )
[ifdef] fixme
   ldr     r0,'user StrongARM?
[else]
   ldr     r0,'user arm4?
[then]
   cmp     r0,#0
   <> if
      pop     r4,sp
      smull   r1,r0,tos,r4
      psh     r1,sp
      mov     tos,r0
      next
   then
   mov     r5,#0				\ clear change-sign flag
   mov     r6,#0xff
   orr     r6,r6,#0xff00
   cmps    tos,#0
   rsblt   tos,tos,#0
   mvnlt   r5,r5			\ setting flag
   and     r0,r6,tos		\ r0: lu2
   and     r1,r6,tos,lsr #0x10 	\ r1: tu2
   pop     tos,sp
   cmps    tos,#0
   rsblt   tos,tos,#0
   mvnlt   r5,r5
   and     r2,r6,tos		\ r2: lu1
   and     r3,r6,tos,lsr #0x10 	\ r3: tu1

   mul     r4,r0,r2		\ low
   mul     r6,r0,r3		\ interm
   mul     tos,r1,r3		\ upper
   mul     r0,r1,r2		\ interm

   adds    r0,r0,r6
   inccs   tos,#0x10000
   adds    r4,r4,r0,lsl #0x10
   adc     tos,tos,r0,lsr #0x10 		\ adding CARRY
   cmps    r5,#0
   <> if
      decs    r4,#1
      sbc     tos,tos,#0
      mvn     r4,r4
      mvn     tos,tos
   then
   psh     r4,sp
c;

\ (32/32division) does a 32/32bit unsigned division
\ r0 / tos =   r0.rem tos.quot
code  (32/32division)
   mov     r3,#1
   cmp     tos,#0
\		' divide-error	dolink eq branch
   mvneq   tos,#0
   moveq   pc,lk

   begin
      cmp     tos,#0x80000000
      cmpcc   tos,r0
      movcc   tos,tos,lsl #1
      movcc   r3,r3,lsl #1
   u>= until
   mov     r2,#0
   begin
      cmp     r0,tos
      subcs   r0,r0,tos
      addcs   r2,r2,r3
      movs    r3,r3,lsr #1
      movne   tos,tos,lsr #1
   0= until
   mov     tos,r2
   mov     pc,lk
end-code

code (u64division)
   orrs    r4,r2,r3
\  ' divide-error  bleq *
   mvneq   r4,#0  \ Max out quotient for divide by 0
   mvneq   r5,#0
   moveq   pc,lk

   stmdb   sp!,{r7,r8,r9}
   mov     r6,#0
   mov     r7,#1
   mov     r4,#0
   mov     r5,#0

   begin
      cmp     r2,#0x80000000
      u< if
         cmp     r2,r0
         cmpeq   r3,r1
         u< if
            mov     r2,r2,lsl #1
            orr     r2,r2,r3,lsr #0x1f
            mov     r3,r3,lsl #1
            mov     r6,r6,lsl #1
            orr     r6,r6,r7,lsr #0x1f
            mov     r7,r7,lsl #1
         then
      then
   u>= until
   begin
      cmp     r0,r2
      cmpeq   r1,r3
      u>= if
         subs    r1,r1,r3
         sbc     r0,r0,r2
         adds    r5,r5,r7
         adc     r4,r4,r6
      then
      movs    r6,r6,lsr #1
      mov     r7,r7,ror #0
      orrs    r8,r6,r7
      0<> if
         movs    r2,r2,lsr #1
         mov     r3,r3,ror #0
      then
      orrs    r8,r6,r7
   0= until
   ldmia   sp!,{r7,r8,r9}
   mov     pc,lk
end-code

\ unsigned 64/64bit division (u64division)
\ r0 ->         r0.h-r1.l               r1 ->           r2.h-r3.l
\ r2 ->         r4.h-r5.l               r3 ->           r6.h-r7.l
\ r01 / r23 = r01.rem r45.quot
code du/mod  ( ud1 ud2 -- du.rem du.quot )
   mov     r2,tos
   pop     r3,sp
   pop     r0,sp
   pop     r1,sp
   bl      'code (u64division)
   psh     r1,sp
   psh     r0,sp
   psh     r5,sp
   mov     tos,r4
c;

code um/mod  ( ud u1 -- u.rem u.quot )
   mov     r2,#0
   mov     r3,tos

   pop     r0,sp
   pop     r1,sp
   bl      'code (u64division)
   psh     r1,sp
   mov     tos,r5
c;
code mu/mod  ( ud u1 -- u.rem ud.quot )
   mov     r2,#0
   mov     r3,tos
   pop     r0,sp
   pop     r1,sp
   bl      'code (u64division)
   psh     r1,sp
   psh     r5,sp
   mov     tos,r4
c;

code fm/mod  ( d.dividend s.divisor -- s.rem s.quot )
   mov     r3,tos           \ r3:divisor.low
   mov     r2,tos,asr #0    \ r2:divisor.high (sign extended)
   pop     r0,sp            \ r0:dividend.high
   pop     r1,sp            \ r1:dividend.low
   stmdb   sp!,{r8,r9}      \ save r8 and r9
   cmp     r0,#0
   < if                     \ negative dividend?
      rsbs    r1,r1,#0
      rsc     r0,r0,#0      \ r0,r1: abs(dividend)
      cmp     r2,#0
      < if                  \ negative divisor?
         rsbs    r3,r3,#0
         rsc     r2,r2,#0   \ r2,r3: abs(divisor)
         bl      'code (u64division)
         rsbs    r1,r1,#0
         rsc     r0,r0,#0   \ negate remainder for floored division
      else                  \ nonnegative divisor
         mov     r8,r2
         mov     r9,r3
         bl      'code (u64division)
         rsbs    r5,r5,#0
         rsc     r4,r4,#0
         orrs    tos,r0,r1
         0<> if
            subs    r5,r5,#1
            sbc     r4,r4,#0
            subs    r1,r9,r1
            sbc     r0,r8,r0
         then
      then
   else
      cmp     r2,#0
      < if
         mov     r8,r2
         mov     r9,r3
         rsbs    r3,r3,#0
         rsc     r2,r2,#0
         bl      'code (u64division)
         rsbs    r5,r5,#0
         rsc     r4,r4,#0
         orrs    tos,r0,r1
         0<> if
            subs    r5,r5,#1
            sbc     r4,r4,#0
            adds    r1,r1,r9
            adc     r0,r0,r8
         then
      else
         bl      'code (u64division)
      then
   then
   ldmia   sp!,{r8,r9}
   psh     r1,sp
   mov     tos,r5
c;

code u/mod  ( u.dividend u.divisor -- u.rem u.quot )
   ldr     r0,[sp]
   ' (32/32division)  bl *	\ r0 / tos =   r0.rem tos.quot
   str     r0,[sp]
c;

code /mod  ( n.dividend s.divisor -- s.rem s.quot )
   ldr     r0,[sp]
   cmp     r0,#0
   < if
      rsb     r0,r0,#0
      cmp     tos,#0
      < if
         rsb     tos,tos,#0
         bl      'code (32/32division)	\ r0 / tos =   r0.rem tos.quot
         rsb     r0,r0,#0
      else
         mov     r4,tos
         bl      'code (32/32division)	\ r0 / tos =   r0.rem tos.quot
         rsb     tos,tos,#0
         cmp     r0,#0
         decne   tos,#1
         subne   r0,r4,r0
      then
   else
      cmp     tos,#0
      < if
         mov     r4,tos
         rsb     tos,tos,#0
         bl      'code (32/32division)	\ r0 / tos =   r0.rem tos.quot
         rsb     tos,tos,#0
         cmp     r0,#0
         decne   tos,#1
         addne   r0,r0,r4
      else
         bl      'code (32/32division)	\ r0 / tos =   r0.rem tos.quot
      then
   then
   str     r0,[sp]
c;

code sm/rem  ( d.dividend s.divisor -- s.rem s.quot )
   mov     r3,tos
   mov     r2,tos,asr #0
   pop     r0,sp
   pop     r1,sp
   cmp     r0,#0			\ dividend <0
   < if
      rsbs    r1,r1,#0
      rsc     r0,r0,#0
      cmp     r2,#0			\ divisor <0
      < if
         rsbs    r3,r3,#0
         rsc     r2,r2,#0
         bl      'code (u64division)
         rsbs    r1,r1,#0
         rsc     r0,r0,#0
      else
         bl      'code (u64division)
         rsbs    r1,r1,#0
         rsc     r0,r0,#0
         rsbs    r5,r5,#0
         rsc     r4,r4,#0
     then
   else
      cmp     r2,#0			\ divisor <0
      < if
         rsbs    r3,r3,#0
         rsc     r2,r2,#0
         bl      'code (u64division)
         rsbs    r5,r5,#0
         rsc     r4,r4,#0
      else
         bl      'code (u64division)
      then
   then
   psh     r1,sp
   mov     tos,r5
c;

: m/mod  (s d# n1 -- rem quot )
   dup >r  2dup xor >r  >r dabs r@ abs  um/mod
   swap r>  0< if  negate  then
   swap r> 0< if
      negate over if  1- r@ rot - swap  then
   then
   r> drop
;

: /  ( dividend divisor -- quotient )  /mod nip  ;
: mod  ( dividend divisor -- modulus )  /mod drop  ;
: */mod  ( n1 n2 n3 -- n.mod n.quot )  >r m* r> fm/mod  ;
: */  ( n1 n2 n3 -- n4 )  */mod nip  ;

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
