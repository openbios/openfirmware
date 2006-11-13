\ See license at end of file
purpose: Simple User Datagram Protocol (UDP) implementation
decimal

headers
\ udp-checksum? controls checksum calculation
\ of outgoing UPD Packets
\ 0 value udp-checksum?
headerless
d# 17 constant UDP

instance variable my-udp-port
instance variable his-udp-port

struct ( udp-header )
   2 sfield udp-source-port
   2 sfield udp-dest-port
   2 sfield udp-length
   2 sfield udp-checksum
constant /udp-header

struct ( udp-pseudo-hdr )
  /i field udp-src-addr
  /i field udp-dst-addr
   2 field udp-protocol-id
   2 field udp-len-copy
constant /udp-pseudo-hdr

/udp-pseudo-hdr instance buffer: udp-pseudo-hdr

0 instance value udp-len

\ Assumes the-struct is the UDP packet.
: fill-udp-pseudo-hdr  ( -- )
   /ip-header negate +struct
   udp-pseudo-hdr                                  ( udp-pseudo-addr )
   ip-source-addr over udp-src-addr copy-ip-addr   ( udp-pseudo-addr )
   ip-dest-addr   over udp-dst-addr copy-ip-addr   ( udp-pseudo-addr )
   UDP over udp-protocol-id xw!                    ( udp-pseudo-addr )
   /ip-header +struct                              ( udp-pseudo-addr )
   udp-length xw@  swap udp-len-copy xw!           (  )
;

\ Assumes the-struct is the UDP packet.
: calc-udp-checksum  ( -- checksum )
   fill-udp-pseudo-hdr
   0 udp-pseudo-hdr /udp-pseudo-hdr  (oc-checksum)  ( cksum )
   0 udp-checksum xw!
   the-struct udp-length xw@ oc-checksum
;

headers
: send-udp-packet  ( data-addr data-len src-port dst-port -- )
   2swap swap /udp-header - set-struct -rot      ( data-len src-port dst-port )
   udp-dest-port xw!  udp-source-port xw!        ( data-len )
   /udp-header +  dup udp-length xw!             ( udp-len )
   0 udp-checksum  xw!                           ( udp-len )

   udp-checksum?  if                             ( udp-len )
      calc-udp-checksum udp-checksum xw!         ( udp-len )
   then                                          ( udp-len )

   the-struct  swap  UDP  send-ip-packet         ( )
;
: allocate-udp  ( payload-len -- payload-adr )
   /udp-header +  allocate-ip  /udp-header +
;
: free-udp  ( payload-adr payload-len -- )
   /udp-header negate /string  free-ip
;
headerless

: bad-udp-checksum?  ( -- bad? )
   udp-checksum xw@  dup  if  ( checksum )
      calc-udp-checksum  <>   ( bad? )
   then                       ( bad? )
;

: lock-udp-address  ( -- )  lock-ip-address  ;

defer handle-udp  ( adr len src-port dst-port -- )
defer handle-bad-udp  ( adr len src-port -- )
headers
: (handle-udp)  ( adr len src-port dst-port -- )
   bootnet-debug  if
      2dup swap
      ." (Discarding UDP packet, source port: " u. ." dest port: " u. ." )" cr
   then
   4drop
;
' (handle-udp) is handle-udp
: (handle-bad-udp)  ( adr len src-port -- )
   bootnet-debug  if
      dup
      ." (Discarding UDP packet with bad checksum, source port: " u. ." )" cr
   then
   3drop
;
' (handle-bad-udp) is handle-bad-udp
headerless

: udp-payload  ( len -- adr' len' src-port )
   drop
   the-struct  udp-length xw@  /udp-header /string  udp-source-port xw@
;
headers
: receive-udp-packet  ( dst-port -- true | udp-packet-adr,len src-port false )
   begin                                                ( port )
      UDP  receive-ip-packet  if  drop true exit  then  ( port udp-adr,len )
      swap set-struct                                   ( port len )
      bad-udp-checksum?   if                            ( port len )
         udp-payload handle-bad-udp			( port )
         drop true exit			\ Discard garbled packet and retry
      else                                              ( port len )
         over udp-dest-port xw@  =  if                  ( port len )
            true                                        ( port len true )
         else                                           ( port len )
            udp-payload  udp-dest-port xw@  handle-udp  ( port )
            false                                       ( port false )
         then                                           ( port [ len ] flag )
      then                                              ( port [ len ] flag )
   until                                                ( port len )
   nip udp-payload  false                               ( adr len port false )
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
