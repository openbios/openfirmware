\ See license at end of file
purpose: Ping (ICMP echo) and ping daemon (ICMP echo server)

: (ip-checksum) ( accumulator addr count -- checksum )
   2dup 2>r  bounds  do  i  be-w@ +  /w  +loop  ( sum r: adr,len )
   \ Subtract the extra byte at the end  
   2r> dup  1 and  if  + c@  -  else  2drop  then
;

: ip-checksum  ( accumulator addr count -- checksum )
   (ip-checksum)                       ( checksum' )
   lwsplit + lwsplit +                 ( checksum" )
   invert  h# 0.ffff and               ( checksum )
   \ Return ffff if the checksum is 0
\  ?dup 0=  if  h# 0.ffff  then        ( checksum )
;

0 value ping-ih
: open-net  ( pathname$ -- )
   " net//obp-tftp:last" open-dev to ping-ih
   ping-ih 0= abort" Can't open network device"
;
: close-net  ( -- )  ping-ih close-dev  ;
: $call-net  ( ? name$ -- ? )  ping-ih $call-method  ;

0 value /packet
d# 1600 constant /packet-max
/packet-max buffer: packet

: get-packet?  ( -- packet? )
   h# 800 " receive-ethernet-packet" $call-net  if  false exit  then   ( adr len )
   /packet-max min  to /packet     ( adr )
   packet /packet move             ( )
   ." ."  true                     ( packet )
;
d# 14 constant /ether-header
0 value ip-offset

: ip-header  ( -- adr )  packet ip-offset +  ;

: ip?  ( -- flag )  ip-header c@  h# 45 =   ;

: link-level-ok?  ( -- flag )
   packet c@  h# 45 =  if
      \ This clause handles the case where the network device is feeding us
      \ unencapsulated IP packets.  45 is the length/version byte for IPv4.
      \ If the first byte of an ethernet header is 45 is a v
      0 to ip-offset
      true exit
   else
      packet d# 12 + be-w@  h# 800 =  if
         /ether-header to ip-offset
         true exit
      then
   then
   false
;

: >/ip-header  ( ip-header -- len )  c@  h# f and  /l*  ;
: ip-payload  ( -- adr len )
   ip-header  dup >/ip-header        ( ip-adr length )
   over +                            ( ip-adr payload-adr )
   swap dup 2+ be-w@ +               ( payload-adr payload-end )
   over -                            ( payload-adr payload-len )
;
: icmp?  ( -- flag )  ip-header 9 +  c@  1 =  ;
: echo?  ( -- flag )  ip-payload drop c@ 8 =  ;
: icmp-echo?  ( -- flag )
   ip? if  icmp? if  echo? if  true exit  then then then
   false
;
: .ipb  ( adr -- adr' )  dup 1+ swap c@  (.) type   ;
: .ipaddr  ( addr-buff -- )
   push-decimal
   3 0  do  .ipb ." ."  loop  .ipb drop
   pop-base
;
: .ip  ( -- )
   ." My IP address is "
   ip-header d# 16 +  .ipaddr
;
: ping?  ( -- flag )
   \ First test the packet assuming that no Ethernet header is present
   icmp-echo? if  true exit  then

   \ Failing that, check for and skip the link level header
   link-level-ok? if  icmp-echo? if  true exit  then  then
   false
;

: exchange-byte  ( adr1 adr2 -- )
   over c@  over c@    ( adr1 adr2 byte1 byte2 )
   swap rot            ( adr1 byte2 byte1 adr2 )
   c!                  ( adr1 byte2 )
   swap c!             ( )
;
: exchange-bytes  ( adr1 adr2 len -- )
   0  ?do  over i +  over i +  exchange-byte  loop  2drop
;
: exchange-macs  ( -- )
   ip-offset /ether-header =  if
      packet packet 6 +  6  exchange-bytes
   then
;
: 'ip-src  ( -- adr )   ip-header  d# 12 +  ;
: 'ip-dst  ( -- adr )   ip-header  d# 16 +  ;

: exchange-ips  ( -- )  'ip-src  'ip-dst  4  exchange-bytes  ;
: change-type  ( -- )  0 ip-payload drop c!  ;
: recompute-ip-checksum  ( -- )
   0 ip-header d# 10 + be-w!	\ Zap IP checksum
   ip-header dup >/ip-header  ( adr len )
   0 -rot  ip-checksum  ip-header d# 10 + be-w!
;

0 instance value the-struct
: set-struct  ( adr -- )  to the-struct  ;
: sfield  ( offset size -- new-offset )
   create over , +
   does> @ the-struct +
;

struct  ( ICMP )
   /c sfield icmp-type
   /c sfield icmp-code
   /w sfield icmp-checksum
   /w sfield icmp-id
   /w sfield icmp-seq
    0 sfield icmp-data
constant /icmp-header

: compute-icmp-checksum  ( adr len -- )
   over set-struct             ( adr len' )
   0  icmp-checksum be-w!      ( adr len )  \ Zap ICMP checksum
   0 -rot  ip-checksum         ( sum )
   icmp-checksum be-w!         ( )
;
: recompute-icmp-checksum  ( -- )
   ip-payload  dup 1 and  if   ( adr len )
       2dup +  0 swap c!  1+   ( adr len' )
   then                        ( adr len' )
   compute-icmp-checksum       ( )
;

: send-packet  ( -- )
   packet /packet  'ip-dst  h# 800 " send-link-packet" $call-net
;

: echo-packet  ( -- )
   exchange-macs
   exchange-ips
   change-type
   recompute-ip-checksum
   recompute-icmp-checksum
   send-packet
;
: ?echo-packet  ( -- )
   ping?  if
      echo-packet
   then
;
: handle-requests  ( -- )
   ." Type any key to quit" cr
   begin
      get-packet?  if  ?echo-packet  then
   key? until
   key drop
;

: pingd  ( -- )
   open-net  handle-requests  close-net
;

d# 64 value ping-size
d# 512 value /ping-max
d# 10 value ping-seconds
d# 1 value #pings
d# 0 value icmp-sequence#
d# 1000 value ping-gap

0 value ping-packet
0 value ping-sent-time

: send-ping  ( -- )
   ping-packet to the-struct
   get-msecs to ping-sent-time
   
   ping-seconds d# 1000 * " set-timeout" $call-net

   8 icmp-type c!
   0 icmp-code c!
   0 icmp-id   be-w!
   icmp-sequence# dup icmp-seq be-w!  1+ to icmp-sequence#
   icmp-data  ping-size 0  do  i  icmp-data i + c!  loop  drop		( )

   the-struct  ping-size /icmp-header +  2dup  compute-icmp-checksum

   1 " send-ip-packet" $call-net	\ 1 is the ICMP protocol number
;
: .ping-data  ( -- )
   get-msecs ping-sent-time -   ( ms )
   ?dup  if  .d  else  ." <1 "  then  ." ms" cr
;

: reply-okay?  ( adr len -- flag )
   swap set-struct                                ( len )

   \ Ignore ICMP packets other then echo replies
   icmp-type c@  if  drop false exit  then         ( len )

   \ Verify the packet length
   /icmp-header ping-size +  2dup  <>  if           ( len exp )
      ." Wrong ping reply packet size - expected "  ( len exp )
      .d ." , got " .d cr                           ( )
   else                                             ( len exp )
      2drop                                         ( )
   then                                             ( )

   icmp-seq be-w@  icmp-sequence# 1-  2dup <>  if   ( rseq sseq )
      ." Sent sequence number " .d                  ( rseq )
      ." , received " .d cr                         ( )
   else                                             ( rseq sseq )
      2drop                                         ( )
   then                                             ( )
   true
;
: ping-reply?  ( -- okay? )
   begin
      1 " receive-ip-packet" $call-net  if  false exit  then   ( adr len )
      reply-okay?
   until
   true
;

: 1ping  ( -- )
   send-ping
   ping-reply?  if  .ping-data  else  ." Timeout" cr  then
;
: try-pings  ( -- )
   1ping
   #pings  1  ?do
      ping-gap ms
      1ping
      key?  if  key drop leave  then
   loop
;

: $ping  ( ip$ -- )
   open-net  " $set-host" $call-net
   /ping-max " allocate-ip" $call-net to ping-packet
   try-pings
   ping-packet /ping-max " free-ip" $call-net
   close-net
;

: ping  ( "host" -- )  safe-parse-word $ping  ;
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
