\ See license at end of file
purpose: Trivial File Transfer Protocol (TFTP) implementation

\ Trivial File Transfer Protocol

decimal

headerless

1 constant rrq-pkt
2 constant wrq-pkt
3 constant data-pkt
4 constant ack-pkt
5 constant err-pkt


struct ( tftp packet )
   2 sfield opcode
   0 sfield block#
   0 sfield filename
   2 sfield errorcode
   0 sfield errmsg
 512 sfield data
constant /tftp-packet

instance variable sid
instance variable did
instance variable this-block
instance variable #retries
false instance value first-try?

0 instance value tftp-packet		\ Buffer address
instance variable #packet

: too-many-tries?  ( -- flag )	\ flag true if too many retries
   bootnet-debug  if
      #retries @  3 and  3 =  if  ." #retries = " #retries @ .d cr  then
   then
   #retries @  tftp-retries u>=
;

\ Unlock from the server so we can capture another one
: .merror  ( tftp-adr,len -- tftp-adr,len )
   \ Unfortunately, we cannot give good error information in the usual
   \ case where use-server? is false (meaning that we aren't sure which
   \ server to use).  If use-server? is false and the first server we try
   \ (i.e. the one that responded to the RARP or BOOTP request) doesn't
   \ have the file, we then try to broadcast the request.  We mustn't
   \ display the error message from the first server because that would
   \ cause spurious complaints in the case where the subsequent broadcast
   \ TFTP operation will succeed.  However, if the subsequent broadcast
   \ TFTP attempt fails, we won't get an error response because TFTP
   \ servers typically return error responses only for unicast requests.
   use-server?  bootnet-debug or  if           ( tftp-adr,len )
      collect(
         ." TFTP error: " errmsg cscount       ( tftp-adr,len msg-adr,len )
         \ Some TFTP implementations neglect to null-terminate the message.
         2 pick 4 - min  type  cr
         [ifdef] .dhcp-server .dhcp-server  [then]
         ." TFTP Server: "  server-ip-addr .ipaddr   cr
         ." Filename: "  tftp-packet set-struct  filename cscount type  cr
      )collect
      use-server?  if  $abort  else  type  then
   then
   d# 69 did !
;

: $cstrput  ( from-adr,len to-adr -- end-adr )
   over >r  place-cstr  r> + 1+
;

: setup-request  ( filename$  rrq-pkt/wrq-pkt -- )
   0 this-block !
   tftp-packet set-struct
   1 sid +!
   d# 69 did !		    ( filename$ rrq-pkt/wrq-pkt )
   opcode xw!               ( filename$ )
   filename $cstrput        ( mode-adr )
   " octet"  rot $cstrput   ( end-adr )
   tftp-packet  -  #packet !
;

: setup-read-request  ( filename$ -- )
   rrq-pkt setup-request
   1 this-block +!
;

: setup-write-request  ( filename$ -- )
   wrq-pkt setup-request
;

: setup-ack-packet  ( -- )
   tftp-packet set-struct
   ack-pkt opcode xw!
   this-block @  block#  xw!
   4 #packet !
   1 this-block +!
;

: send-packet  ( tftp-adr tftp-len -- )
   ( tftp-adr tftp-len )  sid @  did @  send-udp-packet
;

0 instance value error-packet		\ Buffer address

: send-error-packet  ( src-port -- )
   /tftp-packet allocate-udp is error-packet
   did @ >r
   ( src-port ) did !      \ set the udp-source-port to the port indicated
			   \ in the received error packet.
   error-packet  set-struct
   err-pkt opcode xw!
   5 ( Unknown transfer ID )  errorcode xw!
   " Unknown source address" errmsg $cstrput  ( end-address )
   error-packet  tuck  -     ( packet-adr len )
   send-packet
   r>  did !		\ restore the previous did
   error-packet  /tftp-packet free-udp
;

\ Check source port against destination id.
\ If it mismatches, error unless did is currently 69
: bad-src-port?  ( src-port -- error )  \ assumes the-struct is UDP packet
   dup  did @  <>  if                                  ( src-port )
      did @  d# 69 =  if    \ Lock on to his port      ( src-port )
         did !                                         ( )
         bootnet-debug  if  ." Locking onto TFTP server" cr  then
         lock-udp-address   \ Lock onto his addresses  ( )
      else                                             ( src-port )
         send-error-packet                             ( )
         true exit                                     ( true )
      then                                             ( )
   else                                                ( src-port )
      drop                                             ( )
   then                                                ( )
   false
;

\ Check block number.  Assumes the-struct is TFTP packet.
: bad-block#?  ( -- error? )  block# xw@  this-block @ <>  ;

: send-current-packet  ( -- )  tftp-packet  #packet @  send-packet  ;

defer handle-tftp
headers
: (handle-tftp)  ( tftp-adr len -- )
   bootnet-debug  if
      ." Bad TFTP source port; sending TFTP error packet" cr
   then
   2drop
;
' (handle-tftp) is handle-tftp
headerless

: receive-tftp-packet  ( -- true | tftp-packet-adr tftp-len false )
   begin
      sid @  receive-udp-packet  if  true exit  then ( tftp-adr,len src-port )
      2 pick set-struct                              ( tftp-adr,len src-port )
      bad-src-port?                                  ( tftp-adr,len flag )
   while                                             ( tftp-adr,len )
      \ Shut down lingering TFTP server processes from our old attempts
      handle-tftp                                    ( )
   repeat                                            ( tftp-adr,len )
   false
;

: receive-data-packet  ( -- true | data-adr data-len false )
   update-timeout

   \ We don't retry at this level because all possible errors here
   \ cause a resend of the request packet.

   receive-tftp-packet  if  true exit  then  ( tftp-adr tftp-len )

   \ Check packet type
   opcode xw@ err-pkt  =   if  .merror 2drop true exit  then
   opcode xw@ data-pkt <>  if  ." Got a non-data packet"  2drop true exit  then
   bad-block#?  if  2drop true exit  then    ( tftp-adr tftp-len )

   false is first-try?                       ( tftp-adr tftp-len )
   4 /string  false                          ( data-adr,len false )
   compute-srtt                              ( data-adr,len false )
;

: ?try-broadcast  ( -- )
   first-try?  if
      bootnet-debug  if
         ." Trying a different TFTP server by broadcasting" cr
      then
      clear-his-address
      \ Relock the destination port number
      d# 69 did !
      \ Give the server time to come back up. Delay
      \ re-broadcasting to avoid network congestion.
      #retries @  if  5000 ms  then
   else
      bootnet-debug  if  ." TFTP timeout - retrying" cr  then
   then
;

: .receive-failed ( -- )  ." Receive failed" cr  ;

: get-data-packet  ( adr -- adr' more? )
   #retries off
   begin
      opcode xw@ err-pkt <> if   \ if this is an error packet, do not resend
				 \ it.  The error packet had been sent out
				 \ in receive-tftp-packet already.
         send-current-packet 		( adr )
      then
      receive-data-packet 		( adr [ data-adr data-len ] flag )
   while                                ( adr )
      ?try-broadcast                    ( adr )
      1 #retries +!
      too-many-tries?  if  .receive-failed  false exit  then
   repeat                               ( adr data-adr data-len )

   \ Copy data from packet to our buffer at addr
   >r over r@ move  ( adr )

   r@ +           ( adr' )
   r> d# 512 =    ( adr' more? )
;

: tftp-init  ( -- )
   true is first-try?
   /tftp-packet allocate-udp is tftp-packet

   \ Use user port numbers to avoid reserved system ports
   get-msecs  h# 0ffff and  d# 2048 or  sid !  \ "random" number
;
: tftp-close  ( -- )  tftp-packet /tftp-packet free-udp  ;

headers
: tftpread  ( adr filename$ -- size )
   bootnet-debug  if  ." TFTP protocol: Reading file: " 2dup type cr  then
   tftp-init            ( adr filename$ )
   setup-read-request   ( adr )
   dup                  ( adr adr )
   begin                ( adr adr )
      get-data-packet   ( adr adr' more? )
   while                ( adr adr' )
      show-progress setup-ack-packet
   repeat               ( adr adr' )
   \ Send the final acknowledge.  Don't send if receive error.
   too-many-tries? 0= if
      setup-ack-packet
      send-current-packet
   then
   swap -
   \ set ip addresses, for some proms ( client,server,router)
   \ By default, setup-ip-attr is a noop.
   setup-ip-attr
   too-many-tries? tftp-close abort" tftp failed"
;

headerless

\ previous definitions

\ *** New routines for tftpwrite ***

: receive-ack-packet  ( -- true | ack-packet-adr ack-len false )
   receive-tftp-packet  if  true exit  then   ( tftp-adr,len )

   \ Check packet type
   opcode xw@ err-pkt  =   if  .merror 2drop true exit  then
   opcode xw@ ack-pkt  <>  if  ." Got a non-ack packet"  2drop true exit  then
   bad-block#?  if  2drop true exit  then     ( tftp-adr,len )
   4 /string  false                           ( ack-adr,len false )
;

: get-ack-packet  ( -- ack-received? )
   #retries off
   begin
      send-current-packet
      receive-ack-packet   ( [ ack-packet-adr ack-len ] flag )
   while
      1 #retries +!

\ XXX we need to be able to retry the whole transaction at a higher
\ level, so we should exit more gracefully than we do here.

      too-many-tries?  if  .receive-failed  false exit  then
   repeat   2drop true
;

: setup-data-packet  ( adr sizeleft -- adr' sizeleft' done? )
   dup 0<  if true exit then
   tftp-packet set-struct
   data-pkt opcode xw!
   1 this-block +!
   this-block @ block# xw!	( adr sizeleft )
   2dup  d# 512 min		( adr sizeleft adr size<=512 )
   dup  4 + #packet !
   data swap move
   d# 512 -   \ decrease size remaining
   swap d# 512 + swap   \ adjust addr for remaining data
   false
;

\ also forth definitions

headers

: tftpwrite  ( adr size filename$ -- )
   tftp-init             ( adr size filename$ )
   setup-write-request   ( adr size )
   begin
      get-ack-packet if
         setup-data-packet  ( adr' sizeleft' done? )
      else true			\ error exit from loop
      then
   until  2drop
   tftp-close
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
