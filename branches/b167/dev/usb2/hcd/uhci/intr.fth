purpose: UHCI USB Controller interrupt pipes transaction processing
\ See license at end of file

hex
headers

d# 500 instance value intr-in-timeout

0 instance value intr-in-pipe
0 instance value intr-in-interval

0 instance value intr-in-qh
0 instance value intr-in-td

: intr-in-data@   ( -- n )  intr-in-pipe  target di-in-data@  di-data>td-data  ;
: intr-in-data!   ( n -- )  td-data>di-data intr-in-pipe  target di-in-data!   ;
: toggle-intr-in-data   ( -- )  intr-in-pipe  target di-in-data-toggle   ;

\ Fix up data toggle bit if error OR partially finished Q context.
: fixup-intr-in-data  ( td #td -- )
   usb-error USB_ERR_STALL and  if
      2drop intr-in-pipe h# 80 or unstall-pipe
      0 intr-in-data!
      exit
   then
   0  ?do
      dup >hctd-stat le-l@ TD_STAT_ACTIVE  and  if
         dup >hctd-token le-l@  intr-in-data!
         leave
      then
      >td-next @
   loop  drop
;

: process-intr-args  ( buf len pipe timeout -- )  process-bulk-args  ;
: alloc-intr-qhtds   ( -- qh td )  alloc-bulk-qhtds  ;

: fill-intr-io-tds  ( dir td -- )
   /my-buf over >td-/buf-all l!			( dir td )
   my-#tds 0  ?do				( dir td )
      TD_STAT_ACTIVE TD_CTRL_C_ERR3 or		( dir td stat )
      TD_CTRL_SPD or my-speed or		( dir td stat' )
      over >td-next l@ 0=  if  TD_CTRL_IOC or  then	( dir td stat' )
      over >hctd-stat le-l!			( dir td )
      /my-buf my-maxpayload min dup 1- d# 21 <<	( dir td /buf token )
      intr-in-data@  toggle-intr-in-data or	( dir td /buf token' )
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

: begin-intr-in  ( buf len pipe interval -- )
   debug?  if  ." begin-intr-in" cr  then
   intr-in-qh  if  3drop exit  then		\ Already started

   to intr-in-interval
   dup to intr-in-pipe
   intr-in-timeout process-intr-args
   alloc-intr-qhtds  to intr-in-td  to intr-in-qh

   \ IN TDs
   TD_PID_IN intr-in-td fill-intr-io-tds

   \ Start intr in transaction
   intr-in-qh intr-in-interval insert-intr-qh
;

: intr-in?  ( -- actual usberr )
   intr-in-qh 0=  if  0 USB_ERR_INV_OP exit  then
   clear-usb-error
   process-hc-status
   intr-in-qh dup sync-qhtds
   qh-done?  if
      intr-in-td intr-in-qh >qh-#tds l@ get-actual	( actual )
      usb-error						( actual usberr )
      intr-in-td dup >td-buf l@ swap >td-pbuf l@ 2 pick dma-sync
      intr-in-td intr-in-qh >qh-#tds l@ fixup-intr-in-data
   else
      0 usb-error					( actual usberr )
   then
;

headers
: restart-intr-in-td  ( td -- )
   begin  ?dup  while
      dup >hctd-token dup le-l@ TD_TOKEN_DATA1 invert and
      intr-in-data@  toggle-intr-in-data  or  swap le-l!
      dup >hctd-stat dup le-l@
      TD_STAT_ANY_ERROR TD_ACTUAL_MASK or invert and
      TD_STAT_ACTIVE or swap le-l!
      >td-next l@
   repeat
;

external
: restart-intr-in  ( -- )
   debug?  if  ." restart-intr-in" cr  then
   intr-in-qh 0=  if  exit  then

   \ Setup TD again
   intr-in-td restart-intr-in-td

   \ Setup QH again
   intr-in-td >td-phys l@ intr-in-qh >hcqh-elem le-l!
   intr-in-qh sync-qhtds
;

: end-intr-in  ( -- )
   debug?  if  ." end-intr-in" cr  then
   intr-in-qh 0=  if  exit  then

   intr-in-td intr-in-qh >qh-#tds l@ fixup-intr-in-data
   intr-in-td map-out-buf
   intr-in-qh dup  remove-qh  free-qhtds
   0 to intr-in-qh  0 to intr-in-td
;

headers

: (end-extra)  ( -- )  (end-extra) end-intr-in  ;
' (end-extra) to end-extra


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
