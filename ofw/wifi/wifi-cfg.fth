purpose: /package/supplicant configuration data
\ See license at end of file


\ =====================================================================
\ Arguments passed onto the /supplicant support package

struct
    3     field >wc-country		\ Country code
    /n 3 - +				\ Padding
    /n 2* field >wc-ssid		\ adr len (upto 32 ascii bytes)
    /n    field >wc-wep-idx		\ 1-4
    /n 2* field >wc-wep1		\ adr len (binary, len=5 or 13)
    /n 2* field >wc-wep2		\ adr len
    /n 2* field >wc-wep3		\ adr len
    /n 2* field >wc-wep4		\ adr len
    /n 2* field >wc-pmk			\ adr len (binary, len=32)
constant /wifi-cfg

/wifi-cfg buffer: wifi-cfg


\ =====================================================================
\ Country/region tables

: $, ( adr len -- )  here over allot  swap move  ;

create country-region
here
	" US " $, 10 c,			\ US FCC
	" CA " $, 10 c,			\ IC Canada
	" SG " $, 10 c,			\ Singapore
	" EU " $, 30 c,			\ ETSI
	" AU " $, 30 c,			\ Australia
	" KR " $, 30 c,			\ Republic of Korea
	" ES " $, 31 c,			\ Spain
	" FR " $, 32 c,			\ France
	" JP " $, 40 c,			\ Japan
here swap - 4 / constant #country-region

create region-ie-US
here
   1 c, d# 11 c, d# 20 c,		\ Channels 1-11, 100mW
here swap - constant /region-ie-US

create region-ie-EU
here
   1 c, d# 13 c, d# 20 c,		\ Channels 1-13, 100mW
here swap - constant /region-ie-EU

create region-ie-ES
here
   d# 10 c, 2 c, d# 20 c,		\ Channels 10-11, 100mW
here swap - constant /region-ie-ES

create region-ie-FR
here
   d# 10 c, 4 c, d# 20 c,		\ Channels 10-13, 100mW
here swap - constant /region-ie-FR

create region-ie-JP
here
   1 c, d# 13 c, d# 16 c,		\ Channels 1-13, 50mW
   d# 14 c, 1 c, d# 16 c,		\ Channel 14, 50mW
here swap - constant /region-ie-JP

d# 15 3 * dup constant /country-ie   buffer: country-ie

: country>region  ( country$ -- region )
   0 -rot #country-region 0  do		( region adr len )
      country-region i 4 * + 2 pick 2 pick comp
      0=  if  rot drop country-region i 4 * + 3 + c@ -rot  leave  then
   loop  2drop				( region )
;

: region>ch/pwr  ( region -- ch-adr,len )
   case
      10  of  region-ie-US /region-ie-US  endof
      30  of  region-ie-EU /region-ie-EU  endof
      31  of  region-ie-ES /region-ie-ES  endof
      32  of  region-ie-FR /region-ie-FR  endof
      40  of  region-ie-JP /region-ie-JP  endof
      ( default ) null$ rot
   endcase
;

: country>ie  ( country$ -- ie-adr,len )
   country-ie /country-ie erase
   2dup country>region ?dup 0=  if  2drop null$ exit  then
   region>ch/pwr ?dup 0=  if  3drop null$ exit  then
   tuck country-ie 3 + swap move
   over + -rot 3 max country-ie swap move
   country-ie swap
;


\ =====================================================================
\ Scan wireless networks

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

\ Some syntactic sugar
: $wifi  ( country,ssid$ -- )
   dup 0= abort" Empty country,SSID string"
   wifi-cfg  /wifi-cfg erase    ( adr len )
   wifi-cfg  3 blank            ( adr len )
   [char] , left-parse-string   ( tail$ head$ )
   2 pick  0=  if               ( null$ ssid$ )  
      2swap 2drop  " US"        ( ssid$ country$ )
   then                         ( ssid$ country$ )
   dup 3 >  if
      type ." is too long to be a country name." cr
      abort
   then
   wifi-cfg >wc-country swap move   ( ssid$ )
   here >r  ",  r> count            ( ssid$' )  \ Save the string
   wifi-cfg >wc-ssid adrlen!        ( )
;
: wifi  ( "country,ssid" -- )  0 parse $wifi  ;

0 [if]

\ Sample usage:

: us$  ( -- $ )  " US "  ;
: dlink-ssid  ( -- $ )  " dlink"  ;
: dlink-wep1  ( -- $ )  " "(11 22 33 44 55)"  ;
: dlink-pmk   ( -- $ )  " "(db 91 ee 34 a9 3c 73 48 18 35 a2 64 5b 11 d1 34 ec f3 b3 a2 ee ae 33 96 a9 0b 7d b5 1f 2f 48 78)"  ;
: bad-pmk     ( -- $ )  " "(00 91 ee 34 a9 3c 73 48 18 35 a2 64 5b 11 d1 34 ec f3 b3 a2 ee ae 33 96 a9 0b 7d b5 1f 2f 48 78)"  ;
: set-dlink-wifi-cfg  ( -- )
   wifi-cfg  /wifi-cfg erase
   us$        wifi-cfg >wc-country swap move
   dlink-ssid wifi-cfg >wc-ssid adrlen!
   1          wifi-cfg >wc-wep-idx    !
   dlink-wep1 wifi-cfg >wc-wep1 adrlen!
   dlink-pmk  wifi-cfg >wc-pmk  adrlen!
;
set-dlink-wifi-cfg

: us$  ( -- $ )  " US "  ;
: linksys-ssid  ( -- $ )  " linksys"  ;
: linksys-wep1  ( -- $ )  " "(11 22 33 44 55)"  ;
: linksys-pmk   ( -- $ )  " "(35 8b b7 41 ac fc 04 08 73 67 fb 79 11 cb 18 38 36 ca 54 47 49 73 cd 7a 59 35 e8 6c 4f 20 5f 13)" ;
: set-linksys-wifi-cfg  ( -- )
   wifi-cfg    /wifi-cfg erase
   us$          wifi-cfg >wc-country swap move
   linksys-ssid wifi-cfg >wc-ssid adrlen!
   1            wifi-cfg >wc-wep-idx    !
   linksys-wep1 wifi-cfg >wc-wep1 adrlen!
   linksys-pmk  wifi-cfg >wc-pmk  adrlen!
;
set-linksys-wifi-cfg

: us$  ( -- $ )  " US "  ;
: olpc-ssid  ( -- $ )  " olpc"  ;
: olpc-wep1  ( -- $ )  " "(11 22 33 44 55)"  ;
: set-olpc-wifi-cfg  ( -- )
   wifi-cfg /wifi-cfg erase
   us$       wifi-cfg >wc-country swap move
   olpc-ssid wifi-cfg >wc-ssid adrlen!
   1         wifi-cfg >wc-wep-idx    !
   olpc-wep1 wifi-cfg >wc-wep1 adrlen!
;
set-olpc-wifi-cfg

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
