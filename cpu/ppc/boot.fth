purpose: Boot code (cold and warm start) for PowerPC
\ See license at end of file

\ Version for running Forth underneath a "wrapper" program

\ The cold start code is executed when Forth is initially started.
\ Its job is to initialize the Forth virtual machine registers.
\ The warm start code is executed when Forth is re-entered,
\ perhaps as a result of an exception.

hex

only forth also labels also meta also definitions

0 constant main-task
: init-user  (s -- )
;

\ Stuff initialized at cold start time

nuser memtop		\ The top of the memory used by Forth
0 value #args		\ The process's argument count
0 value  args		\ The process's argument list

\ Defining these two in code is a significant performance optimization
\ for Open Firmware
code package(  ( ihandle -- )  
   'user my-self  lwz  t0,*
   stwu    t0,-1cell(rp)
   'user my-self  stw  tos,*
   pop-tos
c;
code )package  ( -- )
   lwz   t0,0(rp)
   rdrop
   'user my-self  stw t0,*
c;

headerless

label cold-code  ( -- )

\ called with   forth_startup(header-adr, functions, mem_end, &gargc, &gargv)
\ 				 r3	    r4	      r5	r6	r7

\ Get some registers
   \ XXX should save registers

\  here origin - . cr

   nop

\ Find the base address
   here-t 4 +   bl   *          \ Absolute address of next instruction
   here-t       set  base,*	\ Relative address of this instruction
   mfspr   t0,lr
   subfc   base,base,t0		\ Base address of Forth kernel
				\ ( Use subfc for POWER compatibility)
 \ Synchronize caches
   addi    t1,r5,31		\ round end address up ...
   rlwinm  t1,t1,0,0,26		\ ... to next cache line boundary

   sync isync
   
   begin
      addi t1,t1,-32  cmpl 0,0,t1,r3		\ Down one cache line
      dcbst r0,t1  sync isync  icbi r0,t1	\ Synchronize it
   <= until

   sync isync
   
\ Find the user area size from the header
   lwz   t1,4(r3)		\ Text size = offset to start of data
   lwz   t0,8(r3)		\ Data size = user area size in t4 

   mr    t5,r5			\ We'll need this later for memtop

\ Allocate high memory for the stacks and stuff, starting at memtop and
\ allocating downwards.  r5 is the allocation pointer.

\ Allocate the RAM copy of the User Area
   subfc   r5,t0,r5		\ ( Use subfc for POWER compatibility)
   rlwinm  r5,r5,0,0,26		\ cache-line-align by clearing 5 low bits 
   mr      up,r5		\ Set user pointer

   'body main-task   set  t2,*	\ Allow the exception handler to find the
        			\ user area by storing the address of the
   stwx  up,base,t2		\ main user area in the "constant" main-task

   \ Copy the initial User Area image to the RAM copy
   add   t3,t1,base		\ Init-up pointer in t3 
   mr    t2,up			\ Destination pointer

   srawi  t0,t0,2
   mtspr  ctr,t0
   addi   t3,t3,-4		\ Account for pre-incrementing
   addi   t2,t2,-4		\ Account for pre-incrementing
   begin
      lwzu  t0,4(t3)
      stwu  t0,4(t2)
   countdown

\ Synchronize the caches in the "next" region
   sync isync  dcbst r0,up  sync isync  icbi r0,up  sync isync

   'user powerpc?  stw  r8,*	\ Set the PowerPC flag

\ Now the user area has been copied to the proper place, so we can set
\ some important user variables whose initial values are determined at
\ run time.

\ Top of memory and dictionary limit
   'user memtop  stw  t5,*

\ Set the up0 user variable
   'user up0  stw  up,*

\ Establish the return stack and set the rp0 user variable
   mr    rp,r5			\ Set rp
   'user rp0  stw  rp,*
   rs-size-t negate  addi  r5,r5,*	\ allocate space for the return stack

\ Establish the Parameter Stack
   'user sp0   stw  r5,*
   addi   sp,r5,4		\ account for the top of stack register

   ps-size-t negate  addi  r5,r5,*	\ Allocate the stuff on the stack

   'user limit   stw  r5,*	\ Top of dictionary growth area

\ Set the dictionary pointer
   add   t1,t1,base		\ Base + text size
   'user dp   stw   t1,*	\ Set dp

\ Save the address of the system call table in the user variable syscall-vec
   'user syscall-vec  stw  r4,*

\ Set the value of #args and args
   'user #args   stw  r6,*
   'user args    stw  r7,*

\ Set the next pointer
   mtspr  ctr,up

\ Enter Forth
   'body cold 4 -   set  ip,*
   add   ip,ip,base
c;

headers

[ifdef] little-endian-under-simulator
: sys-init-io
   sys-init-io
   ['] default-type is (type
   ['] dumb-expect  is expect
   ['] lf-pstr      is newline-pstring
;
[then]

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
