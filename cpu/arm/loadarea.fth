\ See license at end of file
purpose: Manage the allocation and mapping of the program load area (load-base)

h# f000.0000 constant def-load-base
def-load-base to load-limit

h# 10.0000 constant /load-piece
h#  8.0000 constant /reserved
h#  8.0000 constant /dma-reserved

\ Frees virtual address space and physical memory behind it
: release-all  ( virt len -- )
   >r dup mmu-translate  if       ( virt phys mode r: len )
      drop r@ mem-release         ( virt r: len )
      dup r@ mmu-unmap            ( virt r: len )
   then                           ( virt r: len )
   r> mmu-release
;

\ Release-load-area depends on the way that map-load-area populates
\ the load area in piecewise-contiguous section-sized units
: release-load-area  ( boundary-adr -- )
   pagesize round-up		             ( unused-base )

   dup /load-piece round-up load-limit umin  ( unused next-boundary )
   2dup u<  if                               ( unused next-boundary )
      2dup over -  release-all               ( unused next-boundary )
   then                                      ( unused next-boundary )

   load-limit swap  ?do  i /load-piece release-all  /load-piece +loop
					     ( unused )
   to load-limit
;

: map-load-area  ( -- )
   \ Reserve some DMA memory and some ordinary memory
   /dma-reserved " /"  " dma-alloc" execute-device-method  drop >r
   /reserved dup mem-claim  >r           

   \ Allocate and map the load region
   def-load-base  begin                  ( top )
   /load-piece /load-piece ['] mem-claim  catch  0=  while  ( top phys )
      over  /load-piece  0   mmu-claim   ( top phys virt )
      /load-piece  -1  mmu-map           ( top )
      /load-piece +                      ( top' )
   repeat                                ( top x x )
   2drop  to load-limit                  ( )

   r> /reserved mem-release              \ Put the reserved piece back
   r> /dma-reserved  " /"  " dma-free" execute-device-method  drop
;

stand-init: Load area
   map-load-area
;

\ LICENSE_BEGIN
\ Copyright (c) 2010 FirmWorks
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
