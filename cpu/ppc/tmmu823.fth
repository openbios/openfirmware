purpose: Initialization code for PowerPC 823 MMU
\ See license at end of file

headerless
: dmapping-on   ( -- )  msr@ h# 10 or          msr!  ;
: dmapping-off  ( -- )  msr@ h# 10 invert and  msr!  ;

headerless
list: translations-list

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
   fw-base virt-phys -  fw-base  20.0000  -1 map  \ Firmware 
[then]
;
' (initial-map) to initial-map

headerless
defer unmap-temp-io		' noop to unmap-temp-io
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
   
   fw-base                    20.0000     claim-virtual drop
;

headers
warning off
: open  ( -- )
   init-virtual-list

   translations-list to translations

   d# 50 translation-node more-nodes

   translations virt-phys - 4f8 !  \ physical
   virt-phys                4fc !  \ virtual minus physical
   0                        4f4 !  \ Replacement offset
   save-state virt-phys -   4f0 !  \ fallback handler address

   configure-tlb
   init-tlb
   invalidate-tlb
   init-tlb-entries
   initial-map
   install-tlb-miss
   dmapping-on

   true to in-real-mode?
   true
;

: tlb0!  ( rpn -- )
   200 md-epn!  d md-twc!  md-rpn!
   md-ctr@ 700 invert and md-ctr!
   0 md-cam!
   md-cam@ u. md-ram0@ u. md-ram1@ u. cr
;
warning on


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
