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

defer init-vector-base
' noop to init-vector-base

defer vector-base
0 value fixed-vector-base
' fixed-vector-base to vector-base

: hw-install-handler ( handler exception# -- )
   vector-base swap la+     ( handler vector-adr )
 
 \ Put "ldr pc,[pc,40-8]" in exception vector at vector-base + (exception# * 4 )
   h# e59ff038 over instruction!   ( handler vector-adr )

  \ Put handler address in address table at vector-base + 40 + (exception# * 4)
   h# 40 + l!
;
: hw-catch-exception  ( exception# -- )  hw-save-state swap install-handler  ;

\ Some ARM CPUs, such as CortexA8, let you move the vector base anywhere
code vector-base@ ( -- adr )
   psh  tos,sp
   mrc p15,0,tos,cr12,cr0,0
c;

code vector-base! ( adr --- )
   mcr p15,0,tos,cr12,cr0,0
   pop  tos,sp
c;

h# 80 buffer: ram-vector-base-buf
: move-vector-base  ( -- )  ram-vector-base-buf h# 20 round-up vector-base!  ;

\ Execute this at compile time for processors that need it.
\ Ideally we would detect the vector base register at run time
\ but I don't know how yet.
: use-movable-vector-base  ( -- )
   ['] vector-base@ to vector-base
   ['] move-vector-base to init-vector-base
;

: stand-init-io  ( -- )
   stand-init-io
   ['] (restart           is restart
   ['] hw-install-handler is install-handler
   ['] hw-catch-exception is catch-exception
   init-vector-base
   catch-exceptions
   2 catch-exception   \ Software interrupt (we don't catch this under DEMON)
;

headers
only forth also definitions

\ LICENSE_BEGIN
\ Copyright (c) 2009 FirmWorks
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
