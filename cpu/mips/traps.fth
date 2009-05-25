purpose: RAM base exception handlers
\ See license at end of file

only forth also hidden also  forth definitions

headerless

\ Exception:	Vector offset
\ TLB refill	0x000
\ 64TLB refill	0x080
\ Cache error	0x100
\ Others	0x180

: 'vector  ( exception# -- addr )  h# 80 *  ;

\ XXX Need work
label vec0-generic
   
   8   k0         mfc0		\ get BADVADDR
\	_GET_CURRENT(k1)	\ get current task ptr
   k0  d# 22  k0  srl		\ get PGD only bits
\   k1  THREAD_PGDIR  k1  lw	\ get task PG_DIR
   k0  2      k0  sll
   k1  k0     k1  addu		\ add PGD offset
   4   k0         mfc0		\ get CONTEXT
   k0  0      k0  lw
   k0  1      k0  srl		\ get PTE offset
   k0  h# ff8 k0  and
   k1  k0     k1  addu		\ add PTE offset
   k1  0      k0  lw		\ get PTE
   k1  4      k1  lw
   k0  6      k0  srl		\ convert to EntryLo format
   k1  6      k1  srl
   2   k0         mtc0		\ set EntryLo
   3   k1         mtc0
   nop
   tlbwr			\ write random tlb entry
   nop nop nop
   eret				\ return from trap
   nop

end-code

label vec1-generic
   4   k1      mfc0		\ get CP0_CONTEXT
   k1  1   k1  dsra
   k1  0   k0  lwu
   k1  4   k1  lwu
   k0  6   k0  dsrl		\ Convert to EntryLo format
   k1  6   k1  dsrl
   2   k0      dmtc0		\ set EntryLo0
   3   k1      dmtc0		\ set EntryLo1
   nop
   tlbwr
   nop nop nop
   eret
   nop
end-code

: .cacherr  ( CacheErr -- )
   dup h# 8000.0000 and  if  ." data;"  else  ." instruction;"  then
   dup h# 2000.0000 and  if  ."  data field error;"  then
   dup h# 1000.0000 and  if  ."  tag field error;"  then
   dup h# 0800.0000 and  if  ."  error on first doubleword;"  then
   dup h# 0400.0000 and  if  ."  error on SysAD bus;"  then
       h# 0200.0000 and  if  ."  error on one cache"  else  ." error on both caches"  then
;

: cache-error-handler  ( -- )
   ." Cache error at address: " errorepc@ .x
   ." (" cacherr@ .cacherr  ." )" cr
   begin  again
;

label vec2-generic
   here 8 +               bal   \ ra = Absolute address of next instruction
   here origin - 4 + k1   set   \ k1 = relative address of this instruction
   ra       k1       base subu  \ k1 address of Forth kernel

   'body main-task   up   li	\ User pointer address

   \ Set up Forth stacks
   'user sp0   sp   lw
   'user rp0   rp   lw

   \ Account for the presence of the top of stack register
   sp /n   sp   addiu

   np@ origin-  np  set
   np  base     np  addu

   'body cache-error-handler ip set
   ip base ip addu
c;

0 value vector-base
: install-handler  ( handler exception# -- )
   ( exception# ) 'vector vector-base + >r
   ( handler )    lwsplit
   h# 3c1b.0000 or r@     0 + instruction!   \ lui     k1,handler.hi
   h# 377b.0000 or r@     4 + instruction!   \ ori     k1,k1,handler.lo
   h# 0360.0008    r@     8 + instruction!   \ jr      k1
   0               r> h#  c + instruction!   \ nop
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
