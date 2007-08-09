\ See license at end of file
purpose: Simple Internet Protocol version 6 (IPv6) implementation


\ Internet protocol version 6 (IPv6).

\ IPv6 refixes:
\ ::0/8			unaligned
\ 2000::/3		global unicast
\ fe80::/10		link-local unicast
\ fc00::/7		site-local IPv6 address
\ fd00::/8		private administration
\ ff00::/8		multicast

decimal

headerless

[ifndef] include-ipv4
\ Give the net up to 4 seconds to respond to packets
instance variable timeout-msecs   d# 4000 timeout-msecs !
[then]

struct ( ipv6-header )
    4 sfield ipv6-version  \ Actually, this is VVVVCCCC.CCCCFFFF.FFFFFFFF.FFFFFFFF
                           \ VVVV is the version
                           \ CCCCCCCC is the traffic class
                           \ FFFF.FFFFFFFF.FFFFFFFF is the flow label
    2 sfield ipv6-length
    1 sfield ipv6-next-hdr
    1 sfield ipv6-hop-limit
/ipv6 sfield ipv6-source-addr
/ipv6 sfield ipv6-dest-addr
      \ There maybe extension headers here.
constant /ipv6-header

\ Values of ipv6-next-hdr
d#   0 constant IP_HDR_HOP		\ Hop-by-hop option
d#   1 constant IP_HDR_ICMPV4		\ Internet control message protocol - IPv4
d#   2 constant IP_HDR_IGMPV4		\ Internet group management protocol - IPv4
d#   4 constant IP_HDR_IPV4
d#   6 constant IP_HDR_TCP
d#   8 constant IP_HDR_EGP		\ Exterior gateway protocol
d#   9 constant IP_HDR_IGP		\ Cisco private interior gateway
d#  17 constant IP_HDR_UDP
d#  41 constant IP_HDR_IPV6
d#  43 constant IP_HDR_ROUTING		\ Routing header
d#  44 constant IP_HDR_FRAGMENT
d#  45 constant IP_HDR_IDRP		\ Interdomain routing protocol
d#  46 constant IP_HDR_RSVP		\ Resource reservation protocol
d#  47 constant IP_HDR_GRE		\ General routing encapsulation
d#  50 constant IP_HDR_SECURE		\ Encrypted security payload
d#  51 constant IP_HDR_AUTHEN		\ Authentication
d#  58 constant IP_HDR_ICMPV6
d#  59 constant IP_HDR_NONE		\ No next header
d#  60 constant IP_HDR_DEST		\ Destination options
d#  88 constant IP_HDR_EIGRP
d#  89 constant IP_HDR_OSPF
d# 108 constant IP_HDR_COMP		\ IP payload compression protocol
d# 115 constant IP_HDR_L2TP		\ Layer 2 tunneling protocol
d# 132 constant IP_HDR_SCTP		\ Stream control transmission protocol
d# 135 constant IP_HDR_MOBILITY		\ Mobile IPV6

[ifndef] include-ipv4
d# 256 buffer: 'domain-name
' 'domain-name     " domain-name"    chosen-string
: use-server?  ( -- flag )  false  ;
[then]

headers
0 value /prefix                      \ Length of prefix (# of bits)
0 value prefix-flag
0 value prefix-lifetime
/ipv6 buffer: my-prefix

/ipv6 buffer: his-ipv6-addr
/ipv6 buffer: my-ipv6-addr-link-local
/ipv6 buffer: my-ipv6-addr-global
/ipv6 buffer: router-ipv6-addr
/ipv6 buffer: name-server-ipv6

headerless

\ link-local scope multicast all-nodes address
create unknown-ipv6-addr          0 l,  0 l,  0 l,  0 l,
create default-ipv6-addr          h# fe c, h# 80 c, 0 w, 0 l, 0 w, 0 c, h# ff c, h# fe c, 0 c, 0 w,
create ipv6-addr-mc-all-nodes     h# ff c, 2 c, 0 w, 0 l, 0 l, 0 w, 0 c, 1 c,
create ipv6-addr-mc-all-routers   h# ff c, 2 c, 0 w, 0 l, 0 l, 0 w, 0 c, 2 c,
create my-ipv6-addr-mc-sol-node   h# ff c, 2 c, 0 w, 0 l, 0 w, 0 c, 1 c, h# ff c, 0 c, 0 w,
create his-ipv6-addr-mc-sol-node  h# ff c, 2 c, 0 w, 0 l, 0 w, 0 c, 1 c, h# ff c, 0 c, 0 w,

: ipv6=  ( ip-addr1  ip-addr2 -- flag  )   /ipv6 comp  0=  ;

: unknown-ipv6-addr?   ( adr-buf -- flag )  unknown-ipv6-addr  ipv6=  ;
: knownv6?  ( adr-buf -- flag )  unknown-ipv6-addr? 0=  ;

: bits>mask  ( bits -- mask )
   ?dup 0=  if  0 exit  then
   0 swap  0 7  ?do                        ( mask bits )
      1 i << rot or swap                   ( mask' bits )
      1-  dup 0=  if  leave  then          ( mask bits' )
   -1 +loop  drop                          ( mask )
;

: prefix-match?  ( ip1 ip2 -- flag )
   /prefix 8 /mod 2over 2 pick       ( ip1 ip2 rem quot ip1 ip2 quot )
   comp 0=  if
      swap bits>mask >r             ( ip1 ip2 quot )  ( R: mask )
      tuck + c@ r@ and              ( ip1 quot [ip2+quot]&mask )  ( R: mask )
      -rot + c@ r> and =            ( flag )
   else
      4drop false
   then
;

: set-his-ipv6-addr-mc  ( -- )
   his-ipv6-addr /ipv6 + 3 - his-ipv6-addr-mc-sol-node /ipv6 + 3 - 3 move
;
: set-my-ipv6-addr-mc  ( -- )
   my-ipv6-addr-link-local /ipv6 + 3 - my-ipv6-addr-mc-sol-node /ipv6 + 3 - 3 move
;

: his-ipv6-addr-mc?   ( adr-buf -- flag )
   >r
   r@ his-ipv6-addr-mc-sol-node ipv6=        \ His solicited node address?
   r@ ipv6-addr-mc-all-nodes    ipv6= or     \ Multicast all-nodes?
   r> ipv6-addr-mc-all-routers  ipv6= or     \ Multicast all-routers?
;
: my-ipv6-addr-mc?   ( adr-buf -- flag )  
   >r
   r@ my-ipv6-addr-mc-sol-node ipv6=         \ My solicited node address?
   r> ipv6-addr-mc-all-nodes   ipv6= or      \ Multicast all-nodes?
;

: ipv6-addr-local?  ( adr-buf -- flag )  c@ h# e0 and h# 20 <>  ;

: use-routerv6?  ( -- flag )  routerv6-en-addr unknown-en-addr? not  ;

/ipv6 buffer: server-ipv6-addr
: use-serverv6?  ( -- flag )  server-ipv6-addr knownv6?  ;
: use-server?    ( -- flag )
   use-ipv6?  if  use-serverv6?  else  use-server?  then
;

\ Generate his multicast MAC address from his IPv6 address
: set-his-en-addr-mc  ( -- )
   multicast-en-addr     his-en-addr     2 move
   his-ipv6-addr c@ h# ff =  if
      his-ipv6-addr d# 12 + his-en-addr 2 + 4 move
   else
      h# ff                 his-en-addr 2 + c!
      his-ipv6-addr d# 13 + his-en-addr 3 + 3 move
   then
;

partial-headers
[ifndef] include-ipv4
: indent  ( -- )  bootnet-debug  if  ."     "  then  ;
[then]
headerless
: .my-ipv6-addr-link-local   ( -- )
   ." My IPv6 (local link): "  my-ipv6-addr-link-local  .ipv6
;
: .my-ipv6-addr-global  ( -- )
   ." My IPv6 (global):     "  my-ipv6-addr-global  .ipv6
; 
: .his-ipv6-addr  ( -- )  ." His IP: " his-ipv6-addr  .ipv6  ; 
: .my-prefix  ( -- )
   ." My prefix (global):   "  my-prefix  .ipv6  ." /" /prefix .d
;

[ifndef] include-ipv4
0 instance value last-ip-packet
[then]

headers
: set-dest-ipv6  ( buf -- )
   dup his-ipv6-addr ipv6=  if
      drop
   else
      his-ipv6-addr copy-ipv6-addr
      set-his-ipv6-addr-mc
      his-ipv6-addr ipv6-addr-local?  if
         unlock-link-addr
         my-ipv6-addr-link-local
      else
         use-routerv6?  if  routerv6-en-addr his-en-addr copy-en-addr  then
         my-ipv6-addr-global
      then
      my-ipv6-addr copy-ipv6-addr
   then
;

: lock-ipv6-address  ( -- )
   the-struct >r  last-ip-packet set-struct
   \ Don't change his-ipv6-addr for booting over gateway
   use-routerv6?  if   \ booting over a gateway.  
      bootnet-debug  if  indent ." Using router"  cr  then
   else
      \ In case of direct booting, i.e. booting over specified server
      \ don't change his addresses
      use-serverv6? 0=  if  ipv6-source-addr set-dest-ipv6  then
      lock-link-addr
   then
   bootnet-debug  if  indent .his-link-addr .his-ipv6-addr  then
   r> set-struct
;
: unlock-ipv6-address  ( -- )
   unknown-ipv6-addr set-dest-ipv6
   unknown-ipv6-addr server-ipv6-addr copy-ipv6-addr
;
headerless

\ This is a hook for handling IP packets addressed to us that are
\ of a different type than the expected one.  This could be used
\ to handle "behind the scenes" things like ICMP if necessary.
defer handle-ipv6  ( adr len protocol -- )
defer handle-other-ipv6  ( adr len -- )
headers
: (handle-ipv6)  ( adr len protocol -- )
   bootnet-debug  if
      dup ." (Discarding IPv6 packet of protocol " u. ." )" cr
   then
   3drop
;
' (handle-ipv6) is handle-ipv6

: (handle-other-ipv6)  ( adr len -- )
   bootnet-debug  if
      ." (Discarding IPv6 packet because of IP address mismatch)" cr
   then
   2drop
;
' (handle-other-ipv6) is handle-other-ipv6
headerless

: ipv6-payload  ( -- adr len )  the-struct /ipv6-header + ipv6-length xw@  ;

\ Skip checking his-ipv6-addr if it is an ICMPv6 packet which may come from anywhere.
: check-his-ipv6-addr?  ( -- flag )  ipv6-next-hdr c@ IP_HDR_ICMPV6 <>  ;
: ipv6-addr-match?  ( -- flag )
   check-his-ipv6-addr?  if
      his-ipv6-addr his-ipv6-addr-mc?  0=  if
         his-ipv6-addr ipv6-source-addr ipv6=  0=  if  false exit  then
      then
   then

   \ Accept IP multicast packets
   ipv6-dest-addr my-ipv6-addr-mc?  if  true exit  then

   \ If we don't know our own IP address yet, we accept every IP packet
   my-ipv6-addr unknown-ipv6-addr?  if  true exit  then

   \ Otherwise, we know our IP address, so we filter out packets addressed
   \ to other destinations.
   my-ipv6-addr ipv6-dest-addr ipv6=
;

: allocate-ipv6  ( payload-len -- payload-adr )
   /ipv6-header +  allocate-ethernet  /ipv6-header +
;
: free-ipv6  ( payload-adr payload-len -- )
   /ipv6-header negate /string  free-ethernet
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
