purpose: From Forth, call the C subroutine whose address is on the stack
\ See license at end of file

code sp-call  ( [ arg19 .. arg0 ] adr sp -- [ arg19 .. arg0 ] result )
   pop     r6,sp		\ Get the subroutine address

   str     sp,'user saved-sp	\ Save for callbacks
   psh     ip,rp		\ ARM Procedure Call Standard can clobber IP
   str     rp,'user saved-rp	\ Save for callbacks

   mov     rp,#0		\ Set the frame pointer to null

   \ Pass up to 20 arguments
   add     r4,sp,#0x10
   sub     r5,tos,#0x50

   ldmia   r4!,{r0,r1,r2,r3}    \ Arguments 4-7
   stmia   r5!,{r0,r1,r2,r3}    \ .. onto new stack
   ldmia   r4!,{r0,r1,r2,r3}    \ Arguments 8-11
   stmia   r5!,{r0,r1,r2,r3}    \ .. onto new stack
   ldmia   r4!,{r0,r1,r2,r3}    \ Arguments 12-15
   stmia   r5!,{r0,r1,r2,r3}    \ .. onto new stack
   ldmia   r4!,{r0,r1,r2,r3}    \ Arguments 16-19
   stmia   r5!,{r0,r1,r2,r3}    \ .. onto new stack

   ldmia   sp,{r0,r1,r2,r3}     \ First 4 arguments in registers

   sub     sp,tos,#0x50		\ Switch to the new stack

   mov     lk,pc		\ Set link register to return address
   mov     pc,r6		\ Call the subroutine

   ldr     rp,'user saved-rp	\ Restore the return stack pointer
   pop     ip,rp		\ Restore IP
   ldr     sp,'user saved-sp	\ Restore the stack pointer
   mov     tos,r0		\ Return subroutine result
c;
: call  ( [ arg19 .. arg0 ] adr -- [ arg19 .. arg0 ] result )  sp@ sp-call  ;

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
