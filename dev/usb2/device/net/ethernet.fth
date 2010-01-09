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

: stop-net  ( -- )
   stop-nic
   end-bulk-in
   free-buf
;

external

: copy-packet  ( adr len -- len' )
   dup outbuf le-w!  tuck outbuf 2 + swap move  2 +
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
   else
      length-header?  if           ( adr len )
         dup outbuf le-w!          ( adr len )
         tuck outbuf 2 + swap move ( len )
         2 +                       ( len )
      else
         tuck outbuf swap move      ( len )
      then                          ( len )
   then
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
      \ ." Bad length in USB Ethernet" cr
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
   " load" r@ ['] $call-method	catch   ( len false | x x x true )
   r> close-package
   throw
;

: selftest  ( -- flag )
   false
;

: reset  ( -- flag )  reset-nic  ;

headers

\ This loopback test is a reliability improvement.  The AX88772,
\ and perhaps other chips, sometimes loses the first received
\ packet.  That's annoying, as the first packet is often a
\ reply that we care about, thus causing a timeout and retry.
\ We work around that by sending ourselves a few loopback packets
\ until we receive one.  In most cases, the first loopback packet
\ is received correctly, and if not, the second one is okay.
\ We try 5 times just to be safe, exiting as soon as we "win".

0 value scratch-buf
: clear-rx  ( -- )
   d# 200  0  do
      scratch-buf d# 2000 read  -2 =  ?leave
   loop
;   

create test-packet
   h# ff c, h# ff c, h# ff c, h# ff c, h# ff c, h# ff c,  \ Dst - broadcast
   h# 01 c, h# 02 c, h# 03 c, h# 04 c, h# 05 c, h# 06 c,  \ Src - junk
   h# 00 c, h# 00 c,                                      \ Type - junk
   here  h# 40 dup allot erase  \ Junk data
here test-packet - constant /tp

: try-loopback?  ( -- okay? )
   test-packet /tp  write  /tp <>  if  false exit  then
   2 ms
   scratch-buf d# 2000 read  /tp =
;
: loopback-test  ( -- )
   d# 2000 alloc-mem to scratch-buf
   loopback{
      clear-rx
      5 0  do  try-loopback?  ?leave  loop
   }loopback
   scratch-buf d# 2000 free-mem
;

: do-start?  ( -- error? )
   start-nic

   link-up? 0=  if
      ." Network not connected." cr
      stop-nic
      true exit
   then

   init-buf
   inbuf /inbuf bulk-in-pipe begin-bulk-in

   loopback-test

   false
;

external

: close  ( -- )
   opencount @ 1-  0 max  opencount !
   opencount @ 0=  if  stop-net  then
;

: open  ( -- ok? )
   my-args  " debug" $=  if  debug-on  then
   device set-target
   configuration set-config  if
      ." Failed to set configuration" cr
      false exit
   then

   opencount @ 0=  if
      " reset?" $call-parent  if  init-nic  then

      first-open?  if
         false to first-open?
         mac-adr$ encode-bytes  " local-mac-address" property  ( )
         ?make-mac-address-property
      then

      do-start?  if  false exit  then
   then
   opencount @ 1+ opencount !
   true
;

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
