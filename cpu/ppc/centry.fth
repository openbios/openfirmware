purpose: Client interface handler code
\ See license at end of file

d# 108 buffer: cif-reg-save

headerless
code cif-return  !csp
   mr     r3,tos

   'user cif-reg-save   lwz  r7,*	\ Address of register save area in r7

   lwz r13,00(r7)   lwz r14,04(r7)   lwz r15,08(r7)   lwz r16,12(r7)
   lwz r17,16(r7)   lwz r18,20(r7)   lwz r19,24(r7)   lwz r20,28(r7)
   lwz r21,32(r7)   lwz r22,36(r7)   lwz r23,40(r7)   lwz r24,44(r7)
   lwz r25,48(r7)   lwz r26,52(r7)   lwz r27,56(r7)   lwz r28,60(r7)
   lwz r29,64(r7)   lwz r30,68(r7)   lwz r31,72(r7)   lwz r1,76(r7)
   lwz r2,80(r7)    lwz r4,88(r7)    mtspr hid0,r4    
   lwz r4,92(r7)    mtspr sprg0,r4   lwz r4,96(r7)    mtspr sprg1,r4
   lwz r4,100(r7)   mtspr sprg2,r4   lwz r4,104(r7)   mtspr sprg3,r4
   lwz r4,84(r7)

   mtspr  lr,r4
   bclr   20,0
end-code

defer rm-cif-entry  ' noop to rm-cif-entry
defer rm-cif-exit   ' noop to rm-cif-exit

: cif-exec  ( args ... -- )
   rm-cif-entry do-cif rm-cif-exit  cif-return
;

headers
: cif-caller  ( -- adr )  cif-reg-save  d# 84 +  @  ;

headerless
label cif-handler
   \ Registers:
   \ r3			argument array pointer
   \ r1,r2,r13-r31	must be preserved
   \ r0,r4-r12		scratch

   mfspr  r4,lr		\ Save link register for later
   mr     r5,base	\ Save base register (r26)
   mr     r6,up		\ Save user area pointer register (r27)

   \ Set the base register
   here  4 +        bl   *	\ Absolute address of next instruction
   here  origin -   set  base,*	\ Relative address of this instruction
   mfspr  up,lr
   subf   base,base,up		\ Base address of Forth kernel in base

   \ Find the user area
   'body main-task  set  up,*	\ Find the save area
   lwzx  up,up,base		\ Get user pointer

   'user cif-reg-save   lwz  r7,*	\ Address of register save area in r7

   stw r13,00(r7)   stw r14,04(r7)   stw r15,08(r7)   stw r16,12(r7)
   stw r17,16(r7)   stw r18,20(r7)   stw r19,24(r7)   stw r20,28(r7)
   stw r21,32(r7)   stw r22,36(r7)   stw r23,40(r7)   stw r24,44(r7)
   stw r25,48(r7)   stw r5,52(r7)    stw r6,56(r7)    stw r28,60(r7)
   stw r29,64(r7)   stw r30,68(r7)   stw r31,72(r7)   stw r1,76(r7)
   stw r2,80(r7)    stw r4,84(r7)   mfspr r4,hid0    stw r4,88(r7)
   mfspr r4,sprg0   stw r4,92(r7)   mfspr r4,sprg1   stw r4,96(r7)
   mfspr r4,sprg2   stw r4,100(r7)  mfspr r4,sprg3   stw r4,104(r7)

   mr  tos,r3
   
   'user rp0   lwz  rp,*
   'user sp0   lwz  sp,*
   \ We don't add 4 to account for the top of stack register because
   \ there is one item - the argument array address - on the stack
   \ (actually it is in the TOS register; logically it's on the stack)

   'user exception-area   lwz r2,*   mtspr sprg0,r2
   
   mtspr  ctr,up			\ Set "next" pointer
   'body cif-exec 4 -   set  ip,*
   add   ip,ip,base
c;

0 value callback-stack

headers
code callback-call  ( args vector -- )
   mtspr  lr,tos
   lwz    r3,0(sp)
   'user callback-stack   lwz  r1,*
   lwz    tos,1cell(sp)
   addi   sp,sp,2cells
   bclrl  20,0
   mtspr  ctr,up
c;

\ Force allocation of buffer
stand-init: CIF buffers
   cif-reg-save drop
   h# 1000 dup alloc-mem + to callback-stack
;

\ LICENSE_BEGIN
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
