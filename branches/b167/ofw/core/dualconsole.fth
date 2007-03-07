purpose: Make the console go to both serial and the OFW console device
\ See license at end of file

\ If the appropriate OFW console device (stdin or stdout) is null,
\ use the direct serial console.
\ If the OFW console device is not a serial port, use both it and
\ the serial port
\ If the OFW console device is a serial port, use the console device.

: serial?  ( ihandle -- flag )
   ihandle>phandle  " device_type" rot   ( propname$ phandle )
   get-package-property  if  false exit  then  ( value$ )
   get-encoded-string  " serial" $=
;

: utype  ( adr len -- )  bounds  ?do  i c@ uemit  loop  ;

: dual-emit  ( char -- )
   stdout @  0=  if  uemit exit  then
   stdout @ serial?  0=  if  dup uemit  then
   console-emit
;

: dual-type  ( adr len -- )
   stdout @ 0=  if  utype exit  then
   stdout @ serial?  0=  if  2dup utype  then
   console-type
;

: dual-key?  ( -- flag )
   stdin @  0=  if  ukey?  exit  then
   stdin @ serial?  0=  if
      ukey?  if  true exit  then
   then
   console-key?
;

: dual-key  ( -- key )
   stdin @  0=  if  ukey  exit  then
   stdin @ serial?  if  console-key exit  then

   begin  dual-key?  until
   ukey?  if  ukey exit  then
   console-key
;

: install-dual-console  ( -- )
   char-pending? off
   ['] dual-key? to key?
   ['] dual-key to (key
   ['] dual-emit to (emit
   ['] dual-type to (type
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
