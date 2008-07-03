purpose: Suspend/resume test with RTC wakeup
\ See license at end of file

: enable-rtc-irq   ( -- )  h# a1 pc@ h# fe and h# a1 pc!  ;
: disable-rtc-irq  ( -- )  h# a1 pc@     1 or  h# a1 pc!  ;

\ Must agree with lxmsrs.fth
h# 3d constant cmos-alarm-day	\ Offset of day alarm in CMOS
h# 3e constant cmos-alarm-month	\ Offset of month alarm in CMOS
h# 32 constant cmos-century	\ Offset of century byte in CMOS

dev /rtc
   cmos-alarm-day    " alarm_day"   integer-property
   cmos-alarm-month  " alarm_month" integer-property
   cmos-century      " century"     integer-property
dend

false value enable-rtc-irq?

: rtc-handler  ( -- )  h# c cmos@ drop  ." R"  ;	\ Clear RTC interrupt flags

: enable-rtc-alarm   ( -- )
   ['] rtc-handler 8 interrupt-handler!

   enable-rtc-irq?  if  enable-rtc-irq  then
   h# c cmos@ drop				\ Clear RTC interrupt flags
   h# b cmos@ h# 20 or h# b cmos!  
;
: disable-rtc-alarm  ( -- )
   disable-rtc-irq
   h# b cmos@ h# 20 invert and h# b cmos!  
;
: bcd-cmos!  ( binary -- )  " bcd!" clock-node @ $call-method  ;
: set-rtc-alarm  ( secs -- )
   disable-rtc-alarm
   now						( secs s m h )
   d# 60 * d# 60 * swap d# 60 * + + +		( s )
   d# 60 /mod d# 60 /mod d# 24 mod		( s m h )
   h# c0 cmos-alarm-month cmos!			( s m h )	\ Any day
   h# c0 cmos-alarm-day cmos!			( s m h )	\ Any month
   5 bcd-cmos!  3 bcd-cmos!  1 bcd-cmos!	( )
   enable-rtc-alarm
;
d# 1 constant rtc-alarm-delay
: pm-sleep-rtc  ( -- )
   false to enable-rtc-irq?		\ Spec says that IRQ is not necessary
   rtc-alarm-delay set-rtc-alarm
   h# 400.0000 0 acpi-l!		\ Enable RTC SCI
   s
   disable-rtc-alarm
   0 0 acpi-l!				\ Disable RTC SCI
;
: rtc-wackup
   0
   begin  pm-sleep-rtc space dup . (cr 1+  key? until
   key drop
;

stand-init: Century
   h# 20 cmos-century cmos!   \ The century is in BCD, hence h#
;

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
