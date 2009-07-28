\ See license at end of file
purpose: Simple Internet Protocol (IP) implementation


\ Internet protocol (IP).

decimal

4 constant /i			\ Bytes per IP address

: copy-ip-addr  ( src dst -- )  /i move  ;

/i buffer: my-ip-addr
/i buffer: subnetmask

headerless
\ Give the net up to 4 seconds to respond to packets
instance variable timeout-msecs   d# 4000 timeout-msecs !

struct ( ip-header )
   1 sfield ip-version  \ Actually, this is VVVVLLLL, where LLLL is the
			\ header length in 32-bit words.
   1 sfield ip-service
   2 sfield ip-length
   2 sfield ip-id
   2 sfield ip-fragment
   1 sfield ip-ttl
   1 sfield ip-protocol
   2 sfield ip-checksum
  /i sfield ip-source-addr
  /i sfield ip-dest-addr
\ It is possible to have a variable-length list of options here at the end.
\ Options contain information like source routing lists, return route lists,
\ and error reports.  The low nibble of the ip-version byte gives the length
\ of the header including the options.
constant /ip-header

\ These things hardly ever change, so we make them variables
instance variable ttl   d# 123 ttl !
instance variable ip-sequence
d# 256 buffer: 'domain-name
headers
/i buffer: his-ip-addr
/i buffer: name-server-ip
' 'domain-name     " domain-name"    chosen-string

headerless

decimal
h# 800 constant IP_TYPE

instance variable total-length

instance variable bufptr
: -buf,  ( c -- )  -1 bufptr +! bufptr @ c!  ;

/i buffer: broadcast-ip-addr

create def-broadcast-ip  h# ff c,  h# ff c,  h# ff c,  h# ff c,
create unknown-ip-addr   h# 00 c,  h# 00 c,  h# 00 c,  h# 00 c,

: ip=  ( ip-addr1  ip-addr2 -- flag  )   /i comp  0=  ;

: multicast?  ( adr-buf -- flag )  c@  h# f0 and  h# e0 =  ;
: unknown-ip-addr?   ( adr-buf -- flag )  unknown-ip-addr  ip=  ;
: known?  ( adr-buf -- flag )  unknown-ip-addr? 0=  ;

\ Offsets 0,1,2 into this array yield default netmasks for classes C,B,A
create default-netmasks d# 255 c, d# 255 c, d# 255 c,  0 c,  0 c,  0 c,

: default-netmask  ( -- 'netmask )
   default-netmasks                                    ( 'netmask-c )
   my-ip-addr known?  if                               ( 'netmask-c )
      my-ip-addr c@  h# 80 and  0=  if  2+ exit  then  ( 'netmask-c )
      my-ip-addr c@  h# 40 and  0=  if  1+ exit  then  ( 'netmask-c )
   then                                                ( 'netmask-c )
;

\ Matches either h# ffffffff or h# 0 or subnet-specific broadcast addr
: broadcast-ip-addr?   ( adr-buf -- flag )  
   dup  broadcast-ip-addr ip=     ( adr-buf flag )
   over def-broadcast-ip  ip= or  ( adr-buf flag )
   swap unknown-ip-addr?  or      ( flag )
;

: netmask  ( -- 'ip )
   subnetmask unknown-ip-addr?  if  default-netmask  else  subnetmask  then
;
[ifndef] c@+
: c@+  ( adr -- adr' b )  dup 1+  swap c@  ;
[then]
: ip-prefix=?  ( ip1 ip2 -- flag )
   netmask   /i  0  do                        ( ip1 ip2 nm )
      rot c@+ >r                              ( ip2 nm ip1' r: b1 )
      rot c@+ >r                              ( nm ip1' ip2' r: b1 b2 )
      rot c@+                                 ( ip1' ip2' nm' bn r: b1 b2 )
      dup r> and  swap r> and                 ( ip1 ip2 nm b2' b1' )
      <>  if  3drop false unloop exit  then   ( ip1 ip2 nm )
   loop                                       ( ip1 ip2 nm )
   3drop true
;

/i buffer: router-ip-addr
: use-router?  ( -- flag )  router-ip-addr known?  ;

/i buffer: server-ip-addr
: use-server?  ( -- flag )  server-ip-addr known?  ;


: dec-byte  ( n -- )  u#s  ascii . hold  drop  ;
: (.ipaddr)  ( buf -- )
   push-decimal                                                   ( buf )
   <#  dup /i + 1-  do  i c@ dec-byte  -1 +loop  0 u#>  1 /string ( adr len )
   pop-base
   type space
;
: .ipaddr  ( buf -- )
   dup unknown-ip-addr?    if  drop ." none"      exit  then      ( buf )
   dup broadcast-ip-addr?  if  drop ." broadcast" exit  then      ( buf )
   (.ipaddr)
;
partial-headers
: indent  ( -- )  bootnet-debug  if  ."     "  then  ;
headerless
: .my-ip-addr   ( -- )  ."  My IP: "  my-ip-addr   .ipaddr  ; 
: .his-ip-addr  ( -- )  ."  His IP: " his-ip-addr  .ipaddr  ; 

0 instance value last-ip-packet

headers
: set-dest-ip  ( buf -- )
   dup his-ip-addr ip=  if
      drop
   else
      his-ip-addr copy-ip-addr
      unlock-link-addr
   then
;

: lock-ip-address  ( -- )
   the-struct >r  last-ip-packet set-struct
   \ Don't change his-ip-addr for booting over gateway
   use-router?  if   \ booting over a gateway.  
      bootnet-debug  if  indent ." Using router"  cr  then
   else
      \ In case of direct booting, i.e. booting over specified server
      \ don't change his addresses
      use-server? 0=  if  ip-source-addr set-dest-ip  then
      lock-link-addr
   then
   bootnet-debug  if  indent .his-link-addr .his-ip-addr  then
   r> set-struct
;
: unlock-ip-address  ( -- )
   unknown-ip-addr set-dest-ip
   unknown-ip-addr server-ip-addr copy-ip-addr
;
headerless

\ This is a hook for handling IP packets addressed to us that are
\ of a different type than the expected one.  This could be used
\ to handle "behind the scenes" things like ICMP if necessary.
defer handle-ip  ( adr len protocol -- )
defer handle-other-ip  ( adr len -- )
headers
: (handle-ip)  ( adr len protocol -- )
   bootnet-debug  if
      dup ." (Discarding IP packet of protocol " u. ." )" cr
   then
   3drop
;
' (handle-ip) is handle-ip

: (handle-other-ip)  ( adr len -- )
   bootnet-debug  if
      ." (Discarding IP packet because of IP address mismatch)" cr
   then
   2drop
;
' (handle-other-ip) is handle-other-ip
headerless

: ip-payload  ( len -- adr' len' )
   drop  ip-length xw@  ip-version c@ h# f and /l*  payload
;

: ip-addr-match?  ( -- flag )
   \ If we know the server's IP address (e.g. the user specified one, or
   \ we chose one from a RARP or BOOTP reply, or we locked onto one that
   \ responded to a TFTP broadcast), then we silently discard IP packets
   \ from other hosts.
   his-ip-addr broadcast-ip-addr?  0=  if
      his-ip-addr ip-source-addr ip=  0=  if  false exit  then
   then

   \ Accept IP broadcast packets
   ip-dest-addr broadcast-ip-addr?  if  true exit  then

   \ If we don't know our own IP address yet, we accept every IP packet
   my-ip-addr unknown-ip-addr?  if  true exit  then

   \ Otherwise, we know our IP address, so we filter out packets addressed
   \ to other destinations.
   my-ip-addr ip-dest-addr ip=
;

: allocate-ip  ( payload-len -- payload-adr )
   /ip-header +  allocate-ethernet  /ip-header +
;
: free-ip  ( payload-adr payload-len -- )
   /ip-header negate /string  free-ethernet
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
