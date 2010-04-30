\ See license at end of file
purpose: Driver/selftest for OLPC XO-1.5 LEDs

0 0  " 0"  " /" begin-package
0 0 reg  \ So test-all will run the test
" leds" device-name
: open  ( -- okay? )  true  ;
: close  ( -- )  ;
: gpio-lo ( mask -- )  h# 4c acpi-l@  swap invert and  h# 4c acpi-l!  ;
: gpio-hi  ( mask -- )  h# 4c acpi-l@  swap or  h# 4c acpi-l!  ;
: hdd-led-on  ( -- )  h# 400000 gpio-lo  ;
: hdd-led-off ( -- )  h# 400000 gpio-hi  ;
: selftest  ( -- )
   ." Flashing LEDs" cr
   " /wlan" test-dev  " /wlan" test-dev  \ Twice for longer flashing
   d# 20 0 do  hdd-led-on d# 100 ms hdd-led-off d# 100 ms  loop
   confirm-selftest?
;

end-package

\ LICENSE_BEGIN
\ Copyright (c) 2009 FirmWorks
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
