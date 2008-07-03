\ See license at end of file
purpose: Establish the initial values for the MMU and virtual lists

\ The code in this file depends in detail on the initial MMU setup
\ established by initmmu.fth

: (memory?)  ( adr -- flag )  h# 1000.0000 u<  ;
' (memory?) is memory?

dev /mmu

0 value pt-pa

: >p  ( va -- pa )  (translate)  0= abort" Not mapped"  drop  ;

: (initial-mmu-setup)  ( -- )	\ Locate the page directory
   pdir-pa /ptab - to pt-pa
   pdir-pa to pdir-va
;
' (initial-mmu-setup) to initial-mmu-setup

: (initial-claim)  ( -- )
   RAMbase   RAMtop  over -    claim-virtual drop   \ Firmware region
   RAMtop    /ptab 3 *         claim-virtual drop   \ Mapping tables
   h# ffff.0000   h#  1.0000   claim-virtual drop   \ I/O "mapping" region
;
' (initial-claim) to initial-claim

: (initial-map)  ( -- )
   origin >p      origin       /fw-ram              -1 map   \ Firmware 

   \ Formally establish the pre-existing mapping so it can be released later
\  0              0            h# 10.0000           -1 map   \ Low meg

   \ Move the page directory virtual address to the pocket just above the
   \ Forth stacks; typically fc10.0000.
   pdir-pa        RAMtop        /ptab               -1 map   \ Page directory

   \ Page frame for accessing page tables
   RAMtop  /ptab +                ( ptab-va )	

   \ Page frame for changing page table access
   dup /ptab +                    ( ptab-va page-frame-va )

   \ Set up a page frame that maps the ptab-va area
   pt-pa  over  /ptab    -1 map   ( ptab-va page-frame-va )

   \ Don't set this value until we have finished with all the "map" calls,
   \ because it is changed by "map" if pdir-va=pdir-pa
   over to ptab-va                ( ptab-va page-frame-va )

   \ Virtual address of page table entry for the page frame we use to
   \ access other page frames.
   >pt-adr  to ptab-va-pte-va

   RAMtop to pdir-va                              ( old-pdir-va )

\   0   h# 10.0000  2dup unmap 	release			\ Release old mapping
;
' (initial-map) to initial-map

device-end
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
