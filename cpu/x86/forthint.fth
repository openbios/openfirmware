\ See license at end of file
purpose: Low-level handler for alarm interrupt 

\ " Check setting of interrupt flag after an exception" ?reminder
\ " It may be preferable to use a trap gate instead of an interrupt gate" ?reminder
\ " See pages 9-7 - 9-11 in the 486 manual" ?reminder

headerless

create hw-iack			\ HW performs interrupt acknowledge

h# 20 constant irq-vector-base

\ Interfaces to system-dependent routines
defer set-tick-limit  ( #msecs -- )	    \ Setup tick interrupt source
defer init-dispatcher ( -- )
defer dispatch-interrupt  ' noop to dispatch-interrupt

0 value intsave
h# 1100  h# 200 +  constant /intstack

\ The interrupt save/stack area is laid out as follows:
\ register save area  (small)
\ data stack area     (size h#1100 - register save area size )
\ return stack area   (size h#200)

\ The only registers we save in the register save area are esp and ss;
\ others are saved on the stack

hex

\ We don't support a tick callback
\ : ?call-os  ( -- )  intsave " tick"  ($callback1)  ;
alias ?call-os noop  immediate

code interrupt-return  ( -- )

   \ Restore registers

   'user intsave    ax  mov		\ Address of interrupt save area
   0 [ax]  ss  mov
   4 [ax]  sp  mov			\ Go back to the foreground stack

   \ At the first indication of a keyboard abort, we branch to the
   \ Forth entry trap handler.  We do the actual branch after we have
   \ restored all the state, so it appears as if Forth were entered
   \ directly from the program that was running, rather than through
   \ the interrupt handler.

   'user aborted?  ax  mov		\ Abort flag

   1 # ax cmp  =  if
      \ Don't abort in the middle of the terminal emulator, because
      \ it's not reentrant.

      'user terminal-locked?  bx  mov   bx bx or  0=  if
         \ Increment the abort flag past 1 so that we won't see it again
         \ until the interpreter has seen and cleared it.
         ax inc   ax  'user aborted?  mov

         gs pop  fs pop  es pop  ds pop   popa

         \ This is an in-line thunk for "vector" -1
         \ See cpu/x86/catchexc.fth
         also hidden  save-state previous  #) call
         h# ff c,  \ interrupt#
         8 w,      \ data segment selector
         h# 10 w,  \ code segment selector
         0 w, 0 l, \ old-pm-vector (not used in this context)
      then
   then

   gs pop  fs pop  es pop  ds pop   popa
   iret
end-code

: interrupt-handler  ( interrupt# -- )
   irq-vector-base -
   dispatch-interrupt  interrupt-return  
;

label interrupt-preamble
   \ We get here by executing a NEAR call from a vector dispatch object

   \ The stack contains
   \   <pre-fault stack>
   \   eflags (32)
   \   cs     (32)
   \   eip    (32)
   \   <all general registers>
   \   &disp  (32)	\ Address after call instr. in thunk, which was
			\ pushed by the call instruction.

   bx pop		\ Remove disp from stack

   ds push  es push  fs push  gs push

   \ The stack now contains:
   \   eflags (32)
   \   cs     (32)
   \   eip    (32)
   \   <all general registers>
   \   ds, es, fs, gs

   \ Load the data segment register from the thunk
   op: cs: 0 [bx]  ds  mov	\ This load uses CS:

   \ Now DS is correct and we can use normal addressing modes

   make-odd 			 	\ word-align address
   'body main-task   dup #  ax  mov
   -4 allot  token, 			\ rewrite address as relocatable
   0 [ax]           up  mov		\ Establish user pointer

   'user intsave    ax  mov		\ Address of interrupt save area
   ss   0 [ax]  mov			\ Save old SS
   sp   4 [ax]  mov			\ Save old ESP

   \ Set up Forth stacks
   /intstack # ax add  ax rp mov	\ Return stack pointer
   h# 200 #   ax sub			\ Data stack pointer ...
   ds cx mov  cx ss mov  ax sp mov	\ Set stack pointer

   4 [bx]  push				\ Push interrupt number on stack

   cld					\ Establish direction flag

   make-even 				\ word-align for relocation
   'body interrupt-handler  dup #)  ip  lea
   -4 allot  token, 			\ rewrite address as relocatable   
c;

\ The thunk contains the following code, followed by the new DS value
\ and the interrupt number.

: make-irq-thunk  ( vector# -- adr sel )
   d# 14 alloc-mem  >r            r@ d# 10 +  !  ( )
   h# 60                          r@     0 + c!	 \ Pusha
   h# e8                          r@     1 + c!	 \ Near call, 32-bit relative address
   interrupt-preamble  r@ 6 +  -  r@     2 +  !	 \ the call destination offset
   ds@                            r@     6 +  !	 \ Data segment selector
   r> cs@                                        ( adr sel )
;

: catch-interrupts  ( -- )
   irq-vector-base  h# 10  bounds  do  i make-irq-thunk  i pm-vector!  loop
;

0 value (ms-value)

: install-alarm  ( -- )
   /intstack alloc-mem to intsave
   intsave /intstack erase	\ Paranoia
   disable-interrupts
      [ also hidden ]
      catch-interrupts
      init-dispatcher
      [ previous ]
      ['] (get-msecs) to get-msecs
      d# 10 set-tick-limit
   enable-interrupts        \ Turn interrupts on
;

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
