\ See license at end of file

decimal

\ 0 constant struct
\ : field  create over , + does> @ +  ;


only forth also hidden also  forth definitions
: enterforth
   \ Adjust pc if it has been incremented past the trap
   int# 3 =  if  %eip 1- to %eip  then
   handle-breakpoint
;

\ ps-size buffer: pssave
\ rs-size buffer: rssave

struct  ( vector-dispatch )
   1 field  >near-call
   4 field  >offset
   1 field  >interrupt#
   2 field  >data-sel
   2 field  >code-sel
   6 field  >old-pm-vector
\  4 field  >old-rm-vector
constant /vector-dispatch

label reenter
   \ We get here from then end of save-state, either by branching directly
   \ or by modifying the return address in the DPMI exception frame.

   \ UP has already been set up

   \ Establish the Data and Return stacks
   'user rp0          rp   mov
   'user sp0          bx   mov

   \ ".. ss mov" and ".. sp mov" must be together in case of an interrupt
   ds ax mov   ax ss mov   bx sp mov

   \ Restart the Forth interpreter.

   cld

   \ Execute enterforth
\   'body enterforth #)  ip  lea
   make-even 				\ word-align for relocation
   'body enterforth  dup #)  ip  lea
   -4 allot  token, 			\ rewrite address as relocatable   
c;

\ This is the common interrupt handler.
\ We assume that we arrived here from a code fragment that pushed the
\ interrupt number.

label save-state-common

   \ We get here by executing a NEAR call from a vector dispatch object

   \ The stack contains
   \   <pre-fault stack>
   \   eflags (32)
   \   cs     (32)
   \   eip    (32)
   \   (error)(32)	\ Only present for some exceptions
   \   &disp  (32)	\ Address after call instr. in vector dispatch object;
			\ pushed by the call instruction.

   cli		\ Necessary ???
   ds      push
   bx      push

   8 [sp]  bx  mov	\ This load uses SS:		\ Get &disp
   op: cs: offset-of >data-sel 5 -  [bx]  ds  mov	\ This load uses CS:

   \ Now DS is correct and we can use normal addressing modes

   bx      pop		\ old DS is still on the stack underneath &disp

   pusha                \ push all data registers

\ ascii a report
   
   \ The stack now contains:
   \   eflags (32)
   \   cs     (32)
   \   eip    (32)
   \   (error)(32)   GP faults
   \   &disp  (32)
   \    ds    (32)
   \   eax    (32)
   \   ecx    (32)
   \   edx    (32)
   \   ebx    (32)
   \   esp    (32)
   \   ebp    (32)
   \   esi    (32)
   \   edi    (32)

\   'body main-task #  ax  mov
   make-odd 			 	\ word-align address
   'body main-task   dup #  ax  mov
   -4 allot  token, 			\ rewrite address as relocatable

   0 [ax]             up  mov		\ Establish user pointer
   'user cpu-state    bx  mov		\ Base address of save area

\   bx push
\   dot   \ print value in bx
\   bx pop
   
   offset-of %edi [bx]  pop
   offset-of %esi [bx]  pop
   offset-of %ebp [bx]  pop
   offset-of %esp [bx]  pop		\ Correct ESP value will be set later
   offset-of %ebx [bx]  pop
   offset-of %edx [bx]  pop
   offset-of %ecx [bx]  pop
   offset-of %eax [bx]  pop
   offset-of %ds  [bx]  pop
   
   es  offset-of %es   [bx]  mov	\ save other data segments
   fs  offset-of %fs   [bx]  mov
   gs  offset-of %gs   [bx]  mov
   ax ax xor      ax dec
   ax offset-of %state-valid [bx]  mov	\ now mark saved state as valid

   \ ss is handled separately in the variant code

   \ Now the stack is back to where it was when save-state started

   cx pop				\ Get dispatch object pointer
   ax  ax  xor
   offset-of >interrupt#  5 -  [cx]  al  mov 
   ax  offset-of int#  [bx]  mov	\ Copy interrupt# from dispatch object

   \ Now the stack is back to where it was when the thunk was entered

   \ Copy the entire Forth data stack and return stack areas to a save area.

   cld   ds push   es pop         \ Increment pointers, es = ds
   di  dx  mov			  \ Save UP

   \ Data Stack  (load si first because di is the user pointer!)
   'user sp0          si   mov
   'user pssave       di   mov    \ Address of data stack save area
   ps-size #          si   sub    \ Bottom of data stack area (in longwords)

   ps-size 4 / #      cx   mov    \ Size of data stack area
   rep  movs

   dx  di  mov			  \ Restore UP

   \ Return Stack  (load si first because di is the user pointer!)
   'user rp0          si   mov
   'user rssave       di   mov    \ Address of return stack save area
   rs-size #          si   sub    \ Bottom of return stack area

   rs-size 4 / #      cx   mov    \ Size of return stack area (in longwords)
   rep  movs

   dx  di  mov			  \ Restore UP

   \ Extract the error code, if any, from the exception frame.

   ax   cx   mov		  \ Convert exeception# ...
   1 #  ax   mov		  \ ...
   ax   cl   shl		  \ ... to a bit mask
   \ Exceptions 8, 10, 11, 12, 13, 14, 17, and (maybe) 18 stack an error code
   h# 67d00 # ax   test  0<>  if  \ This exception has an error code
      ax pop			  \ Get error code
   else				  \ This exception has no error code
      h# 100 invert  #  8 [sp]  and   \ Turn off trace bit
      ax ax sub			  \ Put a 0 in the error code save variable
   then
   ax  offset-of %error [bx]  mov

   offset-of %eip    [bx]  pop
   0 [sp]  ax  mov		  ax   offset-of %cs     [bx]  mov
   4 [sp]  ax  mov		  ax   offset-of %eflags [bx]  mov
   sp      ax  mov   8 # ax  add  ax   offset-of %esp    [bx]  mov
                                  ss   offset-of %ss     [bx]  mov
\ ascii b report

\   reenter #   push	\ Change the return address to go to "reenter"
   make-odd 			 	\ word-align address
   'body reenter   dup #  push
   -4 allot  token, 			\ rewrite address as relocatable
   
   iret
end-code

code (restart  ( -- )
   \ Restore the Forth stacks.

\ ascii c report

   cld   ds ax mov   ax es mov    \ Increment pointers, es = ds
   di  bx    mov	   	  \ Save UP
   
   \ Establish the Data and Return stack pointers
   'user rp0          rp    mov

   \ Data Stack
   'user pssave       si    mov   \ Address of data stack save area
   'user sp0          di    mov   \ Top of data stack area

   ps-size #          di    sub   \ Bottom of data stack area
   ps-size 4 / #      cx    mov   \ Size of data stack area (in longwords)
   rep movs

   bx  di  mov			  \ Restore UP for 'user

   \ Return Stack
   'user rssave       si    mov   \ Address of return stack save area
   'user rp0          di    mov   \ Top of return stack area

   rs-size #          di    sub   \ Bottom of return stack area
   rs-size 4 / #      cx    mov   \ Size of return stack area (in longwords)
   rep movs
   
   bx  di  mov			  \ Restore UP

   \ Restore registers

   'user cpu-state    bx  mov		\ Base address of save area

   offset-of %gs   [bx]  gs  mov
   offset-of %fs   [bx]  fs  mov
   offset-of %es   [bx]  es  mov

   offset-of %ss   [bx]  ss  mov
   offset-of %esp  [bx]  sp  mov

   \ Push the exception frame

   offset-of %eflags [bx]  push
   offset-of %cs     [bx]  push
   offset-of %eip    [bx]  push

   offset-of %eax    [bx]  push
   offset-of %ecx    [bx]  push
   offset-of %edx    [bx]  push
   offset-of %ebx    [bx]  push
   offset-of %esp    [bx]  push
   offset-of %ebp    [bx]  push
   offset-of %esi    [bx]  push
   offset-of %edi    [bx]  push

   offset-of %ds     [bx]  ax  mov   ax  ds  mov

\ ascii d report
   
   popa
   iret
end-code
' (restart is restart

hidden definitions

\ Store at "location" the 32-bit offset so that a near call
\ whose opcode is at location-1 will jump to "target-adr"
: rel!  ( target-adr location -- )  tuck 4 + -  swap le-l!  ;

defer save-state
' save-state-common to save-state

: make-thunk  ( vector# -- adr sel )
   /vector-dispatch alloc-mem               ( vector# adr )
   >r
   dup             r@ >interrupt#    c!     ( vector# )
\  dup rm-vector@  r@ >old-rm-vector l!     ( vector# )
       pm-vector@  r@ >old-pm-vector farp!  ( )

   h# e8           r@ >near-call     c!     ( )
   save-state      r@ >offset      rel!     ( )
   ds@             r@ >data-sel   le-w!     ( )
   cs@             r@ >code-sel   le-w!     ( )
   r> cs@                                   ( adr sel )
;
: catch-vector  ( vector# -- )  dup  make-thunk  rot pm-vector!  ;

\ Since we are handling exceptions here, not random interrupts,
\ we don't need to deal with the real mode stuff.
\ The only possible down side would be if an exception were to happen
\ in real mode, perhaps due to a bogus argument to a system call.
\ That may not be possible; in real mode, addresses are not protected,
\ so I think you can write to anywhere in the lower meg without a trap.
\ If we wanted to catch real mode exceptions too, we would use pm-rm-vector!

: uncatch-vector  ( vector# -- )
   dup pm-vector@ drop                       ( vector# adr )
   >r                                        ( vector# )
\  r@ >old-rm-vector l@  over rm-vector!     ( vector# )
   r@ >old-pm-vector farp@  rot pm-vector!   ( )
   r> /vector-dispatch free-mem
;

0 value my-vec13
: (wrapper-vectors)  ( -- )
   \ Restore Zortech C's vector 13, because it appears to need it
   my-vec13 >old-pm-vector farp@  d# 13 pm-vector!
;
: (forth-vectors)  ( -- )
   \ Re-install Forth's vector 13
   my-vec13  cs@  d# 13 pm-vector!
;

defer uncatch-exceptions	' noop is uncatch-exceptions

\ If you execute catch-exceptions while compiling, the resulting dictionary
\ file bombs when you start it, because "wrapper-vectors" refers to an
\ invalid thunk, causing problems when Forth calls out to the wrapper to
\ allocate memory.
\ The solution is to uncatch the exceptions before saving the file.

: (uncatch-exceptions)  ( -- )
   d# 00 uncatch-vector	\ Divide by 0
   d# 01 uncatch-vector	\ Debugger
   d# 03 uncatch-vector	\ Breakpoint
   d# 04 uncatch-vector	\ INT0-detected Overflow
   d# 05 uncatch-vector	\ BOUND range exceeded
   d# 06 uncatch-vector	\ Invalid Opcode
   d# 07 uncatch-vector	\ Coprocessor not available
   d# 13 uncatch-vector	\ General protection
   d# 14 uncatch-vector	\ Page fault
   d# 16 uncatch-vector	\ Coprocessor Error

   ['] noop is wrapper-vectors
   ['] noop is forth-vectors
;

forth definitions
: catch-exceptions  ( -- )
   pssave drop  rssave drop	\ Force buffer allocation
   [ 0 alloc-reg ] literal alloc-mem is cpu-state

   d# 00 catch-vector	\ Divide by 0
   d# 01 catch-vector	\ Debugger
   d# 03 catch-vector	\ Breakpoint
   d# 04 catch-vector	\ INT0-detected Overflow
   d# 05 catch-vector	\ BOUND range exceeded
   d# 06 catch-vector	\ Invalid Opcode
   d# 07 catch-vector	\ Coprocessor not available
   \ Avoid exception #9; it's none of our business.
   d# 13 catch-vector	\ General protection
   d# 14 catch-vector	\ Page fault
   d# 16 catch-vector	\ Coprocessor Error
   
   d# 13 pm-vector@ drop is my-vec13
   ['] (wrapper-vectors) is wrapper-vectors
   ['] (forth-vectors)   is forth-vectors

   ['] (uncatch-exceptions) is uncatch-exceptions
;

: (cold-hook  ( -- )
   (cold-hook
   ['] noop is uncatch-exceptions
;

: $save-forth  ( name$ -- )
   ['] uncatch-exceptions behavior  ['] (uncatch-exceptions) =  if 
      uncatch-exceptions  $save-forth  catch-exceptions
   else
      $save-forth
   then
;

only forth also definitions

\ 386 exceptions visible to user programs:

\ Divide by 0
\ Debug (TF flag set)
\ Breakpoint (INT3)
\ Overflow  (INT0 with OF flag set)
\ Bounds check (BOUND instruction)
\ Coprocessor not available
\ Coprocessor error (illegal coprocessor opcode)

string-array exception-names
( 00 ) ," Divide Error"
( 01 ) ," Debugger Call"
( 02 ) ," NMI Interrupt"
( 03 ) ," Breakpoint"
( 04 ) ," INT0-detected Overflow"
( 05 ) ," BOUND range exceeded"
( 06 ) ," Invalid Opcode"
( 07 ) ," Coprocessor Not Available"
( 08 ) ," Double Fault"
( 09 ) ," Coprocessor Segment Overrun"
( 10 ) ," Invalid Task State Segment"
( 11 ) ," Segment Not Present"
( 12 ) ," Stack Exception"
( 13 ) ," General Protection Exception"
( 14 ) ," Page Fault"
( 15 ) ," Intel Reserved"
( 16 ) ," Coprocessor Error"
end-string-array

: (.exception)  ( -- )
   int#
   dup d# 16 <=  if  exception-names ". cr  exit  then
   dup d# 32 >=  if
      ." Interrupt #"
   else
      ." Reserved vector #"
   then
   base @ >r decimal (u.) type cr r> base !
;
' (.exception) is .exception
: print-breakpoint
   .exception
   interactive? 0=  if bye then	\ Restart only if a human is at the controls
   ??cr quit
;
\ ' print-breakpoint is handle-breakpoint

\ defer restart  ( -- )
hidden also
stand-init:
   restartable? off
;
only forth also definitions

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
