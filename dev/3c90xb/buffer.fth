\ See license at end of file
purpose: Buffers and methods for 3COM90xB

hex
headers

\ Data structure fields are in little-endian.
\ dpd is physically allocated as 1 dpd
\ udp is physically allocated as n contiguous implied buffer udps (circularly linked)

d# 32 constant #upd
d# 1528 constant /implied-buffer
1000.0000 constant std-uppktstatus	\ Enable implied buffer mode
1000.0000 constant std-dppktstatus	\ Disable packet round-up
8000.0000 constant dnfraglast		\ Last download fragment indicator

0 value /buf

struct
   4 field >dpnextptr
   4 field >framestartheader
   4 field >dnfragaddr
   4 field >dnfraglen
constant /dpd

struct
   4 field >upnextptr
   4 field >uppktstatus
constant /upd-header

\ aligned addresses
0 value dpd			\ Download Packet Descriptor (8-byte aligned)
0 value upd			\ Upload Packet Descriptor (8-byte aligned)
0 value upd-idx

\ physical addresses
0 value dpd-phys
0 value upd-phys
0 value buf-phys

\ unaligned addresses
0 value dpd-unaligned
0 value upd-unaligned
0 value buf

\ Define some read and write operators.
: le-w@   ( a -- w )   dup c@ swap ca1+ c@ bwjoin  ;
: le-w!   ( w a -- )   >r  wbsplit r@ ca1+ c! r> c!  ;
: le-l@   ( a -- l )   >r  r@ c@  r@ 1+ c@  r@ 2+ c@  r> 3 + c@  bljoin  ;
: le-l!   ( l a -- )   >r lbsplit  r@ 3 + c!  r@ 2+ c!  r@ 1+ c!  r> c!  ;

\ Aligned allocation.
8 constant /align8
: round-up  ( n align -- n' )  1- tuck + swap invert and  ;
: aligned-alloc  ( size align -- unaligned-virt aligned-virtual )
   dup >r +  dma-alloc  dup r> round-up
;
: alloc-buf8  ( size -- unalign-virt buf phys )
   dup >r /align8 aligned-alloc                ( unaligned-virt buf )
   dup r> false dma-map-in
;

\ Data structure maintenance.
: /upd  ( -- len )  /upd-header /implied-buffer +  ;
: >upd  ( idx -- virt )  /upd * upd +  ;
: >upd-phys  ( idx -- phys )  /upd * upd-phys +  ;
: upd-idx+  ( -- )  upd-idx 1+  dup #upd =  if  drop 0  then  to upd-idx  ;

: init-dpd  ( -- )
   dpd  if  exit  then
   /dpd alloc-buf8 to dpd-phys to dpd to dpd-unaligned
   dpd /dpd erase
   std-dppktstatus dpd >uppktstatus le-l!
;

: init-upd  ( -- )
   upd  if  exit  then
   0 to upd-idx
   /upd #upd * alloc-buf8 to upd-phys to upd to upd-unaligned
   #upd 0 do
      i 1+ dup #upd =  if  drop 0  then  >upd-phys i >upd >upnextptr le-l!
      std-uppktstatus i >upd >uppktstatus le-l!
   loop
;

: init-buffers  ( -- )
   init-dpd
   init-upd
;

: find-upload-pkt?  ( -- false | idx true )
   upd-idx >upd upd-idx >upd-phys /upd dma-sync
   upd-idx >upd >uppktstatus le-l@ 8000 and
   if  upd-idx upd-idx+  true  else  false  then
;
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
