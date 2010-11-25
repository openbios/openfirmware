purpose: Low-level handler for alarm interrupt 
\ See license at end of file

headerless

\ Interfaces to system-dependent routines
defer set-tick-limit  ( #msecs -- )	    \ Setup tick interrupt source
defer init-dispatcher ( -- )
defer dispatch-interrupt  ' noop to dispatch-interrupt

0 value intsave
h# 1300 constant /intstack

\ The interrupt save/stack area is laid out as follows:
\ 0000   - register save area  (size h#44)
\ 0044   - data stack area     (size h#1100-h#44)
\ 1100   - return stack area   (size h#200)
\ 1300   - <end>
\
\ The register save area, which is exported to the client program via the
\ "tick" callback, contains the following registers, all from the interrupted
\ context:
\ 00  - psr
\ 04  - r0
\ 08  - r1
\ ...
\ 38  - r13 (sp)
\ 3c  - r14 (lr)
\ 40  - r15 (pc)
\
\ When the interrupt handler returns, the complete context is restored from
\ the save area.  The client program can cause a context switch by modifying
\ these saved valued.

hex

: ?call-os  ( -- )  intsave " tick"  ($callback1)  ;

code interrupt-return  ( -- )

   \ At the first indication of a keyboard abort, we branch to the
   \ Forth entry trap handler.  We do the actual branch after we have
   \ restored all the state, so it appears as if Forth were entered
   \ directly from the program that was running, rather than through
   \ the interrupt handler.

   mov     r3,#0			\ Clear derived abort flag
   ldr     r5,'user aborted?		\ Abort flag

   cmp     r5,#1
   =  if
      \ Don't abort in the middle of the terminal emulator, because
      \ it's not reentrant.

      ldr     r4,'user terminal-locked?
      cmp     r4,#0

      \ Increment the abort flag past 1 so that we won't see it again
      \ until the interpreter has seen and cleared it.
      inceq   r5,#1
      streq   r5,'user aborted?
      mvneq     r3,#0		\ Set derived abort flag
   then

   mov     r13,r3		\ Put derived flag in a safe place

   ldr     r0,'user intsave	\ Address of interrupt save area

   ldr     r1,[r0]		\ Saved SPSR from offset 0   
   msr     spsr,r1		\ Restore it

   mrs     r2,cpsr		\ Remember the current mode
   tst     r1,#0xf		\ Check for user mode
   orreq   r1,r1,#0xf		\ Set system mode if mode was user
   orr     r1,r1,#0x80		\ Disable interrupts
   msr     cpsr,r1		\ Sneak into the other mode

   ldr     r13,[r0,#56]		\ Restore old SP
   ldr     r14,[r0,#60]		\ Restore old LR
   msr     cpsr,r2		\ Return to the interrupt mode

   ldr     r14,[r0,#64]		\ Restore PC to LR

   ldmib   r0,{r0,r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,r11,r12}

   \ Now the registers are back to the state that existed upon entry to
   \ the interrupt handler.  We can use only r13 in the following code.

   cmp     r13,#0		\ Test abort flag
   moveqs  pc,r14		\ Return from interrupt

   adr     r13,'body main-task	\ Get user pointer address
   ldr     r13,[r13]		\ Get user pointer
   ldr     r13,[r13,`'user# cpu-state`]	\ State save address

   stmia   r13,{r0,r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,r11,r12}

   mov     r0,r13		\ Move cpu-state pointer into r0
   mvn     r4,#0		\ Set r4 to -1 to indicate a user abort
   b       'body save-common
end-code

: interrupt-handler  dispatch-interrupt  interrupt-return  ;

label interrupt-preamble
\ here also hidden hwbp previous
   adr     r13,'body main-task		\ Get user pointer address
   ldr     r13,[r13]			\ Get user pointer
   ldr     r13,[r13,`'user# intsave`]	\ Address of interrupt save area

   stmib   r13,{r0,r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,r11,r12}
   mov     r0,r13			\ Switch to r0 for the save pointer

   mrs     r1,spsr
   str     r1,[r0]			\ Save SPSR at offset 0
   dec     r14,#4			\ Account for pipeline
   str     r14,[r0,#64]			\ Save PC at offset 64

   \ Sneak into the old mode to pick up its r13 and r14
   mrs     r2,cpsr			\ Remember the current mode
   tst     r1,#0xf			\ Check for user mode
   orreq   r1,r1,#0xf			\ Set system mode if mode was user
   orr     r1,r1,#0x80			\ Disable interrupts
   msr     cpsr,r1			\ Get into the old mode

   str     r13,[r0,#56]			\ Save old SP
   str     r14,[r0,#60]			\ Save old LR
   msr     cpsr,r2			\ Return to the interrupt mode

   \ Set up Forth stacks
   add     rp,r0,`/intstack #`		\ Return stack pointer
   sub     sp,rp,#0x204			\ Data stack pointer (w/top of stack)

   adr     up,'body main-task		\ Get user pointer address
   ldr     up,[up]			\ Get user pointer

   adr     ip,'body interrupt-handler
c;

: install-alarm  ( -- )
   /intstack alloc-mem to intsave
   intsave /intstack erase	\ Paranoia
   disable-interrupts
      [ also hidden ]
      interrupt-preamble  6  install-handler
      init-dispatcher
      [ previous ]
      d# 1 set-tick-limit
   enable-interrupts        \ Turn interrupts on
;

headers

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
