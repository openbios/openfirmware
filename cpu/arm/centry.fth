purpose: Client interface handler code
\ See license at end of file

d# 11 /n* buffer: cif-reg-save

headerless
code cif-return
   mov     r0,tos   
   ldr     r1,'user cif-reg-save	\ Address of register save area in r1
   ldmia   r1,{r4,r5,r6,r7,r8,r9,r10,r11,r12,r13,pc}   \ Restore registers
end-code

: cif-exec  ( args ... -- )  do-cif cif-return  ;

headers
: cif-caller  ( -- adr )  cif-reg-save  d# 84 +  @  ;

headerless
label cif-handler
   \ Registers:
   \ r0			argument array pointer
   \ r4-r14		must be preserved
   \ r1-r3		scratch


   adr     r2,'body main-task            
   ldr     r2,[r2]			\ Get user pointer
   ldr     r1,[r2,`'user# cif-reg-save`]  \ Address of register save area in r1
   stmia   r1,{r4,r5,r6,r7,r8,r9,r10,r11,r12,r13,r14}  \ Save registers

   mov     up,r2			\ Set user pointer

   mov     tos,r0			\ Set top of stack register to arg
   
   ldr     rp,'user rp0			\ Set return stack pointer
   ldr     sp,'user sp0			\ Set data stack pointer
   \ We don't increment sp because there is one item on the stack, in tos

   adr     ip,'body cif-exec		\ Set interpreter pointer
c;

0 value callback-stack

headers
: callback-call  ( args vector -- )  callback-stack sp-call 2drop  ;

\ Force allocation of buffer
stand-init: CIF buffers
   cif-reg-save drop
   h# 1000 dup alloc-mem + to callback-stack
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
