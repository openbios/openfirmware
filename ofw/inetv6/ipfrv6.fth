\ See license at end of file
purpose:  Internet Protocol version 6 (IPv6) fragmentation/reassembly implementation

headerless

struct ( ipv6-frag-header )
   1 sfield ipv6-fh-next-hdr
   1 sfield ipv6-fh-len
   2 sfield ipv6-fh-frag-offset     \ OOOO.OOOO.OOOO.OxxM
                                    \ Os contain the fragment offset in 8-byte unit
                                    \ M=1=more fragments
   4 sfield ipv6-fh-frag-id
   0 sfield ipv6-fh-data
constant /ipv6-frag-hdr

instance variable frag-id
h# 40 instance value hop-limit

headers

\ *********************************************************************************
\                                   Send IP packet
\ *********************************************************************************

[ifndef] include-ipv4
: send-ip-packet  ( adr len protocol -- )  3drop  ;
[then]

: max-ipv6-fragment  ( -- n )
   max-link-payload /ipv6-header - /ipv6-frag-hdr -
   h# ffff.fff8 and  
;
: max-ipv6-payload  ( -- n )  max-ipv6-fragment /ipv6-frag-hdr +  ;

headerless
: (send-ipv6-packet)  ( adr len protocol -- )
   rot /ipv6-header - set-struct                     ( len protocol )
      h# 6000.0000  ipv6-version     xl!             \ version 6
      ( protocol )  ipv6-next-hdr    xc!             ( len )
      ( len ) dup   ipv6-length      xw!             ( len )
      his-ipv6-addr ipv6-addr-local?  if  hop-limit  else  router-hop-limit  then
      ( hop-limit ) ipv6-hop-limit   xc!             ( len )
      my-ipv6-addr  ipv6-source-addr copy-ipv6-addr  ( len )
      his-ipv6-addr ipv6-dest-addr   copy-ipv6-addr  ( len )
   /ipv6-header +                                    ( ip-len )
   the-struct swap                                   ( ip-adr ip-len )
   ipv6-dest-addr  IPV6_TYPE  send-link-packet       ( )
;

0 value oaddr			\ original data packet address
0 value olen			\ original data packet length
0 value oprotocol		\ original protocol
0 value fadr			\ fragment address

: send-ipv6-fragment  ( offset -- )
   >r fadr dup set-struct		    ( fadr )  ( R: offset )
   olen max-ipv6-fragment min	 	    ( fadr flen )  ( R: offset )
      oaddr r@ + ipv6-fh-data 2 pick move   ( fadr flen )  ( R: offset )
      oprotocol  ipv6-fh-next-hdr    xc!    \ Next header in fragment header
      0          ipv6-fh-len         xc!    \ Length of header in units of 8 bytes - 1
      frag-id @  ipv6-fh-frag-id     xl!    \ Fragment id
      dup olen u<  1 and                    ( fadr flen more? )  ( R: offset )
      r> or ipv6-fh-frag-offset xw!         ( fadr flen )
   olen over - to olen                      ( fadr flen )
   /ipv6-frag-hdr +                         ( fadr flen' )
   IP_HDR_FRAGMENT (send-ipv6-packet)       ( )
;

: send-ipv6-packet  ( adr len protocol -- )
   over max-ipv6-payload <=  if
      (send-ipv6-packet)
   else
      1 frag-id +!
      over max-ipv6-fragment /mod swap 0>  if  1+  then  ( adr len protocol #frags )
      >r to oprotocol to olen to oaddr r>     ( #frags )
      max-ipv6-payload allocate-ipv6 to fadr  ( #frags )
      ( #frags ) 0  ?do                       ( )
         i max-ipv6-fragment * send-ipv6-fragment
      loop
      fadr max-ipv6-payload free-ipv6
   then
;

: send-ip-packet  ( adr len protocol -- )
   use-ipv6?  if  send-ipv6-packet  else  send-ip-packet  then
;

\ *********************************************************************************
\                           Send fully prepared ethernet packet
\          ( For ECHO reply use where ethernet and IP headers are complete. )
\ *********************************************************************************

\ For going between the two headers; used as a pair
: ipv6-struct  ( -- )  /ipv6-header negate +struct  ;
: frag-struct  ( -- )  /ipv6-header +struct  ;

: alloc-fadr  ( adr -- )
   dup link-mtu alloc-mem dup to fadr		( adr adr fadr )
   /ether-header /ipv6-header + move            ( adr )
   /ether-header + set-struct			( )
   ipv6-length xw@ to olen
   ipv6-next-hdr c@ to oprotocol

   \ Initialize static part of IPv6 header
   fadr /ether-header + set-struct
   IP_HDR_FRAGMENT ipv6-next-hdr xc!

   \ Initialize static part of fragment header
   frag-struct
   oprotocol ipv6-fh-next-hdr xc!
   0         ipv6-fh-len      xc!
   frag-id @ ipv6-fh-frag-id  xl!
   ipv6-struct
;

: (send-raw-packet)  ( adr len -- )
   tuck " write" $call-parent
   <>  if  ." Network transmit error" cr  then
;
: send-raw-fragment  ( offset -- )
   >r						( )  ( R: offset )
   olen max-ipv6-fragment min			( flen )  ( R: offset )
   dup /ipv6-frag-hdr + ipv6-length xw!		( flen )  ( R: offset )
   frag-struct					( flen )  ( R: offset )
   dup olen u<  1 and				( flen more? )  ( R: offset )
   r@ or ipv6-fh-frag-offset xw!		( flen )  ( R: offset )
   oaddr r> + ipv6-fh-data 2 pick move		( flen )
   ipv6-struct					( flen )
   olen over - to olen				( flen )
   /ipv6-frag-hdr + /ipv6-header + /ether-header +	( len )
   fadr swap (send-raw-packet)			( )
;
: send-raw-packet  ( adr len -- )
   dup link-mtu <=  if
      (send-raw-packet)
   else
      1 frag-id +!					( adr len )
      over alloc-fadr					( adr len )
      /ether-header /ipv6-header + /string		( content-adr,len )
      swap to oaddr					( content-len )
      max-ipv6-fragment /mod swap 0>  if  1+  then	( #frags )
      ( #frags ) 0  ?do
         i max-ipv6-fragment * send-raw-fragment
      loop
      fadr link-mtu free-mem
   then
;

\ *********************************************************************************
\                                 Receive IP packet
\ *********************************************************************************

list: ipv6list
listnode
 /ether-header field >ipv6-ether	\ Beginning of ethernet header
       0 field >ipv6-header             \ Beginning of IPv6 header
       4 field >ipv6-version
       2 field >ipv6-len                \ Total length of reassembled data
       1 field >ipv6-protocol
       1 field >ipv6-hop-limit
   /ipv6 field >ipv6-source-addr
   /ipv6 field >ipv6-dest-addr          \ End of IPv6 header
      /n field >ipv6-dghead		\ Head of list of IPv6 datagrams
      /n field >ipv6-dgtail		\ Tail of list of IPv6 datagrams
      /n field >ipv6-timer		\ Timeout value in ms
      /n field >ipv6-rangelist		\ Pointer to range info
      /n field >ipv6-id			\ Fragment id
nodetype: ipv6node			\ List of IPv6 reassembly in process

0 ipv6list !
0 ipv6node !

struct
   /n field >dgv6-adr			\ Pointer to content of fragmented data
   /n field >dgv6-len			\ Length of fragmented data
   /n field >dgv6-offset		\ Offset of fragmented data
   /n field >dgv6-next
constant /dgv6list

[ifndef] include-ipv4
struct
   /n field >rl-begin
   /n field >rl-end
   /n field >rl-next
   /n field >rl-prev
constant /rangelist
[then]

0 instance value reassembledv6-adr
0 instance value reassembledv6-len	\ ihl + data len
d# 60 d# 1000 * constant tlbv6		\ 60 seconds for initial timer setting

: ipv6-id=?  ( node -- id=? )
   >r                                                      ( )  ( R: node )
   frag-struct                                             ( )  ( R: node )
   ipv6-fh-next-hdr c@  ipv6-fh-frag-id xl@                ( next-hdr frag-id )  ( R: node )
   ipv6-struct                                             ( next-hdr frag-id )  ( R: node )
   r@ >ipv6-id        @ <>  if  r> 2drop false exit  then  ( next-hdr )  ( R: node )
   r@ >ipv6-protocol c@ <>  if  r> drop  false exit  then  ( )  ( R: node )
   r@ >ipv6-source-addr ipv6-source-addr ipv6= not  if  r> drop false exit  then
   r> >ipv6-dest-addr   ipv6-dest-addr   ipv6=
;

: find-ipv6?  ( -- prev-node this-node | 0 )
   ipv6list ['] ipv6-id=?  find-node
;

: alloc-ipv6  ( last-node -- node )
   ipv6node allocate-node tuck swap insert-after
   >r
   the-struct /ether-header - r@ >ipv6-ether /ipv6-header /ether-header + move
   0 r@ >ipv6-dghead !
   0 r@ >ipv6-dgtail !
   get-msecs tlbv6 + r@ >ipv6-timer !
   0 r@ >ipv6-len xw!
   0 r@ >ipv6-rangelist !
   frag-struct
   ipv6-fh-frag-id xl@ r@ >ipv6-id !
   ipv6-fh-next-hdr c@ r@ >ipv6-protocol xc!
   ipv6-struct
   r>
;

: save-ipv6  ( node -- )
   >r
   ipv6-length xw@ /ipv6-frag-hdr - dup alloc-mem	( len this-dg )  ( R: node )

   frag-struct
   2dup swap the-struct /ipv6-frag-hdr + -rot move	( len this-dg )  ( R: node )
   ipv6-fh-frag-offset xw@ 				( len this-dg offset )  ( R: node )
   ipv6-struct						( len this-dg offset )  ( R: node )
   dup h# fff8 and swap 1 and 0=  if			\ Last fragment
      ipv6-length xw@ /ipv6-frag-hdr - over +		( len this-dg offset )  ( R: node )
      r@ >ipv6-len xw!
   then

   /dgv6list alloc-mem					( len this-dg offset this-dglist )  ( R: node )
   tuck >dgv6-offset !					( len this-dg this-dglist )  ( R: node )
   tuck >dgv6-adr !					( len this-dglist )  ( R: node )
   tuck >dgv6-len !					( this-dglist )  ( R: node )
   0 over >dgv6-next !					( this-dglist )  ( R: node )

   r@ >ipv6-dghead @ 0=  if  dup r@ >ipv6-dghead !  then	( this-dglist )  ( R: node )
   r@ >ipv6-dgtail @ ?dup 0<>  if  >dgv6-next over swap !  then	( this-dglist )  ( R: node )
   r> >ipv6-dgtail !					( )
;

: free-dgv6  ( dg -- )
   begin  ?dup  while				 ( 'dg )
      dup >dgv6-adr  @ over >dgv6-len @ free-mem ( 'dg )
      dup >dgv6-next @				 ( 'dg 'dg-next )
      swap /dgv6list free-mem			 ( 'dg-nest )
   repeat					 ( )
;

[ifndef] include-ipv4
: free-rangelist  ( rl -- )
   begin  ?dup  while				( rl )
      dup >rl-next @ swap /rangelist free-mem	( rl-next )
   repeat					( )
;
[then]

: free-ipv6node  ( prev -- )
   delete-after
   dup ipv6node free-node
   dup >ipv6-dghead @ free-dgv6
   >ipv6-rangelist @ free-rangelist
;

: free-ipv6list  ( -- )
   find-ipv6?  if  free-ipv6node  else  drop  then
;

: ipv6-timeout?  ( node -- flag )  >ipv6-timer @ get-msecs <=  ;

: process-timeoutv6?  ( -- flag )
   ipv6list ['] ipv6-timeout? find-node  if  free-ipv6node true  else  drop false  then
;

[ifndef] include-ipv4
0 value rlb
0 value rle
0 value last-rl

: create-rangelist  ( -- rl )
   /rangelist alloc-mem		( rl )
   rle over >rl-end !		( rl )
   rlb over >rl-begin !		( rl )
;
[then]

: insert-before-rangelistv6  ( node rl -- )
   create-rangelist >r			( node rl )
   dup r@ >rl-next !			( node rl )
   dup >rl-prev @ dup r@ >rl-prev !	( node rl rl-prev )
   ?dup 0<>  if  >rl-next r@ swap !  then	( node rl )
   r@ over >rl-prev !			( node rl )
   r> -rot				( new node rl )
   over >ipv6-rangelist @ =  if  >ipv6-rangelist !  else  2drop  then
;

: insert-endof-rangelistv6  ( node rl -- )
   create-rangelist		( node rl new )
   0 over >rl-next !		( node rl new )
   2dup >rl-prev !		( node rl new )
   -rot tuck			( new rl node rl )
   0=  if  nip >ipv6-rangelist !  else  drop >rl-next !  then
;

\ New range = b:e
\ Current node = x:y
\ if e<x-1, add node to front and exit
\ if b>y+1, goto examine next node
\ if b<x, x=b
\ if e>y, y=e and exit
\ if all the nodes have been examined, add node to end and exit
\
: (update-rangelistv6)  ( ofs len node -- )
   -rot over + 1- to rle to rlb		( node )
   0 to last-rl				( node )
   dup >ipv6-rangelist @		( node rl )
   begin  ?dup  while
      >r				( node )
      rle r@ >rl-begin @ 1- <  if  r> insert-before-rangelistv6 exit  then
      rlb r@ >rl-end @ 1+ <=  if	( node )
         rlb r@ >rl-begin @ <  if  rlb r@ >rl-begin !  then
         rle r@ >rl-end @ >  if  rle r@ >rl-end !  then
         r> 2drop
         exit
      then
      r@ to last-rl			( node )
      r> >rl-next @			( node rl )
   repeat				( node )
   last-rl insert-endof-rangelistv6
;

: update-rangelistv6  ( node -- )
   frag-struct
   ipv6-fh-frag-offset xw@  h# fff8 and	( node ofs )
   ipv6-struct
   ipv6-length xw@  /ipv6-frag-hdr -	( node ofs len )
   rot (update-rangelistv6)
;

: rl-complete?  ( rl -- complete? )
   0 swap 				( 0 rl )
   begin				( e rl )
      2dup >rl-begin @ 1- <		( e rl gap? )
      if  2drop false exit  then	( e rl )
      dup >rl-end @ rot max swap	( e' rl )
      >rl-next @ ?dup 0=		( e' rl-next )
   until				( e' )
   drop true
;

: ipv6-done?  ( node -- done? )
   dup >ipv6-len xw@ 0=  if  drop false exit  then
   >ipv6-rangelist @  rl-complete?
;

: (reassemble-ipv6)  ( adr dg -- )
   begin  ?dup  while			( adr dg )
      2dup >dgv6-offset @ +		( adr dg dst )
      over >dgv6-adr @ swap		( adr dg src dst )
      2 pick >dgv6-len @  move          ( adr dg )
      >dgv6-next @			( adr dg-next )
   repeat  drop				( )
;

: reassemble-ipv6  ( node -- ip-adr,len )
   >r
   r@ >ipv6-len xw@ 						( dlen )  ( R: node )
   /ipv6-header + /ether-header +				( rlen )  ( R: node )
   dup to reassembledv6-len      				( rlen )  ( R: node )
   alloc-mem dup to reassembledv6-adr				( radr )  ( R: node )
   r@ >ipv6-ether swap /ipv6-header /ether-header + move	\ Copy IPv6 header content
   reassembledv6-adr /ipv6-header + /ether-header +		( content-adr )  ( R: node )
   r> >ipv6-dghead @ (reassemble-ipv6)				( )
   reassembledv6-adr reassembledv6-len /ether-header /string	( ip-adr,len )
   free-ipv6list						( ip-adr,len )
;

: process-datagramv6  ( node -- false | ip-adr,len true)
   dup save-ipv6		( node )
   dup update-rangelistv6	( node )
   dup ipv6-done?  if		( node )
      reassemble-ipv6		( ip-adr,len )
      true			( ip-adr,len true )
   else				( node )
      drop false		( false )
   then
;

: process-done-ipv6  ( -- )
   reassembledv6-len 0>  if
      reassembledv6-adr reassembledv6-len free-mem
      0 to reassembledv6-adr 0 to reassembledv6-len
   then
;

: get-done-ipv6?  ( -- false | ip-adr,len true )
   find-ipv6?  ?dup  if  nip  else  alloc-ipv6  then
   process-datagramv6
;

defer handle-icmpv6 ( contents-adr,len protocol -- )  ' 3drop to handle-icmpv6

[ifndef] include-ipv4
: process-done-ip   ( -- )  ;
: process-timeout?  ( -- flag )  false  ;
: process-ipv4-packet  ( adr len type -- flag )
   3drop  ." Discarding IPv4 packet" cr false
;
: ip-payload  ( len -- adr len' )  .ipv4-not-supported  ;
[then]

: process-timeout?  ( -- flag )
   use-ipv6?  if  process-timeoutv6?  else  process-timeout?  then
;

: process-ipv6-packet  ( adr len type -- false | contents-adr,len true )
   \ XXX Assume no additional headers other than fragmentation header for now.
   nip swap                                        ( type adr )
   dup set-struct to last-ipv6-packet              ( type )

   \ If IPv6 packet is not for me, exit
   ipv6-addr-match? not  if                        ( type )
      drop ipv6-payload handle-other-ipv6          ( )
      false  exit                                  \ Got an packet not for me
   then                                            ( type )

   \ If IPv6 packet is a fragment, reassemble packet if possible
   ipv6-next-hdr c@ IP_HDR_FRAGMENT =  if          ( type )
      get-done-ipv6?  if                           ( type false | ip-adr,len true )
         drop dup set-struct to last-ipv6-packet   \ Fragment reassembly complete
      else
         drop false  exit                          \ Fragment reassembly incomplete
      then
   then

   \ By now, we have a complete IPv6 packet.  Is it what we're waiting for?
   ipv6-next-hdr c@ >r                             ( type )  ( R: next-hdr )
   r@ = dup  if                                    ( type=next-hdr? )  ( R: next-hdr )
      ipv6-payload rot                             ( contents-adr,len true )  ( R: next-hdr )
   then                                            ( false | contents-adr,len true ) ( R: next-hdr )
   \ Is it an ICMPv6 packet?
   r> IP_HDR_ICMPV6 =  if                          ( false | contents-adr,len true )
      ipv6-payload IP_HDR_ICMPV6 handle-icmpv6     \ Handle ICMPv6 packets
   else
      dup not  if  ipv6-payload ipv6-next-hdr c@ handle-ipv6  then
                                                   \ Handle other unexpected packets
   then                                            ( false | contents-adr,len true )
;

: receive-ip-packet  ( type -- true | contents-adr,len false )
   process-done-ip
   process-done-ipv6

   begin
      use-ipv6?  if  IPV6_TYPE  else  IP_TYPE  then
      receive-ethernet-packet                    ( type [ip-adr,len] flag )
      if  drop process-timeout? drop true exit  then

      over ipv4?  if
         2 pick process-ipv4-packet              ( type [len] flag )
         if  ip-payload true  else  false  then  ( type [contents-adr,len] flag )
      else
         2 pick process-ipv6-packet              ( type [contents-adr,len] flag )
      then

      ?dup 0=  if				 ( type )
         process-timeout?  if  drop true exit  then
         false
      then
   until					 ( type contents-adr,len )
   rot drop false                                ( contents-adr,len false )
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
