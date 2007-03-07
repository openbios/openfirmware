\ See license at end of file
purpose: Bootstrap Protocol (BOOTP) (RFC 951) + vendor extensions (RFC 1084)

decimal
headerless
struct ( bootp packet )
    1 sfield	bp-op		\ 00 packet type: 1 = request, 2 = reply
    1 sfield	bp-htype	\ 01 hardware addr type
    1 sfield	bp-hlen		\ 02 hardware addr length
    1 sfield	bp-hops		\ 03 gateway hops
    4 sfield	bp-xid		\ 04 transaction ID
    2 sfield	bp-secs		\ 08 seconds since boot began
    2 sfield	bp-unused	\ 0a now "flags" field; see RFC 1542
   /i sfield	bp-ciaddr	\ 0c client IP address
   /i sfield	bp-yiaddr	\ 10 'your' IP address
   /i sfield	bp-siaddr	\ 14 server IP address
   /i sfield	bp-giaddr	\ 18 gateway (BOOTP relay agent) IP address
d# 16 sfield	bp-chaddr	\ 1c client hardware address
d# 64 sfield	bp-sname	\ 2c server host name

d#  128 sfield	bp-file		\ 6c boot file name
    4 sfield	bp-vend-magic	\ ec vendor-specific area
dup constant /bootp-fixed
d# 60 sfield	bp-options	\ f0 vendor-specific area
constant /bootp

0 value /bootp-packet
0 instance value bootp-packet

0 value report-buffer  \ Can't use buffer: because DHCP changes the packet size

0 instance value bootp-len  \ Actual length of received bootp packet

instance variable start-time
instance variable xid

d#  32 instance buffer: server-name
partial-headers
d# 128 buffer: file-name-buf
headerless
d# 128 instance buffer: bootp-name-buf

headers
' file-name-buf     " tftp-file" chosen-string
headerless

d# 255 constant end-option

[ifndef] c@+
: c@+ ( adr -- adr+1 char )  dup ca1+ swap c@  ;
[then]

: elapsed-secs  ( -- #secs )  get-msecs start-time @  -  d# 1000 /  ;

\ RFC 1533 magic number 99.130.83.99
h# 63.82.53.63 constant 1533-magic

: not-1533-magic?  ( -- adr,len false | true )
   bp-vend-magic dup xl@ 1533-magic =  if
      la1+  bootp-len /bootp-fixed -  false
   else
      drop true
   then
;

: do-vendor  ( -- )
   not-1533-magic?  if  exit  then	 ( adr,len )
   over ca+  >r			( adr )  ( r: end )
   begin  dup r@ <=  while	( adr )  ( r: end )
      c@+   case

         end-option  of  r> 2drop exit  endof    \ End (255)

         0  of                 endof             \ Pad

         1  of                                   \ Netmask
               c@+
               over subnetmask copy-ip-addr
               ca+
            endof

         3  of                                   \ Router
               c@+
               over router-ip-addr copy-ip-addr
               ca+
            endof

         \ default - skip option
         drop c@+ ca+ 0	( adr' 0 )  ( r: end )

      endcase			( adr' )    ( r: end )
   repeat			( adr" )    ( r: end )
   r>  2drop
;

: set-cookie  ( -- )  " "(63 82 53 63)" bp-vend-magic swap move  ;

: prepare-bootp-packet  ( -- )
   bootp-packet set-struct
   bootp-packet  /bootp-packet  erase
   1 bp-op xc!          		\ BOOTREQUEST
   arp-address-type bp-htype xc!        \ Hardware address type
   /e bp-hlen xc!                       \ Hardware address length
   xid @  bp-xid xl!                    \ "Random" transaction ID
   unknown-ip-addr subnetmask copy-ip-addr
   unknown-ip-addr my-ip-addr copy-ip-addr

   \ bp-ciaddr should be 0.0.0.0 or a valid unicast address per RFC 1542
   \ This following clause can't execute in light of the preceding line
   \ that clears my-ip-addr.
   my-ip-addr broadcast-ip-addr?  0=  if
      my-ip-addr bp-ciaddr copy-ip-addr
   then

   my-en-addr bp-chaddr copy-en-addr
   server-name    count    bp-sname place-cstr drop
   file-name-buf  cscount  bp-file  place-cstr drop

   set-cookie
   end-option bp-options c!
;

: send-bootp-packet  ( size secs -- )
   bp-secs xw!                                         ( size )
   bootp-packet swap  d# 68  d# 67  send-udp-packet    ( )
;

defer handle-bootp  ( -- )
headers
: (handle-bootp)  ( -- )
   bootnet-debug  if
      ." (Discarding BOOTP packet with unexpected packet type or transaction id)"
      cr
      ."   Header: " 
      the-struct /bootp-fixed cdump cr
   then
;
' (handle-bootp) is handle-bootp
headerless

: get-bootp-reply  ( -- timeout? )
   begin  d# 68 receive-udp-packet  0=  while         ( adr,len src-port )
      drop   to bootp-len  set-struct                 ( )

      bp-xid xl@  xid @  =  if
         bp-op c@  2  =  if
            bp-chaddr  my-en-addr  en=  if  false exit  then
         then
      then
      handle-bootp
   repeat                                             ( )
   true
;
: allocate-bootp  ( size -- )
   allocate-udp is bootp-packet

   get-msecs start-time !

   \ Set "random" transaction ID and random number generator seed
   my-en-addr 2 + xl@  get-msecs  xor  dup  xid !  rn !
;
: free-bootp  ( size -- )  bootp-packet swap free-udp  ;

\ Sets my-ip-addr, his-ip-addr, bootp-name-buf, netmask, router-ip-addr, etc.
: extract-bootp-info  ( -- )
   bp-yiaddr  my-ip-addr      copy-ip-addr
   bp-siaddr  server-ip-addr  copy-ip-addr

   server-ip-addr set-dest-ip	\ Use the indicated server for TFTP later

   \ We do NOT copy (nor to we even pay attention to) the bp-giaddr field.
   \ RFC1542 specifies that said field is for the use of BOOTP relay agents,
   \ not clients.

   do-vendor

   \ Copy the filename as modified by the server back into the filename
   \ buffer, unless it is empty.  We have seen cases where a BOOTP or
   \ DHCP server has nulled out a file name that was supplied to it.
   bp-file cscount  dup  if  bootp-name-buf  place  else  2drop  then

   report-buffer  0=  if  /bootp-packet alloc-mem to report-buffer  then   
   the-struct report-buffer bootp-len move
;

-1 instance value bootp-retries

[ifndef] use-dhcp

h#  7ff constant 2seconds       \ About 2 seconds of milliseconds
h# 3fff constant 16seconds      \ About 16 seconds of milliseconds

instance variable rn-mask       \ Backoff mask

: first-interval  ( -- )  2seconds rn-mask !  ;
: random-interval  ( -- n )
   random  rn-mask @  and  2seconds  max   ( number )
   rn-mask @  16seconds  <  if  rn-mask @  2*  1 or  rn-mask !  then
;

0 instance value try#

: do-bootp  ( -- )
   /bootp to /bootp-packet

   /bootp-packet allocate-bootp

   first-interval
   0 to try#

   prepare-bootp-packet

   \ At this point, server-ip-addr will usually be 0.0.0.0, but it may
   \ have been overridden from the command line.  1275 committee members
   \ have reported that it is necessary to unicast BOOTP requests in some
   \ circumstances.  We don't do this for DHCP though, because DHCP asserts
   \ that the bp-siaddr field denotes the TFTP server, not the BOOTP server.
   server-ip-addr bp-siaddr copy-ip-addr

   begin
      /bootp-packet elapsed-secs send-bootp-packet
      random-interval set-timeout
      get-bootp-reply
   while
      try#  if	\ We always have to retry the first time!
         ." Retrying... Check bootp server and network setup." cr
      then
      try# 1+ to try#
      try# bootp-retries u>  abort" Too many BOOTP retries"
   repeat

   extract-bootp-info

   /bootp-packet free-bootp
;
[then]
headerless
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
