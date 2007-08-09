\ See license at end of file
purpose:  Internet Protocol version 6 (IPv6) fragmentation/reassembly implementation

headerless

struct ( ipv6-frag-header )
   1 sfield ipv6-fh-next-hdr
   1 sfield ipv6-fh-len
   2 sfield ipv6-fh-frag-offset     \ OOOO.OOOO.OOOO.OxxM
                                    \ Os contain the fragment offset; M=1=more fragments
   4 sfield ipv6-fh-frag-id
   \ Maybe followed by zero or more of headers in following order:
   \  -  Hop-by-Hop Options header
   \  -  Destination Options header (for first destination, plus destinations in the
   \     Routing header)
   \  -  Routing header
   \  -  Fragment header
   \  -  Authentication header
   \  -  Encapsulating Security Payload header
   \  -  Destionation Options header (for final destination)
   \  -  Upper-Layer header
constant /ipv6-frag-hdr

instance variable frag-id
h# 40 instance value hop-limit

headers

\ *********************************************************************************
\                                   Send IP packet
\ *********************************************************************************

[ifndef] include-ipv4
: send-ip-packet  ( adr len protocol -- )  3drop  ;
[then]

: max-ipv6-payload  ( -- n )
   max-link-payload /ipv6-header -
   h# ffff.fff8 and  
;
: max-ipv6-fragment  ( -- n )
   max-link-payload /ipv6-header - /ipv6-frag-hdr -
   h# ffff.fff8 and  
;

headerless
: (send-ipv6-packet)  ( adr len protocol -- )
   rot /ipv6-header - set-struct                     ( len protocol )
      h# 6000.0000  ipv6-version     xl!             \ version 6
      ( protocol )  ipv6-next-hdr    xc!             ( len )
      ( len ) dup   ipv6-length      xw!             ( len )
      his-ipv6-addr ipv6-addr-local?  if  hop-limit  else  router-hop-limit  then
      ( hop-limit ) ipv6-hop-limit   xc!             ( len )
      my-ipv6-addr  ipv6-source-addr copy-ipv6-addr  ( len )
      his-ipv6-addr ipv6-dest-addr   copy-ipv6-addr  ( len )
   /ipv6-header +                                    ( ip-len )
   the-struct swap                                   ( ip-adr ip-len )
   ipv6-dest-addr  IPV6_TYPE  send-link-packet       ( )
;

0 value oaddr			\ original data packet address
0 value olen			\ original data packet length
0 value oprotocol		\ original protocol
0 value fadr			\ fragment address

: send-ipv6-fragment  ( offset -- )
   >r fadr				    ( fadr )  ( R: offset )
   olen r@ - max-ipv6-fragment min 	    ( fadr flen )  ( R: offset )
   2dup oaddr r@ + -rot move		    ( fadr flen )  ( R: offset )
   fadr set-struct                          ( fadr flen )  ( R: offset )
      oprotocol  ipv6-fh-next-hdr    xc!    \ Next header in fragment header
      0          ipv6-fh-len         xc!    \ Length of header in units of 8 bytes - 1
      frag-id    ipv6-fh-frag-id     xl!    \ Fragment id
      dup r@ + olen <  1 and                ( fadr flen more? )  ( R: offset )
      r> 3 << or ipv6-fh-frag-offset xw!    ( fadr flen )
   /ipv6-frag-hdr +                         ( fadr flen' )
   IP_HDR_FRAGMENT (send-ipv6-packet)       ( )
;

: send-ipv6-packet  ( adr len protocol -- )
   over max-ipv6-payload <=  if
      (send-ipv6-packet)
   else
      1 frag-id +!
      over max-ipv6-fragment /mod swap 0>  if  1+  then  ( adr len protocol #frags )
      >r to oprotocol to olen to oaddr r>   ( #frags )
      max-ipv6-payload allocate-ipv6 to fadr  ( #frags )
      ( #frags ) 0  do                      ( )
         i max-ipv6-fragment * send-ipv6-fragment
      loop
      fadr max-ipv6-payload free-ipv6
   then
;

: send-ip-packet  ( adr len protocol -- )
   use-ipv6?  if  send-ipv6-packet  else  send-ip-packet  then
;

\ *********************************************************************************
\                                 Receive IP packet
\ *********************************************************************************

defer handle-icmpv6 ( contents-adr,len protocol -- )  ' 3drop to handle-icmpv6

[ifndef] include-ipv4
: process-timeout?  ( -- flag )  false  ;
: process-ipv4-packet  ( adr len type -- flag )
   3drop  ." Discarding IPv4 packet" cr false
;
: ip-payload  ( len -- adr len' )  .ipv4-not-supported  ;
[then]

: process-ipv6-packet  ( adr len type -- false | contents-adr,len true )
   \ XXX Not complete.  Need to process additional headers and fragmentation.
   \ XXX Assume no additional headers for now.

   nip swap                                        ( type adr )
   dup set-struct to last-ip-packet                ( type )
   ipv6-addr-match?  if                            ( type )
      ipv6-next-hdr c@ dup >r = dup  if            ( type=? )  ( R: next-hdr )
         ipv6-payload rot                          ( contents-adr,len true )  ( R: next-hdr )
      then                                         ( false | contents-adr,len true ) ( R: next-hdr )
      r> IP_HDR_ICMPV6 =  if                       ( false | contents-adr,len true )
         ipv6-payload IP_HDR_ICMPV6 handle-icmpv6  \ Handle ICMPv6 packets
      else
         dup not  if  ipv6-payload ipv6-next-hdr c@ handle-ipv6  then
                                                   \ Handle other unexpected packets
      then                                         ( false | contents-adr,len true )
   else
      drop ipv6-payload handle-other-ipv6          \ Handle packets for other address
      false                                        ( false )
   then                                            ( false | contents-adr,len true )
;

: receive-ip-packet  ( type -- true | contents-adr,len false )
   begin
      use-ipv6?  if  IPV6_TYPE  else  IP_TYPE  then
      receive-ethernet-packet                    ( type [ip-adr,len] flag )
      if  drop process-timeout? drop true exit  then

      over ipv4?  if
         2 pick process-ipv4-packet              ( type [len] flag )
         if  ip-payload true  else  false  then  ( type [contents-adr,len] flag )
      else
         2 pick process-ipv6-packet              ( type [contents-adr,len] flag )
      then

      ?dup 0=  if				 ( type )
         process-timeout?  if  drop true exit  then
         false
      then
   until					 ( type contents-adr,len )
   rot drop false                                ( contents-adr,len false )
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
