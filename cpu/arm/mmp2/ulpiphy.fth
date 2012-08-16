\ See license at end of file
purpose: Access to miscellaneous control/enable registers for the ULPI PHY portion of the USB SPH controller

0 0   " d4207000"  " /" begin-package

" mrvl,mmp2-ulpiphy" +compatible

h# 3800 io2-va + constant usbsph-misc-va
: usbsph-misc@  ( -- n )  usbsph-misc-va     4 + l@  ;
: usbsph-misc!  ( n -- )  usbsph-misc-va     4 + l!  ;
: usbsph-int@   ( -- n )  usbsph-misc-va h# 28 + l@  ;
: usbsph-int!   ( n -- )  usbsph-misc-va h# 28 + l!  ;
: usbsph-ctrl@  ( -- n )  usbsph-misc-va h# 30 + l@  ;
: usbsph-ctrl!  ( n -- )  usbsph-misc-va h# 30 + l!  ;
: ulpi-on  ( -- )  h# 0800.0000 usbsph-misc!  ;
: ulpi-resume-interrupt-on  ( -- )  2 usbsph-int!  ;
: ulpi-clock-on  ( -- )  usbsph-ctrl@ 1 or usbsph-ctrl!  ;
: ulpi-clock-select  ( -- )  usbsph-ctrl@ h# 400 or usbsph-ctrl!  ;

: init  ( -- )
   ulpi-clock-on
   ulpi-clock-select
   ulpi-on
;

: open  ( -- true )  true  ;
: close  ;

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
