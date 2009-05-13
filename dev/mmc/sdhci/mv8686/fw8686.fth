purpose: Marvel 8686 firmware loader
\ See license at end of file


\ =======================================================================
\ Firmware download data structures
\ =======================================================================

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

: fw-dn-blksz  ( -- blksz )
   h# 10 1 sdio-reg@
   h# 11 1 sdio-reg@  bwjoin
;
: wait-for-fw-dn-blksz  ( -- blksz )
   \ Wait for the first non-zero value
   d# 5000 0  do  fw-dn-blksz dup  ?leave  drop  loop
   dup 0=  if  ." Failed to get firmware download block size" cr  then
;

: fw-download-ok?  ( -- flag )
   false d# 100 0  do
      sdio-scratch@  FIRMWARE_READY =  if  drop true leave  then
      d# 10 ms
   loop
;

: (download-fw)  ( adr len tx-size -- error? )
   to fw-tx-len
   to fw-len to fw-adr
   0 to dn-idx  0 to dn-retry
   begin
      fw-len dn-idx - fw-tx-len min		( len )
      fw-adr dn-idx + outbuf 2 pick move	( len )
      outbuf over sdio-fw! <>  if
         4 3 1 sdio-reg!			\ FN1 CFG = write iomem fail
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
   2dup fw-image-ok? 0=  if  ." Bad WLAN firmware image" cr  true exit  then

   wait-for-fw-dn-blksz
   ?dup 0=  if  ." Failed to get firmware download block size" cr 2drop true exit  then

   sdio-poll-dl-ready 0=  if  ." Helper not ready" cr 3drop true exit  then
   1 invert and (download-fw)  if  true exit  then

   fw-download-ok? 0=  if  true exit  then

   3 4 1 sdio-reg!                 \ Enable host interrupt mask
   false
;

: (download-helper)  ( adr len -- error? )
   to fw-len to fw-adr
   0 to dn-idx
   begin
      sdio-poll-dl-ready 0=  if  true exit  then
      fw-len dn-idx - /fw-tx min		( len )
      dup outbuf le-l!				( len )
      fw-adr dn-idx + outbuf 4 + 2 pick move	( len )
      dn-idx over + to dn-idx                   ( len )
      outbuf swap 4 + sdio-fw! drop		( )
   dn-idx fw-len >=  until
   \ Write last EOF data
   outbuf fw-blksz erase
   outbuf fw-blksz sdio-fw! drop
   false
;

: download-helper  ( adr len -- error? )
   sdio-scratch@ FIRMWARE_READY =  if  " Firmware downloaded" vtype 2drop true exit  then
   2dup fw-image-ok? 0=  if  ." Bad WLAN helper image" cr true exit  then
   (download-helper)
;

: load-8686-fw  ( -- error? )
   wlan-helper find-fw dup  if  ( adr len )
      download-helper  if  true exit  then
   else                         ( adr len )
      2drop                     ( )
   then                         ( )

   wlan-fw find-fw dup  if  ( adr len )
     download-fw            ( error? )
   else                     ( adr len )
     2drop  false           ( error? )
   then                     ( error? )
;
' load-8686-fw to load-all-fw


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
