\ See license at end of file
purpose: Domain name resolver

headerless
\ struct ( dns header )
\   /w field >id	\ 0 - Number to match questions with answers
\   /w field >dns-flags	\ 2 - q/a:8000 opcode:780 aa:40 tc:20 rd:10 ra:8 rc:f
\   /w field >qdcount	\ 4 - number of following questions
\   /w field >anscount	\ 6 - number of following answer RRs
\   /w field >nscount	\ 8 - number of following name server RRs
\   /w field >arccount	\ a - number of following additional RRs
\ constant /dns-header

\ DNS question format:  QNAME-variable_length, QTYPE(/w), QCLASS(/w)
\ QTYPE value for "A" (host name) is 1
\ QCLASS value for "IN" (Internet) is 1

d# 1022 value fw-port#

\ Encode/decode various DNS data types
: +dnsw  ( w -- )  wbsplit +xb +xb  ;
: -dnsw  ( -- w )  -xb -xb swap bwjoin  ;
: -dnsl  ( -- l )  -dnsw -dnsw swap wljoin  ;

\ A label is a dot-less component of a dotted name.  In DNS packets,
\ a label is represented as a length byte followed by the bytes of the string.
: +dns-label  ( adr len -- )  dup +xb  bounds  ?do  i c@ +xb  loop  ;

\ A name is a full domain name consisting of one or more labels sepearate
\ by dots.  In DNS packets, the dots are not included.
: +dns-name  ( adr len -- )
   begin  dup  while
      [char] . left-parse-string
      +dns-label
   repeat
   2drop
   0 +xb
;
: -dnsbytes  ( len -- adr len )
   dup x$  over >r         ( len len adr rem-len r: adr )
   rot /string  to x$      ( len r: adr )
   r> swap                 ( adr len )
;

: +np  ( adr len byte -- )  >r 2dup +  r> swap c!  1+  ;

defer -dns-tail		\ Forward reference for mutual recursion

0 instance value dns-header	\ Pointer to beginning of DNS header

\ Handle a compressed name tail, which is represented by a 2-byte
\ offset from the beginning of the DNS header to the beginning of a
\ previous uncompressed copy of the name tail.
: do-ptr  ( adr len ptr-offset -- adr len' )
   h# c0 invert and  -xb swap bwjoin  dns-header + d# 255  ( adr len )
   x$ 2>r  to x$
   -dns-tail
   2r> to x$
;

\ Handle the next name component, which is either:
\ a) The end of the name, represented by a 0 byte
\ b) A label, represented by a length byte (0-31) followed by the string
\ c) A pointer, represented by pair of bytes "11oooooo oooooooo", where
\    oooooo oooooooo is a 14-bit offset (see do-ptr)
: -component  ( adr len -- adr len' end? )
   -xb  ?dup  0=  if  true exit  then   
   dup  h# c0 and  case
      h# c0  of  do-ptr true  endof
      h# 00  of  -dnsbytes  bounds  ?do  i c@ +np  loop false  endof
      \ the 80 and 40 cases are reserved
      ( default )  ." Unknown DNS label code" cr  true  swap
   endcase
;

\ Copy the tail of a DNS name from the DNS packet to the buffer adr,len
: (-dns-tail)  ( adr len -- adr len' )
   -component  if  exit  then
   begin  [char] . +np  -component  until
;
' (-dns-tail) to -dns-tail

\ Extract a domain name from the DNS packet into a local buffer
d# 256 buffer: dns-name-buf
: -dns-name  ( -- adr len )  dns-name-buf 0  -dns-tail  ;

\ Add the host name to the packet and tack on the domain name
\ if it's not already there
: +dns-host  ( adr len -- )
   [char] . split-string                ( head$ tail$ )
   dup  if   \ Already fully-qualified  ( head$ tail$ )  
      nip + +dns-name                   ( )
   else      \ No domain name           ( head$ tail$ )
      2drop +dns-label                  ( )
      domain-name +dns-name             ( )
   then                                 ( )
;

d# 512 constant /dns-query
d# 53 constant dns-port#
0 instance value dns-xid

\ Send a DNS question asking for the IP address for the indicated host
: send-dns-query  ( hostname$ -- )
   /dns-query allocate-udp >r
   r@ start-encode
   next-xid lwsplit drop  to dns-xid   \ DNS transaction IDs are 16 bits
   \ Flags=100 means standard query, recursion desired (100)
   \        ID       flags    #questions  #answers  #namesrvrs  #additional
   dns-xid +dnsw  h# 100 +dnsw  1 +dnsw     0 +dnsw   0 +dnsw     0 +dnsw
   +dns-host
   1 +dnsw  1 +dnsw
   x$  fw-port# dns-port# send-udp-packet
   r> /dns-query free-udp
;
defer handle-dns-call  ' noop is handle-dns-call

: unexpected-xid  ( -- )
   bootnet-debug  if
      ." (Discarding DNS reply with mismatched transaction ID)" cr
   then
;

\ Receive a DNS reply, filtering out stuff that's not for us
: receive-dns-reply  ( xid his-port# my-port# -- error? )
   begin
      begin
         \ Filter out other destination ports
\         dup  receive-udp-packet  if    ( xid his mine )  \ Timeout
         dup  receive  if               ( xid his mine )  \ Timeout
            ." Timeout waiting for DNS reply"  cr
            3drop true exit
         then                           ( xid his mine adr len actual-port# )
      \ Filter out other source ports
      4 pick <>  while                  ( xid his mine adr len )
         2drop                          ( xid his mine )
      repeat                            ( xid his mine adr len )

      over to dns-header                ( xid his mine )
      start-decode                      ( xid his mine )

      \ Filter out other transaction IDs
      2 pick  -dnsw  <>  if             ( xid his mine )
         unexpected-xid false           ( xid his mine flag )
      else                              ( xid his mine )
         \ Filter out DNS calls
         -dnsw  h# 8000 and  0=  if     ( xid his mine )
            handle-dns-call  false      ( xid his mine false )
         else                           ( xid his mine )
            true                        ( xid his mine true )
         then                           ( xid his mine done? )
      then                              ( xid his mine done? )
   until                                ( xid his mine )
   3drop false                          ( false )
;

\ Decode/extract a DNS question section from the DNS packet
: -dns-question  ( -- name$ type class )  -dns-name -dnsw -dnsw  ;

\ Discard TTL
: -data  ( -- )  -dnsw  -dnsbytes 2drop  ;
: parse-answer  ( -- false | 'ip true )
   -dns-name  2drop

   -dnsw  -dnsw  wljoin       ( class.type )
   -dnsl drop                 ( class.type )   \ Discard TTL
   h# 1.0001 =  if            ( )
      -dnsw drop	\ Discard RDLENGTH (it better be 4!)
      x$ drop true            ( 'ip true )
   else                       ( )
      -dnsw                   ( datalen )
      -dnsbytes 2drop  false  ( false )
   then
;

\ Decode the reply to a DNS "get IP address for host name" query.
: get-host-addr  ( -- 'ip )
   \ Decoder is pointing at the QDCOUNT field

   -dnsw -dnsw                                  ( #questions #answers )
   -dnsw drop  -dnsw drop  \ Discard NSCOUNT and ARCOUNT

   \ Discard echoed questions
   swap 0  ?do  -dns-question 2drop 2drop  loop            ( #answers )

   0 ?do  parse-answer  if  unloop exit  then  loop        ( )
   4 throw
;

headers
\ Return in the buffer 'ip the IP address address for named host.
\ The host name can be either a simple name (e.g. "pi") or a
\ fully-qualified domain name (e.g. "pi.firmworks.com").
: try-resolve  ( hostname$ -- 'ip )
   name-server-ip set-dest-ip                    ( hostname$ )
   d# 2000 set-timeout                           ( hostname$ )
   send-dns-query                                ( )
   dns-xid dns-port# fw-port# receive-dns-reply  ( error? )
   1 and throw                                   ( )
   get-host-addr                                 ( answer-ip )
;
: (resolve)  ( hostname$ -- )
   bootnet-debug  if                             ( hostname$ )
      ." Using DNS to find the IP address of "   ( hostname$ )
      2dup type cr                               ( hostname$ )
   then                                          ( hostname$ )

   d# 20 0  do		\ Try 20 times at 2 seconds per try
      2dup ['] try-resolve catch  ?dup  if       ( hostname$ x x err )
         nip nip                                    ( hostname$ err )
         1 <>  if                                   ( hostname$ )
            bootnet-debug  if                       ( hostname$ )
               ." Unknown hostname: " 2dup type cr  ( hostname )
            then                                    ( hostname$ )
            true abort" Unknown hostname"
         then                                       ( hostname$ )
      else                                       ( hostname$ 'ip )
         bootnet-debug  if                       ( hostname$ 'ip )
            ." Got IP address "  dup .ipaddr cr  ( hostname$ 'ip )
         then                                    ( hostname$ 'ip )

         nip nip                                 ( 'ip )
         unloop exit
      then                                       ( hostname$ )
   loop                                          ( hostname$ )

   bootnet-debug  if  ." No answer to DNS request" cr  then    ( hostname$ )
   true abort" DNS: No answer"
;
\ : resolve  ( 'ip hostname$ -- )  (resolve) swap copy-ip-addr  ;

headerless
: ?bad-ip  ( flag -- )  abort" Bad host name or address"  ;
4 buffer: ip-buf
: $>ip  ( adr len -- 'ip )
   push-decimal
   ip-buf 4  bounds  do
      [char] . left-parse-string  $number ?bad-ip
      dup  d# 256 >=  ?bad-ip
      i c!
   loop
   pop-base
   2drop
   ip-buf
;

headers
: $set-host  ( hostname$ -- )
   dup 0= ?bad-ip
   over c@  [char] 0 [char] 9 between  if  $>ip  else  (resolve)  then
   set-dest-ip
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
