\ See license at end of file
purpose: Simple User Datagram Protocol version 6 (UDP) implementation
decimal

headerless

[ifndef] include-ipv4
struct ( udp-header )
   2 sfield udp-source-port
   2 sfield udp-dest-port
   2 sfield udp-length
   2 sfield udp-checksum
constant /udp-header

: clear-his-address  ( -- )  ;
: lock-udp-address  ( -- )  ;
: send-udp-packet  ( data-addr data-len src-port dst-port -- )  .ipv4-not-supported  ;
: allocate-udp  ( payload-len -- payload-adr )  .ipv4-not-supported  ;
: free-udp  ( payload-adr payload-len -- )  .ipv4-not-supported  ;
[then]

struct ( udpv6-pseudo-hdr )
  /ipv6 field udpv6-src-addr
  /ipv6 field udpv6-dst-addr
      4 field udpv6-len-copy
      4 field udpv6-protocol-id
constant /udpv6-pseudo-hdr

/udpv6-pseudo-hdr instance buffer: udpv6-pseudo-hdr

\ Assumes the-struct is the UDP packet.
: fill-udpv6-pseudo-hdr  ( his-ipv6 my-ipv6 -- )
   /ipv6-header negate +struct
   udpv6-pseudo-hdr                                      ( udp-pseudo-addr )
   tuck ( my-ipv6-addr )  udpv6-src-addr copy-ipv6-addr  ( udp-pseudo-addr )
   tuck ( his-ipv6-addr ) udpv6-dst-addr copy-ipv6-addr  ( udp-pseudo-addr )
   IP_HDR_UDP over udpv6-protocol-id xl!                 ( udp-pseudo-addr )
   /ipv6-header +struct                                  ( udp-pseudo-addr )
   udp-length xw@  swap udpv6-len-copy xl!               (  )
;

\ Assumes the-struct is the UDP packet.
: calc-udpv6-checksum  ( his-ipv6 my-ipv6 -- checksum )
   fill-udpv6-pseudo-hdr
   0 udpv6-pseudo-hdr /udpv6-pseudo-hdr  (oc-checksum)  ( cksum )
   0 udp-checksum xw!
   the-struct udp-length xw@ oc-checksum
;

headers
: send-udpv6-packet  ( data-addr data-len src-port dst-port -- )
   2swap swap /udp-header - set-struct -rot      ( data-len src-port dst-port )
   udp-dest-port xw!  udp-source-port xw!        ( data-len )
   /udp-header +  dup udp-length xw!             ( udp-len )
   0 udp-checksum  xw!                           ( udp-len )

   his-ipv6-addr my-ipv6-addr calc-udpv6-checksum udp-checksum xw!
                                                 ( udp-len )

   the-struct  swap  IP_HDR_UDP  send-ipv6-packet       ( )
;
: allocate-udpv6  ( payload-len -- payload-adr )
   /udp-header +  allocate-ipv6  /udp-header +
;
: free-udpv6  ( payload-adr payload-len -- )
   /udp-header negate /string  free-ipv6
;

: send-udp-packet  ( data-addr data-len src-port dst-port -- )
   use-ipv6?  if  send-udpv6-packet  else  send-udp-packet  then
;
: allocate-udp  ( payload-len -- payload-adr )
   use-ipv6?  if  allocate-udpv6  else  allocate-udp  then
;
: free-udp  ( payload-adr payload-len -- )
   use-ipv6?  if  free-udpv6  else  free-udp  then
;
headerless

\ XXX Assume no extra IPv6 headers
: bad-udpv6-checksum?  ( -- bad? )
   udp-checksum xw@  dup  if           ( checksum )
      the-struct dup >r                ( checksum )  ( R: udp )
      /ipv6-header - set-struct        ( checksum )  ( R: udp )
      ipv6-source-addr ipv6-dest-addr  ( checksum his-ipv6 my-ipv6 )  ( R: udp )
      r> set-struct                    ( checksum his-ipv6 my-ipv6 )
      calc-udpv6-checksum  <>          ( bad? )
   then                                ( bad? )
;

: lock-udpv6-address  ( -- )  lock-ipv6-address  ;
: lock-udp-address  ( -- )
   use-ipv6?  if  lock-udpv6-address  else  lock-udp-address  then
;

[ifndef] include-ipv4
defer handle-udp  ( adr len src-port dst-port -- )
defer handle-bad-udp  ( adr len src-port -- )
headers
: receive-udp-packet  ( dst-port -- true )  drop true  ;
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
[then]

headers
: receive-udp-packetv6  ( dst-port -- true | udp-packet-adr,len src-port false )
   begin                                                ( port )
      IP_HDR_UDP  receive-ip-packet  if  drop true exit  then  ( port udp-adr,len )
      swap set-struct                                   ( port len )
      bad-udpv6-checksum?   if                          ( port len )
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

: receive-udp-packet  ( dst-port -- true | udp-packet-adr,len src-port false )
   use-ipv6?  if  receive-udp-packetv6  else  receive-udp-packet  then
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
