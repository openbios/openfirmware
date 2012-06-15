purpose: Common USB ethernet driver stuff
\ See license at end of file

hex
headers

\ String comparision
: $=  ( adr0 len0 adr1 len1 -- equal? )
   2 pick <>  if  3drop false exit  then  ( adr0 len0 adr1 )
   swap comp 0=
;

create mac-adr 0 c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c,
6 constant /mac-adr
: mac-adr$  ( -- adr len )  mac-adr /mac-adr  ;

false value use-promiscuous?
false value use-multicast?

defer init-nic         ( -- )			' noop to init-nic
defer reset-nic        ( -- )			' noop to reset-nic
defer wrap-msg         ( adr len -- adr' len' )	' noop to wrap-msg
defer unwrap-msg       ( adr len -- adr' len' )	' noop to unwrap-msg
defer link-up?	       ( -- up? )		' true to link-up?
defer start-phy        ( -- )			' noop to start-phy
defer start-mac        ( -- ) 			' noop to start-mac
defer stop-mac         ( -- )			' noop to stop-mac
defer mii{             ( -- )                   ' noop to mii{  \ Acquire
defer }mii             ( -- )                   ' noop to }mii  \ Release
defer mii@             ( reg -- val )           ' noop to mii@
defer mii!             ( val reg -- )           ' drop to mii@
external
defer promiscuous      ( -- )                   ' noop to promiscuous
defer set-multicast    ( adr len -- )           ' 2drop to set-multicast
headers

: phy-loopback{  ( -- )
   mii{  0 mii@  h# 4000 or  0 mii!  }mii
;
defer loopback{  ' phy-loopback{  to loopback{

: phy-}loopback  ( -- )
   mii{  0 mii@  h# 4000 invert and  0 mii!  }mii
;
defer }loopback  ' phy-}loopback  to }loopback

external
defer get-mac-address  ( -- adr len )		' mac-adr$ to get-mac-address
headers

: max-frame-size  ( -- size )  d# 1514  ;

0 value multi-packet?   \ True if a single USB transaction can
                        \ transfer multiple network packets, e.g. ax88772
0 value length-header?  \ True if 16-bit little-endian length header is
                        \ prefixed to outgoing frames (pegasus)

0 value residue         \ Remaining bytes in the packet buffer
0 value pkt-adr         \ Offset into the packet buffer

0 value vid
0 value pid

0 value outbuf
d# 2048 value /outbuf   \ Power of 2 larger than max-frame-size
                        \ Override as necessary

0 value inbuf
d# 2048 value /inbuf    \ Power of 2 larger than max-frame-size
                        \ Override as necessary

: init-buf  ( -- )
   outbuf 0=  if  /outbuf dma-alloc to outbuf  then
   inbuf  0=  if  /inbuf  dma-alloc to inbuf   then
   0 to residue
;
: free-buf  ( -- )
   outbuf  if  outbuf /outbuf dma-free  0 to outbuf  then
   inbuf   if  inbuf  /inbuf  dma-free  0 to inbuf   then
;

: property-or-abort  ( name$ -- n )
   2dup get-my-property  if          ( name$ )
      ." Can't find property " type cr  stop-mac abort
   then                              ( name$ value$ )
   2swap 2drop  decode-int  nip nip  ( n )
;

: init  ( -- )
   init
   " vendor-id"  property-or-abort  to vid
   " device-id"  property-or-abort  to pid
;

headers

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
