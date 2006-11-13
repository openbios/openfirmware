\ See license at end of file
purpose: IDE bus package implementing a "ide" device-type interface.

hex

\ Map the device into virtual address space
: (map)  ( -- pri-chip-base pri-dor sec-chip-base sec-dor )
   my-address my-space 8 " map-in" $call-parent
   h# 3f6     my-space 1 " map-in" $call-parent
[ifdef] include-secondary-ide
   h# 170     my-space 8 " map-in" $call-parent
   h# 376     my-space 1 " map-in" $call-parent
[else]
   0 0
[then]
;

\ Release the mapping resources used by the device
: (unmap)  ( pri-chip-base pri-dor sec-chip-base sec-dor -- )
[ifdef] include-secondary-ide
   8  " map-out" $call-parent
   1  " map-out" $call-parent
[else]
   2drop
[then]
   8  " map-out" $call-parent
   1  " map-out" $call-parent
;

: int+  ( adr len n -- adr' len' )  encode-int encode+  ;

0 0 encode-bytes
h# 1f0 1  encode-phys  encode+  8 int+
h# 3f6 1  encode-phys  encode+  2 int+
[ifdef] include-secondary-ide
h# 170 1  encode-phys  encode+  8 int+
h# 376 1  encode-phys  encode+  2 int+
[then]
" reg" property
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
