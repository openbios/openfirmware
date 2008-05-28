purpose: Interface to memtest86

: ?memtest-elf-map-in  ( vaddr size -- )
   \ We recognize memtest by its virtual address of 0x10000
   \ It expects that virtual = physical; we depend on the fact
   \ that we have low memory mapped V=P
   over  h# 10000 =  if  ( vaddr size )
      \ Map the frame buffer (virtual=physical)
      h# 910 config-l@ dup 100.0000 -1 mmu-map
      unfreeze
   then

   \ If it's not memtest, chain to the linux recognizer
   ?linux-elf-map-in
;
' ?memtest-elf-map-in is elf-map-in

: memtest  ( -- )  " rom:memtest" $boot  ;

\ LICENSE_BEGIN
\ Copyright (c) 2008 FirmWorks
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
