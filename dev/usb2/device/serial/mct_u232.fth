purpose: Magic Control Technology (MCT) Device Driver
\ See license at end of file

headers
hex

4 buffer: mct-buf

: mct-set-line-ctr  ( control -- )
   mct-buf tuck c!
   1 0 0  DR_OUT DR_VENDOR or 7 ( SET_LINE_CTRL_REQUEST ) control-set  drop
;
: mct-set-modem-ctrl  ( control -- )
   mct-buf tuck c!
   1 0 0  DR_OUT DR_VENDOR or d# 10 ( SET_MODEM_CTRL_REQUEST ) control-set  drop
;
: mct-set-baud  ( -- )
   \ 300:1 600:2 1200:3 2400:4 4800:6 9600:8 19200:9 38400:a 57600:b 115200:c
   mct-buf h# c over le-l!			\ 115200 baud rate
   4 0 0  DR_OUT DR_VENDOR or 5 ( SET_BAUD_RATE_REQUEST ) control-set  drop
;
: mct-rts-dtr-off  ( -- )  8     mct-set-modem-ctrl  ;
: mct-rts-dtr-on   ( -- )  h# b  mct-set-modem-ctrl  ;
: mct-inituart  ( -- )
   mct-rts-dtr-on
   3 mct-set-line-ctr		\ 8,n,1
   mct-set-baud
;

: init-mct  ( -- )
   pid h# 230 =  if		\ Sitecom U232-P25 devices can really handle upto 16 bytes
      d# 16 to /bulk-out-pipe
   then
   1 to bulk-in-pipe		\ It masquerade as interrupt in pipe!

   ['] mct-rts-dtr-off to rts-dtr-off
   ['] mct-rts-dtr-on  to rts-dtr-on
   ['] mct-inituart    to inituart
;

: init-mct-hook  ( -- )
   /bulk-out-pipe bulk-out-pipe set-pipe-maxpayload
;

: init  ( -- )
   init
   vid pid uart-mct?  if  init-mct  ['] init-mct-hook to init-hook  then
;


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
