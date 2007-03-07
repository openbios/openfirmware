purpose: USB Hub Driver
\ See license at end of file

hex

" usb_hub" encode-string  " device_type"     property
2          encode-int     " #address-cells"  property
0          encode-int     " #size-cells"     property

external

\ A usb device node defines an address space of the form
\ "port,interface".  port and interface are both integers.
\ parse-2int converts a text string (e.g. "3,1") into a pair of
\ binary integers.

: decode-unit  ( addr len -- interface port )  parse-2int  ;
: encode-unit  ( interface port -- adr len )
   >r  <# u#s drop ascii , hold r> u#s u#>	\ " port,interface"
;

: open   ( -- flag )  true  ;
: close  ( -- )  ;

headers

: is-hub20?  ( -- flag )
   " high-speed" get-my-property 0=  if  2drop true  else  false  then
;
: hub-id  ( -- dev )
   " assigned-address" get-my-property  if
      ." Property: assigned-address not found."  abort
   then
   decode-int nip nip
;
: probe-hub  ( -- )
   ['] hub-id catch 0=  if
      is-hub20?  if
         dup encode-int " hub20-dev" property
      then
      probe-hub-xt execute
   then
;

probe-hub

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
