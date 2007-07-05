purpose: Save the processor state after a signal.
\ See license at end of file

\ This code is entered as a result of a Unix signal.
\ It saves the processor state, then enters Forth so that the
\ state may be examined, and possibly re-established later.

\ needs signal signal.f

\ exception-area is a place to store registers during exception handling.
\ Each cpu gets its own area and uses SPRG0 to point to it.
h# 40 /l* constant /exception-area
0 value exception-area

decimal

only forth also hidden also  forth definitions

headers
0 value virt-phys

headerless
0 value cpu-state-phys

: enterforth  ( -- )
   state-valid on
   my-self to %saved-my-self
   handle-breakpoint
;

code (restart  ( -- )
   \ Restore the Forth stacks.

   \ Establish the Data and Return stacks
   'user rp0    lwz  rp,*
   'user sp0    lwz  sp,*

   \ Restore the Forth Data and Return stacks from the save area.

   \ Data Stack
   'user sp0      lwz  t3,*
   'user pssave   lwz  t0,*	\ Address of data stack save area
   ps-size        addi t1,r0,*	\ Size of data stack area
   add   t0,t0,t1		\ End of save area

   srawi  t1,t1,2		\ Number of longwords
   mtspr  ctr,t1

   begin
      lwzu   t2,-4(t0)
      stwu   t2,-4(t3)
   bc     16,0,*		\ Decrement and branch if nonzero

   \ Return Stack
   'user rp0     lwz  t3,*
   'user rssave  lwz  t0,*	\ Address of return stack save area
   rs-size       addi t1,r0,*	\ Size of return stack area
   add   t0,t0,t1		\ End of save area

   srawi  t1,t1,2		\ Number of longwords
   mtspr  ctr,t1

   begin
      lwzu   t2,-4(t0)
      stwu   t2,-4(t3)
   bc     16,0,*		\ Decrement and branch if nonzero

   or        r0,r0,r0

   \ The following code communicates with the first part of "save-state".
   \ See the description there.
   here 4 +  bl  *		\ Get current address
   mfspr     t0,lr
   addi      t0,t0,16
   mfspr     t2,sprg0		\ Get this cpu's exception-area address
   stw       t0,h#10(t2)	\ Store the address of the next instruction
				\ so save-state can recognize it

   \ Take another trap, so we can fix up the PC's in the signal handler
   0 asm,			\ Illegal instruction

end-code

\ This is the second half of the state saving procedure.  It is executed
\ in normal state (not exception state).

label finish-save
   \ The base register is already set

   \ Find the user area
   'body main-task  set  up,*	\ Find the save area
   lwzx  up,up,base		\ Get user pointer

   \ Establish the Data and Return stacks

   \ Copy the entire Forth Data and Return stacks areas to a save area.

   \ Data Stack
   'user sp0      lwz  t3,*
   'user pssave   lwz  t0,*	\ Address of data stack save area
   ps-size        addi t1,r0,*	\ Size of data stack area
   add   t0,t0,t1		\ End of save area

   srawi  t1,t1,2		\ Number of longwords
   mtspr  ctr,t1

   begin
      lwzu   t2,-4(t3)
      stwu   t2,-4(t0)
   bc     16,0,*		\ Decrement and branch if nonzero

   'user sp0    lwz  sp,*

   \ Return Stack
   'user rp0     lwz  t3,*
   'user rssave  lwz  t0,*	\ Address of return stack save area
   rs-size       addi t1,r0,*	\ Size of return stack area
   add   t0,t0,t1		\ End of save area

   srawi  t1,t1,2		\ Number of longwords
   mtspr  ctr,t1

   begin
      lwzu   t2,-4(t3)
      stwu   t2,-4(t0)
   bc     16,0,*		\ Decrement and branch if nonzero

   'user rp0     lwz  rp,*

   \ Adjust the stack pointer to account for the top of stack register
   addi   sp,sp,4

   \ Restart the Forth interpreter.

   \ Set the next pointer
   mtspr  ctr,up

   \ Execute enterforth
   'body enterforth 4 -   set  ip,*
   add   ip,ip,base
c;

\ This is the first part of the exception handling sequence.  It is
\ executed in exception state.
\ r2, r3, and lr have been saved. r2 points to the this cpu's exception-area,
\ r3 points to the address where the exception occured.
label save-state
   stw    r3,h#0c(r2)		\ Save exception address
   lwz    r3,h#08(r2)		\ Restore lr
   mtspr  lr,r3
				\ R3 is available
   stw    base,h#14(r2)		\ A register for us to play with
   stw    up,h#18(r2)		\ A register for us to play with
   
   mfcr   base			\ CR is saved in base
   
   \ WARNING: This code is tricky.  The goal is to determine whether or not
   \ the instruction that caused the exception was the illegal instruction at
   \ the end of (restart, just above.  It's not safe to access the instruction
   \ at the saved PC location, because this handler runs with translations
   \ disabled, but the saved PC is virtual address, so accessing it could
   \ result in a machine check (which would cause the system to hang) if the
   \ PC value is not a valid real-mode address.
   \ Instead, we compare the saved PC with the contents of the cell at
   \ sprg0+10, depending on the fact that (restart stored the
   \ address of its illegal instruction there just before executing that
   \ illegal instruction.

   mfspr  up,srr0		\ Saved PC
   lwz    r3,h#10(r2)		\ Get magic address
   cmp    0,0,up,r3		\ Is it the magic address?

   lwz    r3,h#00(r2)		\ Restore r3

   =  if
      \ This is the second half of (restart, so we restore all the registers
      \ from the save area.

      lwz  up,h#18(r2)		\ Get UP back

\      'user cpu-state-phys  lwz  r31,*	\ Get cpu-state buffer address
      lwz  r31,h#38(r2)

      \ Restore floating point registers if they were saved
      36 /l*  31  lwz r0,*		\ saved msr
      andi.  r0,r0,h#2000
      0<> if
         mfmsr  t0			\ Turn on FP unit
         ori    t0,t0,h#2000
         mtmsr  t0
         isync

         106 /l* 31 lfd  0,*		\ Get back fpscr double word into fr0
         mtfsf  h#ff,0			\ Move fr0 to fpscr
	 
	 \ Assemble 32 "lfd fN,42*4+N*8(r31)" instructions
         32  0  do
            i 8 *  42 la+ ( offset ) 31 ( r31 ) i ( reg# )  " lfd *,*" evaluate
         loop
      then

      32 /l*  31  lwz  r0,*   mtspr  xer,r0      \ xer
      33 /l*  31  lwz  r0,*   mtspr  lr,r0       \ lr
      34 /l*  31  lwz  r0,*   mtspr  ctr,r0      \ ctr
      35 /l*  31  lwz  r0,*   mtspr  srr0,r0     \ saved pc
      36 /l*  31  lwz  r0,*   mtspr  srr1,r0     \ saved msr
      37 /l*  31  lwz  r0,*   mtcrf  h#ff,r0     \ cr

\       108 /l* 31  lwz  r0,*   mtspr  sprg0,r0    \ sprg0
\       109 /l* 31  lwz  r0,*   mtspr  sprg1,r0    \ sprg1
\       110 /l* 31  lwz  r0,*   mtspr  sprg2,r0    \ sprg2
\       111 /l* 31  lwz  r0,*   mtspr  sprg3,r0    \ sprg3

      \ Assemble 32 "lwz rN,N*4(r31)" instructions
      32  0  do
         i 4 * ( offset )  31 ( r31 )   i ( reg# )   " lwz *,*" evaluate
      loop
\     lmw   r0,0(up)		\ Restore all general registers

      rfi
   then

   \ This is not the second half of (restart, so we save all the registers
   \ to the save area.
   mtcrf  h#ff,base		\ Restore CR

\    \ Set the base register
\   here  4 +        bl   *	\ Absolute address of next instruction
\   here  origin -   set  base,*	\ Relative address of this instruction
\   mfspr  up,lr
\   subf   base,base,up		\ Base address of Forth kernel
 
\    'body main-task  set  up,*	\ Find the save area
\    lwzx  up,up,base		\ Get user pointer
\ 
\    'user cpu-state-phys  lwz  up,*	\ Get cpu-state buffer address

   lwz    up,h#38(r2)		\ Get address from save area   
   lwz    base,h#3c(r2)		\ Get address from save area   

\  stmw   r0,0(up)		\ Save all general registers
   \ Assemble 32 "stw rN,N*4(up)" instructions
   32  0  do
      i 4 * ( offset )  27 ( up )   i ( reg# )   " stw *,*" evaluate
   loop

   lwz    r0,h#14(r2) 26 /l*  27  stw  r0,*   \ base
   lwz    r0,h#18(r2) 27 /l*  27  stw  r0,*   \ up
   mfspr  r0,xer      32 /l*  27  stw  r0,*   \ xer
   lwz    r0,h#08(r2) 33 /l*  27  stw  r0,*   \ lr
   mfspr  r0,ctr      34 /l*  27  stw  r0,*   \ ctr
   mfspr  r0,srr0     35 /l*  27  stw  r0,*   \ saved pc
   mfspr  r0,srr1     36 /l*  27  stw  r0,*   \ saved msr
   mfcr   r0          37 /l*  27  stw  r0,*   \ cr

   lwz    r0,h#0c(r2)  rlwinm r0,r0,24,24,31
                      38 /l*  27  stw  r0,*   \ exception#
   lwz    r2,h#04(r2)  2 /l*  27  stw  r2,*   \ original r2

\    mfspr  r0,sprg0   108 /l*  27  stw  r0,*   \ sprg0
\    mfspr  r0,sprg1   109 /l*  27  stw  r0,*   \ sprg1
\    mfspr  r0,sprg2   110 /l*  27  stw  r0,*   \ sprg2
\    mfspr  r0,sprg3   111 /l*  27  stw  r0,*   \ sprg3
   
   \ Save floating point registers if floating point is enabled
   mfmsr  t0
   andi.  t0,t0,h#2000
   0<>  if
      \ Assemble 32 "stfd fN,42*4+N*8(up)" instructions
      32  0  do
         i 8 *  42 la+  ( offset )  27 ( up ) i ( reg# )   " stfd *,*" evaluate
      loop
      \ Now that fp regs are saved, we can trounce on them to get the 
      \ fpscr register
      mffs   0			\ Move fpscr to fp0[63:32]
      106 /l*  27  stfd  0,*	\ Move fp0[63:0] to memory
   then

   \ Now we set the saved PC to point to the rest of the state save
   \ routine, then return from interrupt.

   'body finish-save  set  up,*
   add    up,up,base
   mtspr  srr0,up

   rfi
end-code

hidden definitions

' (restart is restart
' (restart is restart-step

string-array exception-name
( 00 )  ," Reserved exception 0"
( 01 )  ," System reset"
( 02 )  ," Machine check"
( 03 )  ," Data access exception"
( 04 )  ," Instruction access exception"
( 05 )  ," External interrupt"
( 06 )  ," Alignment exception"
( 07 )  ," Illegal instruction"
( 08 )  ," Floating point unavailable"
( 09 )  ," Decrementer interrupt"
( 0a )  ," I/O controller interface error"
( 0b )  ," Reserved exception 0b"
( 0c )  ," System call"
( 0d )  ," Trace exception"
( 0e )  ," Floating point assist exception"
( 0f )  ," Reserved exception 0f"
( 10 )  ," Instruction translation miss"
( 11 )  ," Data load translation miss"
( 12 )  ," Data store translation miss"
( 13 )  ," Instruction address breakpoint"
( 14 )  ," System management interrupt"
end-string-array

: (.exception) ( -- )
   exception#  dup  h# 20  =  if
      ." Run mode/trace exception"
   else
      dup h# 15 <  if
         exception-name count type
      else
         ." Reserved exception # " .h
      then
   then
   cr
;
' (.exception) is .exception

: print-breakpoint
   .exception  \ norm
   interactive? 0=  if bye then	\ Restart only if a human is at the controls
   ??cr quit
;
\ ' print-breakpoint is handle-breakpoint

code hwbp  ( adr -- )
   mtspr  iabr,tos
   lwz    tos,0(sp)
   addi   sp,sp,4
c;

code tbar!  ( adr -- okay? )
   \ As a side effect of the  mfspr *,pvr  instruction, the simulator
   \ sets its internal trap base address register (which isn't a real
   \ part of the PowerPC architecture) to the address contained in the
   \ destination register.  That instruction was chosen because it
   \ is not likely to be used in general code, but it is valid on all
   \ PPC implementations.
   mfspr  tos,pvr
c;

forth definitions
0 value exc-adr
: exc,  ( instruction -- )  exc-adr instruction!  exc-adr la1+ to exc-adr  ;
: put-exception  ( exception-handler-addr exception-addr -- )
   to exc-adr  virt-phys - lwsplit
   h# 7c51.43a6       exc,   \ mtspr sprg1,r2		protect r2
   h# 7c50.42a6       exc,   \ mfspr r2,sprg0		set r2 to save area
   h# 9062.0000       exc,   \ stw   r3,0(r2)		save r3
   h# 7c71.42a6       exc,   \ mfspr r3,sprg1
   h# 9062.0004       exc,   \ stw   r3,4(r2)		save r2
   h# 7c68.02a6       exc,   \ mfspr r3,lr
   h# 9062.0008       exc,   \ stw   r3,8(r2)		save lr
   \ h# 80620020 exc, h# 38630001 exc, h# 90620020 exc,
   h# 3c60.0000 or    exc,   \ set   r3,high address half-word
   h# 6063.0000 or    exc,   \ set   r3,low address half-word
   h# 7c68.03a6       exc,   \ mtspr lr,r3		point lr to handler
   h# 3860.0000 exc-adr h# ff00 and or  exc,   \ addi  r3,r0,exception-addr
   h# 4e80.0020       exc,   \ bclr 20,0		jump to handler
;
d# 12 /l* constant /exc	\ size of entry made by put-exception
: catch-exception  ( exception# -- )  8 <<  save-state swap put-exception  ;

headers
: catch-exceptions  ( -- )
   /save-area alloc-mem is cpu-state		( )
   clear-save-area				( )
   pssave drop  rssave drop	\ Force allocation of these buffers
   /exception-area alloc-mem			( virt )
   cpu-state virt-phys -  over h# 38 + l!	( virt )
   origin over h# 3c + l!			( virt )
   virt-phys - dup is exception-area		( virt' )
   sprg0!		\ Save this cpu's exception-area address to SPRG0

   
   2 catch-exception   \ Machine check
   3 catch-exception   \ Data access
   4 catch-exception   \ Instruction access
   6 catch-exception   \ Alignment
   7 catch-exception   \ Illegal instruction
   8 catch-exception   \ Floating point unavailable
;
: stand-init  ( -- )
   msr@ h# 40 invert and msr!
   catch-exceptions
;
: sys-init  ( -- )
   sys-init
   syscall-vec @  0=  if
      h# 4000 alloc-mem tbar!  if
         catch-exceptions
      then
   then
;

only forth also definitions

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
