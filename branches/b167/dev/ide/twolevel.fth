\ See license at end of file
purpose: IDE two-level - master,slave / primary,secondary on different levels

" pci-ide" device-name
" pci-ide" device-type
" chrp,ide" encode-string " compatible" property

\ The IDE device node defines an address space for its children.  That
\ address space is of the form "unit#", an integer.

: decode-unit  ( unit-str len -- phys )
   base @ >r hex
   $number  if  0  then
   r> base !
;

: encode-unit  ( phys -- unit-str len )  base @ >r hex  (u.)  r> base !  ;

1 encode-int " #address-cells" property

: any-blocks?  ( -- flag )  /block@  ;
: cdrom?       ( -- flag )  atapi-drive?@  ;

open-hardware drop

new-device				\ Creating ide@0
   0 encode-int " reg" property
   fload ${BP}/dev/ide/idenode.fth	\ "ide" name declared here

   0 0 " set-address" $call-parent
   any-blocks? 0<>  if
      new-device
         0 encode-int " reg" property	\ Creating disk@0
         0 encode-int " device-id" property
         node-fcode 1 byte-load
         " cdrom?" $call-parent  if
            " cdrom" device-name	\ Re-name to "cdrom"
         then
      finish-device
   then

   0 1 " set-address" $call-parent
   any-blocks? 0<>  if
      new-device
         1 encode-int " reg" property	\ Creating disk@1
         0 encode-int " device-id" property
         node-fcode 1 byte-load
         " cdrom?" $call-parent  if
            " cdrom" device-name	\ Re-name to "cdrom"
         then
      finish-device
   then

finish-device				\ Close ide node

new-device				\ Createing ide@1
   1 encode-int " reg" property
   fload ${BP}/dev/ide/idenode.fth	\ "ide" name declared here

   0 2 " set-address" $call-parent
   any-blocks? 0<>  if
      new-device
         0 encode-int " reg" property	\ Creating disk@0
         0 encode-int " device-id" property
         node-fcode 1 byte-load
         " cdrom?" $call-parent  if
            " cdrom" device-name	\ Re-name to "cdrom"
         then
      finish-device
   then

   0 3 " set-address" $call-parent
   any-blocks? 0<>  if
      new-device
         1 encode-int " reg" property	\ Creating disk@1
         0 encode-int " device-id" property
         node-fcode 1 byte-load
         " cdrom?" $call-parent  if
            " cdrom" device-name	\ Re-name to "cdrom"
         then
      finish-device
   then

finish-device

close-hardware
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
