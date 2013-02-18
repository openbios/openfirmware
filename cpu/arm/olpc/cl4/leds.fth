\ See license at end of file
purpose: Driver/selftest for OLPC XO-1.75 LEDs

0 0  " "  " /" begin-package
   " ols" device-name
   " olpc,xo-light-sensor" +compatible
   0 0 reg  \ So linux will assign a static device name
end-package

0 0  " 0"  " /" begin-package
0 0 reg  \ So test-all will run the test

" gpio-leds" +compatible
" leds" device-name

new-device
  " storage-led" device-name
  " mmc-block" " linux,default-trigger" string-property
  led-storage-gpio#  0  " gpios" gpio-property
finish-device

: open  ( -- okay? )  true  ;
: close  ( -- )  ;

: hdd-led-off     ( -- )  led-storage-gpio# gpio-clr  ;
: hdd-led-on      ( -- )  led-storage-gpio# gpio-set  ;
: hdd-led-toggle  ( -- )  led-storage-gpio# gpio-pin@  if  hdd-led-off  else  hdd-led-on  then  ;

: (cycle)
   ols-led-on
   d# 100 ms
   hdd-led-on
   " led-blink" $call-wlan
   d# 100 ms
   ols-led-off
   ols-led-ec-control
   ols-assy-mode-on
   d# 100 ms
   hdd-led-off
   ols-assy-mode-off
   d# 100 ms
;

: (selftest)
   0 to wlan-ih
   " /wlan:force" open-dev ?dup  if  to wlan-ih  then
   get-msecs d# 10000 +                 ( limit )
   begin
      (cycle)
      key?  if  drop  wlan-ih close-dev  exit  then
      dup get-msecs -  0<               ( limit timeout? )
   until                                ( limit )
   drop                                 ( )
   wlan-ih close-dev
;

: selftest  ( -- error? )
   ." Testing LEDs" cr
   (selftest)
   confirm-selftest?
;

end-package

\ LICENSE_BEGIN
\ Copyright (c) 2011 FirmWorks
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
