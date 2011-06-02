\ See license at end of file
purpose: Setup the initial virtual address map

[ifdef] notdef
\ Synchronizes the instruction and data caches over the indicated
\ address range, thus allowing the execution of instructions that
\ have recently been written to memory.
label sync-cache-range  \ r0: adr, r1: len
   begin
      mcr  p15, 0, r0, cr7, cr10, 1    \ clean D$ line
      mcr  p15, 0, r0, cr7, cr5, 1     \ invalidate I$ line
      add  r0, r0, #32		       \ Advance to next line
      subs r1, r1, #32
   0<= until
   mov	pc, lr	
end-code

\ Forces data in the cache within the indicated address range
\ into memory.
label clean-dcache-range  \ r0: adr, r1: len
   begin
      mcr  p15, 0, r0, cr7, cr10, 1    \ clean D$ line
      add  r0, r0, #32		       \ Advance to next line
      subs r1, r1, #32
   0<= until
   mov	pc, lr	
end-code
[then]

\ Turn on the caches
label caches-on

   \ Invalidate the entire L1 data cache by looping over all sets and ways
   mov r0,#0                           \ Start with set/way 0 of L1 cache
   begin
      \ In this unrolled loop, the number of iterations (8) and the increment
      \ value (0x20000000) depend on fact that this cache has 8 ways.
      mcr  p15, 0, r0, cr7, cr6, 2     \ Invalidate D$ line by set/index
      inc  r0,#0x20000000              \ Next way
      mcr  p15, 0, r0, cr7, cr6, 2     \ Invalidate D$ line by set/index
      inc  r0,#0x20000000              \ Next way
      mcr  p15, 0, r0, cr7, cr6, 2     \ Invalidate D$ line by set/index
      inc  r0,#0x20000000              \ Next way
      mcr  p15, 0, r0, cr7, cr6, 2     \ Invalidate D$ line by set/index
      inc  r0,#0x20000000              \ Next way
      mcr  p15, 0, r0, cr7, cr6, 2     \ Invalidate D$ line by set/index
      inc  r0,#0x20000000              \ Next way
      mcr  p15, 0, r0, cr7, cr6, 2     \ Invalidate D$ line by set/index
      inc  r0,#0x20000000              \ Next way
      mcr  p15, 0, r0, cr7, cr6, 2     \ Invalidate D$ line by set/index
      inc  r0,#0x20000000              \ Next way
      mcr  p15, 0, r0, cr7, cr6, 2     \ Invalidate D$ line by set/index
      inc  r0,#0x20000000              \ Next way - will wrap to 0

      inc  r0,#32                      \ Next set
      ands r1,r0,#0xfe0                \ Mask set bits - depends on #sets=128
   0= until

   \ Invalidate the entire L2 cache by looping over all sets and ways
   mov r0,#2                           \ Start with set/way 0 of L2 cache
   begin
      \ In this unrolled loop, the number of iterations (8) and the increment
      \ value (0x20000000) depend on fact that this cache has 8 ways.
      mcr  p15, 0, r0, cr7, cr6, 2     \ Invalidate D$ line by set/index
      inc  r0,#0x20000000              \ Next way
      mcr  p15, 0, r0, cr7, cr6, 2     \ Invalidate D$ line by set/index
      inc  r0,#0x20000000              \ Next way
      mcr  p15, 0, r0, cr7, cr6, 2     \ Invalidate D$ line by set/index
      inc  r0,#0x20000000              \ Next way
      mcr  p15, 0, r0, cr7, cr6, 2     \ Invalidate D$ line by set/index
      inc  r0,#0x20000000              \ Next way
      mcr  p15, 0, r0, cr7, cr6, 2     \ Invalidate D$ line by set/index
      inc  r0,#0x20000000              \ Next way
      mcr  p15, 0, r0, cr7, cr6, 2     \ Invalidate D$ line by set/index
      inc  r0,#0x20000000              \ Next way
      mcr  p15, 0, r0, cr7, cr6, 2     \ Invalidate D$ line by set/index
      inc  r0,#0x20000000              \ Next way
      mcr  p15, 0, r0, cr7, cr6, 2     \ Invalidate D$ line by set/index
      inc  r0,#0x20000000              \ Next way - will wrap to 0

      inc  r0,#32                      \ Next set
      set  r2,#0xffe0                  \ Mask for set field for L2 cache - depends on #sets=2048
      ands r1,r0,r2                    \ Mask set bits
   0= until

   mcr  p15, 0, r0, cr7, cr5, 0        \ Invalidate entire I$

   mcr  p15, 0, r0, cr7, cr5, 6        \ Flush branch target cache

   mrc p15,0,r0,cr1,cr0,0              \ Read control register
   orr r0,r0,#0x1000                   \ ICache on
   orr r0,r0,#0x0800                   \ Branch prediction on
   orr r0,r0,#0x0004                   \ DCache on
   mcr p15,0,r0,cr1,cr0,0              \ Write control register with new bits

   mrc p15,0,r0,cr1,cr0,1              \ Read aux control register
   orr r0,r0,#0x0002                   \ L2 Cache on
   mcr p15,0,r0,cr1,cr0,1              \ Write control register with new bits

   mov	pc, lr	
end-code

\ Synchronizes the instruction and data caches, thus allowing the
\ execution of instructions that have recently been written to memory.
\ This version, which operates on the entire cache, is more efficient
\ than an address-range version when the range is larger than the
\ L1 cache size.
label sync-caches  \ No args or returns, kills r0 and r1

   \ Clean (push the data out to a higher level) the entire L1 data cache
   \ by looping over all sets and ways
   mov r0,#0                           \ Start with set/way 0 of L1 cache
   begin
      \ In this unrolled loop, the number of iterations (8) and the increment
      \ value (0x20000000) depend on fact that this cache has 8 ways.
      mcr  p15, 0, r0, cr7, cr10, 2    \ clean D$ line by set/index
      inc  r0,#0x20000000              \ Next way
      mcr  p15, 0, r0, cr7, cr10, 2    \ clean D$ line by set/index
      inc  r0,#0x20000000              \ Next way
      mcr  p15, 0, r0, cr7, cr10, 2    \ clean D$ line by set/index
      inc  r0,#0x20000000              \ Next way
      mcr  p15, 0, r0, cr7, cr10, 2    \ clean D$ line by set/index
      inc  r0,#0x20000000              \ Next way
      mcr  p15, 0, r0, cr7, cr10, 2    \ clean D$ line by set/index
      inc  r0,#0x20000000              \ Next way
      mcr  p15, 0, r0, cr7, cr10, 2    \ clean D$ line by set/index
      inc  r0,#0x20000000              \ Next way
      mcr  p15, 0, r0, cr7, cr10, 2    \ clean D$ line by set/index
      inc  r0,#0x20000000              \ Next way
      mcr  p15, 0, r0, cr7, cr10, 2    \ clean D$ line by set/index
      inc  r0,#0x20000000              \ Next way - will wrap to 0

      inc  r0,#32                      \ Next set
      ands r1,r0,#0xfe0                \ Mask set bits - depends on #sets=128
   0= until

   mcr  p15, 0, r0, cr7, cr5, 0        \ Invalidate entire I$
   mov	pc, lr	
end-code
   
\ Insert zeros into the code stream until a cache line boundary is reached
\ This must be enclosed with "ahead .. then" to branch around the zeros.
: cache-align  ( -- )
   begin
      here [ also assembler ] asm-base [ previous ] -  h# 1f and
   while
      0 l,
   repeat
;   

\ Turn on the MMU
label enable-mmu  ( -- )
   mvn     r2, #0               \ Set domains for Manager access - all domains su
   mcr     p15,0,r2,3,0,0       \ Update register 3 in CP15 - domain access control

   \ Enable the MMU
   mrc     p15, 0, r2, 1, 0, 0  \ Read current settings in control reg
   mov     r2,  r2, LSL #18     \ Upper 18-bits must be written as zero,
   mov     r2,  r2, LSR #18     \ ... clear them now.

   orr     r2, r2, 0x200        \ Set the ROM Protection bit
   bic     r2, r2, 0x100        \ Clear the System Protection bit
   orr     r2, r2, 0x001        \ Set the MMU bit

   \ Align following code to a cache line boundary
   ahead
      cache-align
   then

   mcr    p15, 0, r2, cr1, cr0, 0       \ Go Virtual
   mrc    p15, 0, r2, cr2, cr0, 0       \ Ensure that the write completes
   mov    r2,  r2                       \ before continuing
   sub    pc,  pc,  #4

   mov    pc, lr
end-code

\ Map sections virtual=physical within the given address range, using
\ the given protection/cacheability mode.  pt-adr is the page table base address.
label map-sections-v=p  ( r0: pt-adr, r1: adr, r2: len, r3: mode -- )
    begin
       add  r4, r1, r3            \ PA+mode
       str  r4, [r0, r1, lsr #18]
       
       inc  r1, #0x100000
       decs r2, #0x100000
    0<= until

    mov   pc, lr
end-code

\ Initial the section table, setting up mappings for the platform-specific
\ address ranges that the firmware uses.
\ Destroys: r0-r4
label init-map  ( r0: section-table -- )
   mov r10,lr

   mcr p15,0,r0,cr2,cr0,0               \ Set table base address

   \ Clear the entire section table for starters
   mov     r2, #0x1000			\ Section#
   mov     r3, #0			\ Invalid section entry
   begin
      subs    r2, r2, #1		\ Decrement section number
      str     r3, [r0, r2, lsl #2]	\ Invalidate section entry
   0= until

   mov r1,0                             \ Address of low memory
   set r2,`dma-base #`                  \ Size of low memory - up to dma-base
   set r3,#0xc0e                        \ Cache and write bufferable
   bl  `map-sections-v=p`

   set r1,`dma-base #`                  \ Address of DMA area
   set r2,`dma-size #`                  \ Size of DMA area
   set r3,#0xc02                        \ No caching or write buffering
   bl  `map-sections-v=p`

   set r1,`extra-mem-base #`            \ Address of additional allocatable memory
   set r2,`extra-mem-size #`            \ Size of additional allocatable memory
   set r3,#0xc0e                        \ Write bufferable
   bl  `map-sections-v=p`

   set r1,`fw-pa #`                     \ Address of Firmware region
   set r2,`/fw-ram #`                   \ Size of firmware region
   set r3,#0xc0e                        \ Write bufferable
   bl  `map-sections-v=p`

   set r1,`fb-pa #`                     \ Address - Frame buffer
   set r2,`fb-size #`                   \ Size of frame buffer
   set r3,#0xc06                        \ Write bufferable
   bl  `map-sections-v=p`

   set r1,#0xd1000000                   \ Address of SRAM
   set r2,#0x00300000                   \ Size of SRAM
   set r3,#0xc02                        \ No caching or write buffering
   bl  `map-sections-v=p`

   set r1,#0xd4000000                   \ Address of I/O
   set r2,#0x00400000                   \ Size of I/O region
   set r3,#0xc02                        \ No caching or write buffering
   bl  `map-sections-v=p`

   set r1,#0xe0000000                   \ Address of Audio SRAM
   set r2,#0x00100000                   \ Size of audio SRAM
   set r3,#0xc02                        \ No caching or write buffering
   bl  `map-sections-v=p`

\ The cache is not on yet
\   set r1,#0x4000                       \ Size of section table
\   bl  `clean-dcache-range`

   mov     pc, r10
end-code

\ LICENSE_BEGIN
\ Copyright (c) 2011 FirmWorks
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
