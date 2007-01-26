\ See license at end of file
purpose: i386 MMU driver

\ Definition:
\ PDIR: Page Directory - The top level page table that maps the upper
\	10 bits of the linear address to the second level of page tables
\ PTE: Page Table Entry - a page descriptor - a 32 number that goes in
\      a level-2 page table.

fload ${BP}/cpu/x86/mmuparam.fth	\ Sizes of various MMU things

code flush-tlb-entry  ( pte-va -- )
   eax pop
   h# 0f c, 1 c, [eax] o# 070 +  c, 		\ invlpg [eax]
c;

code flush-tlb  ( -- )
   cr3 eax mov
   eax cr3 mov
c;

\ It would be better to flush individual TLB entries, but we would
\ need to be careful to flush the right one; the address at which
\ we store the entry is not the VA to which the address refers.
: pt!  ( n adr -- )  l!  flush-tlb  ; 

alias pdir-pa cr3@
0 value pdir-va		\ Virtual address of the page directory; set later

\ Read and write page directory entries.
: >pdir  ( va -- pdiradr )  d# 22 rshift  pdir-va swap la+  ;
: pdir@  ( va -- pde )  >pdir l@  ;
: pdir!  ( pde va -- )  >pdir pt!  ;

h# 3 value ptab-va-mode		\ D=0, A=0, PCD=0, PWT=0, U=0, W=1, P=1
h# 3 value pde-mode		\ D=0, A=0, PCD=0, PWT=0, U=0, W=1, P=1

0 value ptab-va  \ Virtual address of page used for PTE access

0 value ptab-va-pte-va  \ Location of the pte that is used for mapping ptes

: page-high-bits  ( padr -- high-bits )  h# fff invert and  ;

\ Select the page table at ptab-pa by setting the page table entry for the
\ VA that is reserved for page table accesses.
: map-ptab  ( ptab-pa -- )
   pdir-va pdir-pa =  if
      \ During early startup, we assume that RAM is mapped virtual=physical 
      page-high-bits to ptab-va
   else
      \ Later, we relax the V=P requirement and access page tables through
      \ a virtual page frame.
      ptab-va-pte-va flush-tlb-entry	\ Blast the old entry
      page-high-bits ptab-va-mode or  ptab-va-pte-va pt!
   then
;

\ Allocate memory for a new page table, install it in the
\ page directory at the appropriate location for va, and create a
\ temporary virtual mapping for it so we can access it, returning its
\ temporary virtual address.
: get-ptab  ( va -- )
   /ptab /ptab mem-claim                        ( va pte-pa )
   tuck pde-mode or                             ( pte-pa va ste )
   swap pdir!                                   ( pte-pa )
   map-ptab                                     ( )
;

\ Create a new page table for the section contaning va,
\ initializing it to consecutive physical pages using base-pte as
\ a template.  To create initially-invalid entries, use 0 for base-pte.
: new-ptab  ( va base-pte -- )
   swap get-ptab                                      ( base-pte adr )
   ptab-va /ptab  bounds  do  dup i pt!  pagesize +  /l +loop  ( pte )
   drop                                               ( )
;

0 value remapping?	\ True if a newly-allocated page table will loaded with
			\ new entries.
: present?  ( entry -- flag )  1 and  0<>  ;
: set-ptab  ( va -- )
   dup pdir@  dup  present?  if               ( va pde )
      \ page table for this VA exists
      nip  map-ptab                           ( )
   else                                       ( va ste )
      \ page table for this VA does not exist
      remapping?  if                          ( va ste )
         \ We are going to create mappings in the range,
         \ so create a new page table and prime it with invalid PTEs.
         drop 0 new-ptab                      ( )
      else                                    ( va ste )
         \ If we are going to unmap the range
         \ and it's already unmapped, leave it so.
         2drop                                ( )
      then                                    ( )
   then                                       ( )
;

: >pt-adr  ( va pt-adr -- adr )  swap  d# 12 rshift  h# 3ff and  la+  ;
: (pte-setup)  ( va -- adr )  ptab-va >pt-adr  ;
: (pte!)  ( pte va -- )  (pte-setup) pt!  ;
: (pte@)  ( va -- pte )  (pte-setup) l@  ;

: bigpage?  ( pte -- flag )  h# 80 and  0<>  ;
: .map-mode  ( pte -- )
   ." Mode: " h# fff and dup .x
   dup bigpage?   if  ." 4M "  then
   dup h# 40 and  if  ." Dirty "  then
   dup h# 20 and  if  ." Accessed "  then
   dup h# 10 and  if  ." Don'tCache "  then
   dup h#  8 and  if  ." WriteThrough "  then
   dup h#  4 and  if  ." User " else ." Supervisor "  then
   dup h#  2 and  if  ." R/W " else ." R/O "  then
   drop
   cr
;
: (translate)  ( va -- false | pa status true )
   dup pdir@  dup present?  0=  if
      2drop false                ( false )
      exit
   then                          ( va pde )

   dup bigpage?  if              ( va pde )
      dup h# 3f.ffff invert and  ( va pde pa-base )
      rot h# 3f.ffff and  or     ( pde pa )
   else                          ( va pde )
      map-ptab                   ( va )
      dup (pte@)                 ( va pte )
      dup h# fff invert and      ( va pte pa-base )
      rot h# fff and  or         ( pte pa )
   then                          ( va pde )
   swap h# ff and   true         ( pa mode true )
;

: map?  ( va -- )
   dup  (translate)  if   ( va pa status )
      rot ." VA: " .x                         ( pa mode )
      swap ." PA: " .x cr                     ( status )
      .map-mode
   else
      drop  ." Not mapped" cr
   then
;

\ "Circular arithmetic" max and min.  In circular arithmetic, 0 is greater
\ than ff00.0000.  The use of these operators instead of umax and umin
\ correctly handles the case where an address range ends at 2^^32, which
\ looks like 0 in 32-bit twos-complement arithmetic.
: cmax  ( adr1 adr2 -- max )  2dup - 0>  if  drop  else  nip  then  ;
: cmin  ( adr1 adr2 -- min )  2dup - 0<  if  drop  else  nip  then  ;

\ Break the range into three ranges -
\ The range on top of the stack goes from adr up to the first section boundary
\ The middle range goes from the first to the last section boundary
\ The last range goes from the last section boundary to adr+len
\ Some ranges may be zero-length
: split-range  ( adr len -- end end-sec  end-sec start-sec  start-sec start )
   bounds                                         ( end start )
   over /section round-down  over cmax tuck swap  ( end end-sec end-sec start )
   2dup /section round-up  cmin tuck swap
                             ( end end-sec end-sec start-sec  start-sec start )
;

: ?set-ptab  ( end start -- end start )  2dup <>  if  dup set-ptab  then  ;

: ?release-ptab  ( va -- va )
   dup pdir@  present?  if  \ Reclaim old page table      ( va )
      dup pdir@  page-high-bits  /ptab  mem-release       ( va )
   then                                                   ( va )
;
: invalidate-page  ( va -- )  0 swap (pte!)  ;
: invalidate-section  ( va -- )  ?release-ptab  0 swap pdir!  ;

: remap-pages  ( mode pa va-end va-start -- mode pa' )
   ?do                    ( mode pa )
      2dup or  i (pte!)   ( mode pa )
      pagesize +          ( mode pa' )
   pagesize +loop         ( mode pa' )
;

: remap-sections  ( pa mode va-end va-start mode -- pa' mode )
   ?do                                                 ( mode pa )
      \ XXX In order to use large page sizes (which some x86 systems
      \ support and some don't), then we would need code similar to
      \ that in cpu/arm/mmu.fth:remap-sections
      i pdir@  present?  if  \ Reuse old page table    ( mode pa )
         i pdir@ map-ptab                              ( mode pa )
      else       \ Allocate a new page table           ( mode pa )
         i get-ptab                                    ( mode pa )
      then                                             ( mode pa )
      i /section  bounds  remap-pages                  ( mode pa' )
   /section +loop                                      ( mode pa )
;

: remap-range  ( phys mode adr len -- )
   true to remapping?
   2swap  2 or swap  page-high-bits            ( adr len mode pa )
   2>r  split-range  2r>                       ( d.r2 d.r1 d.r0 mode pa )

   2swap  ?set-ptab  remap-pages               ( d.r2 d.r1 mode pa' )
   2swap  ?set-ptab  remap-sections            ( d.r2 mode pa' )
   2swap  ?set-ptab  remap-pages               ( mode pa' )

   2drop                                       ( )
;

: unmap-range  ( adr len -- )
   false to remapping?
   split-range                                       ( d.range2 d.range1 d.range0 )
   ?set-ptab  ?do  i invalidate-page  pagesize +loop ( d.range2 d.range1 )
   ?do  i invalidate-section  /section +loop         ( d.range2 )
   ?set-ptab  ?do  i invalidate-page  pagesize +loop ( )
;

: (shootdown-range)  ( adr len -- )
   over swap 2>r       ( adr r: adr len )
   translate           ( false | phys mode true  r: adr len )
   if  2r> remap-range  else  2r> unmap-range  then
   flush-tlb
;
' (shootdown-range) to shootdown-range

: (map-mode)  ( phys.. mode -- mode' )
   >r  memory?  r>                    ( memory? mode )
   dup -2 -1 between if               ( memory? -1 )
      drop  if			      ( )
         h# 03	 	\ Memory: PCD=0, PWT=0, W=1, P=1
      else			      ( )
         h# 13		\ I/O:  PCD=1, PWT=0  W=1, P=1
      then			      ( mode' )
   else                               ( memory? mode )
      nip			      ( mode )
   then				      ( mode' )
;
' (map-mode) to map-mode

headerless
list: translations-list

\ After initial-mmu-setup exits, the mmu must be on and pdir-va must
\ be set to the virtual address of the page directory.

defer initial-mmu-setup  ( -- )  ' noop to initial-mmu-setup
defer initial-claim      ( -- )  ' noop to initial-claim
defer initial-map        ( -- )  ' noop to initial-map

: init-virtual-list  ( -- )
   0 memrange !				\ Clear free list

   \ Create the available memory list from which the firmware is allowed
   \ to dynamically allocate virtual memory.

   fw-virt-base  fw-virt-size   set-node  fwvirt  insert-after

   \ Setup the virtual list from which the firmware isn't permitted to allocate
   h# 10.0000                   fw-virt-base add-os-piece
   fw-virt-base fw-virt-size +  0            add-os-piece
;

headers
warning off

\ Redefine translate to go directly to the hardware so we can
\ see provisional translations that haven't been recorded.
: translate  ( va -- false | pa mode true )
   \ Leave just the mode bits, discarding the status ones
   (translate)  if  h# 1f and  true  else  false  then
;

: open  ( -- )
   initial-mmu-setup	\ Do platform-specific stuff as necessary 

   init-virtual-list

   initial-claim	\ Claim any pre-committed platform-specific addresses

   \ Here we could remap the page directory, if we wanted to.

   translations-list to translations

   initial-map		\ Set up platform-specific hardcoded translations
   true
;
warning on




\ LICENSE_BEGIN
\ Copyright (c) 2006 FirmWorks
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
