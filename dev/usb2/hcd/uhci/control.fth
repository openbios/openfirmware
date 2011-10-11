purpose: UHCI USB Controller control pipe transaction processing
\ See license at end of file

hex
headers

\ Local temporary variables (common for control, bulk & interrupt)

\ my-dev and my-real-dev are created here to deal with set-address.
\ Normally my-dev and my-real-dev are both of the value of target.
\ However, during set-address, target=my-dev=0, my-real-dev is the
\ address to be assigned to my-real-dev.  The correct path to get
\ a device's characteristics is via my-real-dev.

0 value my-dev					\ Equals to target
0 value my-real-dev				\ Path to dev's characteristics
0 value my-dev/pipe				\ Device/pipe for ED

0 value my-speed				\ Speed of my-real-dev
0 value my-maxpayload				\ Pipe's max payload

0 value my-#tds					\ # of input or output qTDs

0 value my-buf					\ Virtual address of data buffer
0 value my-buf-phys				\ Physical address of data buffer
0 value /my-buf					\ Size of data buffer

0 value my-td					\ Current TD head
0 value my-qh					\ Current QH

: set-real-dev  ( real-dev target -- )		\ For set-address only
   to my-dev to my-real-dev
;
: set-normal-dev   ( -- )			\ Normal operation
   target dup to my-dev to my-real-dev
;
defer set-my-dev		' set-normal-dev to set-my-dev

: set-my-char  ( pipe -- )
   dup d# 15 << my-dev 8 << or to my-dev/pipe	( pipe )
   my-real-dev dup di-speed@			( pipe dev speed )
   speed-low =  if  TD_CTRL_LOW  else  TD_CTRL_FULL  then  to my-speed
   di-maxpayload@  to my-maxpayload		( )
;
: process-control-args  ( buf phy len -- )
   to /my-buf to my-buf-phys to my-buf
   clear-usb-error
   set-my-dev
   0 set-my-char
;

: alloc-control-qhtds  ( extra-tds -- )
   >r
   my-maxpayload /my-buf    ( maxpayload /buf )
   over round-up            ( maxpayload /buf-rounded )
   swap /  dup to my-#tds   ( maxpayload #tds )
   dup  if  data-timeout  else  nodata-timeout  then  to timeout  ( maxpayload #tds )
   r> + alloc-qhtds  to my-td  to my-qh
;

: fill-setup-td  ( sbuf sphy slen -- )
   TD_STAT_ACTIVE TD_CTRL_C_ERR3 or my-speed or
   my-td >hctd-stat le-l!
   ( slen ) 1- d# 21 << TD_PID_SETUP or my-dev/pipe or
   my-td >hctd-token le-l!
   ( sphy ) my-td 2dup >hctd-buf le-l!
   >td-pbuf l!
   ( sbuf ) my-td >td-buf l!
;
: my-buf++ ( len -- )
   /my-buf     over - to /my-buf
   my-buf-phys over + to my-buf-phys
   my-buf      swap + to my-buf
;
: fill-control-io-tds  ( dir -- std )
   my-td >td-next l@				( dir td )
   my-#tds 0  ?do				( dir td )
      TD_STAT_ACTIVE TD_CTRL_C_ERR3 or		( dir td stat )
      my-speed or				( dir td stat' )
      over >hctd-stat le-l!			( dir td )
      /my-buf my-maxpayload min dup 1- d# 21 <<	( dir td /buf token )
      i 1 and 0=  if  TD_TOKEN_DATA1 or  then   ( dir td /buf token' )
      3 pick or my-dev/pipe or			( dir td /buf token' )
      2 pick >hctd-token le-l!			( dir td /buf )
      my-buf-phys 2 pick 2dup >hctd-buf le-l!	( dir td /buf pbuf td )
      >td-pbuf l!				( dir td /buf )
      my-buf 2 pick >td-buf l!			( dir td /buf )
      my-buf++					( dir td )
      >td-next l@				( dir td' )
   loop	 nip					( std )
;
: fill-status-td  ( std control -- )
   TD_NULL_DATA_SIZE d# 21 << or TD_TOKEN_DATA1 or
   my-dev/pipe or  over >hctd-token le-l!
   TD_STAT_ACTIVE TD_CTRL_IOC or my-speed or
   swap >hctd-stat le-l!
;

\ ---------------------------------------------------------------------------
\ CONTROL pipe operations
\ ---------------------------------------------------------------------------

: (control-get)  ( sbuf sphy slen buf phy len -- actual usberr )
   process-control-args				( sbuf sphy slen )
   /my-buf 0=  if  3drop 0 USB_ERR_INV_OP exit  then
   2 alloc-control-qhtds			( sbuf sphy slen )

   \ SETUP TD
   fill-setup-td				( )

   \ IN TD
   TD_PID_IN fill-control-io-tds		( std )

   \ Status TD (OUT)
   TD_PID_OUT fill-status-td			( )

   \ Start control transaction
   my-qh my-speed insert-ctrl-qh		( )

   \ Process results
   my-qh done?  if
      0						( actual )	\ System error, timeout
   else
      my-td error?  if
         0					( actual )	\ USB error
      else
         my-td >td-next l@ dup my-#tds get-actual		( td actual )
         over >td-buf l@ rot >td-pbuf l@ 2 pick dma-pull	( actual )
      then
   then

   my-qh dup remove-qh  free-qhtds		( actual )
   usb-error					( actual usberr )
;

: (control-set)  ( sbuf sphy slen buf phy len -- usberr )
   process-control-args				( sbuf sphy slen )
   2 alloc-control-qhtds			( sbuf sphy slen )

   \ SETUP TD
   fill-setup-td				( )

   \ OUT TD
   TD_PID_OUT fill-control-io-tds		( std )

   \ Status TD (IN)
   TD_PID_IN fill-status-td			( )

   \ Start control transaction
   my-qh my-speed insert-ctrl-qh

   \ Process results
   my-qh done? 0=  if   my-td error? drop  then

   my-qh dup remove-qh  free-qhtds
   usb-error					( usberr )
;

: (control-set-nostat)  ( sbuf sphy slen buf phy len -- usberr )
   process-control-args				( sbuf sphy slen )
   1 alloc-control-qhtds			( sbuf sphy slen )

   \ SETUP TD
   fill-setup-td				( )

   \ OUT TD
   TD_PID_OUT fill-control-io-tds drop		( )

   \ Start control transaction
   my-qh my-speed insert-ctrl-qh

   \ Process results
   my-qh done? 0=  if   my-td error? drop  then

   my-qh dup remove-qh  free-qhtds
   usb-error					( usberr )
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
