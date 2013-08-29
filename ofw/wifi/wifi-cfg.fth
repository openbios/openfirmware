purpose: /package/supplicant configuration data
\ See license at end of file

\ =====================================================================
\ Arguments passed onto the /supplicant support package

struct
    /n field >wc-ssid		\ pstr (upto 32 ASCII characters)
    /n field >wc-wep-idx	\ 1-4
    /n field >wc-wep1		\ pstr (binary, len=5 or 13)
    /n field >wc-wep2		\ pstr (binary, len=5 or 13)
    /n field >wc-wep3		\ pstr (binary, len=5 or 13)
    /n field >wc-wep4		\ pstr (binary, len=5 or 13)
    /n field >wc-pmk		\ pstr (binary, len=32)
    /n field >wc-psk		\ pstr (ASCII, arbitrary length)
constant /wifi-cfg

/wifi-cfg buffer: ram-wifi-cfg
defer wifi-cfg  ' ram-wifi-cfg to wifi-cfg

: reset-wifi-cfg  wifi-cfg  /wifi-cfg erase  ;

\ =======================================================================
\ wifi-cfg data

\ Make a packed string of $, optimizing for the case where
\ $ is already in the dictionary as a packed string.
: $>pstr  ( $ -- pstr )
   over in-dictionary?  if     ( $ )
      over c@ over =  if  drop 1-  exit  then
   then                        ( $ )
   here >r  ",  r>             ( pstr )
;

: pstr!  ( adr len dst -- )  >r  $>pstr r> !  ;

: pstr@   ( src -- adr len )  @ ?dup  if  count  else  " "  then  ;
: wifi-ssid$     ( -- $ )  wifi-cfg >wc-ssid pstr@  ;
: wifi-pmk$      ( -- $ )  wifi-cfg >wc-pmk  pstr@  ;
: wifi-psk$      ( -- $ )  wifi-cfg >wc-psk  pstr@  ; 
: wifi-wep1$     ( -- $ )  wifi-cfg >wc-wep1 pstr@  ;
: wifi-wep2$     ( -- $ )  wifi-cfg >wc-wep2 pstr@  ;
: wifi-wep3$     ( -- $ )  wifi-cfg >wc-wep3 pstr@  ;
: wifi-wep4$     ( -- $ )  wifi-cfg >wc-wep4 pstr@  ; 
: wifi-wep-idx   ( -- n )  wifi-cfg >wc-wep-idx @ 1- 0 max 4 min  ;

\ The PMK is used internally, rarely entered directly
\ Computing it from the user-visible PSK is relatively expensive, so
\ we store the value for later reuse.  The supplicant package calls $pmk 
\ to store the computed value in the wifi-cfg data structure.
: $pmk  ( pmk$ -- )
   dup d# 32 <>  abort" PMK must be 32 bytes"
   wifi-cfg >wc-pmk pstr!  ( )
;

defer default-ssids  ( -- $ )  ' null$ to default-ssids

0 value ssid-reset?
: $essid  ( essid$ -- )
   dup 0= abort" Empty ESSID string"    ( adr len )
   reset-wifi-cfg                       ( adr len )
   wifi-cfg >wc-ssid pstr!              ( )
   true to ssid-reset?
   \ When an explicit SSID is given, don't fall back to the default list
   ['] null$ to default-ssids
;

\ Stores the result at here
: decode-hex  ( hex$ -- bin$ )
   here >r
   begin  dup  while   ( adr len )
      over 2  push-hex $number pop-base  ( adr len [ true | n false ] )
      abort" Bad hex number"             ( adr len n )
      c,                                 ( adr len )
      2 /string                          ( adr' len' )
   repeat                                ( adr len )
   2drop                                 ( adr len )
   r>  here over -                       ( bin-adr bin-len )
;

\ WEP keys are fundamentally either 5 or 13 bytes long, but they can be
\ expressed either in straight ASCII or in hexadecimal.  In hex, the
\ length is either 10 or 26 bytes, which converts to 5 or 13 ASCII bytes.
: $wep  ( wep$ -- )
   dup d# 10 =  over d# 26 =  or  if     ( wep$ )
      decode-hex                         ( wep$' )
   else                                  ( wep$ )
      dup 5 <>  over d# 13 <>  and  abort" WEP key must be 5 or 13 ASCII characters or 10 or 26 hex digits"
   then                                  ( wep$ )

   wifi-cfg >wc-wep-idx   dup @          ( wep$ adr idx )
   dup 4 >=  abort" Too many WEP keys"   ( wep$ adr idx )
   2dup 1+ swap !                        ( wep$ adr idx )
   2* na+ na1+  pstr!                    ( )
;

: $wpa  ( psk$ -- )   wifi-cfg >wc-psk pstr!  ;

: essid  ( "ssid" -- )  0 parse $essid  ;
alias wifi essid
alias ssid essid

: wep  ( "wep" -- )  0 parse  $wep  ;
: wpa  ( "psk" -- )  0 parse  $wpa  ;

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

: test-antenna  ( -- )
   " /wlan" open-dev >r                 ( r: dev )
   " test-antenna" r@ $call-method      ( r: dev )
   r> close-dev                         ( )
;

0 [if]

\ Sample usage:

: set-dlink-wifi-cfg  ( -- )
   " dlink"  $ssid
   " "(11 22 33 44 55)" $wep
   " "(db 91 ee 34 a9 3c 73 48 18 35 a2 64 5b 11 d1 34 ec f3 b3 a2 ee ae 33 96 a9 0b 7d b5 1f 2f 48 78)" $pmk
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
