purpose: System Control Coprocessor access words
\ See license at end of file

hex
code scc-id@            ( -- n )   psh tos,sp  mrc p15,0,tos,cr0,cr0,0  c;
code cache-type@        ( -- n )   psh tos,sp  mrc p15,0,tos,cr0,cr0,1  c;
code tlb-type@          ( -- n )   psh tos,sp  mrc p15,0,tos,cr0,cr0,3  c;
code mp-id@             ( -- n )   psh tos,sp  mrc p15,0,tos,cr0,cr0,5  c;
code control@           ( -- n )   psh tos,sp  mrc p15,0,tos,cr1,cr0,0  c;
code aux-control@       ( -- n )   psh tos,sp  mrc p15,0,tos,cr1,cr0,1  c;
code coprocessor-access@ ( -- n )  psh tos,sp  mrc p15,0,tos,cr1,cr0,2  c;
code ttbase@            ( -- n )   psh tos,sp  mrc p15,0,tos,cr2,cr0,0  c;
code ttbase0@           ( -- n )   psh tos,sp  mrc p15,0,tos,cr2,cr0,0  c;
code ttbase1@           ( -- n )   psh tos,sp  mrc p15,0,tos,cr2,cr1,0  c;
code ttcontrol@         ( -- n )   psh tos,sp  mrc p15,0,tos,cr2,cr2,0  c;
code domain-access@     ( -- n )   psh tos,sp  mrc p15,0,tos,cr3,cr0,0  c;
code fault-status@      ( -- n )   psh tos,sp  mrc p15,0,tos,cr5,cr0,0  c;
code i-fault-status@    ( -- n )   psh tos,sp  mrc p15,0,tos,cr5,cr1,0  c;
code fault-address@     ( -- n )   psh tos,sp  mrc p15,0,tos,cr6,cr0,0  c;
code wp-fault-address@  ( -- n )   psh tos,sp  mrc p15,0,tos,cr6,cr1,0  c;
code i-fault-address@   ( -- n )   psh tos,sp  mrc p15,0,tos,cr6,cr2,0  c;

code control!           ( n -- )   mcr p15,0,tos,cr1,cr0,0  pop tos,sp  c;
code aux-control!       ( n -- )   mcr p15,0,tos,cr1,cr0,1  pop tos,sp  c;
code coprocessor-access! ( n -- )  mcr p15,0,tos,cr1,cr0,2  pop tos,sp  c;
code ttbase!            ( n -- )   mcr p15,0,tos,cr2,cr0,0  pop tos,sp  c;
code ttbase0!           ( n -- )   mcr p15,0,tos,cr2,cr0,0  pop tos,sp  c;
code ttbase1!           ( n -- )   mcr p15,0,tos,cr2,cr1,0  pop tos,sp  c;
code ttcontrol!         ( n -- )   mcr p15,0,tos,cr2,cr2,0  pop tos,sp  c;
code domain-access!     ( n -- )   mcr p15,0,tos,cr3,cr0,0  pop tos,sp  c;
code fault-status!      ( n -- )   mcr p15,0,tos,cr5,cr0,0  pop tos,sp  c;
code i-fault-status!    ( n -- )   mcr p15,0,tos,cr5,cr1,0  pop tos,sp  c;
code fault-address!     ( n -- )   mcr p15,0,tos,cr6,cr0,0  pop tos,sp  c;
code wp-fault-address!  ( n -- )   mcr p15,0,tos,cr6,cr1,0  pop tos,sp  c;
code i-fault-address!   ( n -- )   mcr p15,0,tos,cr6,cr2,0  pop tos,sp  c;

code c7-wfi             ( -- )     mcr p15,0,r0,cr7,cr0,4  c;

code flush-i$           ( -- )     mcr p15,0,r0,cr7,cr5,0  c;
code flush-i$-entry     ( va -- )  mcr p15,0,tos,cr7,cr5,1  pop tos,sp c;
code flush-i$-entry-way ( sw -- )  mcr p15,0,tos,cr7,cr5,2  pop tos,sp c;
code flush-prefetch     ( -- )     mcr p15,0,r0,cr7,cr5,4  c;
code flush-bt$          ( -- )     mcr p15,0,r0,cr7,cr5,6  c;
code flush-bt$-entry    ( va -- )  mcr p15,0,tos,cr7,cr5,7  pop tos,sp c;

code flush-d$           ( -- )     mcr p15,0,r0,cr7,cr6,0  c;
code flush-d$-entry     ( va -- )  mcr p15,0,tos,cr7,cr6,1  pop tos,sp  c;
code flush-d$-entry-way ( sw -- )  mcr p15,0,tos,cr7,cr6,2  pop tos,sp  c;

code flush-i&d$         ( -- )     mcr p15,1,r0,cr7,cr7,0  c;
code flush-u$           ( -- )     mcr p15,1,r0,cr7,cr7,0  c;
code flush-u$-entry     ( va -- )  mcr p15,1,tos,cr7,cr7,1  pop tos,sp  c;
code flush-u$-way       ( sw -- )  mcr p15,1,tos,cr7,cr7,2  pop tos,sp  c;

code clean-l2$          ( -- )     mcr p15,1,r0,cr7,cr11,0  c;
code clean-l2$-entry    ( va -- )  mcr p15,1,tos,cr7,cr11,1  pop tos,sp  c;
code clean-l2$-way      ( ws -- )  mcr p15,1,tos,cr7,cr11,2  pop tos,sp  c;
code clean-l2$-pa       ( pa -- )  mcr p15,1,tos,cr7,cr11,3  pop tos,sp  c;

code flush-l2$          ( -- )     mcr p15,1,r0,cr7,cr7,0  c;
code flush-l2$-entry    ( va -- )  mcr p15,1,tos,cr7,cr7,1  pop tos,sp  c;
code flush-l2$-way      ( ws -- )  mcr p15,1,tos,cr7,cr7,2  pop tos,sp  c;
code flush-l2$-pa       ( pa -- )  mcr p15,1,tos,cr7,cr7,3  pop tos,sp  c;

code clean&flush-l2$          ( -- )     mcr p15,1,r0,cr7,cr15,0  c;
code clean&flush-l2$-entry    ( va -- )  mcr p15,1,tos,cr7,cr15,1  pop tos,sp  c;
code clean&flush-l2$-way      ( ws -- )  mcr p15,1,tos,cr7,cr15,2  pop tos,sp  c;
code clean&flush-l2$-pa       ( pa -- )  mcr p15,1,tos,cr7,cr15,3  pop tos,sp  c;

\ L2 Cache Extra Features Register
\ Bit 24 is L2 prefetch disable, bit 23 is L2 ECC enable
\ Bit 8 (undocumented) enables write-coalescing
code l2$-efr!  ( n -- )              mcr p15,1,tos,cr15,cr1,0  pop tos,sp  c;  
code l2$-efr@  ( -- n )  psh tos,sp  mrc p15,1,tos,cr15,cr1,0  c;

code l2$-lockdown-way   ( bits -- )  mcr p15,1,tos,cr15,cr10,7  pop tos,sp  c;

code l2$-error@  ( -- n )  psh tos,sp  mcr p15,1,tos,cr15,cr9,6  c;
code l2$-error!  ( n -- )  mcr p15,1,tos,cr15,cr9,6  pop tos,sp  c;

code l2$-error-threshold@  ( -- n )  psh tos,sp  mcr p15,1,tos,cr15,cr9,7  c;
code l2$-error-threshold!  ( n -- )  mcr p15,1,tos,cr15,cr9,7  pop tos,sp  c;

code l2$-error-capture@    ( -- n )  psh tos,sp  mcr p15,1,tos,cr15,cr11,7  c;

code clean-d$           ( -- )     mcr p15,0,r0,cr7,cr10,0  c;
code clean-d$-entry     ( va -- )  mcr p15,0,tos,cr7,cr10,1  pop tos,sp  c;
code clean-d$-way       ( sw -- )  mcr p15,0,tos,cr7,cr10,2  pop tos,sp  c;
code test&clean-d$      ( -- )     mcr p15,0,r0,cr7,cr10,3  c;

code clean-u$           ( -- )     mcr p15,0,r0,cr7,cr11,0  c;
code clean-u$-entry     ( va -- )  mcr p15,0,tos,cr7,cr11,1  pop tos,sp  c;
code clean-u$-way       ( sw -- )  mcr p15,0,tos,cr7,cr11,2  pop tos,sp  c;

code clean&flush-d$             ( -- )     mcr p15,0,r0,cr7,cr14,0  c;
code clean&flush-d$-entry       ( va -- )  mcr p15,0,tos,cr7,cr14,1  pop tos,sp  c;
code clean&flush-d$-entry-way   ( sw -- )  mcr p15,0,tos,cr7,cr14,2  pop tos,sp  c;
code test,clean&flush-d$        ( -- )     mcr p15,0,tos,cr7,cr14,3  c;

code clean&flush-u$             ( -- )     mcr p15,0,r0,cr7,cr15,0  c;
code clean&flush-u$-entry       ( va -- )  mcr p15,0,tos,cr7,cr15,1  pop tos,sp  c;
code clean&flush-u$-entry-way   ( sw -- )  mcr p15,0,tos,cr7,cr15,2  pop tos,sp  c;

code drain-write-buffer ( -- )     mcr p15,0,r0,cr7,cr10,4  c;
alias data-sync-barrier drain-write-buffer
code data-memory-barrier ( -- )    mcr p15,0,r0,cr7,cr10,5  c;

code flush-i&d-tlb      ( -- )     mcr p15,0,r0,cr8,cr7,0  c;
code flush-i&d-tlb-entry ( va -- ) mcr p15,0,tos,cr8,cr7,1  pop tos,sp  c;
code flush-i&d-tlb-asid  ( as -- ) mcr p15,0,tos,cr8,cr7,2  pop tos,sp  c;
code flush-i-tlb        ( -- )     mcr p15,0,r0,cr8,cr5,0  c;
code flush-i-tlb-entry  ( va -- )  mcr p15,0,tos,cr8,cr5,1  pop tos,sp  c;
code flush-i-tlb-asid   ( as -- )  mcr p15,0,tos,cr8,cr5,2  pop tos,sp  c;
code flush-d-tlb        ( -- )     mcr p15,0,r0,cr8,cr6,0  c;
code flush-d-tlb-entry  ( va -- )  mcr p15,0,tos,cr8,cr6,1  pop tos,sp  c;
code flush-d-tlb-asid   ( as -- )  mcr p15,0,tos,cr8,cr6,1  pop tos,sp  c;

code enable-odd-lfsr    ( -- )     mcr p15,0,r0,cr15,cr1,1  c;
code enable-even-lfsr   ( -- )     mcr p15,0,r0,cr15,cr2,1  c;
code clear-lfsr         ( -- )     mcr p15,0,r0,cr15,cr4,1  c;
code lfsr-to-r14        ( -- )     mcr p15,0,r0,cr15,cr8,1  c;
code fast-clock         ( -- )     mcr p15,0,r0,cr15,cr1,2  c;
code slow-clock         ( -- )     mcr p15,0,r0,cr15,cr2,2  c;
code disable-mclk       ( -- )     mcr p15,0,r0,cr15,cr4,2  c;
code wait-for-interrupt ( -- )     mcr p15,0,r0,cr15,cr8,2  c;

code cache-level@  ( -- level )  psh tos,sp  mrc p15,2,tos,cr0,cr0,0  c;
code cache-level!  ( level -- )              mcr p15,2,tos,cr0,cr0,0  pop tos,sp  c;
code cache-size-id@  ( -- n )    psh tos,sp  mrc p15,1,tos,cr0,cr0,0  c;
code cache-level-id@  ( -- n )   psh tos,sp  mrc p15,1,tos,cr0,cr0,1  c;

code silicon-id@  ( -- id )  psh tos,sp  mrc p15,1,tos,cr0,cr0,7  c;

: ttbase  ( -- n )  ttbase@ h# 3ff invert and  ;

: .control  ( -- )  control@  " i..rsb...wcam" show-bits  ;

d# 32 constant /cache-line
: cache-bounds  ( adr len -- end start )
   bounds  swap /cache-line round-up  swap /cache-line round-down
;
: invalidate-cache-range  ( adr len -- )
   dup  if  flush-i$  then
   cache-bounds  ?do  i flush-d$-entry  /cache-line +loop
;
d# 32 constant /cache-line
: flush-d$-range  ( adr len -- )
   bounds  swap /cache-line round-up  swap /cache-line round-down   ?do
      i clean-d$-entry  i flush-d$-entry
   /cache-line +loop
;

code turn-off-dcache  ( adr len -- )
   pop r0,sp  \ tos:len r0:adr
   cmp tos,#0
   <>  if
      begin
         mcr   p15,0,r0,cr7,cr10,1    \ Clean D$ entry
         mcr   p15,0,r0,cr7,cr6,1     \ Flush D$ entry
         add   r0,r0,#32              \ Advance to next line
         decs  tos,#32     \ Assume cache line size of 32 bytes
      0= until
   then
   mcr  p15,0,r0,cr7,cr10,4           \ Drain write buffer
   mrc  p15,0,r0,cr1,cr0,0            \ Read control register
   bic  r0,r0,#4                      \ Clear DCache enable bit
   mcr  p15,0,r0,cr1,cr0,0            \ Write control register
c;

\ System-dependent function to flush the entire cache
\ (In normal ARM nomenclature, as used by most of the words in this file,
\ "flush" means "invalidate without ensuring that cached data has been
\ written to memory", while "clean" means "ensure that cached data has been
\ written to memory".  In normal Open Firmware parlance, "invalidate" means
\ the former and "flush" the latter.  "flush-cache" is a generic Open Firmware
\ operation, so it uses the Open Firmware nomenclature.
defer flush-cache  ' noop to flush-cache

[ifdef] notdef
: l2cache-on   ( -- )  flush-l2$  control@  h# 0400.0000 or          control!  ;
: l2cache-off  ( -- )  clean-l2$  control@  h# 0400.0000 invert and  control!  ;
[else]
: l2cache-on   ( -- )  flush-l2$  aux-control@  2 or          aux-control!  ;
: l2cache-off  ( -- )  clean-l2$  aux-control@  2 invert and  aux-control!  ;
[then]

: bpu-on   ( -- )  flush-bt$  control@  h# 0800 or          control!  ;
: bpu-off  ( -- )             control@  h# 0800 invert and  control!  ;

: icache-on   ( -- )  flush-i$  control@  h# 1000 or          control!  ;
: icache-off  ( -- )            control@  h# 1000 invert and  control!  ;
: dcache-on   ( -- )  flush-d$  control@        4 or          control!  ;
: dcache-off  ( -- )
   control@  dup 4 and  if
      flush-cache
      4 invert and  control!
   else
      drop
   then
;

: write-buffer-on   ( -- )  control@  8 or          control!  ;
: write-buffer-off  ( -- )
   drain-write-buffer control@  8 invert and  control!
;

: stand-sync-cache  ( adr len -- )
   cache-bounds  ?do  i clean-d$-entry  /cache-line +loop
   drain-write-buffer
   flush-i$
;
: stand-init-io  ( -- )
   stand-init-io
   ['] stand-sync-cache to sync-cache
;

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
