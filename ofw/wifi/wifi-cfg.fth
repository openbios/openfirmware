purpose: /package/supplicant configuration data
\ See license at end of file

struct
    /n 2* field >wc-ssid		\ adr len (upto 32 ascii bytes)
    /n    field >wc-wep-idx		\ 1-4
    /n 2* field >wc-wep1		\ adr len (binary, len=5 or 13)
    /n 2* field >wc-wep2		\ adr len
    /n 2* field >wc-wep3		\ adr len
    /n 2* field >wc-wep4		\ adr len
    /n 2* field >wc-pmk			\ adr len (binary, len=32)
constant /wifi-cfg

/wifi-cfg buffer: wifi-cfg

: wifi-children  ( -- )
   \ Ignore nodes that do not have device_type = wireless-network
   " device_type" get-property  if  exit  then
   get-encoded-string " wireless-network" $=  if
      " scan-wifi" method-name 2!  do-method?
   then
;

: scan-wifi  ( -- )
   optional-arg-or-/$  ['] wifi-children scan-subtree
;

: adrlen!  ( adr len dst -- )  tuck na1+ ! !  ;


0 [if]

\ Sample usage:

: dlink-ssid  ( -- $ )  " dlink"  ;
: dlink-wep1  ( -- $ )  " "(11 22 33 44 55)"  ;
: dlink-pmk   ( -- $ )  " "(db 91 ee 34 a9 3c 73 48 18 35 a2 64 5b 11 d1 34 ec f3 b3 a2 ee ae 33 96 a9 0b 7d b5 1f 2f 48 78)"  ;
: bad-pmk     ( -- $ )  " "(00 91 ee 34 a9 3c 73 48 18 35 a2 64 5b 11 d1 34 ec f3 b3 a2 ee ae 33 96 a9 0b 7d b5 1f 2f 48 78)"  ;
: set-dlink-wifi-cfg  ( -- )
   wifi-cfg /wifi-cfg erase
   dlink-ssid wifi-cfg >wc-ssid adrlen!
   1          wifi-cfg >wc-wep-idx    !
   dlink-wep1 wifi-cfg >wc-wep1 adrlen!
   dlink-pmk  wifi-cfg >wc-pmk  adrlen!
;
set-dlink-wifi-cfg

[then]

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
