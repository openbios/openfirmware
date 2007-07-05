purpose: Low-level handler for alarm interrupt 
\ See license at end of file

headerless
\ Interfaces to system-dependent routines
defer init-dispatcher ( -- )  ' noop to init-dispatcher
defer dispatch-interrupt  ' noop to dispatch-interrupt

h# 400 constant /intstack
hex

0 value tick-limit
0 value 'rm-intret

decimal

label rm-interrupt-return  ( -- )
   mfspr  r2,sprg0		\ physical address of this cpu's exception-area
   
   stw  t3,h#0c(r2)		\ Put derived flag in a safe place

   lwz r31,h#9fc(r0)		\ Address of interrupt save area

   \ Now we have to get these guys back into the per-prpcessor
   \ save area. They were squirreld away here by interrupt-preamble
   38 /l*  31  lwz  r0,*   stw  r0,0(r2)	\ r3
   39 /l*  31  lwz  r0,*   stw  r0,4(r2)	\ r2
   40 /l*  31  lwz  r0,*   stw  r0,8(r2)	\ lr

   32 /l*  31  lwz  r0,*   mtspr  xer,r0      \ xer
   34 /l*  31  lwz  r0,*   mtspr  ctr,r0      \ ctr
   35 /l*  31  lwz  r0,*   mtspr  srr0,r0     \ saved pc
   36 /l*  31  lwz  r0,*   mtspr  srr1,r0     \ saved msr

\ XXX the next line is probably unnecessary, because RFI doesn't change the
\ ILE bit, and we are careful to preserve it when we enter the high-level
\ handler.
   mfmsr r1  rlwimi r1,r0,0,15,15  mtmsr r1   \ Restore MSR ILE bit - RFI won't

   37 /l*  31  lwz  r0,*   stw    r0,h#10(r2) \ Put CR in low memory area

   \ Assemble 32 "lwz rN,N*4(r31)" instructions
   32  0  do
      i 4 * ( offset )  31 ( r31 )   i ( reg# )   " lwz *,*" evaluate
   loop

   mfspr  r2,sprg0

   \ Now the registers and low-memory values are back to the state that
   \ existed upon entry to the interrupt handler.  We can use only r3 and lr
   \ in the following code.

   lwz   r3,h#0c(r2)		\ Abort flag
   cmpi  0,0,r3,0
   <>  if			\ Abort if non-zero
      lwz    r3,h#10(r2)	\ Restore CR
      mtcrf  h#ff,r3

      lwz    r3,h#9f0(r0)	\ Save-state address
      mtspr  lr,r3
      addi   r3,r0,-1		\ Indicate an abort
      stw    r3,h#0c(r2)	\ Exception #
      bclr   20,0		\ Jump to save-state
   then

   lwz    r3,h#10(r2)		\ Restore CR
   mtcrf  h#ff,r3

   lwz    r3,h#08(r2)		\ Restore LR
   mtspr  lr,r3

   lwz    r3,h#0(r2)		\ Restore r3
   lwz    r2,h#04(r2)		\ Restore r2

   rfi
end-code

code interrupt-return  ( -- )

   \ At the first indication of a keyboard abort, we branch to the
   \ Forth entry trap handler.  We do the actual branch after we have
   \ restored all the state, so it appears as if Forth were entered
   \ directly from the program that was running, rather than through
   \ the interrupt handler.

   addi  t3,r0,0		\ Clear derived abort flag
   'user aborted?  lwz  t5,*	\ Abort flag

   cmpi  0,0,t5,1
   =  if
      \ Don't abort in the middle of the terminal emulator, because
      \ it's not reentrant.

      'user terminal-locked?   lwz  t4,*
      cmpi   0,0,t4,0
      =  if

         \ Increment the abort flag past 1 so that we won't see it again
         \ until the interpreter has seen and cleared it.
         addi  t5,t5,1
         'user aborted?  stw  t5,*

         addi  t3,r0,-1		\ Set derived abort flag
      then
   then

   mfmsr t4
   rlwinm t4,t4,0,28,25		\ Get back into real mode so we won't have
   mtspr srr1,t4		\ translation faults in the following code.

   'user 'rm-intret  lwz t4,*
   mtspr srr0,t4

   rfi
end-code

: interrupt-handler  ( exc-adr -- )
   h# 900 =  if  check-alarm  else  dispatch-interrupt  then
   interrupt-return
;

\ This routine is entered in real mode.
\ r2, r3, and lr have been saved. r2 points to the this cpu's exception-area,
\ r3 points to the address where the exception occured.
label interrupt-preamble
   stw    r3,h#9e8(r0)		\ Save exception address
   lwz    r3,h#9fc(r0)		\ Physical address of register save area

   \ Save the registers

   \ Assemble 32 "stw rN,N*4(r3)" instructions
   32  0  do
      i 4 * ( offset )  3 ( r3 )   i ( reg# )   " stw *,*" evaluate
   loop

   \ We can't leave these in the sprg save area because they will
   \ get trounced if we get a DSI in the hi level part of the handler
   lwz    r0,0(r2)    38 /l*  3  stw  r0,*	\ r3
   lwz    r0,4(r2)    39 /l*  3  stw  r0,*	\ r2
   lwz    r0,8(r2)    40 /l*  3  stw  r0,*	\ lr

   mfspr  r0,xer      32 /l*  3  stw  r0,*   \ xer
   mfspr  r0,ctr      34 /l*  3  stw  r0,*   \ ctr
   mfspr  r0,srr0     35 /l*  3  stw  r0,*   \ saved pc
   mfspr  r0,srr1

   \ Save the ILE bit too; it doesn't show up in SRR1, so we get it
   \ from the LE bit in in the current MSR value, putting it in its
   \ normal position in the saved value.
   mfmsr r1    rlwimi r0,r1,16,15,15

   \ Keep a copy for later use in establishing the MSR value for the
   \ high-level interrupt handler, but turn off the EE bit so that the
   \ handler can't be re-entered
   rlwinm  t1,r0,0,17,15

                      36 /l*  3  stw  r0,*   \ saved msr
   mfcr   r0          37 /l*  3  stw  r0,*   \ cr

   lwz    t0,h#9ec(r0)		\ Virtual address of interrupt stack area

   \ Set up Forth stacks
   addi   sp,t0,h#200		\ Data stack pointer
   addi   rp,sp,h#200		\ Return stack pointer

   lwz    t0,h#9f4(r0)		\ Get decrementer initial value
   mtspr  dec,t0		\ Restart ticker

   here 4 +  bl  *		\ Get address of next instruction into LR
   here origin -  set   t0,*	\ Relative address of this instruction
   mfspr  base,lr
   subf   base,t0,base		\ Base register is now set (physical address)

   'body main-task  set  up,*	\ Relative address of main-task
   lwzx   up,up,base		\ User pointer is now set

   lwz    base,h#9f8(r0)	\ Virtual address of origin
   lwz    tos,h#9e8(r0)		\ Stack exception address

   'body interrupt-handler 4 -  set  ip,*
   add    ip,ip,base

   mtspr  ctr,up		\ Pointer to NEXT routine

   \ Restore old MSR value so normal address translation can occur, but
   \ don't allow other external interrupts
   mtspr  srr1,t1		\ Old MSR value
   mtspr  srr0,up		\ Address of NEXT routine
   rfi
end-code

\ code dec!  ( #ticks -- )
\    mtspr  dec,tos
\    lwz    tos,0(sp)
\    addi   sp,sp,1cell
\ c;
\ code dec@  ( -- #ticks )
\    stwu   tos,-1cell(sp)
\    mfspr  tos,dec
\ c;

\ The implementations are defined in msr.fth
' (enable-interrupts) to enable-interrupts
' (disable-interrupts) to disable-interrupts
' (lock) to lock[
' (unlock) to ]unlock

: set-tick-limit  ( #msecs -- )
   to ms/tick
   ms/tick counts/ms *  to tick-limit
   tick-limit dec!
   tick-limit h# 9f4 !
;
: install-alarm  ( -- )
   \ Put various important parameters in real memory where the
   \ real-mode part of the interrupt handler can find them.

   /intstack alloc-mem  dup h# 9ec !  >physical h# 9fc !  \ Interrupt stack
   origin                   h# 9f8 !
   tick-limit		    h# 9f4 !
   save-state >physical     h# 9f0 !

   rm-interrupt-return >physical  to 'rm-intret

   disable-interrupts
      interrupt-preamble  h# 500  put-exception  \ External interrupt
      interrupt-preamble  h# 900  put-exception  \ Decrementer interrupt
      init-dispatcher
      d# 10 set-tick-limit
   enable-interrupts		\ Turn interrupts on
;

headers
hex

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
