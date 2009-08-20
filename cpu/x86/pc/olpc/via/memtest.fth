purpose: Interface to memtest86


h# 200 constant lb-table-address
0 value table-start
variable #lb-entries

: ,memrange  ( adr len type -- )
    rot  l, 0 l,   ( len type )  \ 64-bit address
    swap l, 0 l,   ( type )      \ 64-bit size
    l,             ( )           \ type
;
: make-lb-table  ( -- )
   #lb-entries off
   here to table-start
   " LBIO" $,  \ Signature
   6 /l* l,    \ header_bytes
   0     l,    \ header_checksum, set later
   0     l,    \ table_bytes, set later
   0     l,    \ table_checksum, set later
   1     l,    \ table_entries - just a memory tag
   
   here        ( mem-struct-adr )

   1     l,    \ MEM tag
   0     l,    \ size of memory struct, set later

   h# 100000 memory-limit over - 1 ,memrange

   here over -  over la1+ !           ( mem-struct-adr )         \ Set size of memory struct
   here over -  table-start 3 la+ l!  ( mem-struct-adr )         \ Set table_bytes
   here over -  0 -rot  ip-checksum   table-start 4 la+ be-w!  ( )  \ Set table checksum
   0 table-start 6 /l*  ip-checksum   table-start 2 la+ be-w!  ( )  \ Set header checksum

   table-start  lb-table-address  here table-start -  move
;


: ?memtest-elf-map-in  ( vaddr size -- )
   \ We recognize memtest by its virtual address of 0x10000
   \ It expects that virtual = physical; we depend on the fact
   \ that we have low memory mapped V=P
   over  h# 10000 =  if  ( vaddr size )
[ifdef] notdef
[ifdef] virtual-mode
      \ Map the frame buffer (virtual=physical)
      h# 810 config-l@ dup 100.0000 -1 mmu-map
[then]
[else]
      screen-ih  if
         " text-mode3" screen-ih $call-method
      then
      text-off
      make-lb-table
[then]
[ifdef] unfreeze unfreeze  [then]
      usb-quiet
   then

   \ If it's not memtest, chain to the linux recognizer
   ?linux-elf-map-in
;
' ?memtest-elf-map-in is elf-map-in

: memtest  ( -- )  " rom:memtest" $boot  ;

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
