purpose: EHCI USB Controller intr pipes transaction processing
\ See license at end of file

hex
headers

\ XXX Need to implement periodic interrupt transactions

d# 500 constant intr-in-timeout

0 instance value intr-in-pipe
0 instance value intr-in-interval

0 instance value intr-in-qh
0 instance value intr-in-qtd

: intr-in-data@        ( -- n )  intr-in-pipe  target di-in-data@  di-data>td-data  ;
: intr-in-data!        ( n -- )  td-data>di-data intr-in-pipe  target di-in-data!  ;
: toggle-intr-in-data  ( -- )    intr-in-pipe  target di-in-data-toggle  ;
: fixup-intr-in-data   ( qh -- n )
   usb-error USB_ERR_STALL and  if
      drop intr-in-pipe h# 80 or unstall-pipe
      TD_TOGGLE_DATA0
   else
      >hcqh-overlay >hcqtd-token le-l@
   then
   intr-in-data!
;

: process-intr-args  ( buf len pipe -- )  process-bulk-args  ;
: alloc-intr-qhqtds  ( -- qh qtd )  alloc-bulk-qhqtds  ;
: fill-intr-io-qtds  ( dir qtd -- )
   my-#qtds 0  do				( dir qtd )
      my-buf my-buf-phys /my-buf 3 pick fill-qtd-bptrs
						( dir qtd /bptr )
      2 pick over d# 16 << or			( dir qtd /bptr token )
      TD_C_ERR3 or TD_STAT_ACTIVE or		( dir qtd /bptr token' )
      intr-in-data@  toggle-intr-in-data  or	( dir qtd /bptr token' )
      2 pick >hcqtd-token le-l!			( dir qtd /bptr )
      my-buf++					( dir qtd )
      dup fixup-last-qtd			( dir qtd )
      >qtd-next l@				( dir qtd' )
   loop  2drop					( )
;

external

: begin-intr-in  ( buf len pipe interval -- )
   debug?  if  ." begin-intr-in" cr  then
   intr-in-qh  if  4drop exit  then		\ Already started

   to intr-in-interval
   dup to intr-in-pipe
   process-intr-args
   alloc-intr-qhqtds  to intr-in-qtd  to intr-in-qh
   intr-in-timeout intr-in-qh >qh-timeout l!

   \ IN qTDs
   TD_PID_IN intr-in-qtd fill-intr-io-qtds

   \ Start intr in transaction
   intr-in-qh pt-intr fill-qh
   intr-in-qh my-speed intr-in-interval insert-intr-qh
;

: intr-in?  ( -- actual usberr )
   intr-in-qh 0=  if  0 USB_ERR_INV_OP exit  then  ( )
   clear-usb-error                   ( )
   intr-in-qh qh-done?  if           ( )
      intr-in-qh error?  if          ( )
         0                           ( actual )
      else                           ( )
         intr-in-qh sync-qhqtds      ( )
         intr-in-qtd  intr-in-qh >qh-#qtds l@  get-actual  ( actual )
         intr-in-qtd >qtd-buf  intr-in-qtd >qtd-pbuf l@  2 pick  dma-sync  ( actual )
      then                           ( actual )
      usb-error                      ( actual usberr )
      intr-in-qh fixup-intr-in-data  ( actual usberr )
   else                              ( )
      0 usb-error                    ( actual usberr )
   then                              ( actual usberr )
;

headers
: restart-intr-in-qtd  ( qtd -- )
   begin  ?dup  while
      dup >hcqtd-bptr0 dup le-l@ h# ffff.f000 and swap le-l!
      dup >qtd-/buf l@ d# 16 <<
      TD_STAT_ACTIVE or TD_C_ERR3 or TD_PID_IN or
      intr-in-data@ or 
      over >hcqtd-token le-l!
      >qtd-next l@
   repeat
;

external
: restart-intr-in  ( -- )
   intr-in-qh 0=  if  exit  then

   \ Setup qTD again
   intr-in-qtd restart-intr-in-qtd

   \ Setup QH again
   intr-in-timeout intr-in-qh >qh-timeout l!
   intr-in-qh >hcqh-endp-char dup le-l@ QH_TD_TOGGLE invert and swap le-l!
   intr-in-qtd >qtd-phys l@ intr-in-qh >hcqh-overlay >hcqtd-next le-l!
   intr-in-qh sync-qhqtds
;

: end-intr-in  ( -- )
   debug?  if  ." end-intr-in" cr  then
   intr-in-qh 0=  if  exit  then
   intr-in-qh dup fixup-intr-in-data
   intr-in-qtd map-out-bptrs
   dup remove-intr-qh  free-qh
   0 to intr-in-qh  0 to intr-in-qtd
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
