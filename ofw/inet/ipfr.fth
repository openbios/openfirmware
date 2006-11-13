\ See license at end of file
purpose:  Internet Protocol (IP) fragmentation/reassembly implementation

headers
: max-ip-payload  ( -- n )
   max-link-payload /ip-header -
   h# ffff.fff8 and  
;

headerless
: ihl  ( -- len )  ip-version c@ h# f and /l*  ;

: (send-ip-packet)  ( adr len protocol fragment -- ) 
   3 pick /ip-header - set-struct                 ( adr len protocol fragment )
      ( fragment ) ip-fragment xw!                ( adr len protocol )
      ( protocol ) ip-protocol xc!     		  ( adr len )
      swap drop                                   ( len )
      h# 45    ip-version xc!    ( 45 is ip version 4, length 5 longwords )
      0        ip-service xc!
      ( len )  /ip-header +  dup  ip-length xw!   ( ip-len )
      ip-sequence @  ip-id     xw!
      ttl @    ip-ttl      xc!
      0        ip-checksum xw!
      my-ip-addr     ip-source-addr copy-ip-addr
      his-ip-addr    ip-dest-addr   copy-ip-addr
      0 the-struct  /ip-header  oc-checksum   ip-checksum  xw!
							( ip-len )
   the-struct swap                                      ( ip-adr ip-len )

   ip-dest-addr  IP_TYPE  send-link-packet              ( )
;

0 value oaddr			\ original data packet address
0 value olen			\ original data packet length
0 value oprotocol		\ original protocol
0 value fadr			\ fragment address

: send-ip-fragment  ( offset -- )
   >r fadr				( fadr )
   olen r@ - max-ip-payload min 	( fadr flen )
   2dup oaddr r@ + -rot move		( fadr flen )
   oprotocol 				( fadr flen protocol )
   r@ 8 / 				( fadr flen protocol fo )
   r> max-ip-payload + olen <  if  h# 2000 or  then  ( fadr flen protocol fo )
   (send-ip-packet)			( )
;

: send-ip-packet  ( adr len protocol -- )
   1 ip-sequence +!
   over max-ip-payload /mod swap 0>  if  1+  then  ( adr len protocol #frags )
   dup 1 =  if
      drop 0  (send-ip-packet)
   else
      >r to oprotocol to olen to oaddr r>
      max-ip-payload allocate-ip to fadr
      0 do
         i max-ip-payload * send-ip-fragment
      loop
      fadr max-ip-payload free-ip
   then
;

list: iplist
listnode
   /n field >ip-dghead		\ head of list of datagrams
   /n field >ip-dgtail		\ tail of list of datagrams
   /n field >ip-timer		\ timeout value in ms
   /n field >ip-len		\ total length of original data
   /n field >ip-dg0		\ pointer to datagram with fragment offset 0
   /n field >ip-rangelist	\ pointer to range info
   /i field >ip-source-addr
   /i field >ip-dest-addr
   2  field >ip-id
   1  field >ip-protocol
nodetype: ipnode		\ list of reassembly in process

0 iplist !
0 ipnode !

struct
   /n field >dg-adr
   /n field >dg-len
   /n field >dg-next
constant /dglist

struct
   /n field >rl-begin
   /n field >rl-end
   /n field >rl-next
   /n field >rl-prev
constant /rangelist

0 instance value reassembled-adr
0 instance value reassembled-len	\ ihl + data len
d# 15 d# 1000 * constant tlb		\ 15 seconds for initial timer setting

: ip-id=?  ( node-adr -- id=? )
   >r
   r@ >ip-id xw@ ip-id xw@ = dup  if
      drop r@ >ip-protocol c@ ip-protocol c@ = dup  if
         drop r@ >ip-source-addr ip-source-addr ip= dup  if
            drop r@ >ip-dest-addr ip-dest-addr ip=
   then then then
   r> drop
;

: find-ip?  ( -- prev-node this-node | 0 )
   iplist ['] ip-id=?  find-node
;

: alloc-ip  ( last-node -- node )
   ipnode allocate-node tuck swap insert-after
   >r
   0 r@ >ip-dghead !
   0 r@ >ip-dgtail !
   get-msecs tlb + r@ >ip-timer !
   0 r@ >ip-len !
   0 r@ >ip-dg0 !
   0 r@ >ip-rangelist !
   ip-source-addr r@ >ip-source-addr copy-ip-addr
   ip-dest-addr r@ >ip-dest-addr copy-ip-addr
   ip-id xw@ r@ >ip-id xw!
   ip-protocol c@ r@ >ip-protocol xc!
   r>
;

: save-ip  ( node -- )
   >r
   ip-length xw@ dup alloc-mem 		( len this-dg )
   2dup swap the-struct -rot move	( len this-dg )
   ip-fragment xw@ h# 1fff and 0=  if
      dup r@ >ip-dg0 !
   then
   /dglist alloc-mem			( len this-dg this-dglist )
   tuck >dg-adr !			( len this-dglist )
   tuck >dg-len !			( this-dglist )
   0 over >dg-next !			( this-dglist )
   r@ >ip-dghead @ 0=  if  dup r@ >ip-dghead !  then	( this-dglist )
   r@ >ip-dgtail @ ?dup 0<>  if  >dg-next over swap !  then	( this-dglist )
   r> >ip-dgtail !			( )
;

: reset-timer  ( node -- )
   >ip-timer dup @ get-msecs ip-ttl c@ d# 1000 * + max swap !
;

: free-dg  ( dg -- )
   begin  ?dup  while			( 'dg )
      dup >dg-adr @ over >dg-len @ free-mem ( 'dg )
      dup >dg-next @			( 'dg 'dg-next )
      swap /dglist free-mem		( 'dg-nest )
   repeat				( )
;

: free-rangelist  ( rl -- )
   begin  ?dup  while				( rl )
      dup >rl-next @ swap /rangelist free-mem	( rl-next )
   repeat					( )
;

: free-ipnode  ( prev -- )
   delete-after
   dup ipnode free-node
   dup >ip-dghead @ free-dg
   >ip-rangelist @ free-rangelist
;

: free-iplist  ( -- )
   find-ip?  if  free-ipnode  else  drop  then
;

: ip-timeout?  ( node -- flag )
   >ip-timer @ get-msecs <=
;

: process-timeout?  ( -- flag )
   iplist ['] ip-timeout? find-node  if  free-ipnode true  else  drop false  then
;

: update-len  ( node -- )
   ip-fragment xw@ h# 2000 and 0=  if
      ip-length xw@ ihl -
      ip-fragment xw@ h# 1fff and 8 * +
      swap >ip-len !
   else
      drop
   then
;

0 value rlb
0 value rle
0 value last-rl

: create-rangelist  ( -- rl )
   /rangelist alloc-mem		( rl )
   rle over >rl-end !		( rl )
   rlb over >rl-begin !		( rl )
;

: insert-before-rangelist  ( node rl -- )
   create-rangelist >r			( node rl )
   dup r@ >rl-next !			( node rl )
   dup >rl-prev @ dup r@ >rl-prev !	( node rl rl-prev )
   ?dup 0<>  if  >rl-next r@ swap !  then	( node rl )
   r@ over >rl-prev !			( node rl )
   r> -rot				( new node rl )
   over >ip-rangelist @ =  if  >ip-rangelist !  else  2drop  then
;

: insert-endof-rangelist  ( node rl -- )
   create-rangelist		( node rl new )
   0 over >rl-next !		( node rl new )
   2dup >rl-prev !		( node rl new )
   -rot tuck			( new rl node rl )
   0=  if  nip >ip-rangelist !  else  drop >rl-next !  then
;

\ New range = b:e
\ Current node = x:y
\ if e<x-1, add node to front and exit
\ if b>y+1, goto examine next node
\ if b<x, x=b
\ if e>y, y=e and exit
\ if all the nodes have been examined, add node to end and exit
\
: (update-rangelist)  ( ofs len node -- )
   -rot over + 1- to rle to rlb		( node )
   0 to last-rl				( node )
   dup >ip-rangelist @			( node rl )
   begin  ?dup  while
      >r				( node )
      rle r@ >rl-begin @ 1- <  if  r> insert-before-rangelist exit  then
      rlb r@ >rl-end @ 1+ <=  if	( node )
         rlb r@ >rl-begin @ <  if  rlb r@ >rl-begin !  then
         rle r@ >rl-end @ >  if  rle r@ >rl-end !  then
         r> 2drop
         exit
      then
      r@ to last-rl			( node )
      r> >rl-next @			( node rl )
   repeat				( node )
   last-rl insert-endof-rangelist
;

: update-rangelist  ( node -- )
   ip-fragment xw@  h# 1fff and 8 *	( node ofs )
   ip-length xw@  ihl -			( node ofs len )
   rot (update-rangelist)
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

: ip-done?  ( node -- done? )
   dup >ip-len @ 0=  if
      drop false
   else
      >ip-rangelist @ rl-complete?
   then
;

: (reassemble-ip)  ( adr dg -- )
   the-struct >r
   begin  ?dup  while			( adr dg )
      2dup >dg-adr @ set-struct		( adr dg adr )
      ip-fragment xw@ h# 1fff and 8 * +	( adr dg ofs )
      ihl dup				( adr dg ofs ihl ihl )
      ip-length xw@ swap -		( adr dg ofs ihl len )
      swap the-struct + -rot move	( adr dg )
      >dg-next @			( adr dg-next )
   repeat				( adr )
   drop r> set-struct
   reassembled-len ip-length xw!
   0 ip-fragment xw!
   0 ip-checksum xw!
   0 the-struct ihl oc-checksum ip-checksum xw!
;

: reassemble-ip  ( node -- ip-adr,len )
   >r
   r@ >ip-len @ 				( dlen )
   r@ >ip-dg0 @ set-struct ihl tuck +		( ihl rlen )
   dup to reassembled-len			( ihl rlen )
   alloc-mem to reassembled-adr			( ihl )
   r@ >ip-dg0 @ over reassembled-adr swap move	( ihl )
   reassembled-adr dup set-struct +		( content-adr )
   r> >ip-dghead @ (reassemble-ip)		( )
   reassembled-adr reassembled-len		( ip-adr,len )
   free-iplist
;

: process-datagram  ( node -- false | ip-adr,len true)
   dup save-ip			( node )
   dup update-len		( node )
   dup update-rangelist		( node )
   dup ip-done?  if		( node )
      reassemble-ip		( ip-adr,len )
      true			( ip-adr,len true )
   else				( node )
      reset-timer		( )
      false			( false )
   then
;

: process-done-ip  ( -- )
   reassembled-len 0>  if
      reassembled-adr reassembled-len free-mem
      0 to reassembled-adr 0 to reassembled-len
   then
;

: receive-ip-packet  ( type -- true | contents-adr,len false )
   process-done-ip

   begin   
      IP_TYPE receive-ethernet-packet
      if  drop process-timeout? drop true exit  then

      swap  dup set-struct  to last-ip-packet    ( type len )
      ip-addr-match?  if                         ( type len )
         over ip-protocol c@  =  if              ( type len )
            true                                 ( type len true )
         else                                    ( type len )
            ip-payload ip-protocol c@ handle-ip  ( type )
            false                                ( type false )
         then                                    ( type [ len ] flag )
      else                                       ( type len )
         ip-payload handle-other-ip  	         ( type )
         false        \ Discard other's packets  ( type false )
      then                                       ( type [ len ] flag )

      if					 ( type len )
         ip-fragment xw@ h# 3fff and 0=  if
            free-iplist
            true				
         else				
            drop
            find-ip? ?dup  if  nip  else  alloc-ip  then
            process-datagram
            if  swap to last-ip-packet true  else  false  then
         then
      else					 ( type )
         false
      then
      ?dup 0=  if				 ( type )
         process-timeout?  if  drop true exit  then
         false
      then
   until					 ( type len )
			
   nip ip-payload false
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
