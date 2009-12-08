\ See license at end of file
purpose: Dynamic Host Configuration Protocol (DHCP) (RFC 1541)

[ifdef] notdef
dev /obp-tftp
[then]

partial-headers
defer .dhcp-msg  ( adr len -- )

: (.dhcp-msg)  ( adr len -- )  bootnet-debug  if  indent type cr  else  2drop  then  ;
' (.dhcp-msg) to .dhcp-msg

headerless
defer .discover-error
: (.discover-error)  " DHCP discover failed; restarting" .dhcp-msg  ;
' (.discover-error)  to .discover-error

defer .request-error
: (.request-error)  " DHCP request failed; retrying" .dhcp-msg  ;
' (.request-error)  to .request-error

d# 308 constant /options-field

/bootp  d# 60 -  /options-field +  constant /dhcp

\ Search for the DHCP option whose tag is "code#", returning its value if found
: find-option  ( code# -- false | adr len true )
   \ XXX handle options overload
   bp-options  begin                               ( code# adr )
      dup c@  dup 0<>  swap d# 255 <>  and         ( code# adr )
   while                                           ( code# adr )
      2dup c@ =  if  nip 1+ count true exit  then  ( code# adr )
      1+ count +                                   ( code# adr' )
   repeat                                          ( code# adr )
   2drop false
;

\ For NVT-ASCII data, which might or might not have trailing nulls
: -nulls  ( adr len -- adr len' )
   dup 0  ?do  2dup + 1- c@  0<> ?leave  1-  loop
;

\ True if the BOOTP vendor extensions area contains DHCP options
: dhcp-options?  ( -- flag )  bp-vend-magic  " "(63 82 53 63)"  comp 0=  ;

/options-field d# 64 + d# 128 +  constant /options-max
/options-max buffer: options

0 value next-option

\ Initialize the temporary options buffer in preparation for adding options
: start-options  ( -- )  options /options-max erase  0 to next-option  ;

\ Add a byte to the temporary options buffer
: option,  ( byte -- )
   next-option options + c!  next-option 1+ to next-option
;

\ Add to the temporary options buffer an option with code# as the tag and
\ the value from the memory range adr,len
: +option  ( adr len code# -- )
   \ 3 is 1 for the code#, 1 for the length byte, and 1 for an END option
   over 3 +  next-option +      ( adr len code# new#options )
   /options-max >=  abort" DHCP options buffer overflow"  ( adr len code# )
   option, dup option,  bounds  ?do  i c@ option,  loop   ( )
;

\ Copy the temporary options buffer to the outgoing packet
: copy-options  ( -- )
   end-option option,
   next-option  /options-field  >  abort" DHCP options overload not supported"
   set-cookie
   bp-options /options-field erase
   options bp-options  next-option  move
;

\ Return the DHCP message type
: dhcp-type  ( -- true | message-type false )
   dhcp-options?  0=  if  true exit  then
   \ Look for a DHCP message type option
   d# 53 find-option  if  drop c@  false  else  true  then
;

\ Add a "request parameters" option
\ : request-parameters  ( adr len -- )  d# 55 +option  ;

\ Display the "message" option from a DHCPNAK message
: .nak-message  ( -- )  d# 56 find-option  if  -nulls type cr  then  ;

: root-property  ( name$ -- true | value false )
   ['] root-node get-package-property
;

\ Add a "vendor class" option if there is an "architecture" property
\ in the root node
: set-vendor-class  ( -- )
   " architecture" root-property  if  exit  then   ( adr len )
   get-encoded-string  d# 60 +option	\ Vendor class identifier option
;

\ Add a "client identifier" option whose value is the MAC address
\ XXX we should probably use the root-node system-id property instead,
\ if its value differs from the mac-address value.
0 value client-id
: set-client-id  ( -- )
   " system-id" root-property  if  exit  then   ( adr len )

   dup 1+ dup >r alloc-mem  to client-id        ( adr len r: len' )
   tuck client-id 1+  swap  move                ( len )
   1  client-id  c!                             ( len )
   client-id swap 1+ d# 61 +option	\ Client identifier option
   client-id r> free-mem
;

0 value backoff    \ First set to d# 4000, then double up to d# 32,000

\ The spec recommends a 4 second initial timeout, but that appears to be
\ a bit short in some environments, especially considering that
\ a) The actual delay is randomized by +- 1 second.
\ b) Some DHCP servers, when dynamically allocating an IP address, first
\    test that IP address by issuing an ARP request and waiting a timeout
\    interval, prior to responding to the DHCPDISCOVER.
: init-backoff  ( -- )  ( d# 4000 ) d# 8000 to backoff  ;
: too-many?  ( -- flag )  backoff d# 64,000 >=  ;

\ The nominal retry delay interval starts at 4 seconds and doubles each
\ time, giving up after the retry following the 32 second delay.  The
\ actual delay is the nominal delay randomized by a uniformly-distributed
\ random number in the range +-1.023 seconds.
: next-backoff  ( -- #ms )
   random  dup  h# 3ff and  swap h# 400 and  if  negate  then
   backoff +              ( #ms )
   backoff 2* to backoff
;

: erase-ip-addr  ( adr -- )  /i erase  ;

\ This is similar to but not exactly the same as my-ip-addr
\ The differences have to do with DHCP protocol requirements
\ about when the BOOTP ciaddr field must be 0.
/i instance buffer: accepted-ip
/i instance buffer: offered-ip

: start-dhcp-packet  ( dhcptype$ -- )
   prepare-bootp-packet
   bp-yiaddr erase-ip-addr
   bp-siaddr erase-ip-addr
   bp-giaddr erase-ip-addr
   accepted-ip bp-ciaddr copy-ip-addr
   start-options
   ( adr len ) d# 53 +option      \ DHCPTYPE
   set-client-id
;
\ Options common to discover, inform, and request messages
: other-parameters  ( -- )
   set-vendor-class


   \ Parameter request list
   \ h# 01 -  1 Subnet mask
   \ h# 03 -  3 Router IP address
   \ h# 06 -  6 Name Server IP address
   \ h# 0c - 12 Client name
   \ h# 0f - 15 Domain name
   \ h# 11 - 17 Root path
   \ h# 1c - 28 Broadcast IP address
   \ h# 2b - 43 Vendor options
   \ h# 36 - 54 Server IP address
   " "(01 03 06 0c 0f 11 1c 2b 36)" d# 55 +option

   \ Later: Add requested IP address if we know it
   \ Later: Add requested IP lease time if we have a preference
   \ Later: Add maximum message size if we should need to
;
: use-ip-broadcast  ( -- )  broadcast-ip-addr set-dest-ip  ;

0 instance value dhcp-secs

: prepare-discover-packet  ( -- )
   \ Note: It is permissible to unicast this packet if a DHCP server's
   \ IP address is known; see clause 4.4.4
   use-ip-broadcast

   elapsed-secs to dhcp-secs
   " "(01)"  start-dhcp-packet	\ DHCPDISCOVER
   other-parameters
   copy-options
;

\ Common code for SELECTING, INIT-REBOOT, BOUND, RENEWING, and REBINDING
: start-request-packet  ( -- )
   \ Note: It is permissible to unicast this packet in either INIT or
   \ REBOOTING state if a DHCP server's IP address is known; see clause 4.4.4
   use-ip-broadcast

   " "(03)"  start-dhcp-packet	\ DHCPREQUEST
   other-parameters
;

: send-dhcp-packet  ( -- )
   /bootp-packet  dhcp-secs  send-bootp-packet
   next-backoff set-timeout
;

false instance value bootp-only?   \ Set to true if a BOOTP server replies

defer handle-dhcp
headers
: (handle-dhcp)  ( -- )
   bootnet-debug  if
      ." (Discarding DHCP packet of unexpected type)" cr
      ."   Packet: " the-struct /bootp cdump cr
   then
;
' (handle-dhcp) is handle-dhcp
headerless

: receive-dhcp-packet  ( accept-mask -- true | dhcp-type false )
   >r
   begin
      get-bootp-reply  if  r> drop  true  exit  then

      dhcp-type  if           \ Not a DHCP packet
         true to bootp-only?  \ This flag may be useful for a fallback to BOOTP
         r> drop  0 false exit
      else                    ( dhcp-type )
         1 over lshift  r@  and  if   \ We got one of the types we want
            r> drop  false exit       ( dhcp-type false )
         then                         ( dhcp-type )
         drop                         ( )  \ Silently discard other types
         handle-dhcp		      ( )
      then                            ( )
   again
;

defer handle-dhcp-nak

d# 256 buffer: 'root-path
d# 256 buffer: 'client-name
d# 256 buffer: 'vendor-options
headers
' 'client-name     " client-name"    chosen-string
' 'vendor-options  " vendor-options" chosen-string
' 'root-path       " root-path"      chosen-string
: domain-name  ( -- adr len )  'domain-name cscount  ;

/i buffer: dhcp-server-ip
: (handle-dhcp-nak)  ( -- )
   bootnet-debug  if
      indent ." (Discarding bogus DHCP NAK packet from server: "
      dhcp-server-ip .ipaddr ." )" cr
   then
;
' (handle-dhcp-nak) is handle-dhcp-nak

: init-dhcp  ( -- )
   0 'domain-name c!
   0 'root-path   c!
   0 'client-name c!
   0 'vendor-options c!
   0 file-name-buf c!
   unknown-ip-addr name-server-ip copy-ip-addr
   unknown-ip-addr dhcp-server-ip copy-ip-addr
   unknown-ip-addr ntp-server-ip  copy-ip-addr
;

also forth definitions
stand-init:  DHCP init
   init-dhcp
;
previous definitions

: .dhcp-server  ( -- )
   bootp-only?  0=  if
      ." DHCP server: " dhcp-server-ip .ipaddr cr
   then
;

headerless

: .offer  ( -- )
   bootnet-debug  if
      indent  ." Received offer of IP address " my-ip-addr .ipaddr
      ." from "
      bootp-only?  if
         ." BOOTP server " server-ip-addr
      else
         ." DHCP server " dhcp-server-ip
      then
      .ipaddr cr

      indent indent  ." Boot server IP: " server-ip-addr .ipaddr
      ."   Filename: " bootp-name-buf count type cr
      subnetmask known?  if
         indent indent  ." Netmask: "  subnetmask .ipaddr  cr
      then
      use-router?  if
         indent indent  ." BOOTP relay agent: " router-ip-addr .ipaddr cr
      then
   else
      ." got " my-ip-addr .ipaddr cr
   then
;

partial-headers
\ wanted? is the DHCP offer filter.  Many environments have multiple DHCP
\ servers, some giving incomplete information.  You can set wanted? to
\ require specific characteristics in the offer data.

\ A better approach would be to collect several offers within a time period
\ and choose the best among them, stopping early if a "perfect" offer arrives.

\ The default value of wanted? accepts the first DHCPOFFER that is received
defer wanted?  ( -- flag )  ' true to wanted?

\ This filter accepts offers that specify a router
: router?  ( -- flag )
   3 find-option  dup  if  nip nip  then
;

\ This filter accepts offers that specify a name server
: ns?  ( -- flag )
   6 find-option  dup  if  nip nip  then
;

: router+ns?  ( -- flag )  router? ns? and  ;

: adaptive-wanted?  ( -- flag )
   backoff  case
      d#  8000 of  router+ns? exit  endof
      d# 16000 of  router?    exit  endof
   endcase
   true
;
' adaptive-wanted? to wanted?		\ By default, we accept all DHCP offers

\ This filter rejects offers whose siaddr field is empty, (Microsoft's
\ DHCP server doesn't fill in siaddr), since we are hosed if we don't know
\ which server to use.

: (wanted?)  ( -- flag )
   \ If we already know the boot server, we needn't insist on one from DHCP
   use-server?  if  true exit  then
   bp-siaddr known?  dup  0=  if
      " The DHCP 'siaddr' field is empty" .dhcp-msg
   then
;
\ ' (wanted?) to wanted?


\ Another plausible criterion for choosing a particular offer might be:
\    If a vendor class identifier is supplied, reject offers that do
\    not return that identifier, instead waiting for an offer from a
\    server that explicitly recognizes the vendor class.

: choose-response  ( -- timeout? )
   begin
   \ Accept DHCPOFFER packets (4 = 1 LSHIFT 2; 2 is the DHCPOFFER type code)
      4 receive-dhcp-packet  if  true exit  then   ( dhcp-type=2 )
      drop  wanted?  if  false exit  then          ( )
      " Discarding unwanted DHCPOFFER" .dhcp-msg
   again
;
: do-discover  ( -- error? )
   accepted-ip erase-ip-addr
   prepare-discover-packet

   bootnet-debug  if
      indent  ." DHCP Discover: requesting an IP address for "
      my-en-addr .enaddr cr
   else
      ." DHCP "
   then

   init-backoff
   begin
      send-dhcp-packet
      \ Enter SELECTING state
      choose-response                  ( timeout? )
   while                               ( )
      bootnet-debug  if  " Timeout" .dhcp-msg  else  ." Retry "  then

      \ If too many retries, go to INIT state
      too-many?  if  true exit  then
   repeat

   extract-bootp-info

   \ A BOOTP reply essentially takes to directly to BOUND-DONE state
   bootp-only?  if  .offer  false exit  then

   d# 54 find-option  0= abort" Server identifier missing"  ( adr len )
   drop  dhcp-server-ip copy-ip-addr
   .offer

   \ get yiaddr from ack packet for use in subsequent request packet
   bp-yiaddr offered-ip copy-ip-addr

   false
;

headerless
create null-ip-addr  0 c, 0 c, 0 c, 0 c,

: ip-in-use?  ( -- error? )
   \ ARP to see if somebody else has the IP address we were assigned.
   \ use my-en-addr as sender's hardware address, and 0 as sender's IP
   \ address, per last paragraph of clause 4.4.1

   my-ip-addr broadcast-en-addr null-ip-addr my-en-addr 1  ARP_TYPE  ( params )
   send-arp/rarp-packet

   \ If we get a response within a short time, that indicates a conflict.
   d# 200 set-timeout
   begin  ARP_TYPE receive-ethernet-packet  0=  while   ( arp-adr,len )
      drop set-struct                                   ( )
      arp-tha my-ip-addr ip=  if		     \ Addressed to me
         arp-opcode xw@  2 =  if  true exit  then    \ ARP reply
      then
   repeat
   false
;

\ Broadcast an ARP reply, announcing our new IP address in order to clear
\ any stale ARP cache entries out there (see 4.4.1 in the DHCP RFC).
: arp-notify  ( -- )
   broadcast-ip-addr broadcast-en-addr
   my-ip-addr my-en-addr  2  ARP_TYPE  send-arp/rarp-packet
;

[ifdef] notdef
Appropriate responses for request failure:
          my-ip-address-unknown? 0=  if
             (it is permitted to go to BOUND state if the lease is unexpired)
          then
          notify-user  retry-at-INIT-state
[then]

: set-server-id  ( -- )
   dhcp-server-ip  /i  d# 54 +option	\ Server identifier option
;
\ Common end options for DHCPREQUEST and DHCPDECLINE packets
: finish-request/decline  ( -- )
   offered-ip      /i  d# 50 +option	\ Requested IP address option
   copy-options
;

: send-decline  ( -- )
   accepted-ip erase-ip-addr
   0 to dhcp-secs
   " "(04)"  start-dhcp-packet	\ DHCPDECLINE
   " Duplicate IP address"  d# 56 +option	\ Message option
   set-server-id
   finish-request/decline
;

partial-headers
defer parse-vendor  ( adr len -- adr len )  ' noop is parse-vendor

headerless
\ true on top of the stack means that a NAK was received from our chosen
\ server, in which case the caller will abandon this DHCP attempt.
\ false on top of the stack means either a timeout or an ACK.
: receive-ack  ( -- true | timeout? false )   \ True if our server NAK'ed
   begin
      \ Accept DHCPACK and DHCPNAK packets
      \ 60 masks bits 5 and 6, 5 is DHCPACK and 6 is DHCPNAK

      \ If receive-dhcp-packet returns true, it's a timeout, so we
      \ retry at that higher level where the DHCPREQUEST will be resent.
      h# 60 receive-dhcp-packet   if  true false exit  then  ( dhcp-type )

      \ If it's an ACK, we return "false false" so the higher level will
      \ proceed.
      5 =  if  false false exit  then                        ( )

      \ It was a NAK; our response depends on which server issued it.

      \ XXX this code may need modification if we add
      \ support for the DHCP INIT-REBOOT state.

      d# 54 find-option  if            ( )
         \ If the NAK is from the chosen server, we give up.
         drop  dhcp-server-ip ip=  if  ( )
            " Received DHCP NAK from the chosen server!" .dhcp-msg
            \ XXX clear any remembered IP address
            \ Return "true" so the higher level will give up.
            true exit
         then                          ( )
      then                             ( )

      \ The NAK was from a server that we don't care about,
      \ so we just ignore it and keep looking.
      handle-dhcp-nak
   again
;

\ If we ever implement persistent IP addresses, we will need to add code to
\ clear the remembered IP address.
: (requesting)  ( -- error? )     \ Packet must be prepared in advance
   " Confirming IP address with DHCP Request" .dhcp-msg

   init-backoff

   begin
      send-dhcp-packet
      \ Entering REQUESTING or REBOOTING state
      receive-ack  if  true exit  then  ( timeout? )
   while                                ( )
      too-many?  if  true exit  then    ( )
   repeat                               ( )

   \ We got an ACK
   \ Entering BOUND state
   extract-bootp-info

   \ If the BOOTP or DHCP server did not return a filename, and
   \ the user did not supply one in the package arguments, then
   \ we return the system architecture name in bootp-name-buf.
   bootp-name-buf count nip 0=  if  
      file-name-buf c@ 0=  if
         " architecture" ['] root-node get-package-property 0=  if  ( prop$ )
            get-encoded-string					    ( name$ )
            bootp-name-buf place				    ( )
         then
      then
   then

   d#  6 find-option  if  drop name-server-ip    copy-ip-addr  then
   d# 28 find-option  if  drop broadcast-ip-addr copy-ip-addr  then
   d# 15 find-option  if  'domain-name    place-cstr drop  then
   d# 12 find-option  if  'client-name    place-cstr drop  then
   d# 42 find-option  if  drop ntp-server-ip    copy-ip-addr  then
   d# 43 find-option  if  parse-vendor  'vendor-options place-cstr drop  then
   d# 17 find-option  if  'root-path      place-cstr drop  then

   bootnet-debug  if
      indent ." Received DHCP ACK" cr
      name-server-ip known?  if
         indent indent ." Name server: " name-server-ip .ipaddr cr
      then
      broadcast-ip-addr   if
         indent indent ." IP broadcast: " broadcast-ip-addr (.ipaddr) cr
      then
      'domain-name c@  if
         indent indent ." Domain: " 'domain-name cscount type cr
      then
      'client-name c@  if
         indent indent ." My hostname: " 'client-name cscount type cr
      then
      'root-path c@  if
         indent indent ." Root path: " 'root-path cscount type cr
      then
      ntp-server-ip known?  if
         indent indent ." NTP server: " ntp-server-ip .ipaddr cr
      then
      'vendor-options c@  if
         indent indent ." Vendor options: " 'vendor-options cscount type cr
      then
   then

   " Using ARP to check if the assigned IP address is free." .dhcp-msg

   ip-in-use?  if
      " Oops, it's already in use; sending DHCP Decline" .dhcp-msg

      send-decline
      ." The IP address assigned to us by the DHCP server is already in use" cr
      d# 10,000 ms	\ Per clause 3.1.5 in dhcp-09
      \ Go to INIT state
      true exit
   else
      " Broadcasting ARP reply to announce my IP address" .dhcp-msg
      \ Broadcast ARP reply, announcing the new IP address
      arp-notify
   then

   \ Everything is just fine; we are finished with the protocol for now
   false
;

\ True when in the INIT/SELECTING branch of the state machine.
\ False when in the INIT-REBOOT/REBOOTING branch.

true value unknown-ip?

: requesting  ( -- error? )
   start-request-packet
   unknown-ip?  if  set-server-id  then
   finish-request/decline
   (requesting)
;

\ XXX the spec calls for a randomized 1-10 second delay prior to obtaining
\ an IP address via DHCP DISCOVER.  We default to not doing this, because
\ of concerns that it would slow down the booting process.  A particular
\ system can override this by plugging in a non-null implementation of
\ desync-delay.
defer desync-delay  ' noop is desync-delay

\ XXX currently the presence of a client IP address in the load arguments
\ causes DHCP to be bypassed.  We should probably change that to have it
\ do a DHCPINFORM.

: do-dhcp  ( -- )
   bootnet-debug  if
      ." DHCP protocol: Getting network addresses and client information" cr
   then
   /dhcp to /bootp-packet

   /bootp-packet allocate-bootp

   \ XXX Derive, or pass in as an argument, the initial IP address
   \ and set unknown-ip? according to its existence or lack thereof.

   false to bootp-only?

   unknown-ip?  if  desync-delay  then	\ 1-10 seconds; per 4.4.1

   \ INIT state or INIT-REBOOT state

   begin
      unknown-ip?  if
         \ INIT state
         begin  do-discover  while  .discover-error  repeat
      then
      
      bootp-only? 0=
   while
      requesting
   while
      .request-error
      true to unknown-ip?
   repeat
   then

   setup-ip-attr
   /bootp-packet free-bootp
;

[ifdef] notdef
BOUND state:
    Now we have a good IP address




If we already know our IP address via manual configuration:
    send-inform    (actually, INFORM is used only when the client already
                    knows its IP address, and needs only to get the rest
                    of its parameters.  If the client got the IP address
                    with the preceding algorithm, it will have already
                    obtained all of its parameters)
    receive-ack


Option packing:
   options field first   - end option must be present if chaining,
                           but pad options are optional
   file field next - but only if file field is enabled in the options
                     overload option.  end option must be present and
                     pad options must be used as necessary to fill the field
   sname field next - but only if sname field is enabled in the options
                     overload option.  end option must be present and
                     pad options must be used as necessary to fill the field


client concatenates all options of the same name.


backoff: randomized exponential backoff
   ethernet:  1st retransmission at 4 seconds randomized by a uniformly
                 distributed random number between -1 and 1
              2nd retransmission at 8 seconds randomized by -1 to +1
              3rd retransmission at 16 seconds randomized by -1 to +1
              4th retransmission at 32 seconds randomized by -1 to +1
              last retransmission at 64 seconds randomized by -1 to +1

How to choose xids to minimize collisions?  perhaps hash
ethernet address and clock value?

Be careful: The server will not automatically extend an extant lease
when the client requests the address again.  If the lease needs to
be extended, that must be done explicitly.  This implies that
the client probably needs to keep track of its extant lease and
try to reuse/extend it.

See page 28 for an interesting table.

Note: lease durations need to be converted to absolute expiration
times by adding to the local clock.  It might be better to time
stamp the acquisition of the lease, so the firmware doesn't have
to do studly time calculations.

Note: source address field in IP header must be set to 0 before the
client has obtained its IP address

    my-leased-ip-address-known-and-unexpired?  if
       must not fill-in-ciaddr-field  (see end of 3.5 on p.22)

       don't fill in server identifier option (see 4.3.2)

       fill in 'requested-IP address' option

       (okay for client to respond to pings (ICMP echo requests))

       fill in list of specific parameters client is interested in,
       using "parameter request list" option.

       set 'maximum DHCP message size' option

       for the next REQUEST:
          if INIT-REBOOT state:  (table 4 p33)
             (broadcast)
             server identifier must not be filled in
             set requested IP address with previous-assigned address
             ciaddr must be 0 per 4.3.2

          if RENEWING state:  (table 4 p33)
             (unicast)
             server identifier must not be filled in
             requested IP address must not be filled in
	     ciaddr must be the client's IP address

          if REBINDING state:  (table 4 p33)
             (broadcast)
             server identifier must not be filled in
             requested IP address must not be filled in
	     ciaddr must be the client's IP address
    else
[then]
\ XXX Remove now-obsolete bootp code like do-bootp
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
