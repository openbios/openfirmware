purpose: EHCI USB Controller control pipe transaction processing
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

0 value my-#qtds				\ # of input or output qTDs

0 value my-buf					\ Virtual address of data buffer
0 value my-buf-phys				\ Physical address of data buffer
0 value /my-buf					\ Size of data buffer
0 value my-dir					\ Direction (in or out)

0 value my-qtd					\ Current TD head
0 value my-qh					\ Current QH

: set-real-dev  ( real-dev target -- )		\ For set-address only
   to my-dev to my-real-dev
;
: set-normal-dev   ( -- )			\ Normal operation
   target dup to my-dev to my-real-dev
;
defer set-my-dev		' set-normal-dev to set-my-dev

: set-my-char  ( pipe -- )
   dup 8 << my-dev or to my-dev/pipe		( pipe )
   my-real-dev dup di-speed@  to my-speed	( pipe dev )
   di-maxpayload@  to my-maxpayload		( )
;
: process-control-args  ( buf phy len -- )
   to /my-buf to my-buf-phys to my-buf
   clear-usb-error
   set-my-dev
   0 set-my-char
;

: alloc-control-qhqtds  ( extra-qtds -- )
   >r						( r: extra-qtds )
   my-buf-phys /my-buf cal-#qtd dup to my-#qtds	( #data-qtds r: extra-qtds )
   dup r> + alloc-qhqtds  to my-qtd  to my-qh	( #data-qtds )
   if  data-timeout  else  nodata-timeout  then	( timeout )
   my-qh >qh-timeout l!				( )
;

: fill-qh  ( qh pipetype -- )
   my-speed  dup d# 12 <<			( qh pipetype speed endp-char )
   QH_TD_TOGGLE or my-dev/pipe or		( qh pipetype speed endp-char' )
   swap speed-high =  if			( qh pipetype endp-char' )
      QH_TUNE_RL_HS or				( qh pipetype endp-char' )
      swap  case				( qh endp-char pipetype )
         pt-ctrl  of  QH_MULT1  d#  64  endof	( qh endp-char endp-cap /max )
         pt-bulk  of  QH_MULT1  d# 512  endof	( qh endp-char endp-cap /max )
         ( default )  r> QH_MULT1  my-maxpayload r>
						( qh endp-char endp-cap /max )
      endcase
      d# 16 << rot or swap			( qh endp-char endp-cap )
   else						( qh pipetype endp-char )
      swap pt-ctrl =  if  QH_CTRL_ENDP or  then	( qh endp-char' )
      my-maxpayload d# 16 << or			( qh endp-char' )
      QH_TUNE_RL_TT or				( qh endp-char' )
      QH_MULT1					( qh endp-char endp-cap )
      my-real-dev di-port@ d# 23 << or		( qh endp-char endp-cap' )
      my-real-dev di-hub@ d# 16 << or		( qh endp-char endp-cap' )
   then						( qh endp-char endp-cap )
   2 pick >hcqh-endp-cap le-l!			( qh endp-char )
   swap >hcqh-endp-char le-l!			( )
;

: fill-setup-qtd  ( sbuf sphys slen -- )
   dup d# 16 << TD_TOGGLE_DATA0 or TD_C_ERR3 or TD_PID_SETUP or TD_STAT_ACTIVE or
   my-qtd tuck >hcqtd-token le-l!
   fill-qtd-bptrs  drop
;

: my-buf++  ( len -- )
   /my-buf min				( len' )
   /my-buf     over - to /my-buf	( len )
   my-buf-phys over + to my-buf-phys	( len )
   my-buf      swap + to my-buf		( )
;
: fixup-last-qtd  ( td -- )
   /my-buf  if  drop exit  then
   dup >hcqtd-next le-l@ swap >hcqtd-next-alt le-l!
;
: fill-control-io-qtds  ( dir -- std )
   my-qtd >qtd-next l@				( dir qtd' )
   my-#qtds 0  ?do				( dir qtd )
      my-buf my-buf-phys /my-buf 3 pick fill-qtd-bptrs
						( dir qtd /bptr )
      2 pick over d# 16 << or TD_C_ERR3 or TD_STAT_ACTIVE or
						( dir qtd /bptr token )
      i 1 and  if  TD_TOGGLE_DATA0  else TD_TOGGLE_DATA1  then  or
						( dir qtd /bptr token' )
      2 pick >hcqtd-token le-l!			( dir qtd /bptr )
      my-buf++					( dir qtd )
      dup fixup-last-qtd			( dir qtd )
      >qtd-next l@				( dir qtd' )
   loop  nip					( std )
;


\ ---------------------------------------------------------------------------
\ CONTROL pipe operations
\ ---------------------------------------------------------------------------

: (control-get)  ( sbuf sphy slen buf phy len -- actual usberr )
   process-control-args				( sbuf sphy slen )
   /my-buf 0=  if  3drop 0 USB_ERR_INV_OP exit  then
   2 alloc-control-qhqtds			( sbuf sphy slen )

   \ SETUP TD
   fill-setup-qtd				( )

   \ IN TD
   TD_PID_IN fill-control-io-qtds		( std )

   \ Status TD (OUT)
   TD_TOGGLE_DATA1 TD_C_ERR3 or TD_PID_OUT or TD_STAT_ACTIVE or
   swap >hcqtd-token le-l!			( )

   \ Start control transaction
   my-qh pt-ctrl fill-qh
   my-qh insert-qh

   \ Process results
   my-qh done?  if
      0						( actual )	\ System error, timeout
   else
      my-qh error?  if
         0					( actual )	\ USB error
      else
         my-qtd >qtd-next l@ dup my-#qtds get-actual		( qtd actual )
         over >qtd-buf l@ rot >qtd-pbuf l@ 2 pick dma-sync	( actual )
      then
   then

   my-qh dup remove-qh  free-qhqtds		( actual )
   usb-error					( actual usberr )
;

: run-control  ( -- usberr )
   \ Start control transaction
   my-qh pt-ctrl fill-qh
   my-qh insert-qh

   \ Process results
   my-qh done? 0=  if  my-qh error? drop  then

   my-qh dup remove-qh  free-qhqtds
   usb-error
;

: (control-set)  ( sbuf sphy slen buf phy len -- usberr )
   process-control-args				( sbuf sphy slen )
   2 alloc-control-qhqtds			( sbuf sphy slen )

   \ SETUP TD
   fill-setup-qtd				( )

   \ OUT TD
   TD_PID_OUT fill-control-io-qtds		( std )

   \ Status TD (IN)
   TD_TOGGLE_DATA1 TD_C_ERR3 or TD_PID_IN or TD_STAT_ACTIVE or
   swap >hcqtd-token le-l!			( )

   run-control
;

: (control-set-nostat)  ( sbuf sphy slen buf phy len -- usberr )
   process-control-args				( sbuf sphy slen )
   1 alloc-control-qhqtds			( sbuf sphy slen )

   \ SETUP TD
   fill-setup-qtd				( )

   \ OUT TD
   TD_PID_OUT fill-control-io-qtds drop		( )

   run-control                                  ( usberr )
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
