purpose: Save the processor state after an exception - hardware version
\ See license at end of file

only forth also hidden also  forth definitions

\ The common subroutines on which this depends are defined in
\ cpu/arm/register.fth

headerless

\ This is the first part of the exception handling sequence and the last
\ half of the exception restart sequence.  It is executed in exception state.

label hw-save-state
   \ On entry: r13: scratch  r14: PC from old mode

   \ Check for second half of (restart, if so restore all the registers
   \ from the save area and return from the exception.

   'code (restart drop  restart-offset +   ( offset )
   adr     r13,*		    	\ Address of trap in (restart

   dec     r14,1cell              	\ Point to the trapped instruction
   cmp     r13,r14             

   adr     r13,'body main-task         	\ Get user pointer address
   ldr     r13,[r13]                   	\ Get user pointer
   ldr     r13,[r13,`'user# cpu-state`] \ State save address

   beq     'body restart-common

   stmia   r13,{r0,r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,r11,r12}

   mov     r0,r13         		\ Move cpu-state pointer into r0
   mov     r4,#0			\ Set r4 to 0 to indicate no user abort
   b       'body save-common
end-code

: hw-install-handler  ( handler exception# -- )
   \ Put "ldr pc,[pc,40-8]" in exception vector at 0 + (exception# * 4)
   h# e59ff038 over /l* instruction!   ( exception# )

   \ Put handler address in address table at 40 + (exception# * 4)
   h# 40 swap la+ l!
;
: hw-catch-exception  ( exception# -- )  hw-save-state swap install-handler  ;

: stand-init-io  ( -- )
   stand-init-io
   ['] (restart           is restart
   ['] hw-install-handler is install-handler
   ['] hw-catch-exception is catch-exception
   catch-exceptions
   2 catch-exception   \ Software interrupt (we don't catch this under DEMON)
;

headers
only forth also definitions

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
