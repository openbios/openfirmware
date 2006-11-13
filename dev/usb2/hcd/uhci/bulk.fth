purpose: UHCI USB Controller bulk pipes transaction processing
\ See license at end of file

hex
headers

d# 500 instance value bulk-in-timeout
d# 500 constant bulk-out-timeout

0 instance value bulk-in-pipe
0 instance value bulk-out-pipe

0 instance value bulk-in-qh
0 instance value bulk-in-td

: bulk-in-data@   ( -- n )  bulk-in-pipe  target di-in-data@  di-data>td-data  ;
: bulk-out-data@  ( -- n )  bulk-out-pipe target di-out-data@ di-data>td-data  ;
: bulk-in-data!   ( n -- )  td-data>di-data bulk-in-pipe  target di-in-data!   ;
: bulk-out-data!  ( n -- )  td-data>di-data bulk-out-pipe target di-out-data!  ;
: toggle-bulk-in-data   ( -- )  bulk-in-pipe  target di-in-data-toggle   ;
: toggle-bulk-out-data  ( -- )  bulk-out-pipe target di-out-data-toggle  ;

\ Fix up data toggle bit if error OR partially finished Q context.
: fixup-bulk-in-data  ( td #td -- )
   usb-error USB_ERR_STALL and  if
     2drop bulk-in-pipe h# 80 or unstall-pipe
     0 bulk-in-data!
     exit
   then
   0  ?do
      dup >hctd-stat le-l@ TD_STAT_ACTIVE  and  if
         dup >hctd-token le-l@  bulk-in-data!
         leave
      then
      >td-next @
   loop  drop
;
: fixup-bulk-out-data  ( td #td -- )
   usb-error USB_ERR_STALL and  if
     2drop bulk-out-pipe unstall-pipe
     0 bulk-out-data!
     exit
   then
   0  ?do
      dup >hctd-stat le-l@ TD_STAT_ACTIVE  and  if
         dup >hctd-token le-l@  bulk-out-data!
         leave
      then
      >td-next @
   loop  drop
;

: process-bulk-args  ( buf len pipe timeout -- )
   to timeout
   clear-usb-error
   set-my-dev
   ( pipe ) set-my-char
   2dup hcd-map-in  to my-buf-phys to /my-buf to my-buf
;
: alloc-bulk-qhtds  ( -- qh td )
   my-maxpayload /my-buf over round-up swap / dup to my-#tds
   alloc-qhtds
;
: fill-bulk-io-tds  ( dir td -- )
   /my-buf over >td-/buf-all l!			( dir td )
   my-#tds 0  ?do				( dir td )
      TD_STAT_ACTIVE TD_CTRL_C_ERR3 or		( dir td stat )
      TD_CTRL_SPD or my-speed or		( dir td stat' )
      over >td-next l@ 0=  if  TD_CTRL_IOC or  then	( dir td stat' )
      over >hctd-stat le-l!			( dir td )
      /my-buf my-maxpayload min dup 1- d# 21 <<	( dir td /buf token )
      3 pick TD_PID_IN =  if
         bulk-in-data@  toggle-bulk-in-data	( dir td /buf token' )
      else
         bulk-out-data@ toggle-bulk-out-data	( dir td /buf token' )
      then  or
      3 pick or my-dev/pipe or			( dir td /buf token' )
      2 pick >hctd-token le-l!			( dir td /buf )
      my-buf-phys 2 pick 2dup >hctd-buf le-l!	( dir td /buf pbuf td )
      >td-pbuf l!				( dir td /buf )
      my-buf 2 pick >td-buf l!			( dir td /buf )
      my-buf++					( dir td )
      >td-next l@				( dir td' )
   loop  2drop					( )
;

external

: set-bulk-in-timeout  ( t -- )  ?dup  if  to bulk-in-timeout  then  ;

: begin-bulk-in  ( buf len pipe -- )
   debug?  if  ." begin-bulk-in" cr  then
   bulk-in-qh  if  3drop exit  then		\ Already started

   dup to bulk-in-pipe
   bulk-in-timeout process-bulk-args
   alloc-bulk-qhtds  to bulk-in-td  to bulk-in-qh

   \ IN TDs
   TD_PID_IN bulk-in-td fill-bulk-io-tds

   \ Start bulk in transaction
   bulk-in-qh my-speed insert-bulk-qh
;

: bulk-in?  ( -- actual usberr )
   bulk-in-qh 0=  if  0 USB_ERR_INV_OP exit  then
   clear-usb-error
   process-hc-status
   bulk-in-qh dup sync-qhtds
   qh-done?  if
      bulk-in-td bulk-in-qh >qh-#tds l@ get-actual	( actual )
      usb-error						( actual usberr )
      bulk-in-td bulk-in-qh >qh-#tds l@ fixup-bulk-in-data
   else
      bulk-in-qh dup >hcqh-elem le-l@			( qh elem )
      1 ms  over sync-qhtds				( qh elem )
      swap >hcqh-elem le-l@ =  if			\ No movement in the past ms
         bulk-in-td bulk-in-qh >qh-#tds l@ get-actual	( actual )
         usb-error					( actual usberr )
         bulk-in-td bulk-in-qh >qh-#tds l@ fixup-bulk-in-data
      else						\ It may not be done yet
         0 usb-error					( actual usberr )
      then
   then
   over  if
      bulk-in-td dup >td-buf l@ swap >td-pbuf l@ 2 pick dma-sync
   then
;

headers
: restart-bulk-in-td  ( td -- )
   begin  ?dup  while
      dup >hctd-token dup le-l@ TD_TOKEN_DATA1 invert and
      bulk-in-data@  toggle-bulk-in-data  or  swap le-l!
      dup >hctd-stat dup le-l@
      TD_STAT_ANY_ERROR TD_ACTUAL_MASK or invert and
      TD_STAT_ACTIVE or swap le-l!
      >td-next l@
   repeat
;

external
: restart-bulk-in  ( -- )
   debug?  if  ." restart-bulk-in" cr  then
   bulk-in-qh 0=  if  exit  then

   \ Setup TD again
   bulk-in-td restart-bulk-in-td

   \ Setup QH again
   bulk-in-td >td-phys l@ bulk-in-qh >hcqh-elem le-l!
   bulk-in-qh sync-qhtds
;

: end-bulk-in  ( -- )
   debug?  if  ." end-bulk-in" cr  then
   bulk-in-qh 0=  if  exit  then

   bulk-in-td bulk-in-qh >qh-#tds l@ fixup-bulk-in-data
   bulk-in-td map-out-buf
   bulk-in-qh dup  remove-qh  free-qhtds
   0 to bulk-in-qh  0 to bulk-in-td
;

: bulk-in  ( buf len pipe -- actual usberr )
   debug?  if  ." bulk-in" cr  then
   dup to bulk-in-pipe
   bulk-in-timeout process-bulk-args
   alloc-bulk-qhtds  to my-td  to my-qh

   \ IN TDs
   TD_PID_IN my-td fill-bulk-io-tds

   \ Start bulk in transaction
   my-qh my-speed insert-bulk-qh

   \ Process results
   my-qh done?  if
      0						( actual )	\ System error, timeout
   else
      my-td error?  if
         0					( actual )	\ USB error
      else
         my-td dup my-#tds get-actual		( td actual )
	 over >td-buf l@ rot >td-pbuf l@ 2 pick dma-sync	( actual )
      then
   then

   usb-error					( actual usberr )
   my-td my-#tds fixup-bulk-in-data
   my-td map-out-buf
   my-qh dup  remove-qh  free-qhtds
;

: bulk-out  ( buf len pipe -- usberr )
   debug?  if  ." bulk-out" cr  then
   dup to bulk-out-pipe
   bulk-out-timeout process-bulk-args
   alloc-bulk-qhtds  to my-td  to my-qh

   \ OUT TDs
   TD_PID_OUT my-td fill-bulk-io-tds

   \ Start bulk out transaction
   my-qh my-speed insert-bulk-qh

   \ Process results
   my-qh done? 0=  if  my-td error? drop  then

   usb-error					( actual usberr )
   my-td my-#tds fixup-bulk-out-data
   my-td map-out-buf
   my-qh dup  remove-qh  free-qhtds
;

headers

: (end-extra)  ( -- )  end-bulk-in  ;


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
