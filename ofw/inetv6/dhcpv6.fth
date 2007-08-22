\ See license at end of file
purpose: Dynamic Host Configuration Protocol for IPv6 (DHCPv6) (RFC 3315)

d# 1000 constant dhcpv6-timeout    \ 1 second timeout

d# 546 constant client-port
d# 547 constant dhcpv6-port

struct ( dhcpv6 packet )
   1 sfield  dh6-op                \ DHCPv6 message type
   3 sfield  dh6-xid               \ Transaction ID
   0 sfield  dh6-options           \ DHCPv6 options
constant /dhcpv6-hdr

: dh6-xid@  ( -- xid )  dh6-xid 2 + c@ dh6-xid 1+ c@ dh6-xid c@ 0 bljoin  ;
: dh6-xid!  ( xid -- )  lbsplit  drop dh6-xid c! dh6-xid 1+ c! dh6-xid 2 + c!  ;

\ dh6-op values
\    1  SOLICIT         Used by clients to locate DHCP servers
\    2  ADVERTISE       Used by servers as response to SOLICIT
\    3  REQUEST         Used by clients to get info from servers
\    4  CONFIRM         Used by clients to verify validity of params
\    5  RENEW           Used by clients to extend lifetime
\    6  REBIND          Used by clients to extend lifetime if no reply to RENEW
\    7  REPLY           Used by servers to respond
\    8  RELEASE         Used by clients to release their IPv6 addresses
\    9  DECLINE         Used by clients to decline assigned addresses
\   10  RECONFIGURE     Used by DHCP servers to inform clients of new cfg
\   11  INFO_REQUEST    Used by clients to request additional cfg params
\   12  RELAY_FORWARD   Used by DHCP relays to forward client msgs to servers
\   13  RELAY_REPLY     Used by DHCP servers to send msgs to clients via a relay

struct ( dhcpv6 option )
   2 sfield  do6-code              \ Option code
   2 sfield  do6-len               \ Option len
   0 sfield  do6-data              \ Option data
constant /do6-hdr

d# 1024 constant /dhcpv6-packet

\ do6-code values
\    1  client ID
\    2  server ID
\    3  ID association for nontemporary address (IA_NA)
\    4  ID association for temporary address (IA_TA)
\    5  IA address
\    6  option request
\    7  preference
\    8  elapse time
\    9  relay message
\   11  authentication
\   12  server unicast

[ifndef] include-ipv4
d# 256 buffer: 'root-path
d# 256 buffer: 'client-name
d# 256 buffer: 'vendor-options
headers
' 'client-name     " client-name"    chosen-string
' 'vendor-options  " vendor-options" chosen-string
' 'root-path       " root-path"      chosen-string
: domain-name  ( -- adr len )  'domain-name cscount  ;
[then]

0 instance value dhcpv6-packet
0 instance value dhcpv6-len              \ Actual length of received DHCPv6 packet
0 instance value dhcpv6-option           \ Pointer to option field in dhcpv6-packet

: /dhcpv6-packet     ( -- len )  dhcpv6-option dhcpv6-packet -  ;
: set-dhcpv6-option  ( -- )      dh6-options to dhcpv6-option  ;
: +dhcpv6-option     ( n -- )    dhcpv6-option + to dhcpv6-option  ;
: opc!  ( c -- )  dhcpv6-option c! 1 +dhcpv6-option  ;
: opw!  ( w -- )  dhcpv6-option be-w!  2 +dhcpv6-option  ;
: opl!  ( l -- )  dhcpv6-option be-l!  4 +dhcpv6-option  ;
: op$!  ( $ -- )  tuck dhcpv6-option swap move  +dhcpv6-option  ;

: allocate-dhcpv6  ( size -- )
   allocate-udp dup is dhcpv6-packet  set-struct
   set-dhcpv6-option

   get-msecs start-time !

   \ Set "random" transaction ID and random number generator seed
   my-en-addr 2 + xl@  get-msecs  xor  dup  xid !  rn !
;
: free-dhcpv6  ( size -- )  dhcpv6-packet swap free-udp  ;

: init-dhcpv6  ( -- )
[ifndef] include-ipv4
   0 'domain-name c!
   0 'root-path   c!
   0 'client-name c!
   0 'vendor-options c!
\   0 file-name-buf c!
[then]
;

also forth definitions
stand-init:  DHCPv6 init
   init-dhcpv6
;
previous definitions

: send-dhcpv6-packet  ( size op -- )
   dh6-op c!
   xid  dh6-xid!
   dhcpv6-packet swap client-port dhcpv6-port send-udpv6-packet
;

: detect-dhcpv6-packet  ( op -- timeout? )
   >r
   dhcpv6-timeout set-timeout
   begin  client-port receive-udp-packet  0=  while       ( adr,len src-port )
      drop  to  dhcpv6-len  set-struct
the-struct dhcpv6-len dump cr
      dh6-xid@ xid @ h# ff.ffff =  dh6-op c@ r@ =  and  if  r> drop false exit  then
   repeat
   r> drop true
;

: option-client-id  ( -- )
   1 opw!                                   \ Client ID option
   /e 4 + opw!                              \ Option len
   3 opw!                                   \ DUID type: link-layer address
   1 opw!                                   \ Hardware type: ethernet
   my-en-addr /e op$!                       \ My mac address
;

: option-req-option  ( -- )
   6 opw!                                   \ Option request option
   2 opw!                                   \ Option len
   d# 23 opw!                               \ OPTION_DNS_SERVERS
;

: dhcpv6-solicit  ( -- )
   ipv6-addr-mc-all-dhcp his-ipv6-addr copy-ipv6-addr
   set-his-en-addr-mc
   option-client-id
   \ option-ia to which server will assign addresses
   option-req-option
   /dhcpv6-packet d# 11 send-dhcpv6-packet
   2 detect-dhcpv6-packet  abort" Timeout soliciting DHCPv6 server"
;
: dhcpv6-req-info  ( -- )
   ipv6-addr-mc-all-dhcp his-ipv6-addr copy-ipv6-addr
   set-his-en-addr-mc
   option-client-id
   option-req-option
   /dhcpv6-packet d# 11 send-dhcpv6-packet
   7 detect-dhcpv6-packet  abort" Timeout waiting for requested info"
;

: do-dhcpv6-stateless  ( -- )
   ." DHCPv6 stateless auto configuration not supported yet" cr exit

   bootnet-debug  if
      ." DHCPv6 protocol: Getting network information" cr
   then
   /dhcpv6-packet allocate-dhcpv6

   ['] dhcpv6-req-info catch  drop

   /dhcpv6-packet free-dhcpv6
;

: do-dhcpv6-stateful  ( -- )
   true abort" Stateful autoconfiguration not supported yet"
;

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
