purpose: Maintain a byte swap table for the Forth dictionary
\ See license at end of file

decimal

0 value swap-map

\ The swap map has one bit for every 32-bit word, since we assume
\ that relocated longwords must start on a 32-bit boundary
d# 32 constant bits/swapbit

\ Number of bytes in bitmap
: >swap-map-size  ( end-adr -- )
   origin -  bits/swapbit /mod  swap  if  1+  then
; 
: /swap-map  ( -- n )  memtop @  >swap-map-size  ;

defer set-swap-bit
: (set-swap-bit)  ( addr -- )
   origin -  2 >>           ( lword-index )
   dup  3 >> /swap-map u<  if  swap-map bitset  else  drop  then
;

\ The upper endpoint must be aligned in case the lower endpoint
\ is unaligned and the lower endpoint straddles an alignment boundary.
\ In that case, if we didn't align the upper endpoint, the last
\ word of the range would not be marked.
: note-string  ( adr len -- adr len )
   2dup  over + aligned swap  ?do  i set-swap-bit  /n +loop
;

defer init-swap-map
: (init-swap-map)  ( -- )
   /swap-map alloc-mem  is swap-map
   swap-map /swap-map erase
   \ Copy in old swap map
   here user-size +  swap-map  here >swap-map-size  move
   ['] (set-swap-bit) is set-swap-bit
;
' (init-swap-map) is init-swap-map

\ Plug this into init-swap-map to turn off swap-map management
: no-swap-map  ( -- )  ['] drop is set-swap-bit  ;

: init  ( -- )  init  init-swap-map  ;

\ LICENSE_BEGIN
\ Copyright (c) 2007 FirmWorks
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
