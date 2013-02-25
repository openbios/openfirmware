purpose: Wireless ethernet driver
\ See license at end of file

hex
headers

" wlan" device-name
" wireless-network" device-type

variable opencount 0 opencount !

headers

: ?make-mac-address-property  ( -- )
   driver-state ds-ready <  if  exit  then
   " mac-address"  get-my-property  if
      mac-adr$ encode-bytes  " local-mac-address" property
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
   marvel-get-mac-address
   ?make-mac-address-property
;

: ?load-fw  ( -- error? )
   driver-state ds-not-ready =  if
      load-all-fw  if
         ." Failed to download firmware" cr
         true exit
      then
      ds-ready to driver-state
   then
   init-net
   false
;

false instance value use-promiscuous?

external

\ Set to true to force open the driver without association.
\ Designed for use by application to update the Marvel firmware only.
\ Normal operation should have force-open? be false.
false instance value force-open?
				
: parse-args  ( $ -- )
   false to use-promiscuous?
   begin  ?dup  while
      ascii , left-parse-string
      2dup " debug" $=  if  debug-on  then
      2dup " promiscuous" $=  if  true to use-promiscuous?  then
           " force" $=  if  true to force-open?  then
   repeat drop
;

: open  ( -- ok? )
   my-args parse-args
   set-parent-channel
   opencount @ 0=  if
      reset?  if
         configuration set-config  if
            ." Failed to set USB configuration for wireless" cr
            false exit
         then
         bulk-in-pipe bulk-out-pipe reset-bulk-toggles
      then
      init-buf
      /inbuf /outbuf setup-bus-io  if  free-buf false exit  then
      ?load-fw  if  release-bus-resources free-buf false exit  then
      my-args " supplicant" $open-package to supplicant-ih
      supplicant-ih 0=  if  release-bus-resources free-buf false exit  then
      nonce-cmd
      force-open?  0=  if
         link-up? 0=  if
            ['] 2drop to ?process-eapol
            do-associate 0=  if  free-buf false exit  then
            ds-disconnected reset-driver-state
            ds-associated set-driver-state
            ['] do-process-eapol to ?process-eapol
         then
         start-nic
      then
   then
   force-open?  0=  if
      use-promiscuous?  if  enable-promiscuous  else  disable-promiscuous  then
   then
   opencount @ 1+ opencount !
   true
;

: close  ( -- )
   opencount @ 1-  0 max  opencount !
   opencount @ 0=  if
      disable-multicast
      mesh-stop drop
      link-up?  if  target-mac$ deauthenticate  then
      ['] 2drop to ?process-eapol
      stop-nic
      mac-off
      supplicant-ih ?dup  if  close-package 0 to supplicant-ih  then
      release-bus-resources
   then
;

\ Read and write ethernet messages regardless of the associate state.
\ Used by the /supplicant support package to perform key handshaking.
: write-force  ( adr len -- actual )
   tuck					( actual adr len )
   wrap-msg				( actual adr' len' )
   data-out                             ( actual )
;

: read-force  ( adr len -- actual )
   got-packet?  0=  if  		( adr len )
      2drop  -2  exit
   then                                 ( adr len [ error | buf actual type 0 ] )

   if	\ receive error			( adr len )
      recycle-packet			( adr len )
      2drop  -1  exit
   then					( adr len buf actual type )

   false to got-data?			( adr len buf actual type )
   process-rx				( adr len )
   recycle-packet			( adr len )

   got-data?  if			( adr len )
      /data min tuck data -rot move	( actual )
   else					( adr len )
      2drop -2				\ No data
   then					( actual )

;

\ Normal read and write methods.
: write  ( adr len -- actual )
   link-up? 0=  if  2drop 0 exit  then	\ Not associated yet.
   ?reassociate				\ In case if the connection is dropped
   write-force
;
: read  ( adr len -- actual )
   \ If a good receive packet is ready, copy it out and return actual length
   \ If a bad packet came in, discard it and return -1
   \ If no packet is currently available, return -2

   link-up? 0=  if  2drop 0 exit  then	\ Not associated yet.
   ?reassociate				\ In case if the connection is dropped
   read-force
;

: load  ( adr -- len )
   link-up? 0=  if  drop 0 exit  then	\ Not associated yet.

   " obp-tftp" find-package  if		( adr phandle )
      my-args rot  open-package		( adr ihandle|0 )
   else					( adr )
      0					( adr 0 )
   then					( adr ihandle|0 )

   dup  0=  if  ." Can't open obp-tftp support package" stop-nic abort  then
					( adr ihandle )

   >r
   " load" r@ $call-method		( len )
   r> close-package
;

: reset  ( -- flag )  reset-nic  ;

: (scan-wifi)  ( -- error? )
   true to force-open?
   open
   false to force-open?
   0=  if  ." Can't open Marvell wireless" cr true close  exit  then

   (scan)  if
      ." Failed to scan" true cr
   else    ( adr len )
      drop .scan false
   then

   close
;

: scan-wifi  ( -- )  (scan-wifi) drop  ;

: selftest  ( -- error? )  (scan-wifi)  ;

headers

\ LICENSE_BEGIN
\ Copyright (c) 2007 FirmWorks
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
