purpose: Map registers, allocate and map DMA space
\ See license at end of file

\ Possibly-unaligned addresses.  We allocate a bit extra and return a
\ 16-byte-aligned address within the allocated piece.
0 value real-vaddr
0 value real-size

: lance-allocate-dma  ( size -- vadr )
   h# 10 + to real-size                   ( )

   real-size " dma-alloc" my-parent $call-method  to real-vaddr

   real-vaddr real-size false  " dma-map-in" $call-parent   ( real-paddr )

   real-vaddr swap -  to dma-offset

   real-vaddr  h# f +  h# f invert and    ( vadr )
;

: lance-free-dma  ( adr size -- )
   2drop  real-vaddr real-size " dma-free" my-parent $call-method
;

\ Dma-sync could be dummy routine if parent device doesn't support.
: dma-sync  ( virt-addr dev-addr size -- )
   " dma-sync" my-parent ['] $call-method catch if
      2drop 2drop 2drop
   then				     ( nbytes eb )
;

\ Set PCI configuration registers
: my-config-w!  ( w-value offset -- )  my-space + " config-w!" $call-parent  ;

: map-chips    ( -- )
   0 0 my-space  h# 100.0010 +  h# 20  " map-in" $call-parent   to la

   \ Status field: Clear PERR, SERR and DATAPERR = c100
   \ Command field: Set BMEN and IOEN = 0005
   h# c100 6 my-config-w!  0005 4 my-config-w!
;

: unmap-chips  ( -- )
   la h# 20 " map-out" my-parent $call-method
   0 to la
;

\ LICENSE_BEGIN
\ Copyright (c) 1994 FirmWorks
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
