\ See license at end of file
purpose:  Internet Control Message Protocol version 6 (ICMPv6) echo message handlers

: exchange-byte  ( adr1 adr2 -- )
   over c@  over c@    ( adr1 adr2 byte1 byte2 )
   swap rot            ( adr1 byte2 byte1 adr2 )
   c!                  ( adr1 byte2 )
   swap c!             ( )
;
: exchange-bytes  ( adr1 adr2 len -- )
   0  ?do  over i +  over i +  exchange-byte  loop  2drop
;
: exchange-mac  ( adr len -- )
   drop dup /e + /e exchange-bytes
;
: exchange-ipsv6  ( adr len -- )  drop 8 + dup /ipv6 + /ipv6  exchange-bytes  ;
: change-typev6  ( adr len -- )  drop d# 129 swap xc!  ;

: recompute-icmpv6-checksum  ( icmp-adr,len ip-adr,len -- )
   2swap dup 1 and  if            ( ip-adr,len icmp-adr,len )
       2dup +  0 swap c!  1+      ( ip-adr,len icmp-adr,len' )
   then                           ( ip-adr,len icmp-adr,len' )
   2swap drop 8 + dup /ipv6 +     ( icmp-adr,len ipv6-1 ipv6-2 )
   compute-icmpv6-checksum        ( )
;

: handle-echo-req  ( icmp-adr,len -- )
   \ XXX For now, support simplistic IPv6 header + ICMPv6 echo packet.
   2dup /ipv6-header  negate /string    ( icmp-adr,len ip-adr,len )
   2dup /ether-header negate /string    ( icmp-adr,len ip-adr,len en-adr,len )
   bootnet-debug  if
      ." Echo request from: " over /e + .enaddr cr
   then
   2dup exchange-mac -drot              ( en-adr,len icmp-adr,len ip-adr,len )
   2dup exchange-ipsv6                  ( en-adr,len icmp-adr,len ip-adr,len )
   2over change-typev6                  ( en-adr,len icmp-adr,len ip-adr,len )
   recompute-icmpv6-checksum            ( en-adr,len )
   tuck " write" $call-parent           ( len actual )
   <>  if  ." Network transmit error" cr  then
;

: handle-echo-reply  ( adr len -- )  2drop  ;

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


