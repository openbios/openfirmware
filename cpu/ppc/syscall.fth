purpose: Low-level I/O interface for use with the C "wrapper" program
\ See license at end of file

\ The C program provides the Forth kernel with an array of entry-points
\ into C subroutines for performing the actual system calls.
\ This scheme should be reasonably compatible with nearly any Unix
\ implementation.  The only difference would be in the implementation of
\ "syscall", which has to look up the address of the actual system call
\ C routine in the system call table provided to it by the C program loader.
\ It then has to convert the stack arguments into the same form as is
\ expected by the C system call routines.  This obviously depends on the
\ details of the C calling sequence, but should not be too hard because
\ C compilers usually pass arguments on the stack.
\    Syscall is defined in the kernel, because it is needed for basics like
\ key and emit.

decimal

/l ualloc-t  dup equ syscall-user#
user syscall-vec   \ long address of system call vector
nuser sysretval

\ I/O for running under an OS with a C program providing actual I/O routines

meta
code syscall ( call# -- )
   lwz	 r3,0(sp)  	\ Get some arguments
   lwz   r4,4(sp)
   lwz   r5,8(sp)
   lwz   r6,12(sp)
   lwz   r7,16(sp)
   lwz   r8,20(sp)

   'user syscall-vec   lwz   t0,*	\ Get address of system call table
   cmpi  0,0,t0,0
   0<> if
      andi. r0,t0,1	\ If low bit is set, this is not a TOC-based system
      0<> if
         rlwinm t0,t0,0,0,30	\ Clear low bit
         lwzx   t2,t0,tos	\ Code address in t2
      else
         lwzx  t1,t0,tos	\ ptr-glue address in t1
         lwz   t2,0(t1)		\ Code address
         lwz   r2,4(t1)		\ New TOC
      then
      mtspr lr,t2
      bclrl 20,0
      mtspr ctr,up	\ Restore CTR
   else
      tw	0,tos,tos	\ XXX Hack for use with simulator
   then

   'user sysretval  stw  r3,*	\ Save the result

   lwz   tos,0(sp)		\ Fix stack
   addi  sp,sp,4
c;
: retval   ( -- return_value )     sysretval l@  ;
: lretval  ( -- l.return_value )   sysretval l@  ;

nuser errno	\ The last system error code
: error?  ( return-value -- return-value error? )
   dup 0< dup  if  60 syscall retval errno !  then   ( return-value flag )
;

true value powerpc?	\ As opposed to POWER.  Set by startup code

code u/mod  (s u.dividend u.divisor -- u.remainder u.quotient )
   second-to-t0	\ dividend
   'user powerpc?   lwz t3,*
   cmpi  0,0,t3,0
   0=  if		\ Use POWER division (RS/6000)
      mtspr mq,t0
      addi  t0,r0,0
      div   t1,t0,tos   \ quotient in t1
      mfspr t2,mq
   else
      divwu t1,t0,tos   \ quotient in t1
      mullw t2,t1,tos   \ quot*divisor in t2
      subfc t2,t2,t0    \ remainder in t2 \ Use subfc for POWER compatibility
   then
   stw   t2,0(sp)	\ Put remainder on stack
   mr    tos,t1		\ Put quotient on stack
c;

: /    (s n1 n2 -- quot )  /mod  nip   ;
: mod  (s n1 n2 -- rem )   /mod  drop  ;

\ 32*32->64 bit unsigned multiply
\            y  rs2     y  rd

code um*   ( n1 n2 -- x[lo hi] )
   second-to-t0
   'user powerpc?   lwz t3,*
   cmpi  0,0,t3,0
   0= if		\ Use POWER, not PowerPC, division
      mul    tos,t0,tos
      mfspr  t1,mq
   else
      mullw  t1,t0,tos
      mulhwu tos,t0,tos
   then
   stw    t1,0(sp)
c;

code m*  ( n1 n2 -- low high )
   second-to-t0
   'user powerpc?  lwz t3,*	\ "patch" div instr for simulator
   cmpi  0,0,t3,0
   0= if		\ Use POWER, not PowerPC multiplication
      mul    tos,t0,tos
      mfspr  t1,mq
   else
      mullw  t1,t0,tos
      mulhw  tos,t0,tos
   then
   stw    t1,0(sp)
c;

\ Rounds down to a block boundary.  This causes all file accesses to the
\ underlying operating system to occur on disk block boundaries.  Some
\ systems (e.g. CP/M) require this; others which don't require it
\ usually run faster with alignment than without.

\ Aligns to a 512-byte boundary
hex
: _falign  ( l.byte# fd -- l.aligned )  drop  1ff invert and  ;
: _dfalign  ( d.byte# fd -- d.aligned )  drop  swap 1ff invert and swap  ;

code $sim-find-next  (s adr len link -- adr len alf true  |  adr len false )
   mr   r6,tos
   mr   r5,base
   lwz  r4,0(sp)
   lwz  r3,1cell(sp)
   addi sp,sp,-4
   mr   r7,sp
   twi  0,tos,0
   or.  tos,tos,tos
   0=  if
      addi sp,sp,4
   then
c;

: set-endian  ( -- )
   here off  1 here c! here @ 1 = is in-little-endian?
;

\ : aix-flush-cache  ( adr -- adr )  4 swap sys-flush-cache nip  ;
: sys-init-io  ( -- )
\ ['] drop origin - ['] set-swap-bit >body >user !
   install-wrapper-io
\   ['] aix-flush-cache is flush-cache
   install-disk-io
   \ Don't poll the keyboard under Unix; block waiting for a key
   ['] (key              ['] key            (is
   syscall-vec @  0=  if  ['] $sim-find-next is $find-next  then

   set-endian

\   allocate-buffers

\   init-keyboard
\   init-disk-files

\   decimal
;
' sys-init-io is init-io

: sys-init ;  \ Environment initialization chain
' sys-init is init-environment
decimal

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
