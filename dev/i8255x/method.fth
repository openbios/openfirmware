\ See license at end of file
purpose: Standard methods for the 82559 controller

hex
headers

create mac-adr 0 c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c,
create pms-adr ff c, ff c, ff c, ff c, ff c, ff c,

: max-frame-size  ( -- size )  d# 1500  ;
: set-address  ( adr len -- )
   2 /n* cb-alloc
   cb-buf /cb-hdr + swap move
   cb-cmd-ia cb-eol or cb-buf >cmd le-w!
   cb-go  drop
;
: promiscuous-mode  ( -- )  pms-adr 6 set-address cb-cfg-promiscuous  ;

: 100base?      ( -- 100? )   gstat@ 2 and  ;
: full-duplex?  ( -- full? )  gstat@ 4 and  ;
: link-up?      ( -- up? )    gstat@ 1 and  ;

: start-device  ( -- )  mac-address set-address  cb-cfg-init  ;
: stop-device   ( -- )  port-sel-reset  ;
: global-reset  ( -- )  port-reset  ;

\ The Intel ethernet driver specifies that the eeprom contains
\ a 16-bit checksum in the last (size-1) location, such that
\ the 16-bit sum of all 16-bit eeprom locations is h# baba.
\ First we zero the checksum location, then calculate the correct
\ value and write it back. This routine doesn't affect any
\ values other than the checksum itself.

: set-checksum  ( -- )
   1 /eeprom <<                         ( max )
   0 over 1- eeprom!                    ( max )
   0 over 0 do i eeprom@ + loop         ( max sum )
   h# baba swap - h# ffff and           ( max calc-checksum )
   swap 1- eeprom!
;

external

: get-mac-address  ( -- adr len )	\ Reads the MAC address from the EEPROM
   3 0 do
      i eeprom@			( w )
      wbsplit			( l h )
      mac-adr i 2 * + 1+ c!	( l )
      mac-adr i 2 * + c!	( )
   loop
   mac-adr 6
;

: set-mac-address  ( addr len -- )
   bounds do  i c@  loop
   3 0 do
      bwjoin 2 i - eeprom!
   loop
   set-checksum
;

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

\ String comparision
: $=  ( adr0 len0 adr1 len1 -- equal? )
   2 pick <>  if  3drop false exit  then  ( adr0 len0 adr1 )
   swap comp 0=
;

: .rx-err  ( status -- )
   dup rfd-err-rx and        if  ." Receive error" cr  then
   dup rfd-err-type-len and  if  ." Type/len error" cr  then
   dup rfd-err-short and     if  ." Frame shorter than 64 bytes" cr  then
   dup rfd-err-overrun and   if  ." Overrun: DMA fail to acquire system bus" cr  then
   dup rfd-err-long and      if  ." Frame longer than " /rfd-data .d " bytes" cr  then
   dup rfd-err-align and     if  ." Alignment error" cr  then
   rfd-err-crc and           if  ." CRC error" cr  then
;

external

: close  ( -- )
   stop-device
   free-buffers
   unmap-regs
;

: open  ( -- ok? )
   ?make-mac-address-property
   map-regs
   link-up? 0=  if  ." Network not connected."  unmap-regs false exit  then
   set-frame-size
   init-buffers
   start-device
   my-args  " promiscuous" $=  if  promiscuous-mode  then
   true
;

: write  ( adr len -- actual )
   2dup false dma-map-in tuck
   ?rx-start
   over tx-go  if  dup  else  0  then  >r
   dma-map-out
   r>
;

: read  ( adr len -- actual )
   \ If a good receive packet is ready, copy it out and return actual length
   \ If a bad packet came in, discard it and return -1
   \ If no packet is currently available, return -2

   ?rx-start

   cur-rfd >rfd cur-rfd >rfd-phys /rfd dma-pull
   cur-rfd >rfd >stat le-w@ dup cb-complete and  if
      dup cb-ok and  if
         drop
         cur-rfd >rfd >rfd-actual le-w@ rfd-actual-mask and
         min tuck cur-rfd >rfd >rfd-data -rot move
      else
         .rx-err
         2drop -1
      then
      0 cur-rfd >rfd >stat le-w!
      0 cur-rfd >rfd >rfd-actual le-w!
      cur-rfd >rfd cur-rfd >rfd-phys /rfd dma-push
      cur-rfd+
      ?rx-resume
   else
      3drop -2
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

headers
external

: selftest  ( -- flag )
   false
;

: reset  ( -- flag )  map-regs global-reset unmap-regs ;
\ reset

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
