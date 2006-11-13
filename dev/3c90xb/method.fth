\ See license at end of file
purpose: Standard methods for the 3COM90xB controller

hex
headers

create mac-adr 0 c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c,

false value 100base?
false value full-duplex?

external

: get-mac-address  ( -- adr len )	\ Reads the MAC address from the EEPROM
   4 0 do
      i a + eeprom@		( w )
      wbsplit			( l h )
      mac-adr i 2 * + c!	( l )
      mac-adr i 2 * + 1 + c!	( )
   loop
   mac-adr 6
;

headers

: set-frame-size  ( -- )
   " max-frame-size" get-my-property  if   ( )
      max-frame-size encode-int  " max-frame-size" property
   else                                    ( prop$ )
      2drop
   then
;

: wait-for-auto-neg?  ( -- negotiated? )
   d# 120000 0 do			\ Wait up to two seconds
      auto-neg-status 20 and  if  leave  then
   loop
   auto-neg-status 20 and
;

: auto-negotiated?  ( -- negotiated? )
   wait-for-auto-neg?  if
      auto-neg-ability auto-neg-advert and 5 >> 1f and ?dup  if
         dup 8 and  if
            drop  true to 100base?  true to full-duplex?
         else
         dup 4 and  if
            drop  true to 100base?  false to full-duplex?
         else
         2 and if
            false to 100base?  true to full-duplex?
         else
            false to 100base?  false to full-duplex?
         then then then
      else
         false				\ No common capabilities with link partner
      then
   else
      false				\ XXX Restart auto-neg. If fail again, manual neg.
   then
;

true value first-time?
: start-device  ( -- )
   mac-address  set-address
   upd-phys uplistptr!
   full-duplex?  if  full-duplex  else  half-duplex  then
   4 rx-reset    \ Reset everything but the CSMA/CD core; resetting the
                 \ core makes everything take longer to start up, to the
                 \ extent that the first outgoing packet gets eaten unless
                 \ you wait about 3 seconds for things to settle down.
   rx-disable  5 rx-filter!  rx-enable  int-ack
   0 tx-reset  tx-enable  int-ack
   h# 10 indicate-enable!
   link-beat-enable
   auto-select-on
   uplistptr@ 0=  if  0 to upd-idx upd-phys uplistptr!  then
;

: stop-device  ( -- )
   rx-disable
   tx-disable
   4 rx-reset
;

\ String comparision
: $=  ( adr0 len0 adr1 len1 -- equal? )
   2 pick <>  if  3drop false exit  then  ( adr0 len0 adr1 )
   swap comp 0=
;

external

: close  ( -- )
   stop-device
   unmap-regs
;

: wait-negotiate  ( -- link-ok? )
   0
   d# 5000 0  do                       ( old-status )
      drop auto-neg-status             ( new-status )
      dup  4 and  if  leave  then      ( new-status )
      1 ms
   loop                                ( last-status )
[ifdef] notdef
." AN-status: " dup 5 u.r
."   AN-advert: " auto-neg-advert dup 5 u.r
."   AN-ability: " auto-neg-ability dup 5 u.r
."   intersection: " and 5 u.r cr
\ ."   AN-expansion: " 6 18 mii@ 5 u.r  cr  \ This value doesn't match the docs
[then]
   4 and 0<>
;

: open  ( -- ok? )
   map-regs
\   auto-negotiated?  0=  if  unmap-regs false exit  then
   set-frame-size
   init-buffers
   start-device
   my-args  " promiscuous" $=  if  promiscuous-mode  then
   wait-negotiate  if
      \ For some unknown reason, the chip misses incoming
      \ packets unless you wait a while after starting it
      \ the first time after power is applied.
      first-time?  if  false to first-time?  d# 1500 ms  then
      true
   else  close false  then
;

: write  ( adr len -- actual )
   2dup to /buf to buf
   false dma-map-in to buf-phys

   int-ack			( adr len )	\ Clear interupts

   tx-status@                   ( adr len )
   dup  30 and  if  0 tx-reset  then	\ Reset TX engine if Underrun or Jabber

   \ Re-enable TX engine for underrun, jabber, max collisions, or status ovflow
   h# 3e and  if  tx-clear tx-enable  then

   0                   dpd >dpnextptr        le-l!	\ Setup dpd
   std-dppktstatus     dpd >framestartheader le-l!
   buf-phys            dpd >dnfragaddr       le-l!
   /buf dnfraglast or  dpd >dnfraglen        le-l!

   buf buf-phys /buf dma-sync
   dpd dpd-phys /dpd dma-sync
   dpd-phys dnlistptr!		\ Start download

   d# 2000 0 do
      dnlistptr@ 0=  if  leave  then
      1 ms
   loop
   dnlistptr@  0=  if  /buf  else  0  then

   buf buf-phys /buf dma-map-out
;

: read  ( adr len -- actual )
   \ If a good receive packet is ready, copy it out and return actual length
   \ If a bad packet came in, discard it and return -1
   \ If no packet is currently available, return -2

   int-ack			( adr len )	\ Clear interupts

   find-upload-pkt?  if
      >r
      r@ >upd >uppktstatus le-l@ dup 4.0000 and  if
         drop 2drop -1
      else
         1fff and min
         r@ >upd /upd-header + -rot dup >r move r>
      then
      std-uppktstatus r@ >upd >uppktstatus le-l!
      r@ >upd r> >upd-phys /upd dma-sync
   else
      2drop -2
   then

   uppktstatus@ 2000 and  if  up-unstall  then
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

headers

: receive?  ( -- len | -1:bad | -2:none )
   int-ack
   find-upload-pkt?  if
      >r
      r@ >upd >uppktstatus le-l@                           ( status )
      dup 4.0000 and  if  drop -1  else  1fff and  then    ( length|-1 )

      std-uppktstatus r@ >upd >uppktstatus le-l!  \ Release buffer
      r@ >upd  r> >upd-phys  /upd  dma-sync                ( length|-1 )
   else
      -2
   then

   uppktstatus@ h# 2000 and  if  up-unstall  then
;

[ifdef] notdef
: watch-test  ( -- )
   ." Looking for Ethernet packets." cr
   ." '.' is a good packet.  'X' is a bad packet."  cr
   ." Type any key to stop."  cr
   begin
      receive? dup 0>  if  drop ." ."  else  -1 =  if  ." X"  then then
      key? dup  if  key drop  then
   until
;

: (watch-net)  ( -- )
   map-regs
   set-frame-size
   init-buffers
   start-device
   promiscuous-mode

   watch-test

   stop-device
   unmap-regs
;
[then]

external

: selftest  ( -- flag )		\ See p 9-9 on loopbacks
   false
;

[ifdef] notdef
: watch-net  ( -- )
   selftest  0=  if  (watch-net)  then
;
[then]

: reset  ( -- flag )  map-regs global-reset unmap-regs ;
reset

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
