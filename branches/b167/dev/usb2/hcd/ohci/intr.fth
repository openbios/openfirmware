purpose: OHCI USB Controller interrupt pipes transaction processing
\ See license at end of file

hex
headers

d# 500 constant intr-in-timeout

0 value #intr-in			\ Count of outstanding begin-intr-in

0 instance value intr-in-pipe
0 instance value intr-in-interval

0 instance value intr-in-ed		\ Instance variables for begin-intr-in, intr-in?,
0 instance value intr-in-td		\ restart-intr-in and end-intr-in

: #intr-in++  ( -- )  #intr-in 1+ to #intr-in  ;
: #intr-in--  ( -- )  #intr-in 1- to #intr-in  ;

: disable-periodic  ( -- )  4 hc-cntl-clr  next-frame  ;
: enable-periodic   ( -- )  4 hc-cntl-set  ;

: insert-in-intr  ( ed -- )
   ( ed ) intr-in-interval insert-intr-ed
   enable-periodic
;
: remove-intr  ( ed -- )
   disable-periodic
   ( ed ) remove-intr-ed
   #intr-in  if  enable-periodic  then
;

: intr-in-data@        ( -- n )  intr-in-pipe  target di-in-data@ di-data>ed-data  ;
: intr-in-data!        ( n -- )  ed-data>di-data intr-in-pipe  target di-in-data!  ;
: fixup-intr-in-data   ( ed -- )
   usb-error USB_ERR_STALL and  if
      drop intr-in-pipe h# 80 or unstall-pipe
      ED_TOGGLE_DATA0
   else
      >hced-tdhead le-l@
   then
   intr-in-data!   
;

: process-intr-args  ( buf len pipe timeout -- )  process-bulk-args  ;
: alloc-intr-edtds  ( -- ed td )   alloc-bulk-edtds  ;
: fill-intr-io-tds  ( td -- )      fill-bulk-io-tds  ;
: fill-intr-in-ed  ( ed -- )
   my-dev/pipe my-speed or ED_DIR_IN or ED_SKIP_OFF or ED_FORMAT_G or
   my-maxpayload d# 16 << or
   over >hced-control le-l!
   ( ed ) dup >hced-tdhead le-l@		( ed head )
   intr-in-data@  or				( ed head' )
   over >hced-tdhead le-l!			( ed )
   ( ed ) sync-edtds				( )
;
: remove-my-intr  ( ed -- )  dup remove-intr  free-edtds  ;

external

: begin-intr-in  ( buf len pipe interval -- )
   debug?  if  ." begin-intr-in" cr  then
   intr-in-ed  if  4drop exit  then		\ Already started
   #intr-in++

   to intr-in-interval
   dup to intr-in-pipe
   intr-in-timeout process-intr-args
   alloc-intr-edtds  to intr-in-td  to intr-in-ed

   \ IN TD
   intr-in-td fill-intr-io-tds

   \ Start intr transaction
   intr-in-ed dup fill-intr-in-ed
   insert-in-intr
;

: intr-in?  ( -- actual usberr )
   intr-in-ed 0=  if  0 USB_ERR_INV_OP exit  then
   clear-usb-error				( )
   process-hc-status				( )
   intr-in-ed dup sync-edtds			( ed )
   ed-done?  if					( )
      intr-in-td error?  if
         0					( actual )
      else					( )
	 intr-in-td dup get-actual		( td actual )
         over >td-cbp l@ rot >td-pcbp l@ 2 pick dma-sync	( actual )
      then
      usb-error					( actual usberr )
      intr-in-ed fixup-intr-in-data		( actual usberr )
   else
      0	usb-error				( actual usberr )
   then
;

headers
: restart-intr-in-td  ( td -- )
   begin  ?dup  while
      dup >td-next l@  if
         TD_CC_NOTACCESSED TD_DIR_IN or TD_INTR_OFF or TD_ROUND_ON or
         over >hctd-control le-l!
         dup >td-pcbp l@ over >hctd-cbp le-l!
         dup >td-next l@ >td-phys l@ over >hctd-next le-l!
      then
      >td-next l@
   repeat
;

external
: restart-intr-in  ( -- )
   intr-in-ed 0=  if  exit  then
   intr-in-ed ed-set-skip

   \ Setup TD again
   intr-in-td restart-intr-in-td

   \ Setup ED again
   intr-in-td >td-phys l@ intr-in-data@ or intr-in-ed >hced-tdhead le-l!
   intr-in-ed dup sync-edtds
   ed-unset-skip
;

: end-intr-in  ( -- )
   debug?  if  ." end-intr-in" cr  then
   intr-in-ed 0=  if  exit  then
   #intr-in--
   intr-in-td map-out-cbp
   intr-in-ed remove-my-intr
   0 to intr-in-ed  0 to intr-in-td
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
