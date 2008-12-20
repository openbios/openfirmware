purpose: ARM MMU driver
\ See license at end of file

\ Definition:
\ PTE: Page Table Entry - a page descriptor - a 32 number that goes in
\      a level-2 page table.
\ PMEG: Page Map Entry Group - a level-2 page table - a group of 256
\      page table entries.

0 value st-va
h# 400 constant /pmeg
h# 10.0000 constant /section

\ Read and write section-table entries.
: >section  ( va -- smadr )  d# 20 rshift  st-va swap la+  ;
: section@  ( va -- ste )  >section l@  ;
: section!  ( ste va -- )  >section l!  ;

0 constant st-imp	\ 0 or h# 10 - "imp" bit setting
0 5 lshift constant fw-domain
h# c02  fw-domain or  constant ste-lowbits   \ AP=11, C=0, B=0,

0 value pmeg-pa	 \ Physical address page selector bits for current PMEG
0 value 'pt-ent  \ Location of the pte that is used for mapping ptes

0 value pmeg-section-va  \ Virtual address of section used for PMEG access

\ Returns the virtual address where the selected PMEG can be accessed
: pmeg-va  ( -- adr )  pmeg-pa  pmeg-section-va or  ;

\ Select the PMEG at pmeg-pa by setting the section entry for
\ pmeg-section-va to refer to it.
: map-pmeg  ( ste|pmeg-pa -- )
   h# 3ff invert and  dup h# 000f.f000 and to pmeg-pa
   pmeg-section-va flush-d-tlb-entry	\ Blast the old entry
   h# f.f000 invert and  ste-lowbits or  pmeg-section-va section!
;

\ Convert a level-1 (section) map entry to a level-2 (page) map entry
\ with the same permissions and beginning page number.  This is used
\ when converting a section-level mapping to page-level mappings.
: ste>pte  ( ste -- pte )
   dup h# fff0.000f and  swap   ( base/cb l1-pte )
   h# c00 and  dup 2 rshift or  ( base/cb ap3/2 )
   dup 4 rshift or  or          ( base/ap3/2/1/0/cb )
;

\ Allocate memory for a new page map entry group, install it in the
\ section table at the appropriate location for va, and create a
\ temporary virtual mapping for it so we can access it, returning its
\ temporary virtual address.
: get-pmeg  ( va -- )
   /pmeg /pmeg mem-claim                        ( va pte-pa )
   tuck fw-domain or  st-imp or  1 or           ( pte-pa va ste )
   swap section!                                ( pte-pa )
   map-pmeg                                     ( )
;

\ Create a new page map entry group for the section contaning va,
\ initializing it to consecutive physical pages using base-pte as
\ a template.  To create initially-invalid entries, use 0 for base-pte.
: new-pmeg  ( va base-pte -- )
   swap get-pmeg                                      ( base-pte adr )
   pmeg-va /pmeg  bounds  do  dup i l!  pagesize +  /l +loop  ( pte )
   drop                                               ( )
;

0 value remapping?	\ True if a newly-allocated PMEG will loaded with
			\ new entries.
: set-pmeg  ( va -- )
   dup section@  dup 3 and  case                 ( va ste type )
      1 of                                       ( va ste )
         nip  map-pmeg                           ( )
      endof                                      ( )
      2 of                                       ( va ste )
         ste>pte new-pmeg                        ( )
      endof                                      ( )
      ( default )                                ( va ste type )
         remapping?  if                          ( va ste type )
            \ We are going to create mappings in the range,
            \ so create a new PMEG and prime it with invalid PTEs.
            nip swap 0 new-pmeg                  ( type )
         else                                    ( va ste type )
            \ If we are going to unmap the range
            \ and it's already unmapped, leave it so.
            nip nip                              ( type )
         then                                    ( type )
      ( end default )                            ( type )
   endcase                                       ( )
;

: (pte-setup)  ( va -- adr )  d# 10 rshift  h# 3fc and  pmeg-va +  ;
: (pte!)  ( pte va -- )  (pte-setup) l!  ;
: (pte@)  ( va -- pte )  (pte-setup) l@  ;

: >pt  ( va -- true | offset pte-page-pa false )
   dup section@  dup 3 and  1 =  if         ( va ste )
      h# 3ff invert and                     ( va pte-page-pa )
      swap d# 10 rshift  h# 3fc and  swap   ( offset pte-page-pa )
      false
   else
      2drop true
   then
;

: .cb  ( s/pment -- )
   dup 8 and  if  ."  Cacheable"  then
   4 and  if  ."  Buffered"  then
;
: .domain  ( ste -- )  ."  Domain: " d# 5 rshift h# f and .  ;
: .ap  ( n bit# -- n )  over swap rshift 3 and (.) type  ;
: .l1-mapping  ( va ste -- )
   push-hex
   ." Section-mapped - Physical: "                          ( va ste )
   swap h# fffff and  over h# fffff invert and  or  8 u.r   ( ste )
   ."  AP: " d# 10 .ap  space                               ( ste )
   dup .domain                                              ( ste )
   dup h# 10 and  if  ."  IMP"  then                        ( ste )
   .cb                                                      ( )
   cr
   pop-base
;
: .l2-mapping  ( va ste -- )
   push-hex
   ." PMEG at: " dup h# ffff.fc00 and 8 u.r                    ( va ste )
   dup .domain                                                 ( va ste )
   map-pmeg dup (pte@) cr                                      ( va pte )
   dup 3 and  1 2 between  if                                  ( va pte )
      dup 3 and  1 =  if                                       ( va pte )
         ." 64K"  h# ffff                                      ( va pte mask )
      else                                                     ( va pte )
         ." 4K"   h# 0fff                                      ( va pte mask )
      then                                                     ( va pte mask )
      ."  Physical: "  rot over and                            ( pte mask val )
      -rot invert over and  rot or  8 u.r                      ( pte )
      ."  AP: "                                                ( pte )
      d# 10 .ap ." ,"  8 .ap ." ,"  6 .ap ." ," 4 .ap  space   ( pte )
     .cb                                                       ( )
   else                                                        ( va pte )
     2drop ." Not Mapped"                                      ( )
   then                                                        ( )
   cr
   pop-base
;

: map?  ( va -- )
   dup section@  dup 3 and  case   ( va ste type )
      1 of  .l2-mapping   endof
      2 of  .l1-mapping   endof
      ( default: va ste type )
         ." Not mapped at section level"  3drop exit
   endcase
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

: ?set-pmeg  ( end start -- end start )  2dup <>  if  dup set-pmeg  then  ;

: ?release-pmeg  ( va -- va )
   dup section@  3 and  1 =  if  \ Reclaim old PMEG          ( va )
      dup section@  h# ffff.fc00 and  /pmeg  mem-release     ( va )
   then                                                      ( va )
;
: invalidate-page  ( va -- )  0 swap (pte!)  ;
: invalidate-section  ( va -- )  ?release-pmeg  0 swap section!  ;

: remap-pages  ( mode pa va-end va-start -- mode pa' )
   ?do                                 ( mode pa )
      over ste>pte over or  i (pte!)   ( mode pa )
      pagesize +                       ( mode pa' )
   pagesize +loop                      ( mode pa' )
;

: remap-sections  ( pa mode va-end va-start mode -- pa' mode )
   ?do                                                    ( mode pa )
      dup  h# f.f000 and  if                              ( mode pa )
         \ Physical not aligned; use page-level mappings
         i section@  3 and  1 =  if  \ Reuse old PMEG     ( mode pa )
            i section@ map-pmeg                           ( mode pa )
         else       \ Allocate a new PMEG                 ( mode pa )
            i get-pmeg                                    ( mode pa )
         then                                             ( mode pa )
         i /section  bounds  remap-pages                  ( mode pa' )
      else                                                ( mode pa )
         \ Physical is aligned; use section-level mappings
         i ?release-pmeg drop                             ( mode pa )
         2dup or   i section!                             ( mode pa )
         /section +                                       ( mode pa' )
      then                                                ( mode pa' )
   /section +loop                                         ( mode pa )
;

: remap-range  ( phys mode adr len -- )
   true to remapping?
   2swap  2 or swap  h# fff invert and         ( adr len mode pa )
   2>r  split-range  2r>                       ( d.r2 d.r1 d.r0 mode pa )

   2swap  ?set-pmeg  remap-pages               ( d.r2 d.r1 mode pa' )
   2swap  ?set-pmeg  remap-sections            ( d.r2 mode pa' )
   2swap  ?set-pmeg  remap-pages               ( mode pa' )

   2drop                                       ( )
;

\ XXX Perhaps we should invalidate the cache within this range.
: unmap-range  ( adr len -- )
   2dup  invalidate-cache-range
   false to remapping?
   split-range                                  ( d.range2 d.range1 d.range0 )
   ?set-pmeg  ?do  i invalidate-page  pagesize +loop   ( d.range2 d.range1 )
   ?do  i invalidate-section  /section +loop        ( d.range2 )
   ?set-pmeg  ?do  i invalidate-page  pagesize +loop   ( )
;

: (shootdown-range)  ( adr len -- )
   over swap 2>r       ( adr r: adr len )
   translate           ( false | phys mode true  r: adr len )
   if  2r> remap-range  else  2r> unmap-range  then
   flush-i&d-tlb
;
' (shootdown-range) to shootdown-range

: (map-mode)  ( phys.. mode -- mode' )
   >r  memory?  r>                    ( memory? mode )
   dup -2 -1 between if               ( memory? -1 )
      drop  if			      ( )
         h# c0c	 \ Memory: AC=3, C=1, B=1
      else			      ( )
         h# c00	 \ I/O:  AC=3, C=0, B=0
      then			      ( mode' )
   else                               ( memory? mode )
      nip			      ( mode )
   then				      ( mode' )
;
' (map-mode) to map-mode

headerless
list: translations-list

\ After initial-mmu-setup exits, the mmu must be on and st-va must
\ be set to the virtual address of the section table.
defer initial-mmu-setup  ( -- )  ' noop to initial-mmu-setup
defer initial-claim      ( -- )  ' noop to initial-claim
defer initial-map        ( -- )  ' noop to initial-map

: init-virtual-list  ( -- )
   0 memrange !				\ Clear free list

   \ Create the available memory list from which the firmware is allowed
   \ to dynamically allocate virtual memory.

   fw-virt-base  fw-virt-size   set-node  fwvirt  insert-after

   \ Setup the virtual list from which the firmware isn't permitted to allocate
   0                            fw-virt-base add-os-piece
   fw-virt-base fw-virt-size +  0            add-os-piece
;

headers
warning off
: open  ( -- )
   initial-mmu-setup	\ Do platform-specific stuff as necessary 

   init-virtual-list

   initial-claim	\ Claim any pre-committed platform-specific addresses

   \ Grab a Meg of virtual address space to use for temporary PMEG access
   /section /section claim to pmeg-section-va

   translations-list to translations

   initial-map		\ Set up platform-specific hardcoded translations
   true
;
warning on

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
