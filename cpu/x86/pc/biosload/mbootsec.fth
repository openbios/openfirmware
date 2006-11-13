\ See license at end of file
purpose: Make OFW boot floppy

hex

\ create make-boot-sector-only

: $, ( adr len -- )  here over allot  swap move  ;

create ofw-boot-sectors
here
fload ${BP}/cpu/x86/pc/biosload/build/bootsec.hex
here swap - constant /ofw-boot-sectors

: lew@  ( adr -- w )  dup c@  swap 1+ c@  bwjoin  ;
: lew!  ( w adr -- )  2dup c!  swap 8 >> swap 1+ c!  ;
: lel!  ( l adr -- )  >r lwsplit r@ 2+ lew! r> lew!  ;

\ Usage: " /isa/fdc/disk@0" make-ofw-floppy
\
: make-ofw-floppy  ( name$ -- )
   open-partition-map

   \ Write boot sectors
   ofw-boot-sectors /ofw-boot-sectors " write" disk-dev $call-method
   /ofw-boot-sectors <>  if  ." Boot sector write failed" cr  then

[ifndef] make-boot-sector-only
   \ Init fats
   sector-buf /sector erase
   ofw-boot-sectors 10 + c@ 0 ?do
      00fffff0 sector-buf lel!
      sector-buf /sector " write" disk-dev $call-method drop
      sector-buf /sector erase
      ofw-boot-sectors 16 + lew@ 1- 0 ?do
         sector-buf /sector " write" disk-dev $call-method drop
      loop
   loop

   \ Init root directory
   ofw-boot-sectors 11 + lew@ 20 * /sector / 0 ?do
      sector-buf /sector " write" disk-dev $call-method drop
   loop
[then]

   close-partition-map
   ." Open Firmware bootable floppy created." cr
   ." Please copy OFW.IMG to the floppy." cr
;
: make-floppy-image  ( -- )
   " floppy0.img" $new-file

   /sector alloc-mem to sector-buf

   \ Write boot sectors
   ofw-boot-sectors /ofw-boot-sectors ofd @ fputs

[ifndef] make-boot-sector-only
   \ Init fats
   sector-buf /sector erase
   ofw-boot-sectors 10 + c@ 0 ?do
      00fffff0 sector-buf lel!
      sector-buf /sector ofd @ fputs
      sector-buf /sector erase
      ofw-boot-sectors 16 + lew@ 1- 0 ?do
         sector-buf /sector ofd @ fputs
      loop
   loop

   \ Init root directory
   ofw-boot-sectors 11 + lew@ 20 * /sector / 0 ?do
      sector-buf /sector ofd @ fputs
   loop
[then]

   ofd @ fclose
   ." Open Firmware bootable floppy image created." cr
   ." Please copy OFW.IMG to the floppy." cr
;
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
