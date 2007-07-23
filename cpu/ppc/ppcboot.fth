purpose: PowerPC Forth startup code
\ See license at end of file

hex

\ Boot code (cold and warm start).  The cold start code is executed
\ when Forth is initially started.  Its job is to initialize the Forth
\ virtual machine registers.  The warm start code is executed when Forth
\ is re-entered, perhaps as a result of an exception.

hex

warning @ warning off
: stand-init-io  ( -- )
   stand-init-io

\  inituarts		\ Already done in startup code
   install-uart-io

   ['] noop        to mark-error
   ['] noop        to show-error
   ['] reset-all   to bye
   ['] crlf-pstr   to newline-pstring
   ['] no-swap-map to init-swap-map

   real-mode? to use-real-mode?
;
warning !

headerless
defer rom-init-io
headers	\ Debugging is difficult if rom-init-environment is headerless
defer rom-init-environment
headerless
defer rom-cold-hook

: rom-cold  (s -- )
   hex
\   ?putc $
   rom-init-io				  \ Memory allocator and character I/O
\   ?putc #
   do-init				  \ Kernel
\   ?putc %
   stand-init-debug?  if
      cr ." Type 'i' to interrupt stand-init sequence" cr 
      d# 200 ms
      key?  if  key drop  ." Interacting" cr  interact  then
   then
   ['] rom-init-environment guarded	  \ Environmental dependencies
   ['] rom-cold-hook        guarded	  \ Open Firmware final startup

   fw-title
   quit
;

[ifndef] ,64bit?
: ,64bit?  ( -- )
   " mfspr r0,pvr  rlwinm r0,r0,16,16,31  cmpi 0,0,r0,20  =" evaluate
;
[then]

label synchronize-caches  ( scratch: r0 r3 r4 )

   \ Flush Dcache if it's on

   mfspr   r3,hid0
   andi.   r3,r3,h#4000
   0<>  if
      ,64bit?  if
         h# 10000 64 /  set r4,*	\ #cache-lines
         mtspr  ctr,r4
         set    r4,64			\ /cache-line
      else
         h# 10000 32 /  set r4,*	\ #cache-lines
         mtspr  ctr,r4
         set    r4,32			\ /cache-line
      then

      neg    r3,r4		\ Begin at 0 - /cache-line

      begin
         lbzux   r0,r3,r4	\ Touch each cache block
      countdown			\ from [0 to 64K) (0x800 * 0x20)

      neg        r4,r4		\ Prepare to count down
      begin
         dcbf    r0,r3		\ Flush each block
         add.    r3,r3,r4	\ on the way back down to 0
      0<> until
   then

   \ Invalidate Icache if it's on

   mfspr   r3,hid0
   andi.   r3,r3,h#8000
   0<>  if
      mfspr  r3,hid0
      ori    r0,r3,h#800
      sync isync
      mtspr  hid0,r0	\ Set the invalidate bit
      sync isync
      mtspr  hid0,r3	\ Clear the invalidate bit for 603
      sync isync
   then

   bclr 20,0
end-code

[ifndef] nv-adr-low
h# 74 constant nv-adr-low
h# 75 constant nv-adr-high
h# 77 constant nv-data
[then]

create force-big-endian
\ \needs read-le-flag  fload ${BP}/arch/prep/leflag.fth

label memcpy  ( r3: dst r4: src r5: n -- r3: dst )
   mtspr  ctr,r5
   mr     r6,r3

   addi   r3,r3,-1	\ Account for pre-decrement
   addi   r4,r4,-1	\ Account for pre-decrement
   begin
      lbzu r5,1(r4)
      stbu r5,1(r3)
   countdown

   mr    r3,r6		\ Return dst
   bclr  20,0
end-code

[ifdef] switcheroo
label ?switch-endian
   mfspr   r30,lr

   switcheroo origin - set r4,*
   add     r4,r4,base		\ Absolute address of switcheroo code
   set     r3,h#1000	 	\ Temporary RAM location for switcheroo code
   /switcheroo  set  r5,*
   memcpy  bl *

   bla     h#1000		\ Execute the RAM copy of switcheroo

   nop nop nop nop		\ Endian-independent landing pad

   mtspr  lr,r30
   bclr   20,0
end-code
[else]

label move-user-area
\ move-user-area copies the initial user area image to its final RAM location

\ In:  r13: header-adr   r14: little-endian?   r15: allocation pointer
\ Destroys: r20-r24
\ Out: up: final user area address   r15: updated allocation pointer

\ Find the user area size from the header
   lwz   r21,4(r13)		\ Text size = offset to start of data
   lwz   r20,8(r13)		\ Data size = user area size in r20 

\ Allocate high memory for the stacks and stuff, starting at memtop and
\ allocating downwards.  r15 is the allocation pointer.

\ Allocate the RAM copy of the User Area
   subf    r15,r20,r15
   rlwinm  r15,r15,0,0,28	\ doubleword-align by clearing 3 low bits 
   mr      up,r15		\ Set user pointer

   \ Copy the initial User Area image to the RAM copy
   add    r23,r21,base		\ Init-up pointer in r23 
   mr     r22,up		\ Destination pointer

   srawi  r20,r20,2
   mtspr  ctr,r20
   addi   r23,r23,-4		\ Account for pre-incrementing
   addi   r22,r22,-4		\ Account for pre-incrementing
   begin			\ Copy without byte swapping
      lwzu  r20,4(r23)
      stwu  r20,4(r22)
   countdown

   bclr   20,0
   nop

end-code
[then]

\ create uboot-entry
label rom-cold-code  ( r3:fw-RAM-base r4:fw-RAM-size -- )

[ifdef] uboot-entry
   set r13,h#0f000000		\ Firmware memory base address in r13
   set r11,h#00200000		\ Firmware memory size in r11
[else]
   mr  r13,r3			\ Firmware memory base address in r13
   mr  r11,r4			\ Firmware memory size in r11
[then]

   lwz r12,0(r0)		\ Get memsize from low memory

   add r15,r13,r11		\ r15 is the allocation pointer

carret ?report
linefeed ?report
ascii A ?report

[ifdef] force-big-endian
   set r14,0
[else]
   read-le-flag  bl *
   mr r14,r3
[then]

   \ Allocate HTAB
   ,64bit?  if			\ 64-bit CPUs
      set r22,h#40000		\ /htab-64
   else				\ 32-bit CPUs
      set   r22,h#10000		\ /htab-32
   then
   rlwinm   r2,base,0,0,19	\ Round base down to page boundary

   subf     r15,r22,r15
   mr       r6,r15

ascii B ?report
\ Find the base address
   here 4 +   bl   *		\ Absolute address of next instruction
   here origin - set base,*	\ Relative address of this instruction
   mfspr   r0,lr
   subf    base,base,r0		\ Base address of Forth kernel

[ifdef] ?switch-endian
   ?switch-endian  bl *

" ppcboot.fth: Do we need to sync caches after endian switch?" ?reminder
\ set r3,h#1f0.0000 set r4,h#10.0000  sync-cache bl *
\ mr  r3,up   user-size set r4,*  sync-cache bl *
[else]
\   mr r3,r13 .r3
\   lwz r3,4(r13) .r3
   lwz r3,8(r13) .r3

   move-user-area  bl *
[then]

ascii Q ?report
[ifdef] ?enter-virtual-mode
   mr    r3,r13			\ Firmware memory base address
   mr    r4,r11			\ Firmware memory size

   ?enter-virtual-mode  bl *	\ Returns virt minus phys offset
   mr    r16,r3
[else]
    set   r16,0			\ Set virtual-physical offset to 0
[then]

ascii R ?report
   add   r15,r15,r16		\ Convert allocation pointer to virtual
   add   up,up,r16		\ Convert user pointer to virtual

   \ This must be done after we switch modes because longwords may be
   \ exchanged in the RAM copy of the user area prior to the mode switch.
   'user in-little-endian?  stw  r14,*  \ Assert mode for Forth code
   'user virt-phys          stw  r16,*  \ Assert mode for Forth code

   'user htab-phys  stw  r6,*	\ Allocated address of hash table
   add   r2,r2,r16		\ Convert htab address to virtual
   'user htab       stw  r6,*	\ Allocated address of hash table

ascii J ?report

\ Find the base address
   here 4 +   bl   *		\ Absolute address of next instruction
   here origin -  set  base,*	\ Relative address of this instruction
   mfspr   r22,lr
   subf    base,base,r22	\ Base address of Forth kernel

\ Now the user area has been copied to the proper place, so we can set
\ some important user variables whose inital values are determined at
\ run time.

   'body main-task   set  r22,*	\ Allow the exception handler to find the
        			\ user area by storing the address of the
   stwx  up,base,r22		\ main user area in the "constant" main-task

   set  r0,-1
   'user powerpc?  stw  r0,*

\ Top of memory and dictionary limit
   add   r0,r11,r13		\ Compute memtop
   'user memtop  stw  r0,*
   'user memsize stw  r12,*

\ Set the up0 user variable
   'user up0  stw  up,*

\ Establish the return stack and set the rp0 user variable
   mr    rp,r15			\ Set rp
   'user rp0  stw  rp,*
   rs-size negate  addi  r15,r15,*	\ allocate space for the return stack

ascii K ?report
\ Establish the Parameter Stack
   'user sp0   stw  r15,*
   addi   sp,r15,4		\ account for the top of stack register

   ps-size negate  addi  r15,r15,*	\ Allocate the stuff on the stack

   initial-heap-size  set  r22,* \ Reserve some space for the heap
   subf    r15,r22,r15
   'user limit   stw  r15,*	\ Top of dictionary growth area

\ Set the dictionary pointer
   add   r21,r21,base		\ Base + text size
   'user dp   stw   r21,*	\ Set dp

ascii L ?report
\ Save the address of the system call table in the user variable syscall-vec
   set r0,0
   'user syscall-vec  stw  r0,*

\ Set the value of #args and args
   'user #args   stw  r0,*
   'user args    stw  r0,*

   synchronize-caches  bl *

ascii M ?report
\ Set the next pointer
   mtspr  ctr,up

ascii N ?report
\ Enter Forth
   'body rom-cold 4 -   set  ip,*
   add   ip,ip,base
\ ctr:np w:r25, base:r26, up:r27, tos:r28, ip:r29, rp:r30, sp: r31
h# 20 ?report
mfspr r3,ctr .r3  mr r3,base .r3  mr r3,up .r3   mr r3,ip .r3  mr r3,rp .r3  mr r3,sp .r3  
lwz r3,0(ip) .r3
carret ?report
c;

: install-rom-cold  ( -- )
   " stand-init-io"  $find-name is rom-init-io
   " stand-init"     $find-name is rom-init-environment
   " startup"        $find-name is rom-cold-hook

   rom-cold-code origin put-branch
;

headers

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
