purpose: Startup code for running under the C wrapper
\ See license at end of file

\ Version for running Forth as a Unix user process

\ Boot code (cold start).  The cold start code is executed
\ when Forth is initially started.  Its job is to initialize the Forth
\ virtual machine registers.

hex

only forth also labels also meta also definitions

0 constant main-task
: init-user  (s -- )  ;

headerless

\ Stuff initialized at cold start time

nuser memtop		\ The top of the memory used by Forth
0 value #args		\ The process's argument count
0 value args		\ The process's argument list

: process-command-line  ( -- )  ;

\ This code gets control shortly after Forth is first called from the
\ C wrapper program (the executable file "forth").  At the beginning
\ of the Forth dictionary, there is a branch instruction that branches
\ to the following code. 

label cold-code  ( -- )
here-t  cld 8 + branch!
\ called with   forth_startup(header-adr, functions, mem_end, &gargc, &gargv)
\ 				 a0	    a1	      a2	a3	a4

   sp 10   t8  lw	\ &gargv

\ Get a fresh set of local registers.
   sp 8 /n* negate  sp  addiu   \ Make room on stack
   s0   sp  0  sw	\ Save registers
   s1   sp  4  sw
   s2   sp  8  sw
   s3   sp  c  sw
   s4   sp 10  sw
   s5   sp 14  sw
   s6   sp 18  sw
   s7   sp 1c  sw

\ Allocate high memory for the stacks and stuff, starting at memtop and
\ allocating downwards.  a2 contains the "mem_end" argument passed in
\ from C; we use it as an the allocation pointer.

   $a2              t6  move	\ We'll need this value later for memtop

\ Find the user area size from the header. a0 contains the "header-adr"
\ argument passed in from C.

   $a0 8            t4  lw	\ Data size = user area size in t4
   bubble

\ Allocate the RAM copy of the User Area

   $a2  t4         $a2  subu	\ Allocate the bytes
   $a2             up   move	\ Set user pointer

   $a0 20         base  addiu	\ Base address of image

   'body main-task  t5  li	\ Allow the exception handler to find the
   t5 base          t5  addu	\ user area by storing the address of the
   up             t5 0  sw	\ main user area in the "constant" main-task

\ Copy the initial User Area image to the RAM copy
   $a0 4            t3  lw	\ Text size = offset to start of data
   up               t7  move	\ Destination pointer (load delay)
   t3 base          t3  addu	\ Relocate Init-up pointer in t3
   t3  t4           t4  addu	\ t4 = source limit

   begin
      t3 0   t5  lw		\ Read a longword
      t3 4   t3  addiu		\ (load delay) Increment src
      t5   t7 0  sw		\ Write a longword
   t3 t4  = until		\ Loop until limit is reached
      t7 4   t7  addiu		\ Increment destination (delay slot)

\ Now the user area has been copied to the proper place, so we can set
\ some important user variables whose inital values are determined at
\ run time.

\ Little-endian flag
   $a0 0  t0  lb		\ Get first byte of header
   h# 10  t1  li		\ Most significant byte of "branch" instruction
   t0 t1  <>  if
   $0   t0  move		\ Delay - set flag to 0 (big-endian)
      $0 -1  t0  addiu		\ Set flag to -1 (little-endian)
   then
   t0  'user in-little-endian?  sw

\ Top of memory and dictionary limit
   t6    'user memtop  sw	\ t6 contains the mem_end value saved above

\ Set the up0 user variable
   up        'user up0  sw

\ Establish the return stack and set the rp0 user variable
   $a2       rp          move	\ Set rp register
   rp        'user rp0   sw	\ Save in rp0 user variable
   $a2 rs-size-t negate  $a2    addiu   \ allocate space for the return stack

\ Establish the Parameter Stack
   $a2 20 negate   $a2   addiu	\ Guard band between Parameter Stack and TIB
   $a2      'user sp0   sw	\ Store initial stack pointer in sp0 user var.
   $a2 /n   sp          addi	\ /n accounts for the top of stack register

   $a2 ps-size-t negate  $a2   addiu	\ Allocate space for the stack

   t6 $a2    $at  sltu
   $at $0  <> if  nop
      t6  $a2  move
   then
   $a2    'user limit   sw	\ Set the dictionary limit value


\ Save the address of the system call table in the user variable syscall-vec
\ $a1 constains the value of the "functions" argument passed in from C.
   $a1  up syscall-user#  sw

\ Set the dictionary pointer; $a0 is the header address
   $a0 4     t0         lw	\ Text size field from header
   bubble
   t0 base   t0         add	\ Base + text_size = text_end_adr

\ $a0 8     t1         lw		\ Data size field from header
\ t0 t1     t0         add	\ preserve ua init area so restart is faster

   t0        'user dp   sw	\ Set dp

   $a3    'user #args   sw	\ Set argc and argv
   t8     'user args    sw

   (next)    np         li
   np base   np         addu	\ Set NEXT pointer

\ Enter Forth
   'body cold      ip   li	\ Relative address of "cold" Forth word
   ip base         ip   addu	\ Relocate it to an absolute address

c;				\ c; automatically assembles "next"
				\ so this enters Forth executing "cold"

0 [if]
: warm  ( -- )  ." Warm start"  cr  quit  ;

label warm-code  ( -- )

   here-t 8 +   $0   bgezal
   nop
   here-t       base li		\ Offset to here
   ra  base     base subu	\ base: Absolute address of origin

   'body main-task  up  li	\ Find the user area
   up base          up  add
   up 0             up  lw

   'user rp0        rp  lw	\ Set the return stack pointer
   'user sp0        sp  lw	\ Set the data stack pointer
   sp /n            sp  addi	\ /n accounts for the top of stack register

   (next)    np         li
   np base   np         addu	\ Set NEXT pointer

\ Enter Forth
   'body warm       ip  li	\ Relative address of "cold" Forth word
   ip base          ip  addu	\ Relocate it to an absolute address

c;				\ c; automatically assembles "next"
				\ so this enters Forth executing "warm"
[then]
headers

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
