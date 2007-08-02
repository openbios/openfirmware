\ See license at end of file
purpose: Ping (ICMP echo) and ping daemon (ICMP echo server)

d# 58 constant ICMPV6_TYPE

[ifndef] ping
0 value ping-ih
: open-net  ( pathname$ -- )
   dup 0=  if  2drop " net"  then     ( pathname$' )
   open-dev to ping-ih
   ping-ih 0= abort" Can't open network device"
;
: close-net  ( -- )  ping-ih close-dev  ;
: $call-net  ( ? name$ -- ? )  ping-ih $call-method  ;
[then]

\ XXX There may be additional headers.
d# 40 constant /ipv6-header

[ifndef] ping
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
[then]

: handle-requestsv6  ( -- )
   ." Type any key to quit" cr
   begin
      key?  if  key drop exit  then
      ICMPV6_TYPE " receive-ip-packet" $call-net 0=  if  2drop  then
   again
;

: $pingd6  ( pathname$ -- )
   open-net  handle-requestsv6  close-net
;

: pingd6  ( ["device"] -- )
   parse-word ?dup 0=  if  drop  " net//obp-tftp:last"  then
   $pingd6  
;

[ifndef] ping
d# 64 value ping-size
d# 512 value /ping-max
d# 10 value ping-seconds
d# 1 value #pings
d# 0 value icmp-sequence#
d# 1000 value ping-gap

0 value ping-packet
0 value ping-sent-time
[then]

: send-pingv6  ( -- )
   ping-packet to the-struct
   get-msecs to ping-sent-time
   
   ping-seconds d# 1000 * " set-timeout" $call-net

   d# 128 icmp-type c!
   0 icmp-code c!
   0 icmp-id   be-w!
   icmp-sequence# dup icmp-seq be-w!  1+ to icmp-sequence#
   icmp-data  ping-size 0  do  i  icmp-data i + c!  loop  drop		( )

   the-struct  ping-size  " send-icmpv6-packet" $call-net
;

[ifndef] ping
: .ping-data  ( -- )
   get-msecs ping-sent-time -   ( ms )
   ?dup  if  .d  else  ." <1 "  then  ." ms" cr
;
[then]

: reply-okayv6?  ( adr len -- flag )
   swap set-struct                                  ( len )

   \ Ignore ICMP packets other then echo replies
   icmp-type c@ d# 129 <> if  drop false exit  then ( len )

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
: ping-replyv6?  ( -- okay? )
   begin
      ICMPV6_TYPE " receive-ip-packet" $call-net  if  false exit  then   ( adr len )
      reply-okayv6?
   until
   true
;

: 1pingv6  ( -- )
   send-pingv6
   ping-replyv6?  if  .ping-data  else  ." Timeout" cr  then
;
: try-pingsv6  ( -- )
   1pingv6
   #pings  1  ?do
      ping-gap ms
      1pingv6
      key?  if  key drop leave  then
   loop
;

: $ping6  ( ip$ -- )
   " net//obp-tftp:last" open-net  " $set-host" $call-net
   /ping-max " allocate-ipv6" $call-net to ping-packet
   try-pingsv6
   ping-packet /ping-max " free-ipv6" $call-net
   close-net
;

: ping6  ( "host" -- )  safe-parse-word $ping6  ;

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
