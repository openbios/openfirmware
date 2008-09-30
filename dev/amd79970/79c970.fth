purpose: Driver for AMD 79C970 Ethernet controller
\ See license at end of file

headers
hex
: map-chips    ( -- ) 
   0 0 0100.0010 my-space +  h# 20  " map-in" $call-parent   to la
   \ Enable card response
   h# c100  my-space 6 +  " config-w!" $call-parent
   my-space 4 + dup  " config-w@" $call-parent  5 or
   swap  " config-w!" $call-parent
;
: unmap-chips  ( -- )
   la h# 20  " map-out" $call-parent  0 to la
   \ Disable card response
   my-space 4 + dup  " config-w@" $call-parent  5 invert and
   swap  " config-w!" $call-parent
;

0 instance value dma-region
0 instance value dma-region-size

0 instance value dma-virt
0 instance value dma-phys
0 instance value dma-size

: 3drop  ( n n n -- )  2drop drop  ;
defer dma-sync  ' 3drop to dma-sync

: synchronize  ( -- )  dma-virt dma-phys dma-size  dma-sync  ;

: lance-allocate-dma  ( size -- vadr )
   to dma-size

   \ In 32-bit mode, the DMA message descriptors must be 16-byte aligned,
   \ so we allocate extra space and round up the beginning address
   dma-size h# 10 + to dma-region-size
   
   " dma-sync" my-parent ihandle>phandle find-method  if
      to dma-sync
   then

   dma-size " dma-alloc" $call-parent  to dma-region

   dma-region h# f +  h# f invert and  to dma-virt

   dma-virt dma-size false " dma-map-in" $call-parent  to dma-phys
   dma-virt dma-phys -  to dma-offset

   dma-virt
;

decimal

: lance-free-dma  ( adr size -- )
   2drop
   dma-virt dma-phys dma-size  " dma-map-out" $call-parent

   dma-region dma-region-size " dma-free" $call-parent
;

\ *** Initialization routines ***

: extra-init   ( -- )  ;

64 constant /loopback

headers

\ LICENSE_BEGIN
\ Copyright (c) 1995 FirmWorks
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
