purpose: Marvel SDIO WLAN module firmware loader
\ See license at end of file


\ =======================================================================
\ Firmware download data structures
\ =======================================================================

0 value fw-buf

h# fedc constant FIRMWARE_READY

fw-blksz 2 * 4 - constant /fw-tx


\ =========================================================================
\ Firmware Download
\ =========================================================================

0 value dn-idx
0 value fw-len
0 value fw-adr
0 value fw-tx-len
0 value dn-retry

: fw-dn-blksz  ( -- blksz )  host-f1-rd-base-0-reg sdio-w@  ;
: wait-for-fw-dn-blksz  ( -- blksz )
   \ Wait for the first non-zero value
   d# 5000 0  do  fw-dn-blksz dup  ?leave  drop  loop
   dup 0=  if  ." Failed to get firmware download block size" cr  then
;

: fw-download-ok?  ( -- flag )
   false d# 100 0  do
      sdio-fw-status@  FIRMWARE_READY =  if  drop true leave  then
      d# 10 ms
   loop
;

: (download-fw)  ( adr len tx-size -- error? )
   to fw-tx-len
   to fw-len to fw-adr
   0 to dn-idx  0 to dn-retry
   begin
      fw-len dn-idx - fw-tx-len min		( len )
      fw-adr dn-idx + fw-buf 2 pick move	( len )
      fw-buf over sdio-fw! <>  if
         4 config-reg sdio-b!		\ FN1 CFG = write iomem fail
      then
      sdio-poll-dl-ready 0=  if  ." Download fw died" cr true exit  then
      fw-dn-blksz ?dup 0=  if  false exit  then
      dup 1 and  if
         dn-retry 1+ dup to dn-retry
         2 >  if  ." Retry fail" cr true exit  then
      else
         0 to dn-retry
         dn-idx fw-tx-len + to dn-idx
      then
      1 invert and to fw-tx-len
   dn-idx fw-len >=  until
   false
;

: fw-image-ok?  ( adr len -- flag )  2drop true  ;

: download-fw  ( adr len -- error? )
   2dup fw-image-ok? 0=  if  ." Bad WLAN firmware image" cr  true exit  then  ( adr len )

   wait-for-fw-dn-blksz
   ?dup 0=  if  ." Failed to get firmware download block size" cr 2drop true exit  then

   sdio-poll-dl-ready 0=  if  ." Helper not ready" cr 3drop true exit  then
   1 invert and (download-fw)  if  true exit  then

   fw-download-ok? 0=  if  true exit  then

   mv8787?  if
      2 config-reg sdio-b!             \ Host power up
   then
   false
;

: (download-helper)  ( adr len -- error? )
   to fw-len to fw-adr
   0 to dn-idx
   begin
      sdio-poll-dl-ready 0=  if  true exit  then
      fw-len dn-idx - /fw-tx min		( len )
      dup fw-buf le-l!				( len )
      fw-adr dn-idx + fw-buf 4 + 2 pick move	( len )
      dn-idx over + to dn-idx                   ( len )
      fw-buf swap 4 + sdio-fw! drop		( )
   dn-idx fw-len >=  until
   \ Write last EOF data
   fw-buf fw-blksz erase
   fw-buf fw-blksz sdio-fw! drop
   false
;

: download-helper  ( adr len -- error? )
   sdio-fw-status@ FIRMWARE_READY =  if  " Firmware downloaded" vtype 2drop true exit  then
   2dup fw-image-ok? 0=  if  ." Bad WLAN helper image" cr true exit  then
   (download-helper)
;

: free-fw-buf  ( -- )  fw-buf d# 2048 dma-free  ;
: load-all-fw  ( -- error? )
   d# 2048 dma-alloc to fw-buf
   helper?  if
      wlan-helper find-fw dup  if  ( adr len )
         2dup download-helper      ( adr len error? )
         -rot free-mem             ( error? )
	 if  free-fw-buf true exit  then       ( )
      else                         ( adr len )
         2drop                     ( )
      then                         ( )
   then

   wlan-fw find-fw dup  if  ( adr len )
      2dup download-fw      ( adr len error? )
      -rot free-mem         ( error? )
   else                     ( adr len )
      2drop  true           ( error? )
   then                     ( error? )
   free-fw-buf              ( error? )
;

false value fw-active?
: set-address  ( function# -- )
   init-function
   fw-active? 0=  if
      load-all-fw  if
         ." Marvell WLAN module firmware load failed" cr
         abort
      then
      true to fw-active?
   then
   mv8787?  if
      card-rx-unit-reg sdio-b@ to rx-shift
   then
;
: reset-host-bus  ( -- )  " wlan-reset" evaluate  false to fw-active?  ;

0 value open-count
: open  ( -- flag )
   set-parent-channel
   open-count  if
      true
   else
      setup-bus-io  0=
   then  ( okay? )
   dup  if  open-count 1+ to open-count  then
;
: close  ( -- )
   open-count 1 =  if  false to fw-active?  then
   open-count 1-  0 max  to open-count
;

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
