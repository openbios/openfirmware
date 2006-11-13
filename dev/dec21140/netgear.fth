\ See license at end of file
purpose: NetGear LC82C169 Ethernet FCode driver

hex

" Netgear,LC82C169" model

headers
hex

0 value phyadr

: mii-read  ( reg -- data )
   d# 18 << h# 6002.0000 or phyadr d# 23 << or  a0 e!
   h# ffff  d# 1000 0  do
      a0 e@ dup  h# 8000.0000 and 0=  if  and leave  else  drop  then
   loop
;

: mii-write  ( data reg -- )
   d# 18 << or h# 5002.0000 or phyadr d# 23 << or  a0 e!
   d# 1000 0  do
      a0 e@ h# 8000.0000 and 0=  if  leave  then
   loop
  
;

: phy-present?  ( -- flag )
   h# 20 0  do
      i to phyadr
      2 mii-read  dup h# ffff <>  swap 0<>  and  if  true unloop exit  then
   loop
   0 to phyadr
   false exit
;

external
: tp  ( -- )
   \ This may not be exactly right, but it seems to work ... for now
    ctl e@  h# 4000 or  ctl e!
\   ctl e@  h# 0004.0000 invert and  ctl e!
\   0 csr13 e!					\ SIA reset, 10Base-T
\   0 csr14 e!					\ enable
\   8 csr15 e!					\ enable external transceiver
    ctl e@  h# 0004.0000 or  ctl e!            \ port select, half-duplex
;
: coax  ( -- )
;
: aui  ( -- )
;
: 100bt  ( -- )
   \ XXX implement me
;

headers

: netgear-set-address  ( -- error? )
   make-setup-frame
   tbuf  dup buf>physical  setup-size  " dma-push" $call-parent

   \ Ask the host system for the station address and give it to the adapter
   \ use transmit buffer as setup frame
   setup-size 0800.0000 or end-of-ring or  tdesc 4 + le-l!
   own tdesc le-l!
   tdesc  dup descs - descs-phys + /desc  " dma-push" $call-parent

   \ enable transmitter
   ctl e@  transmit-enable or  ctl e!	\ process setup frame
   d# 1 ms				\ Give chip time to do it
   tdesc  dup descs - descs-phys + /desc  " dma-pull" $call-parent
   tdesc le-l@  h# 7fff.0000 <>
;
' netgear-set-address to set-address

6 buffer: my-mac
: srom@  ( -- n )
   1 ms
   srom e@ dup h# 8000.0000 and  if  ." Ethernet SROM timeout" cr abort  then
   h# ffff and

;
: get-mac  ( -- )
   3 0  do
      h# 600 i + h# 98 e!
      srom@ wbsplit my-mac i 2* + tuck c! 1+ c!
   loop
;

true value xcvr-present?  ( -- present? )

0 value andv	\ Debug
0 value dsdv	\ Debug

0 value hm-timeout
: set-hm-timeout  ( #ms -- )   get-msecs + to hm-timeout  ;
: hm-timeout?  ( -- flag )  get-msecs hm-timeout - 0>=  ;

0 value an-timeout
: set-an-timeout  ( #ms -- )   get-msecs + to an-timeout  ;
: an-timeout?  ( -- flag )  get-msecs an-timeout - 0>=  ;

fload ${BP}/dev/dec21140/transcvr.fth

: set-mac-interface  ( -- )
   \ Select the MII port for half- or full-duplex modes.
   h# 814c.0000
   h# 5 mii-read dup h# 100 and swap c0 and 40 = or   if  h# 200  or  then
   ctl e!
;

: auto-set-interface  ( -- )
   phy-present?  if
      h# 0000.0001 csr15 e!
      h# 0201.b07a h# b8 e!	\ turn off chip autonegotiation
      phy-status-reg@ phy-link-up and 0=  if  setup-mii?  else  0  then
      0=  if  set-mac-interface exit  then
   then
   h# 0042.0000 ctl e!
   h# 0000.0030 csr12 e!
   h# 0001.f078 h# b8 e!
   h# 0201.f078 h# b8 e!
   tp
;
' auto-set-interface to set-interface

: init-netgear  ( -- )
   0 40 my-space + " config-l!" $call-parent	\ exit sleep mode
   map-regs
   ['] get-mac catch 0=  if
      my-mac 6  encode-bytes  " local-mac-address" property  ( mem-adr 6 )
   then
   unmap-regs
;

init-netgear

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
