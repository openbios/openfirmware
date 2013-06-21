\ See license at end of file
purpose: Driver/selftest for OLPC XO-1.75 LEDs

0 0  " "  " /" begin-package
   " ols" device-name
   " olpc,xo-light-sensor" +compatible
end-package

0 0  " 0"  " /" begin-package
0 0 reg  \ So test-all will run the test
" leds" device-name

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

: selftest  ( -- error? )
   ." Flashing LEDs" cr

   d# 10 0 do  ols-led-on d# 200 ms ols-led-off d# 200 ms  loop
   ols-led-ec-control
   ols-assy-mode-on

   " /wlan:quiet" test-dev  " /wlan:quiet" test-dev  \ Twice for longer flashing

   d# 20 0 do  hdd-led-on d# 100 ms hdd-led-off d# 100 ms  loop
   ols-assy-mode-off

   confirm-selftest?  ( error? )
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
