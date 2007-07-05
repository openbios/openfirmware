purpose: Cache driver for 603 PowerPC chip
\ See license at end of file

\ XXX - Dcache size is 1MB for Pegakid, because L2 cache is always on.
\ Fix this! Maybe parameterize /dcache?

headerless
d# 32 constant /dcache-block
d# 32 constant /icache-block

code (603-dcache-off)  ( -- )
   \ Don't do anything if the data cache is already off
   mfspr  t1,hid0
   andi.  t1,t1,h#4000
   0=  if
      next
   then

   \ Disable data translations before the flush loop: we'll run
   \ in real mode to make sure there are no mapping problems.
   mfmsr   t2
   rlwinm  t1,t2,0,28,26	\ Disable translation by clearing h#10 bit
   sync isync
   mtmsr   t1
   sync isync
   
   \ Flush Dcache before turning it off
   set     t1,h#10.0000         \ Fill Dcache with known addresses
   begin
      addic.  t1,t1,-32
      lwz     r0,0(t1)
   = until

   set     t1,h#10.0000         \ Size of dcache
   begin
      addic.  t1,t1,-32         \ Size of cache line
      dcbf    r0,t1             \ Flush Dcache line
   = until
   sync

   isync
   mtmsr   t2			\ Restore original MSR
   sync isync
   mfspr   t0,hid0		\ Old HID0 value
   rlwinm  t0,t0,0,18,16	\ Disable cache by clearing h#4000 bit
   isync
   mtspr   hid0,t0
   isync
c;
headers
: 603-dcache-off  ( -- )   lock[ (603-dcache-off) ]unlock  ;
defer dcache-off	' 603-dcache-off to dcache-off
headerless

\ Warning: it is tempting to subtract one from the length, so that it refers
\ to the last byte in the range, and then decrement the index inside the loop.
\ However, that doesn't work because some PowerPC processors (e.g 604), when
\ in little-endian mode, do not appear to perform the following cache
\ operations properly when the effective address is unaligned.  This was
\ determined empirically.

code invalidate-603-i$-range  ( adr len -- )
   mr    t2,tos
   lwz   t0,0(sp)
   lwz   tos,1cell(sp)
   addi  sp,sp,2cells

   \ Don't touch the cache if it's off
   mfspr  t1,hid0
   andi.  t1,t1,h#8000
   0<>  if
      add       t0,t0,t2	\ Bias the base so we can increment the index
      neg.      t2,t2		\ Bias the index
      ahead begin   
         icbi   t0,t2
         addic. t2,t2,32
      but then  0>= until
      sync
   then
c;
defer invalidate-i$-range   ' invalidate-603-i$-range to invalidate-i$-range

code flush-603-d$-range  ( adr len -- )
   mr    t2,tos
   lwz   t0,0(sp)
   lwz   tos,1cell(sp)
   addi  sp,sp,2cells

   \ Don't touch the cache if it's off
   mfspr  t1,hid0
   andi.  t1,t1,h#4000
   0<>  if
      add       t0,t0,t2	\ Bias the base so we can increment the index
      neg.      t2,t2		\ Bias the index
      ahead begin   
         dcbf   t0,t2
         addic. t2,t2,32
      but then  0>= until
      sync
   then
c;
headers
defer flush-d$-range	' flush-603-d$-range to flush-d$-range
headerless

code invalidate-603-d$-range  ( adr len -- )
   mr    t2,tos
   lwz   t0,0(sp)
   lwz   tos,1cell(sp)
   addi  sp,sp,2cells

   \ Don't touch the cache if it's off
   mfspr  t1,hid0
   andi.  t1,t1,h#4000
   0<>  if
      add       t0,t0,t2	\ Bias the base so we can increment the index
      neg.      t2,t2		\ Bias the index
      ahead begin   
         dcbi   t0,t2
         addic. t2,t2,32
      but then  0>= until
      sync
   then
c;
defer invalidate-d$-range   ' invalidate-603-d$-range to invalidate-d$-range

code store-603-d$-range  ( adr len -- )
   mr    t2,tos
   lwz   t0,0(sp)
   lwz   tos,1cell(sp)
   addi  sp,sp,2cells

   \ Don't touch the cache if it's off
   mfspr  t1,hid0
   andi.  t1,t1,h#4000
   0<>  if
      add       t0,t0,t2	\ Bias the base so we can increment the index
      neg.      t2,t2		\ Bias the index
      ahead begin   
         dcbst  t0,t2
         addic. t2,t2,32
      but then  0>= until
      sync
   then
c;
defer store-d$-range	' store-603-d$-range to store-d$-range

: stand-sync-cache  ( adr len -- adr )
   2dup store-d$-range  invalidate-i$-range
;

defer invalidate-icache  ' noop  to invalidate-icache

: invalidate-603-icache  ( -- )  hid0@ dup  h# 800 or hid0!  hid0!  ;
: invalidate-604-icache  ( -- )  hid0@      h# 800 or hid0!  ;

headers
: 603-icache-on  ( -- )
   \ Bail out if it's already on, to avoid causing inconsistencies
   \ with L2 caches during invalidation.
   hid0@  h# 8000 and  if  exit  then

   hid0@
   sticky-cache-invalidate?  if
      h#  800 or         dup hid0!      \ Flush
      h# 8000 or         dup hid0!      \ Turn on
      h#  800 invert and     hid0!      \ Release flush bit
      ['] invalidate-603-icache
   else                                 \ 604
      h# 8800 or             hid0!      \ turn on and invalidate
      ['] invalidate-604-icache
   then
   to invalidate-icache
;
defer icache-on		' 603-icache-on to icache-on

: 603-icache-off  ( -- )
   hid0@  h#  800 or  h# 8000 invert and  hid0!
   ['] noop to invalidate-icache
;
defer icache-off	' 603-icache-off to icache-off

headerless
: 603-dcache-on?  ( -- flag )  hid0@  h# 4000 and  0<>  ;
: 603-icache-on?  ( -- flag )  hid0@  h# 8000 and  0<>  ;
defer dcache-on?	' 603-dcache-on? to dcache-on?
defer icache-on?	' 603-icache-on? to icache-on?

headers
: 603-dcache-on  ( -- )
   \ Bail out if it's already on, to avoid causing inconsistencies
   \ with L2 caches during invalidation.
   dcache-on?  if  exit  then

   hid0@
   sticky-cache-invalidate?  if
      h#  400 or         dup hid0!      \ Invalidate
      h# 4000 or         dup hid0!      \ Turn on
      h#  400 invert and     hid0!      \ Release flush bit
   else
      h# 4400 or             hid0!      \ Invalidate and turn on
   then
;
defer dcache-on		' 603-dcache-on to dcache-on

\ Do this early so that the debugger will work as early as possible
: stand-init-io   ( -- )   stand-init-io
   ['] stand-sync-cache to sync-cache
;

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
