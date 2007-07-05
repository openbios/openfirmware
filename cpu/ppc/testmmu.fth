purpose: Initialization code for PowerPC MMU
\ See license at end of file

headerless
code v>p  ( virt -- phys&mode )
   mr     r3,tos
   get-phys  bl  *
   mr     tos,r3
c;
code vtopte  ( virt -- vsid pteg )
   mr fault,tos
   find-pte  bl *
   stwu  vsid,-4(sp)
   mr tos,pteg
c;
headers
: .htab   htab /htab  bounds  do  i @  if  i .  then  8 +loop  ;

headerless
list: translations-list

: init-srs  ( -- )  h# 10 0  do  i i sr!  loop  ;

[ifndef] initial-map
also forth definitions
: fw-base  ( -- adr )  origin pagesize round-down  ;

headers
defer initial-map
: (initial-map)  ( -- )
[ '#adr-cells @ 2 = ] [if]
\            0 0          0  2000.0000 -1 map	\ Memory

           0 0    over     2.0000 -1 map	\ Hash table and trap vectors
      2.0000 0    over  fw-base over -  -1 map	\ program load area
     e0.0000 0    over    10.0000 -1 map	\ Displacement flush area
     f0.0000 0    over    10.0000 -1 map	\ Firmware 

   f100.0000 0    over   100.0000 -1 map	\ Firmware I/O
\  2000.0000 0    over  e000.0000 -1 map	\ I/O
[else]
   0                    0        memsize  -1 map  \ Trap vects, pgm load area
   fw-base virt-phys -  fw-base  htab /htab + over -   -1 map  \ Firmware 
[then]

[ifdef] io-base
   io-base  io-base  h# 10000 -1  map
[then]
;
' (initial-map) to initial-map

headerless
defer unmap-temp-io
: (unmap-temp-io)  ( virt -- )  \ Remove temporary I/O mapping
[ifdef] io-base
   dup io-base =  if  drop  else  h# 1000  unmap  then
[else]
   drop
[then]
;
' (unmap-temp-io) to unmap-temp-io
[then]
previous definitions
[then]

: init-virtual-list  ( -- )
   0 memrange !				\ Clear free list
   d# 500  memrange  more-nodes		\ Get enough nodes "forever"

   \ Create the available memory list from which the firmware is allowed
   \ to dynamically allocate virtual memory.

   fw-virt-base  fw-virt-size   set-node  fwvirt  insert-after

   \ Setup the virtual list from which the firmware isn't permitted to allocate
   0                            fw-virt-base add-os-piece
   fw-virt-base fw-virt-size + ?dup  if  0 add-os-piece  then
   
[ '#adr-cells @ 2 = ] [if]
   \ XXX Claim the firmware and displacement flush areas for now
   e0.0000                    20.0000     claim-virtual drop
[else]
   fw-base        htab /htab + over -     claim-virtual drop
[then]
;

headers
warning off
: open  ( -- )
   init-srs

   use-real-mode?  if
      install-bat-handler 
      setup-real-bat-table
      clear-bats      mapping-on
      true  exit  
   then

   set-mmu

   init-virtual-list

   translations-list to translations

   d# 50 translation-node more-nodes

   translations virt-phys - 4f8 !  \ physical
   virt-phys                4fc !  \ virtual minus physical
   0                        4f4 !  \ Replacement offset
   save-state virt-phys -   4f0 !  \ fallback handler address

   init-paged-mmu

   initial-map

   configure-tlb

[ifdef] install-tlb-miss
[ifdef] exponential
   704-class? if
      install-exp-tlb-miss
   else      
      install-tlb-miss
   then
[else]
   install-tlb-miss
[then]
[then]

   htab-dsi-handler h# 300 put-exception
   htab-isi-handler h# 400 put-exception

   virt-phys  if  mapping-on clear-bats  else  clear-bats mapping-on  then

   false to in-real-mode?

   true
;
warning on

[ifdef] NOTYET
Allocate contiguous physical memory and add nodes to the translations
list.  The memory should have one extra cell at the beginning, which is
the list head.  Set "translations" to the virtual base address of the
beginning of that memory.
Store the difference between the physical and virtual base address of
that memory somewhere that the trap handler can find.
This is necessary because the fault handler runs in real mode, and needs
a convenient way to chase the list links without having to apply different
translations to different list nodes.
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
