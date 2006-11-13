purpose: OHCI USB Controller transaction processing
\ See license at end of file

hex
headers

: disable-control  ( -- )  10 hc-cntl-clr  next-frame  0 20 ohci-reg!  ;
: enable-control   ( -- )
   ed-control >ed-phys l@ 20 ohci-reg!	\ set HcControlHeadED
   2 hc-cmd!				\ mark TD added in control list
   10 hc-cntl-set  			\ enable control list processing
;

: insert-control  ( ed -- )
   ed-control  if  disable-control  then
   ( ed ) insert-control-ed
   enable-control
;
: remove-control  ( ed -- )
   disable-control
   ( ed ) remove-control-ed
   ed-control  if  enable-control  then
;

\ Local temporary variables (common for control, bulk & interrupt)

\ my-dev and my-real-dev are created here to deal with set-address.
\ Normally my-dev and my-real-dev are both of the value of target.
\ However, during set-address, target=my-dev=0, my-real-dev is the
\ address to be assigned to my-real-dev.  The correct path to get
\ a device's characteristics is via my-real-dev.

0 value my-dev					\ Equals to target
0 value my-real-dev				\ Path to device's characteristics
0 value my-dev/pipe				\ Device/pipe for ED

0 value my-speed				\ Speed of my-real-dev
0 value my-maxpayload				\ Pipe's max payload

0 value my-buf					\ Virtual address of data buffer
0 value my-buf-phys				\ Physical address of data buffer
0 value /my-buf					\ Size of data buffer

0 value my-td					\ Current TD head
0 value my-ed					\ Current ED

: set-real-dev  ( real-dev target -- )		\ For set-address only
   to my-dev to my-real-dev
;
: set-normal-dev   ( -- )			\ Normal operation
   target dup to my-dev to my-real-dev
;
defer set-my-dev		' set-normal-dev to set-my-dev

: set-my-char  ( pipe -- )			\ Set device's characteristics
   dup 7 << my-dev or to my-dev/pipe		( pipe )
   my-real-dev dup di-speed@			( pipe dev speed )
   speed-full =  if  ED_SPEED_FULL  else  ED_SPEED_LO  then  to my-speed
						( pipe dev )
   di-maxpayload@  to my-maxpayload		( )
;
: process-control-args  ( buf phy len -- )
   to /my-buf to my-buf-phys to my-buf
   clear-usb-error
   set-my-dev
   0 set-my-char
;

: alloc-control-edtds  ( extra-tds -- )
   /my-buf  if  1+ data-timeout  else  nodata-timeout  then  to timeout
   alloc-edtds to my-td to my-ed
;

: fill-setup-td  ( sbuf sphy slen control -- )
   TD_CC_NOTACCESSED or TD_DIR_SETUP or TD_INTR_OFF or TD_TOGGLE_USE_LSB0 or
   my-td >hctd-control le-l!
   over + 1-  my-td >hctd-be le-l!
   ( sphy ) my-td 2dup >hctd-cbp le-l!
   ( sphy ) >td-pcbp l!
   ( sbuf ) my-td >td-cbp l!
;

: fill-io-tds  ( td control -- )
   over >hctd-control le-l!
   my-buf over >td-cbp l!
   my-buf-phys over 2dup >hctd-cbp le-l!
   >td-pcbp l!
   my-buf-phys /my-buf + 1- swap >hctd-be le-l!
;
: fill-control-io-tds  ( dir -- std )
   my-td >td-next l@				( dir td )
   /my-buf 0=  if  nip exit  then		( dir td )
   dup rot					( td td dir )
   TD_CC_NOTACCESSED or TD_INTR_OFF or TD_TOGGLE_USE_LSB1 or
						( td td control )
   fill-io-tds					( td )
   >td-next l@					( std )
;

: fill-control-ed  ( ed -- )
   my-dev my-speed or ED_DIR_TD or ED_SKIP_OFF or ED_FORMAT_G or
   my-maxpayload d# 16 << or
   swap >hced-control le-l!
;

: insert-my-control  ( -- )
   my-ed dup fill-control-ed
   dup sync-edtds
   insert-control
;

: remove-my-control  ( -- )
   my-ed dup remove-control
   free-edtds
;


\ ---------------------------------------------------------------------------
\ CONTROL pipe operations
\ ---------------------------------------------------------------------------

: (control-get)  ( sbuf sphy slen buf phy len -- actual usberr )
   process-control-args				( sbuf sphy slen )
   /my-buf 0=  if  3drop 0 USB_ERR_INV_OP exit  then
   3 alloc-control-edtds			( sbuf sphy slen )

   \ SETUP TD
   TD_ROUND_ON fill-setup-td			( )

   \ IN TD
   TD_DIR_IN TD_ROUND_ON or fill-control-io-tds	( std )

   \ Status TD (OUT)
   TD_CC_NOTACCESSED TD_DIR_OUT or TD_INTR_MIN or TD_TOGGLE_USE_LSB1 or
   TD_ROUND_ON or
   swap >hctd-control le-l!			( )

   \ Start control transaction
   insert-my-control				( )

   \ Process results
   my-ed done?  if				( )
      0						( actual )	\ System error, timeout
   else
      my-td error?  if				( )
	 0					( actual )	\ USB error
      else
         my-td >td-next l@ dup get-actual	( td actual )
         over >td-cbp l@ rot >td-pcbp l@ 2 pick dma-sync	( actual )
      then
   then

   remove-my-control				( actual )
   usb-error					( actual usberr )
;

: (control-set)  ( sbuf sphy slen buf phy len -- usberr )
   process-control-args				( sbuf sphy slen )
   3 alloc-control-edtds			( sbuf sphy slen )

   \ SETUP TD
   0 fill-setup-td				( )

   \ OUT TD
   TD_DIR_OUT fill-control-io-tds		( std )

   \ Status TD (IN) 	   			( std )
   TD_CC_NOTACCESSED TD_DIR_IN or TD_INTR_MIN or TD_TOGGLE_USE_LSB1 or
   ( TD_ROUND_ON or )
   swap >hctd-control le-l!			( )

   \ Start control transaction
   insert-my-control

   \ Process results
   my-ed done? 0=  if  my-td error? drop  then

   remove-my-control				( )
   usb-error					( usberr )
;

: (control-set-nostat)  ( sbuf sphy slen buf phy len -- usberr )
   process-control-args				( sbuf sphy slen )
   2 alloc-control-edtds			( sbuf sphy slen )

   \ SETUP TD
   0 fill-setup-td				( )

   \ OUT TD
   TD_DIR_OUT fill-control-io-tds drop		( )

   \ Start control transaction
   insert-my-control				( )

   \ Process results
   my-ed done? 0=  if  my-td error? drop then

   remove-my-control				( )
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
