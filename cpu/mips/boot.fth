\ See license at end of file
purpose: Low-level startup code for MIPS

\ boot.fth -- Version for running Forth on Q-system

headers

\ Boot code (cold start).  The cold start code is executed
\ when Forth is initially started.  Its job is to initialize the Forth
\ virtual machine registers.

\ 	r: cause of entry (could = xir-magic)
\	%i6: base of physical memory (is it phys or virt?)
\	%i7: size of physical memory 

\ MAJC entry assumption: code has been placed where loader wanted it;
\ Loader passes in physical address of base of ram to use as RAM in r8,
\  top of RAM in r9

headerless
defer rom-init-io
headers	\ Debugging is difficult if rom-init-environment is headerless
defer rom-init-environment
headerless
defer rom-cold-hook

: rom-cold  (s -- )
   hex
   rom-init-io				  \ Memory allocator and character I/O
   do-init				  \ Kernel

   stand-init-debug?  case
      -1 of
         cr ." Type 'i' to interrupt stand-init sequence" cr 
         d# 500 ms
         key?  if  key drop  ." Interacting" cr  interact  then
      endof
      1  of
        ." Interacting" cr  interact
      endof
   endcase

   ['] rom-init-environment guarded	  \ Environmental dependencies
   ['] rom-cold-hook        guarded	  \ Open Firmware final startup

   title
   quit
;

: abs-jal  ( adr -- )
   2 >> h# 3ff.ffff land  h# 0c00.0000 or  ,
;

label rom-cold-code  ( a0: fw-RAM-base a1: fw-RAM-size -- )

   \ Find the base address
[ifndef] rom-based?
   h# 81f0.0000 $a0 set		\ Load address
   h# 8200.0000 $a1 set		\ FW RAMtop
[then]
   here 8 + bal

   here origin - 4 + base  set	\ base = relative address of this instruction
   ra       base base  subu	\ Base address of Forth kernel

   \ Copy the initial contents of the user area to their final positions

   \ Get the address of the initial contents of the user area
   base h# -20   t4   addi	\ Address of dictionary file header
   ( base )  t4  d# 1  4* t1   lw	\ Size of initial dictionary
   base t1       t1   addu	\ Address of user area image

   user-size     t0   set
   $a1  t0       up   subu	\ RAM address of user area
   ( base )  t4  d# 2 4*  t2   lw	\ Size of user area image

   'body main-task t3 set	\ Allow the exception handler to find the
   base t3       t3   addu	\ user area by storing the address of the
   up   t3            put	\ main user area in the "constant" main-task

   \ Copy the initial User Area image to the RAM copy
   begin
      t2  -4  t2  addi
      t1  t2  t3  addu
      t3  t3      get
      up  t2  t5  addu
      t3  t5      put
   t2 0 =  until
   nop

   t4 0  t4  lb		\ Get first byte of header
   h# 10 $at li		\ Most significant byte of "branch" instruction
   t4 $at <>  if
   $0   t4  move		\ Delay - set flag to 0 (big-endian)
      $0 -1  t4  addiu		\ Set flag to -1 (little-endian)
   then
   t4  'user in-little-endian?  sw

   \ The User Area is now initialized
   $a1 'user memtop   sw	\ Set memtop
   up  'user up0      sw   	\ Set the up0 user variable
   up  rp             move	\ Set return stack pointer
   rp  'user rp0      sw	\ Set the rp0 user variable
   rp  rs-size negate sp  addi	\ Set data stack pointer
   sp  'user sp0      sw	\ Set the sp0 user variable
   sp  ps-size negate t3  addi	\ Compute limit
   sp  /n             sp  addi	\ Account for the top of stack register

   t3 initial-heap-size negate t3  addi	\ Less heap
   t3  'user limit    sw	\ Set the limit user variable

[ifdef] global-dictionary
   'body dp       t5  set
   base t5        t5  addu
   t1             t5  put	\ Set dp
[else]
   t1  'user dp       sw	\ Set the dp user variable
[then]

   \ Clear return stack area
   rp  rs-size negate  rp  addi
   rs-size             t0  set
   t1  t1              t1  xor
   begin
     t0  -4  t0  addi
     t1  rp      put
   t0 0 =  until
   nop
   rp  rs-size  rp  addi

   \ Enter Forth
   np@ origin-  np  set
   np  base     np  addu

   'body rom-cold ip  set
   ip  base       ip  addu
c;

[ifndef] rom-based?
: put-jump  ( target-adr branch-adr -- )
   tuck ( 4 - ) - rom-base +  h# 20 +  2/ 2/ h# 03ff.ffff and 
   h# 0800.0000 or
   swap !
;
[then]

: install-rom-cold  ( -- )
   " stand-init-io"  $find-name is rom-init-io
   " stand-init"     $find-name is rom-init-environment
   " startup"        $find-name is rom-cold-hook

[ifdef] rom-based?
   rom-cold-code origin- origin !
[else]
   rom-cold-code origin put-jump
[then]
;

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
