purpose: Program channel 2 of an ISA DMA controller for use with an ISA floppy
\ See license at end of file

hex
headerless

: dma-setup  ( vadr len write-memory? -- vadr devaddr len )
   14 8 pc!		           \ disable the chip while programming it

   if  46  else  4a  then   b pc!  \ single transfer, increment addr,
				   \ no autoinit, ch 2

   2dup true  " dma-map-in" $call-parent  swap  ( vadr devadr len )

   \ Load count                                 ( vadr devadr len )
   0 c pc!		               \ Reset address byte pointer
   dup 1- wbsplit  swap 5 pc!  5 pc!            ( vadr devadr len )

   \ Load address
   0 c pc!		               \ Reset address byte pointer
   over  lbsplit  2swap  swap 4 pc!  4 pc!      ( vadr devadr len page-byte hi-byte )

   swap 81 pc!                                  ( vadr devadr len hi-byte )

   \ Setting this high byte register last causes the DMA controller
   \ in the 82378 to increment all 32 bits of the address.
   481 pc!                                      ( vadr devadr len )

   c0 d6 pc!  			   \ Set cascade mode for channel 4
   0 d4 pc!			   \ Release channel 4 (master for chs. 0-3)
   2 a pc!			   \ Release channel 2

   10 8 pc!			   \ re-enable the chip

;
: dma-wait  ( vaddr devaddr len -- timeout? )
   true
   d# 400  0  do
      8 pc@  4 and  if  0= leave  then
      d# 10 ms
   loop
   >r
   " dma-map-out" $call-parent
   r>
;

headers
external

\ The deblocker needs these
: dma-alloc  ( len -- adr )
   \ We must ensure that the buffer is in the lower 16 MBytes,
   \ and doesn't cross a 64K boundary.

   \ Allocate twice as much as is wanted to guarantee that there will
   \ be a piece of the desired size on one side of a 64K boundary.

   dup 2*  " dma-alloc" $call-parent  swap    ( adr len )

   \ The boundary crossing must be evaluated in physical space
   2dup true " dma-map-in"  $call-parent      ( adr len phys )
   3dup swap " dma-map-out" $call-parent      ( adr len phys )

   h# ffff and                                ( adr len offset )

   tuck + na1+  h# 10000  >  if               ( adr offset )
      \ The start is too close to the boundary,
      \ so we use the piece above the boundary

      over swap -  h# 10000 +                 ( adr adr' )
   else                                       ( adr offset )
      drop  dup  na1+                         ( adr adr' )
   then

   \ Store the address of the allocated piece just before the returned
   \ address, so that dma-free can find that address
   tuck -1 na+ !                              ( adr' )
;
: dma-free   ( adr len -- )  swap  -1 na+ @  swap  " dma-free"  $call-parent  ;

headers

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
