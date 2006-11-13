purpose: Belkin Device Driver
\ See license at end of file

headers
hex

: belkin-cmd  ( req val -- )
   swap >r >r
   0 0 0 r> h# 40 ( SET_REQUEST_TYPE ) r> control-set drop
;

: belkin-rts-dtr-off  ( -- )
   d# 10 ( SET_DTR_REQUEST ) 0 belkin-cmd
   d# 11 ( SET_RTS_REQUEST ) 0 belkin-cmd
;
: belkin-rts-dtr-on   ( -- )
   d# 10 ( SET_DTR_REQUEST ) 1 belkin-cmd
   d# 11 ( SET_RTS_REQUEST ) 1 belkin-cmd
;

: belkin-set-baud  ( -- )
   belkin-rts-dtr-on
   d# 00 ( SET_BAUDRATE_REQUEST ) d# 230400 d# 9600 / belkin-cmd
   d# 03 ( SET_PARITY_REQUEST ) 0 ( PARITY_NONE ) belkin-cmd
   d# 02 ( SET_DATA_BITS_REQUEST ) 8 5 - belkin-cmd
   d# 01 ( SET_STOP_BITS_REQUEST ) 1 1 - belkin-cmd
   d# 16 ( SET_FLOW_CTRL_REQUEST ) 0 ( FLOW_NONE ) belkin-cmd
;

: belkin-inituart  ( -- )
   belkin-set-baud
;

: init-belkin  ( -- )
   ['] belkin-rts-dtr-off to rts-dtr-off
   ['] belkin-rts-dtr-on  to rts-dtr-on
   ['] belkin-inituart    to inituart
;

: init  ( -- )
   init
   vid pid uart-belkin?  if  init-belkin  then
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
