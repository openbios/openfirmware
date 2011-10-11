purpose: EHCI USB Controller bulk pipes transaction processing
\ See license at end of file

hex
headers

d# 500 instance value bulk-in-timeout
d# 500 constant bulk-out-timeout

0 instance value bulk-in-pipe
0 instance value bulk-out-pipe

8 constant #bulk-qtd-max		\ Preallocated qtds for bulk-qh
					\ Each qtd can transfer upto 0x5000 bytes
0 instance value bulk-qh		\ For bulk-in and bulk-out

0 instance value bulk-in-qh		\ For begin-bulk-in, bulk-in?,...
0 instance value bulk-in-qtd		\ For begin-bulk-in, bulk-in?,...

0 instance value bulk-out-qh		\ For begin-bulk-out-ring ...
0 instance value bulk-out-qtd		\ For begin-bulk-out-ring ...

0 instance value my-bulk-qh             \ Cannot use my-qh because unstall-pipe kills it
0 instance value my-bulk-qtd

: bulk-in-data@         ( -- n )  bulk-in-pipe  target di-in-data@   di-data>td-data  ;
: bulk-out-data@        ( -- n )  bulk-out-pipe target di-out-data@  di-data>td-data  ;
: bulk-in-data!         ( n -- )  td-data>di-data bulk-in-pipe  target di-in-data!   ;
: bulk-out-data!        ( n -- )  td-data>di-data bulk-out-pipe target di-out-data!  ;
: toggle-bulk-in-data   ( -- )    bulk-in-pipe  target di-in-data-toggle   ;
: toggle-bulk-out-data  ( -- )    bulk-out-pipe target di-out-data-toggle  ;

: qtd-fixup-bulk-in-data  ( qtd -- )
   usb-error USB_ERR_STALL and  if
      drop bulk-in-pipe h# 80 or unstall-pipe 
      TD_TOGGLE_DATA0
   else
      >hcqtd-token le-l@
   then
   bulk-in-data!
;
: fixup-bulk-in-data    ( qh -- )  >hcqh-overlay qtd-fixup-bulk-in-data  ;

: fixup-bulk-out-data   ( qh -- )
   usb-error USB_ERR_STALL and  if
      drop bulk-out-pipe unstall-pipe
      TD_TOGGLE_DATA0
   else
      >hcqh-overlay >hcqtd-token le-l@
   then
   bulk-out-data!
;

: set-bulk-vars  ( pipe -- )
   clear-usb-error      ( pipe )
   set-my-dev           ( pipe )
   set-my-char          ( )
;

: process-bulk-args  ( buf len pipe -- )
   set-bulk-vars	( buf len )
   2dup hcd-map-in  to my-buf-phys to /my-buf to my-buf
;

: alloc-bulk-qhqtds  ( -- qh qtd )
   my-buf-phys /my-buf cal-#qtd dup to my-#qtds   ( #qtds )
   alloc-qhqtds      ( qh qtd )
;

: ?alloc-bulk-qhqtds  ( -- qh qtd )
   my-buf-phys /my-buf cal-#qtd dup to my-#qtds   ( #qtds )
   dup #bulk-qtd-max >  if  ." Requested bulk transfer is too big." cr abort  then  ( #qtds )

   bulk-qh 0=  if                                 ( #qtds )
      #bulk-qtd-max alloc-qhqtds drop to bulk-qh  ( )
   then                                           ( #qtds )
   bulk-qh reuse-qhqtds
;
: free-bulk-qh  ( -- )
   bulk-qh ?dup  if                     ( qh )
      free-qh				( )
      0 to bulk-qh
   then
;

: fill-bulk-io-qtds  ( dir qtd -- )
   my-#qtds 0  do				( dir qtd )
      my-buf my-buf-phys /my-buf 3 pick fill-qtd-bptrs
						( dir qtd /bptr )
      \ Setup the token word
      2 pick over d# 16 << or			( dir qtd /bptr token )
      TD_C_ERR3 or TD_STAT_ACTIVE or		( dir qtd /bptr token' )
      3 pick TD_PID_IN =  if			( dir qtd /bptr token' )
         bulk-in-data@  toggle-bulk-in-data
      else
         bulk-out-data@ toggle-bulk-out-data
      then  or					( dir qtd /bptr token' )
      2 pick >hcqtd-token le-l!			( dir qtd /bptr )

      my-buf++					( dir qtd )
      dup fixup-last-qtd			( dir qtd )
      >qtd-next l@				( dir qtd' )
   loop  2drop					( )
;

: more-qtds?  ( qtd -- qtd flag )
   dup >hcqtd-next le-l@		( qtd next )
   over >hcqtd-next-alt le-l@  <>	( qtd more? )
;

: activate-in-ring  ( qtd -- )
   \ Start with the second entry in the ring so the first entry
   \ is the last to be activated, thus deferring host controller
   \ activity until all qtds are active.
   >qtd-next l@  dup				( qtd0 qtd )
   begin					( qtd0 qtd )
      TD_C_ERR3 TD_PID_IN or TD_STAT_ACTIVE or	( qtd0 qtd token )
      over >hcqtd-token le-w!			( qtd0 qtd )
      >qtd-next l@				( qtd0 qtd' )
   2dup = until					( qtd0 qtd' )
   2drop
;

: new-fill-bulk-io-qtds  ( /buf qtd -- )
   swap to /my-buf					( qtd )
   my-buf-phys /my-buf cal-#qtd to my-#qtds		( /buf qtd )
   my-#qtds 0  do					( qtd )
      >r						( r: qtd )
      my-buf my-buf-phys /my-buf r@ fill-qtd-bptrs	( /bptr r: qtd )
      dup r@ >hcqtd-token 2+ le-w!			( /bptr r: qtd )
      my-buf++						( r: qtd )
      r> >qtd-next l@					( qtd' )
   loop  drop						( )
;

\ Attach the qtd transaction chain beginning at "qtd" to "successor-qtd".
: attach-qtds  ( successor-qtd qtd -- )
   begin				( succ qtd )
      \ Test before setting "next-alt"
      more-qtds? >r			( succ qtd r: flag )

      \ Point each next-alt field to the successor
      over >qtd-phys l@			( succ qtd succ-phys )
      over >hcqtd-next-alt le-l!	( succ qtd r: flag )
   r>  while  				( succ qtd )
      >qtd-next l@			( succ qtd' )
   repeat				( succ last-qtd )

   \ Only the final qtd's next field points to the successor
   over >qtd-phys l@  over  >hcqtd-next le-l!	( succ last-qtd )
   >qtd-next l!				( )
;

: alloc-ring-qhqtds  ( buf-pa /buf #bufs -- qh qtd )
   0 swap  0 ?do		( pa /buf #qtds )
      >r 2dup cal-#qtd >r 	( pa /buf r: #qtds this-#qtds )
      tuck + swap		( pa' /buf r: #qtds this-#qtds )
      r> r> +			( pa' /buf #qtds' )
   loop				( pa' /buf #qtds' )
   nip nip  alloc-qhqtds	( qh qtd0 )
;

: unmap&free  ( va pa len -- )
   >r			( va pa r: len )
   over swap		( va va pa r: len )
   r@ hcd-map-out	( va r: len )
   r> dma-free		( )
;
: alloc&map  ( len -- va pa )
   dup dma-alloc	( totlen va )
   dup rot hcd-map-in  	( va pa )
;

\ It would be better to put these fields in the qh extension
\ so we don't need separate ones for in and out.

: free-ring  ( qh -- )
   >r  r@ >qh-buf l@  r@ >qh-buf-pa l@
   r@ >qh-#bufs l@  r> >qh-/buf l@ *
   unmap&free
;

: set-bulk-in-timeout  ( ms -- )   to bulk-in-timeout  ;

: alloc-ring-bufs  ( /buf #bufs qh -- )
   >r
   2dup  r@ >qh-#bufs l!  r@ >qh-/buf l!	( /buf #bufs )
   * alloc&map  r@ >qh-buf-pa l!  r> >qh-buf l!	( )
;
: link-ring  ( qh qtd -- )
   swap >r				( qtd r: qh )
   r@ >qh-buf-pa l@ to my-buf-phys      ( qtd r: qh )
   r@ >qh-buf    l@ to my-buf		( qtd r: qh )
   r@ >qh-/buf   l@ swap		( /buf qtd r: qh )
   r> >qh-#bufs  l@			( /buf qtd #bufs )

   over >r				( /buf qtd #bufs r: qtd0 )

   1-  0  ?do				( /buf qtd )
      2dup new-fill-bulk-io-qtds	( /buf qtd )

      dup  my-#qtds /qtd * +		( /buf qtd next-qtd )
      dup rot attach-qtds		( /buf next-qtd )
   loop					( /buf qtd r: qtd0 )

   tuck new-fill-bulk-io-qtds		( qtd  r: qtd0 )
   r> swap attach-qtds			( )
;

: make-ring  ( /buf #bufs in? -- qh qtd )
   -rot                                         ( in? /buf #bufs )
   2dup * alloc&map				( in? /buf #bufs va pa )
   dup  4 pick 4 pick  alloc-ring-qhqtds	( in? /buf #bufs va pa qh qtd )
   >r >r					( in? /buf #bufs va pa r: qtd qh )
   r@ >qh-buf-pa l!  r@ >qh-buf  l!		( in? /buf #bufs )
   r@ >qh-#bufs  l!  r@ >qh-/buf l!		( in? r: qtd qh )

   r@ pt-bulk fill-qh				( in? r: qtd qh )

   \ Let the QH keep track of the data toggle on an ongoing basis ...
   r@ >hcqh-endp-char dup le-l@ QH_TD_TOGGLE invert and swap le-l!

   \ But we have to initialize it here based on the last state
   r@ >hcqh-overlay >hcqtd-token                ( in? token-adr r: qtd qh )
   dup le-l@                                    ( in? token-adr token-val r: qtd qh )
   rot  if  bulk-in-data@  else  bulk-out-data@  then   ( token-adr token-val toggle r: qtd qh )
   or                                           ( token-adr token-val' r: qtd qh )
   TD_IOC or                                    ( token-adr token-val' r: qtd qh )
   swap le-l!                                   ( r: qtd qh )

   r> r>					( qh qtd )
   2dup link-ring				( qh qtd )
   over insert-qh				( qh qtd )
;

\ Find the last qtd in a chain of qtds for the same transaction.
: transaction-last-qtd  ( qtd -- qtd' )
   begin  more-qtds?  while  >qtd-next l@  repeat	( qtd' )
;

: qtd-successor  ( qtd -- qtd' )  transaction-last-qtd >qtd-next l@  ;

\ Insert the qtd transaction chain "new-qtd" in the circular list
\ after "qtd".  This is safe only if qtd is inactive.
: qtd-insert-after  ( new-qtd qtd -- )
   \ First make qtd's successor new-qtd's successor
   2dup qtd-successor swap attach-qtds	( new-qtd qtd )

   \ Then make new-qtd qtd's successor
   attach-qtds				( )
;

external

0 value bulk-out-pending
: activate-out  ( qtd len -- )
   over to bulk-out-pending	( qtd len )
   over >hcqtd-token		( qtd len token-adr )
   tuck 2+ le-w!		( qtd token-adr )
   TD_C_ERR3  TD_PID_OUT or  TD_STAT_PING or  TD_STAT_ACTIVE or   swap le-w!  ( qtd )
   push-qtd
;

: wait-out  ( qtd -- error? )
   begin  dup qtd-done?  until	( qtd )
   >hcqtd-token c@ h# fc and
;

\ Possible enhancement: pass in a size argument so that a chain of qtds can be
\ allocated, with more total buffer space than can be represented by one qtd.
\ That can get complicated though - if the chain wraps around the ring, the
\ buffer space would be discontiguous.

: get-out-buffer  ( -- qtd buf )
   bulk-out-qtd begin  dup qtd-done?  until	( qtd )
   dup >qtd-next l@ to bulk-out-qtd		( qtd )
   dup >qtd-buf	l@				( qtd buf )
;

: send-out  ( adr len -- qtd )
   >r  get-out-buffer				( adr qtd buf r: len )
   rot swap r@ move				( qtd r: len )
   dup r> activate-out
;

: begin-out-ring  ( /buf #bufs pipe -- )
   debug?  if  ." begin-out-ring" cr  then
   bulk-out-qh  if  3drop exit  then		\ Already started

   dup to bulk-out-pipe				( /buf #bufs pipe )
   set-bulk-vars				( /buf #bufs )

   false make-ring				( qh qtd )
   to bulk-out-qtd  to bulk-out-qh		( )
   bulk-out-timeout bulk-out-qh >qh-timeout l!	( )
;

: begin-in-ring  ( /buf #bufs pipe -- )
   debug?  if  ." begin-bulk-in-ring" cr  then
   bulk-in-qh  if  3drop exit  then		\ Already started

   dup to bulk-in-pipe				( /buf #bufs pipe )
   set-bulk-vars				( /buf #bufs )

   true make-ring				( qh qtd )
   dup activate-in-ring				( qh qtd )
   to bulk-in-qtd  to bulk-in-qh		( )
   bulk-in-timeout bulk-in-qh >qh-timeout l!	( )
;

: bulk-in-ready?  ( -- false | error true |  buf actual 0 true )
   clear-usb-error
   bulk-in-qtd >r
   r@ pull-qtd
   r@ qtd-done?  if				( )
      r@  bulk-in-qh qtd-error? ?dup  0=  if	( )
         r@ >qtd-buf l@				( buf actual )
         r@ qtd-get-actual			( buf actual )
         2dup  r@ >qtd-pbuf l@  swap  dma-pull	( buf actual )
         0					( buf actual 0 )
      then					( error | buf actual 0 )
      true					( ... )
      \ Possibly unnecessary 
      r@ qtd-fixup-bulk-in-data			( ... )

\ XXX Ethernet does not like process-hc-status!
\      process-hc-status
   else						( )
      false				        ( false )
   then						( ... )
   r> drop
;

headers
: recycle-one-qtd  ( qtd -- )
   \ Clear "Current Offset" field in first buffer pointer
   dup >qtd-pbuf l@  over >hcqtd-bptr0 le-l!  ( qtd )

   \ Reset the "token" word which contains various transfer control bits
   dup >qtd-/buf l@ d# 16 <<                       ( qtd token_word )
   TD_STAT_ACTIVE or TD_C_ERR3 or TD_PID_IN or     ( qtd token_word' )

   \ Not doing data toggles here!

   swap >hcqtd-token le-l!
;
: recycle-bulk-in-qtd  ( qtd -- )
   dup
   begin  more-qtds?  while	( qtd0 qtd )
      >qtd-next l@		( qtd0 qtd' )
      dup recycle-one-qtd	( qtd0 qtd )
   repeat			( qtd0 qtd )

   \ Recycle the first qtd last so the transaction is atomic WRT the HC
   drop dup recycle-one-qtd	( qtd0 )
   push-qtds
;

\ Fixup the host-controller-writable fields in the chain of qTDs -
\ current offset, bytes_to_transfer, and status
: restart-bulk-in-qtd  ( qtd -- )
   begin					   ( qtd )
      \ Clear "Current Offset" field in first buffer pointer
      dup >hcqtd-bptr0 dup le-l@ h# ffff.f000 and swap le-l!  ( qtd )

      \ Reset the "token" word which contains various transfer control bits
      dup >qtd-/buf l@ d# 16 <<                    ( qtd token_word )
      TD_STAT_ACTIVE or TD_C_ERR3 or TD_PID_IN or  ( qtd token_word' )

      \ We need not adjust the data toggle here, as the controller handles
      \ it automatically while the queue is active.  We set it initially
      \ when creating the the queue head, and save it for later after
      \ detaching the queue head.

      over >hcqtd-token le-l!                      ( qtd )
   more-qtds?   while				   ( qtd )
      >qtd-next l@                                 ( qtd' )
   repeat					   ( qtd )
   drop
;

external
\ Wait for the hardware next pointer to catch up with the software pointer.
: drain-bulk-out  ( -- )
   debug?  if  ." drain-bulk-out" cr  then
   bulk-out-qtd >qtd-phys l@	( qtd-pa )
   bulk-out-qh >hcqh-overlay >hcqtd-next	( qtd-pa 'qh-next )
   begin  2dup le-l@ =  until   ( qtd-pa 'qh-next )
   2drop
;

: end-out-ring  ( -- )
   debug?  if  ." end-out-ring" cr  then
   bulk-out-qh 0=  if  exit  then
   drain-bulk-out

   bulk-out-qh remove-qh
   bulk-out-qh free-ring
   bulk-out-qh free-qh
   
   0 to bulk-out-qh  0 to bulk-out-qtd
;

: end-bulk-in  ( -- )
   debug?  if  ." end-bulk-in" cr  then
   bulk-in-qh 0=  if  exit  then

   bulk-in-qh remove-qh
   bulk-in-qh fixup-bulk-in-data
   bulk-in-qh free-ring
   bulk-in-qh free-qh
   
   0 to bulk-in-qh  0 to bulk-in-qtd
;

0 instance value app-buf

: begin-bulk-in  ( buf len pipe -- )
   rot to app-buf
   h# 20 swap begin-in-ring
;

: bulk-in?  ( -- actual usberr )
   bulk-in-ready?  if		( usberr | buf actual 0 )
      ?dup  if			( usberr )
         0 swap			( actual usberr )
      else			( buf actual )
         tuck			( actual buf actual )
         app-buf swap move	( actual )
         0			( actual usberr )
      then                      ( actual usberr )
   else				( )
      0 0			( actual usberr )
   then
;

: restart-bulk-in  ( -- )
   debug?  if  ." recycle buffer" cr  then
   bulk-in-qh 0=  if  exit  then

   \ Setup qTD again
   bulk-in-qtd recycle-bulk-in-qtd

   bulk-in-qtd qtd-successor to bulk-in-qtd
;

: bulk-read?  ( -- [ buf ] actual )
   bulk-in?  if  restart-bulk-in  -1 exit  then    ( actual )
   dup 0=  if  drop -2 exit  then                  ( actual )
   bulk-in-qtd >qtd-buf l@ swap                    ( buf actual )
;

: recycle-buffer restart-bulk-in ;

: start-bulk-transaction  ( pid -- )
   my-bulk-qtd fill-bulk-io-qtds	( )
   my-bulk-qh pt-bulk fill-qh		( )
   my-bulk-qh interrupt-on-last-td      ( )
   my-bulk-qh insert-qh			( )
;
: bulk-in  ( buf len pipe -- actual usberr )
   debug?  if  ." bulk-in" cr  then
   dup to bulk-in-pipe
   process-bulk-args
   ?alloc-bulk-qhqtds  to my-bulk-qtd  to  my-bulk-qh
   bulk-in-timeout my-bulk-qh >qh-timeout l!

   \ IN qTDs
   TD_PID_IN start-bulk-transaction		( )

   \ Process results
   my-bulk-qh done-error?  if			( )		\ System error, timeout, or USB error
      0						( actual )	
   else						( )
      my-bulk-qtd dup my-#qtds get-actual	( qtd actual )
      over >qtd-buf l@ rot >qtd-pbuf l@ 2 pick dma-pull	( actual )
   then						( actual )

   usb-error					( actual usberr )
   my-bulk-qtd map-out-bptrs			( actual usberr )
   my-bulk-qh dup fixup-bulk-in-data		( actual usberr qh )
   remove-qh					( actual usberr )
;

0 instance value bulk-out-busy?
: done-bulk-out  ( -- error? )
   \ Process results
   my-bulk-qh done-error?		( usberr )
   my-bulk-qtd map-out-bptrs		( usberr )
   my-bulk-qh fixup-bulk-out-data	( usberr )
   my-bulk-qh remove-qh			( usberr )
   false to bulk-out-busy?		( usberr )
;
: start-bulk-out  ( buf len pipe -- usberr )
   bulk-out-busy?  if			( buf len pipe )
      done-bulk-out  ?dup  if   nip nip nip exit  then
   then					( buf len pipe )

   debug?  if  ." bulk-out" cr  then
   dup to bulk-out-pipe			( buf len pipe )
   process-bulk-args			( )
   ?alloc-bulk-qhqtds  to my-bulk-qtd  to my-bulk-qh	( )
   bulk-out-timeout my-bulk-qh >qh-timeout l!		( )
   my-bulk-qh >hcqh-overlay >hcqtd-token dup le-l@ TD_STAT_PING or swap le-l!

   \ OUT qTDs
   TD_PID_OUT start-bulk-transaction	( )
   true to bulk-out-busy?		( )
   0					( usberr )
;
: bulk-out  ( buf len pipe -- usberr )
   start-bulk-out drop done-bulk-out
;

headers

: (end-extra)  ( -- )  end-bulk-in free-bulk-qh  ;


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
