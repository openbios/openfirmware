purpose: Ethernet driver
\ See license at end of file

hex
headers

" ethernet" device-name
" network" device-type

variable opencount 0 opencount !
true value first-open?

headers

: ?make-mac-address-property  ( -- )
   " mac-address"  get-my-property  if
      mac-address encode-bytes " mac-address" property
   else
      2drop
   then
;
: set-frame-size  ( -- )
   " max-frame-size" get-my-property  if   ( )
      max-frame-size encode-int  " max-frame-size" property
   else                                    ( prop$ )
      2drop
   then
;

: init-net  ( -- )
   init-nic
   mac-adr$ encode-bytes  " local-mac-address" property  ( )
;

external

: close  ( -- )
   opencount @ 1-  0 max  opencount !
   opencount @ 0=  if
      end-bulk-in
      stop-nic
      free-buf
   then
;

: open  ( -- ok? )
   my-args  " debug" $=  if  debug-on  then
   device set-target
   opencount @ 0=  if
      init-buf
      first-open?  if
         init-net
         false to first-open?
         ?make-mac-address-property
      then
      link-up? 0=  if
         ." Network not connected." cr
         free-buf
         false exit
      then
      start-nic
      inbuf /inbuf bulk-in-pipe begin-bulk-in
   then
   opencount @ 1+ opencount !
   true
;

: write  ( adr len -- actual )
   swap >r				( len )  ( R: adr )
   /outbuf /mod				( rem #loop )
   r> 0 rot 0  ?do			( rem adr act )
      over outbuf /outbuf move		( rem adr act )
      outbuf /outbuf bulk-out-pipe bulk-out
					( rem adr act usberr )
      if  nip nip exit  then
      /outbuf +				( rem adr act' )
      swap /outbuf + swap		( rem adr' act' )
   loop					( rem adr' act' ) 

   -rot swap				( act adr rem )
   ?dup  if
      tuck outbuf swap move		( act rem )
      outbuf over bulk-out-pipe bulk-out
					( act rem usberr )
      if  drop  else  +  then		( act' )
   else
      drop				( act )
   then
;

: read  ( adr len -- actual )
   \ If a good receive packet is ready, copy it out and return actual length
   \ If a bad packet came in, discard it and return -1
   \ If no packet is currently available, return -2

   bulk-in?  if  nip nip restart-bulk-in exit  then	\ USB error; restart
   ?dup  if				( adr len actual )
      inbuf swap 			( adr len in-adr actual' )
      rot min dup >r			( adr in-adr actual )  ( R: actual )
      rot swap move r>			( actual )
      restart-bulk-in			( actual )
   else
      2drop -2				\ No packet is currently available
   then
;

: load  ( adr -- len )
   " obp-tftp" find-package  if		( adr phandle )
      my-args rot  open-package		( adr ihandle|0 )
   else					( adr )
      0					( adr 0 )
   then					( adr ihandle|0 )

   dup  0=  if  ." Can't open obp-tftp support package" abort  then
					( adr ihandle )

   >r
   " load" r@ $call-method		( len )
   r> close-package
;

: selftest  ( -- flag )
   false
;

: reset  ( -- flag )  reset-nic  ;

headers

: init  ( -- )
   init
   init-buf
   device set-target
   configuration set-config  if  ." Failed to set ethernet configuration" cr  then
   free-buf
;

init

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
