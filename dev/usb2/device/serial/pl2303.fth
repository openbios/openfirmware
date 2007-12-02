purpose: PL2303 Device Driver
\ See license at end of file

headers
hex

7 buffer: pl2303-buf

: pl2303-get-line  ( -- )
   pl2303-buf 7 0 0 DR_IN DR_HIDD or 21 ( GET_LINE_REQUEST ) control-get  2drop
;
: pl2303-set-line  ( -- )
   pl2303-buf 7 0 0 DR_OUT DR_HIDD or 20 ( SET_LINE_REQUEST ) control-set  drop
;

: pl2303-vendor-read  ( adr len idx value -- )
   DR_IN DR_VENDOR or 1 ( VENDOR_READ_REQUEST ) control-get  2drop
;

: pl2303-vendor-write  ( adr len idx value -- )
   DR_OUT DR_VENDOR or 1 ( VENDOR_WRITE_REQUEST ) control-set  drop
;

: pl2303-set-control  ( control -- )
   \ SET_CONTROL_REQUEST
   >r 0 0 0 r> DR_OUT DR_HIDD or 22 ( SET_CONTROL_REQUEST ) control-set  drop
;
: pl2303-rts-dtr-off  ( -- )  0 pl2303-set-control  ;
: pl2303-rts-dtr-on   ( -- )  3 pl2303-set-control  ;

: pl2303-set-baud  ( -- )
   pl2303-get-line

   0 0 1 0 pl2303-vendor-write

   d# 115200 pl2303-buf le-l!	\ Baud rate = 115200
   0 pl2303-buf 4 ca+ c!	\ # stop bits = 1 (0=1, 1=1.5, 2=2)
   0 pl2303-buf 5 ca+ c!	\ parity = none
				\ (0=none, 1=odd, 2=even, 3=mark, 4=space)
   8 pl2303-buf 6 ca+ c!	\ # data bits = 8 (5, 6, 7, 8)
   pl2303-set-line

   pl2303-get-line
;

: pl2303-inituart  ( -- )
   pl2303-buf 1 00 8484 pl2303-vendor-read
   0          0 00 0404 pl2303-vendor-write
   pl2303-buf 1 00 8484 pl2303-vendor-read
   pl2303-buf 1 00 8383 pl2303-vendor-read
   pl2303-buf 1 00 8484 pl2303-vendor-read
   0          0 01 0404 pl2303-vendor-write
   pl2303-buf 1 00 8484 pl2303-vendor-read
   pl2303-buf 1 00 8383 pl2303-vendor-read
   0          0 01 0000 pl2303-vendor-write
   0          0 c0 0001 pl2303-vendor-write
   0          0 04 0002 pl2303-vendor-write
   pl2303-set-baud
;

: init-pl2303  ( -- )
   ['] pl2303-rts-dtr-off to rts-dtr-off
   ['] pl2303-rts-dtr-on  to rts-dtr-on
   ['] pl2303-inituart    to inituart
;

: init  ( -- )
   init
   vid pid uart-pl2303?  if  init-pl2303  then
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
