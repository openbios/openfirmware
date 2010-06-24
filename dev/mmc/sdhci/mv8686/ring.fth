\ See license at end of file
purpose: Packet queue routines

\ Maintain a ring of packets that were received while transmitting.

\ Since the firmware mostly uses request/response protocols, the expected
\ queue length is either 0 or 1.  But for NANDblaster, the queue can
\ get pretty large, because the incoming data rate is rather high.

\ To avoid expensive dma-alloc and dma-free operations during reception,
\ we pre-allocate all the DMA space and manage it as a ring buffer.
\ Each slot in the ring is fixed length.  The first word is the packet
\ length, followed by the data.

\ The ring is empty when next-put == next-get .  It is full when
\ advance(next-put) == next-get .  The "wasted" ring slot is used
\ to handle the ring-full condition gracefully.  When new-buffer is
\ called with the ring full, the empty slot at next-put is returned,
\ but when enque-buffer is subsequently called, if the ring is still
\ full, next-put is not updated, so that slot will be overwritten
\ the next time.

d# 32 constant max#queued	\ Toss old packets after this number
d# 1600 constant /packet-max
max#queued /packet-max * constant /ring

0 instance value next-put
0 instance value next-get

0 instance value rx-ring

: init-queue  ( -- )
   /ring  dma-alloc  to rx-ring
   rx-ring to next-put
   rx-ring to next-get
;

: advance  ( adr -- adr' )
   /packet-max +                  ( adr' )
   dup  rx-ring /ring +  =  if    ( adr )
      drop rx-ring                ( adr' )
   then                           ( adr )
;

: drain-queue  ( -- )  rx-ring /ring dma-free  ;

: new-buffer  ( packet-length -- handle adr len )
   next-put                  ( packet-length handle )
   dup na1+                  ( packet-length handle adr )
   rot /packet-max /n - min  ( handle adr len )
   dup 3 pick !              ( handle adr len )
;

: enque-buffer  ( handle -- )
   advance  dup next-get <>  if  to next-put  then
;

: get-queued?  ( -- false | adr len true )
   next-put next-get =  if  false exit  then  ( )
   next-get na1+  next-get @  true            ( adr len true )
;
: recycle-queued  ( -- )  next-get advance to next-get  ;

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
