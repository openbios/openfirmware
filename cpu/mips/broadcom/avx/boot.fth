purpose: Low-level startup code for MIPS
copyright: Copyright 2000-2001, FirmWorks.  All Rights Reserved.

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

create debug-reset
fload ${BP}/arch/mips/broadcom/avx/report.fth

headerless
defer rom-init-io
headers	\ Debugging is difficult if rom-init-environment is headerless
defer rom-init-environment
headerless
defer rom-cold-hook

: rom-cold  (s -- )
begin uart-base h# 3fd + c@ h# 20 and until
ascii r uart-base h# 3f8 + c!
   hex
   rom-init-io				  \ Memory allocator and character I/O
begin uart-base h# 3fd + c@ h# 20 and until
ascii o uart-base h# 3f8 + c!
   do-init				  \ Kernel
begin uart-base h# 3fd + c@ h# 20 and until
ascii m uart-base h# 3f8 + c!
[ifdef] notyet
   stand-init-debug?  if
      cr ." Type 'i' to interrupt stand-init sequence" cr 
      d# 200 ms
      key?  if  key drop  ." Interacting" cr  interact  then
   then
[then]
begin uart-base h# 3fd + c@ h# 20 and until
ascii c uart-base h# 3f8 + c!
." hello" cr
   ['] rom-init-environment guarded	  \ Environmental dependencies
begin uart-base h# 3fd + c@ h# 20 and until
ascii d uart-base h# 3f8 + c!
   ['] rom-cold-hook        guarded	  \ Open Firmware final startup

   title
   quit
;

: abs-jal  ( adr -- )
   2 >> h# 3ff.ffff land  h# 0c00.0000 or  ,
;

label rom-cold-code  ( a0: fw-RAM-base a1: fw-RAM-size -- )

[ifdef] debug-reset
carret ?report
linefeed ?report

$a0 s7 move
dot
$a1 $a0 move dot
s7 $a0 move

ascii C ?report
[then]

   \ Find the base address
[ifdef] rom-based?
   here 8 + bal
[else]
   h# 81f0.0000 $a0 set
   h# 8200.0000 $a1 set

   here origin - 8 + rom-base + abs-jal	\ ra = Absolute address of next instruction
[then]
   here origin - 4 + base  set	\ base = relative address of this instruction
   ra       base base  subu	\ Base address of Forth kernel

   \ Copy the initial contents of the user area to their final positions

ascii O ?report
   \ Get the address of the initial contents of the user area
   base h# -20   t4   addi
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
      up  t2  t4  addu
      t3  t4      put
   t2 0 =  until
   nop

ascii L ?report
[ifdef] debug-reset
up 0 $a0 lw dot
up 4 $a0 lw dot
[then]

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
   t1  'user dp       sw	\ Set the dp user variable

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

ascii D ?report
   \ Enter Forth
   np@ origin-  np  set
   np  base     np  addu

   'body rom-cold ip  set
   ip  base       ip  addu

[ifdef] debug-reset
carret ?report
linefeed ?report
np $a0 move dot
base $a0 move dot
up $a0 move dot
tos $a0 move dot
ip $a0 move dot
rp $a0 move dot
sp $a0 move dot
carret ?report
linefeed ?report
np 0 $a0 lw dot
np 4 $a0 lw dot
np 8 $a0 lw dot
np h# c $a0 lw dot
np h# 10 $a0 lw dot
np h# 14 $a0 lw dot
carret ?report
linefeed ?report
ip 0 $a0 lw dot
[then]

c;

: put-jump  ( target-adr branch-adr -- )
   tuck ( 4 - ) - rom-base + ( h# 20 + )  2/ 2/ h# 03ff.ffff and 
   h# 0800.0000 +
   swap !
;

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

