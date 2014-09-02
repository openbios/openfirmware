\ See license at end of file
purpose: IDE two-level - master,slave / primary,secondary on different levels

0 0  " i1f0"  " /isa" begin-package
" ide-controller" device-name

create node-fcode
fload $(BP)/dev/ide/node.hex

fload $(BP)/dev/ide/isaintf.fth
fload $(BP)/dev/ide/generic.fth

\ The ide-controller address space is of the form "unit#", an integer.
\ Each child is an IDE "string"

: decode-unit  ( unit-str len -- phys )
   base @ >r hex
   $number  if  0  then
   r> base !
;

: encode-unit  ( phys -- unit-str len )  base @ >r hex  (u.)  r> base !  ;

1 encode-int " #address-cells" property

: any-blocks?  ( -- flag )  /block@  ;
: cdrom?       ( -- flag )  atapi-drive?@  ;

new-device				\ Create ide@0
   0 encode-int " reg" property
   fload ${BP}/dev/ide/idenode.fth	\ "ide" name declared here
finish-device

new-device				\ Create ide@1
   1 encode-int " reg" property
   fload ${BP}/dev/ide/idenode.fth	\ "ide" name declared here
finish-device

end-package

stand-init: Probe IDE
   " /ide-controller/ide@0" select-dev  " probe" $call-self  unselect-dev
   " /ide-controller/ide@1" select-dev  " probe" $call-self  unselect-dev
;

\ LICENSE_BEGIN
\ Copyright (c) 2014 William M. Bradley
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
