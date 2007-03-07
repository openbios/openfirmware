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
      first-open?  if
         init-net
         false to first-open?
         ?make-mac-address-property
      then
      link-up? 0=  if
         ." Network not connected." cr
         false exit
      then
      init-buf
      start-nic
      inbuf /inbuf bulk-in-pipe begin-bulk-in
   then
   opencount @ 1+ opencount !
   true
;

: copy-packet  ( adr len -- len' )
   dup multi-packet?  if  4 +  then   ( adr len len' )
   /outbuf >  if  ." USB Ethernet write packet too long" cr  stop-nic abort  then  ( adr len )

   multi-packet?  if       ( adr len )
      dup wbsplit          ( adr len len.low len.high )
      dup outbuf 1+ c!  invert outbuf 3 + c!  ( adr len len.low )
      dup outbuf c!     invert outbuf 2 + c!  ( adr len )
      tuck  outbuf 4 + swap  move             ( len )
      4 +                                     ( len' )
   else                          ( adr len )
      tuck outbuf swap move      ( len )
   then                          ( len )
;

: write  ( adr len -- actual )
   tuck  copy-packet                      ( len len' )
   outbuf swap bulk-out-pipe bulk-out     ( len usberr )
   if  drop -1  then                      ( actual )
;

: even  ( n -- n' )  1+ -2 and  ;

\ The data format is:
\  length.leword  ~length.leword  data  [ pad-to-even ]
: extract-packet  ( -- data-adr len )
   residue 4 <  if  ." Short residue from USB Ethernet" cr stop-nic  abort  then

   pkt-adr dup 4 +  swap >r
   r@ c@     r@ 1+  c@ bwjoin   ( data-adr length )
   r@ 2+ c@  r> 3 + c@ bwjoin   ( data-adr length ~length )
   over + h# ffff <>  if        ( data-adr length )
      ." Bad length in USB Ethernet" cr
      \ We got out of sync so we must discard the entire buffer
      \ Return  data-adr 0
      drop 0
      0 to residue  0 to pkt-adr
      exit
   then                           ( data-adr length )
   2dup even                      ( data-adr length data-adr padded-len )
   tuck +  to pkt-adr             ( data-adr length padded-len )
   residue swap - 4 - to residue  ( data-adr actual )
;

: packet-data  ( -- data-adr data-len )
   \ In multi-packet mode, the device can return multiple packets in
   \ a single USB transaction.  Each packet is preceded by a 32-bit
   \ header containing the packet length and its one's complement.

   multi-packet?  if   \ Extract packet from buffer
      extract-packet                         ( in-adr actual )
   else                \ Buffer contains entire packet
      pkt-adr residue                        ( in-adr actual' )
      0 to residue
   then                                      ( in-adr actual' )
   unwrap-msg                                ( data-adr data-len )
;

: read  ( adr len -- actual )
   \ If a good receive packet is ready, copy it out and return actual length
   \ If a bad packet came in, discard it and return -1
   \ If no packet is currently available, return -2

   residue  0=  if                          ( adr len )
      bulk-in?  if  restart-bulk-in  then   ( adr len actual ) \ USB error; restart 
      to residue                            ( adr len )
      residue 0=  if  2drop -2 exit  then   ( adr len )
      inbuf to pkt-adr
   then

   \ At this point we can be sure that residue is nonzero
   packet-data                             ( adr len  data-adr data-len )
   rot min >r			           ( adr in-adr R: actual )
   swap r@ move  r>			   ( actual )

   residue 0=  if  restart-bulk-in  then  \ Release buffer
;

: load  ( adr -- len )
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

: selftest  ( -- flag )
   false
;

: reset  ( -- flag )  reset-nic  ;

headers

: init  ( -- )
   init
   device set-target
   configuration set-config  if  ." Failed to set ethernet configuration" cr  then
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
