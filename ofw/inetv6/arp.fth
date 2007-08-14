\ See license at end of file
purpose: Address Resolution Protocol (ARP) and Reverse ARP (RARP)

\ Address Resolution Protocol (ARP)
\   Given the local Ethernet address, finds a server's Ethernet address
\
\ Reverse Address Resolution Protocol (RARP)
\   Given the local Ethernet address, finds corresponding Internet address
\
\ These protocols are specific to both Ethernet and Internet, since
\ their purpose is to relate corresponding addresses from the two
\ families.
\
\ do-arp  ( -- )
\   If his-en-addr contains the broadcast Ethernet address,
\   performs the ARP protocol and sets his-en-addr to the
\   responding server's Ethernet address
\
\ do-rarp  ( -- )
\   If my-ip-addr contains a broadcast IP address (the first byte is ff),
\   performs the RARP protocol and sets my-ip-addr to my Internet address,
\   and his-en-addr and his-ip-addr to the responding server's Ethernet
\   address and Internet address.
\
\ clear-net-addresses  ( -- )
\   Sets his-en-addr and my-ip-addr to the broadcast values so that
\   ARP and RARP will have to re-acquire them.

decimal

headerless
h# 806 constant ARP_TYPE
h# 8035 constant RARP_TYPE

: arp-address-type  ( -- type )
   " arp-address-type" ['] $call-parent catch  if  ( x x )
      2drop 1                                      ( ARPHRD_ETHER )
   then                                            ( type )
;

\ Request structure shared between ARP and RARP

struct ( arp-packet)
   2 sfield arp-hw       \ set to 1 for ethernet
   2 sfield arp-protocol \ set to IP_TYPE
   1 sfield arp-hwlen    \ set to 6 for ethernet
   1 sfield arp-protolen \ set to 4 for IP
   2 sfield arp-opcode   \ 1 arp req., 2 arp reply, 3 rarp req., 4 rarp reply
  /e sfield arp-sha      \ sender hardware address
  /i sfield arp-spa      \ sender protocol address
  /e sfield arp-tha      \ target hardware address
  /i sfield arp-tpa      \ target protocol address
constant /arp-packet

/ether-header /arp-packet +  constant  /ether+arp

0 value arp-packet
\ Common ARP/RARP request packet constructor
: send-arp/rarp-packet  ( his-ip his-en my-ip my-en req-type en-type -- )
   >r                   ( his-ip his-en my-ip my-en req-type r: en-type )
   /arp-packet allocate-ethernet to arp-packet
   arp-packet set-struct
   arp-address-type arp-hw xw!
   IP_TYPE arp-protocol xw!
   /e      arp-hwlen    xc!
   /i      arp-protolen xc!
   ( ... req-type )     arp-opcode   xw!
   ( ... my-en-addr )   arp-sha copy-en-addr
   ( ... my-ip-addr )   arp-spa copy-ip-addr
   ( ... his-en-addr )  arp-tha copy-en-addr
   (     his-ip-addr )  arp-tpa copy-ip-addr

   the-struct /arp-packet  r>  broadcast-en-addr  send-ethernet-packet
   arp-packet /arp-packet free-ethernet
;
\ The backoff goes as follows (in seconds):  0 1 2 4 8 16 32 1 2 4 8 16 32 ...
instance variable arp-delay

: arp-backoff  ( -- )
   arp-delay @  ms
   arp-delay @  d# 1000 max  2*
   dup  d# 32000  >  if  drop d# 1000  then  arp-delay !
;

: .arp/rarp-timeout ( -- )
   " Timeout waiting for ARP/RARP packet" diag-type diag-cr
;

: arpcom  ( his-ip his-en  my-ip my-en  req-type  en-type  -- ok? )
   arp-backoff
   send-arp/rarp-packet
   timeout-msecs @ set-timeout
;

: decode-arp-packet  ( -- )
   arp-sha  his-en-addr  copy-en-addr    \ grab his Ethernet address
;

: use-fixed   ( -- addr )
   use-router?  if  router-ip-addr  else  his-ip-addr  then
;
: sought-ip-addr  ( -- ip )
   \ If we don't know who we are, we don't know our network number, so
   \ we have to guess.
   my-ip-addr unknown-ip-addr?  if  use-fixed exit  then

   \ If we are on the same network as the destination host, we send
   \ directly to him.
   my-ip-addr his-ip-addr ip-prefix=?  if  his-ip-addr exit  then

   \ Otherwise, we are not on the same net, so we want to send to the
   \ router, but if we don't have the address of a router, we will
   \ try to send directly just in case it might work anyway.
   use-fixed
;

\ we use router-ip-addr in case of gateway booting.
\ In fact, the response ethernet address (router's) will be
\ moved in "his-en-addr". This is correct behavior since the package
\ uses his-en-addr as destination ethernet address.
: try-arp  ( -- )
   sought-ip-addr his-en-addr my-ip-addr my-en-addr 1  ARP_TYPE  ( params )
   arpcom

   begin  ARP_TYPE  receive-ethernet-packet  0=  while   ( arp-adr,len )
      drop set-struct                                    ( )
      arp-tpa my-ip-addr ip=  if		     \ Addressed to me
         arp-opcode xw@  2 =  if  decode-arp-packet exit  then   \ ARP reply
      then                                               ( )
   repeat
   .arp/rarp-timeout
;

headers

: do-arp  ( -- )
   sought-ip-addr broadcast-ip-addr?  if
      broadcast-en-addr his-en-addr copy-en-addr  exit
   then
   bootnet-debug  if
      ." ARP protocol: Getting MAC address for IP address: "
      his-ip-addr .ipaddr cr
   then
   0 arp-delay !

   \ Loop until we find the destination Ethernet address
   current-timeout >r
   begin   his-en-addr xw@  h# ffff  =  while  try-arp  repeat
   r> restore-timeout

   bootnet-debug  if  indent ." Got MAC address: " his-en-addr .enaddr cr  then
;

: (resolve-en-addr)  ( 'dest-adr type -- 'en-adr type )
   dup IP_TYPE  =  if                                ( 'ip-adr ip-type )
      swap  dup broadcast-ip-addr?  if               ( ip-type 'ip-adr )
         drop                                        ( ip-type )
         broadcast-en-addr his-en-addr copy-en-addr  ( ip-type )
      else                                           ( ip-type 'ip-adr )
         his-ip-addr copy-ip-addr                    ( ip-type )
         his-ip-addr my-ip-addr ip-prefix=?  if
            his-en-addr broadcast-en-addr en=  if  do-arp  then  ( ip-type )
         else
            router-en-addr his-en-addr copy-en-addr  \ Not local, go through the gateway
         then
      then
      his-en-addr  swap exit
   then                                              ( 'dest-adr type )
   nip his-en-addr swap
;
\ ' (resolve-en-addr) to resolve-en-addr

headerless

\ Handle incoming arp packets if we know our address
: arp-response  ( adr len type -- )
   ARP_TYPE  <>  if  2drop exit  then                   \ Packet type filter
   /arp-packet  <  if  drop exit  then                  \ Packet length filter
   set-struct
   arp-protocol xw@  IP_TYPE  <>  if  exit  then        \ Type filter
   arp-opcode xw@ 1 <>  if  exit  then                  \ Type filter
   arp-tpa  my-ip-addr  ip=  0=  if  exit  then         \ For somebody else?

   \ All the checks have succeeded, so we can send the reply
   2 arp-opcode xw!
   arp-sha     arp-tha  copy-en-addr
   my-en-addr  arp-sha  copy-en-addr
   arp-spa     arp-tpa  copy-ip-addr
   my-ip-addr  arp-spa  copy-ip-addr

   the-struct /arp-packet  ARP_TYPE  arp-tha  send-ethernet-packet
;
' arp-response is handle-ethernet

\ Reverse Address Resolution Protocol - finds my Internet address
\ given my Ethernet address.

: decode-rarp-packet  ( -- )
   arp-opcode xw@ 4 <>  if  exit  then
   arp-sha  his-en-addr  copy-en-addr    \ grab his Ethernet address
   arp-spa  his-ip-addr  copy-ip-addr    \ grab his IP address
   arp-tpa  my-ip-addr   copy-ip-addr    \ grab my IP address
;

: try-rarp  ( -- )
   broadcast-ip-addr my-en-addr broadcast-ip-addr my-en-addr  3 RARP_TYPE
   arpcom

   begin  RARP_TYPE  receive-ethernet-packet  0=  while   ( arp-adr,len )
      drop set-struct                                     ( )
      arp-tha my-en-addr en=  if	     \ Addressed to me
         arp-opcode xw@  4 =  if                     \ RARP reply
             decode-rarp-packet exit
         then
      then                                               ( )
   repeat
   .arp/rarp-timeout
;

headers

: do-rarp  ( -- )
   0 arp-delay !
   bootnet-debug  if
      ." RARP protocol: Getting IP address for MAC address: "
      my-en-addr .enaddr cr
   then

   current-timeout >r
   begin  my-ip-addr unknown-ip-addr?  while  try-rarp  repeat
   r> restore-timeout

   bootnet-debug  if  indent ." Got IP address: " my-ip-addr .ipaddr cr  then
;

: clear-his-address  ( -- )
   use-router? use-server? or  if  exit  then

   broadcast-ip-addr set-dest-ip
;
: clear-my-address  ( -- )
   unknown-ip-addr    my-ip-addr      copy-ip-addr
;
: clear-net-addresses  ( -- )
   clear-his-address
   clear-my-address
   unknown-ip-addr    name-server-ip  copy-ip-addr
   unknown-ip-addr    subnetmask      copy-ip-addr
;

false instance value pp?
\ Support for point-to-point links
warning @ warning off
: open-link  ( -- )
   open-link

   ['] (resolve-en-addr) to resolve-en-addr

   " point-to-point?" ['] $call-parent catch  if  2drop exit  then
   ( false | 'his-ip 'my-ip true )  if                   ( 'his-ip 'my-ip )
      my-ip-addr copy-ip-addr  his-ip-addr copy-ip-addr  ( )
      ['] noop to resolve-en-addr
      true to pp?
   then

   " dns-servers" ['] $call-parent catch  if    ( x x )
      2drop                                     ( )
   else                                         ( false | 'ip1 'ip0 true )
      if                                        ( 'ip1 'ip0 )
         dup known?  if  nip  else  drop  then  ( 'ip )
         name-server-ip copy-ip-addr            ( )
      then
   then

   " domain-name" ['] $call-parent catch  if    ( x x )
      2drop                                     ( )
   else                                         ( name$ )
      'domain-name place-cstr drop
   then
;

: close-link  ( -- )  close-link  pp?  if  clear-my-address  then  ;
warning !
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
