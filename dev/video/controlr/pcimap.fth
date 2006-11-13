\ See license at end of file
purpose: PCI mapping functions

: map-pci-io  ( -- )
   \ h# 8100.0000 means non-relocatable I/O space
   0 0 h# 8100.0000  h# 1.0000  map-in to io-base

   \ Enable I/O space response
   4 c-w@ 1 or 4 c-w!
;
' map-pci-io to map-io-regs

: unmap-pci-io  ( -- )
   \ Unmaps VGA IO space and disables I/O space response, or at least
   \ it should. For you see, NT HALs expect the graphics adapters to 
   \ respond to I/O accesses when the HAL gets control, so alas, we
   \ must leave IO enabled.

   \ If the HAL ever gets fixed, uncomment the following two lines.
   \ my-space 4 +  dup   " config-w@" $call-parent  ( adr value )
   \ 1 invert and  swap  " config-w!" $call-parent

   io-base  h# 1.0000  map-out
   -1 to io-base
;
' unmap-pci-io to unmap-io-regs

: map-bar10-fb  ( -- )
   \ Compute entire phys.lo..hi address for base address register 10
   map-in-broken?  if
      my-space h# 8200.0010 +  get-base-address        ( phys.lo,mid,hi )
   else
      0 0  my-space h# 200.0010 +                      ( phys.lo,mid,hi )
   then                                                ( phys.lo,mid,hi )

   /fb map-in to frame-buffer-adr

   \ Enable memory space access
   4 c-w@ 2 or 4 c-w!

   frame-buffer-adr encode-int " address" property
;
' map-bar10-fb   to map-frame-buffer

: unmap-bar10-fb  ( -- )
   4 c-w@ 2 invert and  4 c-w!
   
   frame-buffer-adr /fb map-out
   -1 to frame-buffer-adr

   " address" delete-property
;
' unmap-bar10-fb to unmap-frame-buffer
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
