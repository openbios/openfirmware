\ See license at end of file
purpose: Definitions related to Ethernet headers and addresses

hex

headerless
d# 1514 constant ethernet-max		\ Header (14) + data (1500)
					\ Checksum (4) not counted

0 instance value (link-mtu)	\ max packet size
0 instance value packet-buffer

\ Determine the Ethernet address for his-ip-addr
instance defer resolve-en-addr  ( 'dest-adr type -- 'en-adr type )
\ will be set later

: link-mtu  ( -- n )
   (link-mtu) ?dup 0=  if
      " max-frame-size" get-inherited-property  if
         " max-frame-size" my-parent ihandle>phandle find-method  if
            drop " max-frame-size" my-parent $call-method
         else
            ethernet-max
         then
      else
         get-encoded-int
         then
      dup to (link-mtu)
   then
;

: open-link   ( -- )  link-mtu alloc-mem  to packet-buffer  ;
: close-link  ( -- )  packet-buffer link-mtu free-mem  ; 

6 constant /e

: en=  ( adr1 adr2 -- flag )  /e comp 0=  ;
: copy-en-addr  ( src dst -- )  /e move  ;

/e buffer: my-en-addr
/e buffer: his-en-addr
/e buffer: router-en-addr                 \ IPv4 gateway/router
/e buffer: routerv6-en-addr               \ IPv6 router
/e buffer: mc-en-addr

: .my-link-addr      ( -- )  ." My MAC: " my-en-addr .enaddr  ;
: .his-link-addr     ( -- )  ." His MAC: " his-en-addr .enaddr  ;
: .router-en-addr    ( -- )  ." Gateway MAC: " router-en-addr .enaddr  ;
: .routerv6-en-addr  ( -- )  ." IPv6 router MAC: " routerv6-en-addr .enaddr  ;

create mc-en-addr-all-nodes  h# 33 c, h# 33 c, h# 00 c, 0 c, 0 c, 1 c,
create multicast-en-addr     h# 33 c, h# 33 c, h# ff c, 0 c, 0 c, 0 c,
create broadcast-en-addr     h# ff c, h# ff c, h# ff c, h# ff c, h# ff c, h# ff c,

: unknown-en-addr?  ( 'en -- flag )  dup l@ 0= swap w@ 0= and  ;

decimal

struct ( ether-header )
   /e sfield en-dest-addr
   /e sfield en-source-addr
    2 sfield en-type
constant /ether-header

: (set-mc-hash)  ( 'mc-en-adr -- err? )
   /e " $crc" evaluate invert
   " set-hash" ['] $call-parent catch  if  3drop true  else  false  then
;

: set-mc-hash  ( -- err? )
   my-en-addr 3 + multicast-en-addr 3 + 3 move
   /e 2 * dup >r alloc-mem >r                        ( R: len adr )
   multicast-en-addr    r@      /e move              ( R: len adr )
   mc-en-addr-all-nodes r@ /e + /e move              ( R: len adr ) 
   2r@ swap " set-multicast" ['] $call-parent catch  ( flag )  ( R: len adr )
   2r> swap free-mem                                 ( flag )
   0=  if  false exit  then
   4drop
   multicast-en-addr    (set-mc-hash)
   mc-en-addr-all-nodes (set-mc-hash) or
;

: multicast-en-addr?  ( adr -- flag )  w@ h# 3333 =  ;

: select-ethernet-header  ( -- )  packet-buffer set-struct  ;

: max-link-payload  ( -- n )  link-mtu /ether-header -  ;

defer handle-ethernet  ( adr len type -- )  ' 3drop is handle-ethernet
headers
: (handle-ethernet)  ( adr len type -- )
   ." (Discarding ethernet packet of type " u. ." )" cr
   2drop
;
headerless

list: ethlist
listnode
   /n field >eth-adr		\ contents-adr
   /n field >eth-len		\ contents-len
   2  field >eth-type
nodetype: ethnode

0 ethlist !
0 ethnode !
0 value eth-type

: free-ethnode  ( prev -- adr len )
   delete-after
   dup ethnode free-node
   dup >eth-adr @ swap >eth-len @	( adr len )
   2dup packet-buffer swap move		( adr len )
   tuck free-mem			( len )
   packet-buffer swap			( adr len )
;

decimal
th  800 constant IP_TYPE
th 86dd constant IPV6_TYPE
hex

: ip-type?  ( type -- ip-type? )  dup IP_TYPE = swap IPV6_TYPE = or  ;

: eth-type=?  ( type -- flag )
   eth-type ip-type?  if  ip-type?  else  eth-type =  then
;

: eth-type-find  ( node-adr -- flag )  >eth-type w@ eth-type=?  ;

: enque  ( adr len type -- )
   -rot  dup alloc-mem swap 2dup 2>r move 2r>	( type adr' len )
   ethnode allocate-node			( type adr len node )
   dup ethlist last-node insert-after		( type adr len node )
   tuck >eth-len !				( type adr node )
   tuck >eth-adr !				( type node )
   >eth-type w!					( )
;

: dequeue?  ( type -- 0 | adr len true )
   to eth-type
   ethlist ['] eth-type-find  find-node  if
      free-ethnode				( adr len )
      true					( adr len true )
   else
      drop 0
   then
;

: (receive-ethernet-packet)  ( type -- true | adr len false )
   begin
      pause
      packet-buffer link-mtu  " read" $call-parent      ( type length|-error )
      dup  0>  if                                       ( type length )
         select-ethernet-header                         ( type length )
         over  en-type xw@ =  if                        ( type length )
            nip  /ether-header payload false  exit      ( adr len false )
         else                                           ( type length )
            dup /ether-header payload                   ( type len adr len )
            en-type xw@ dup ip-type?  if		( type len adr len type )
               enque					( type len )
            else					( type len adr len type )
               handle-ethernet                          ( type length )
            then
         then                                           ( type length )
      then                                              ( type 0|-error )
      drop                                              ( type )
      timeout?                                          ( type flag )
   until                                                ( type )
   drop true                                            ( true )
;

: receive-ethernet-packet  ( type -- true | adr len false )
   dup dequeue?  if  rot drop false exit  then
   (receive-ethernet-packet)
;

: send-ethernet-packet  ( data-adr data-len type dst-en-addr -- )
   2swap swap /ether-header - set-struct -rot	( data-len type dst )

   en-dest-addr    copy-en-addr                 ( data-len type )
   en-type xw!                                  ( data-len )
   my-en-addr   en-source-addr  copy-en-addr    ( data-len )

   the-struct  swap /ether-header +  tuck  " write" $call-parent  ( len actual )
   <>  if  ." Network transmit error" cr  then
;

: lock-link-addr  ( -- )
   the-struct >r  select-ethernet-header
   en-source-addr  his-en-addr  copy-en-addr
   r> set-struct
;
: allocate-ethernet  ( payload-len -- payload-adr )
   /ether-header +  alloc-mem  /ether-header +
;
: free-ethernet  ( payload-adr payload-len -- )
   /ether-header negate /string  free-mem
;

: unlock-link-addr  ( -- )  broadcast-en-addr his-en-addr copy-en-addr  ;

: send-link-packet  ( packet-adr packet-len [ 'dest-adr ... ] type -- )
   resolve-en-addr   ( packet-adr packet-len 'en-adr type -- )
   swap  send-ethernet-packet

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
