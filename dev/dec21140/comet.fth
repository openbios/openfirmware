\ See license at end of file
\ ADMtek Comet FCode Ethernet driver

hex

" ADMtek,comet" model

external
: tp  ( -- )
   \ This may not be exactly right, but it seems to work ... for now
   ctl e@  h# 4000 or  ctl e!
\   ctl e@  h# 0004.0000 invert and  ctl e!
\   0 csr13 e!					\ SIA reset, 10Base-T
\   0 csr14 e!					\ enable
\   8 csr15 e!					\ enable external transceiver
   ctl e@  h# 0004.0000 or  ctl e!		\ port select, half-duplex
;
: coax  ( -- )
;
: aui  ( -- )
;
: 100bt  ( -- )
   \ XXX implement me
;
' tp to set-interface

headers

: comet-set-address  ( -- error? )
   mac-address   ( adr len )
   bounds  do  i c@  loop  ( e5 e4 e3 e2 e1 e0 )
   bwjoin h# a8 e!  ( e5 e4 e3 e2 )
   bljoin h# a4 e!  ( )
   \ enable transmitter
   ctl e@  transmit-enable or  ctl e!	\ process setup frame
   false
;
' comet-set-address to set-address

6 buffer: my-mac
: init-comet  ( -- )
   0 40 my-space + " config-l!" $call-parent	\ exit sleep mode
   map-regs
   h# a8 e@ wbflip wbsplit               ( e0 e1 )
   h# a4 e@ lbsplit lbflip               ( e0 e1 e2 e3 e4 e5 )
   my-mac 6 bounds do  i c!  loop        ( )
   my-mac 6  encode-bytes  " local-mac-address" property  ( mem-adr 6 )
   unmap-regs
;

init-comet
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
