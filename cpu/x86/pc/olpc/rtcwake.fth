purpose: Suspend/resume test with RTC wakeup
\ See license at end of file

dev /rtc

cmos-alarm-day    " alarm_day"   integer-property
cmos-alarm-month  " alarm_month" integer-property
cmos-century      " century"     integer-property

\ There are a couple of reasons why you might not want to enable the IRQ:
\ a) It might be shared with the timer IRQ so it is already enabled
\ b) When using the alarm to wakeup from sleep, the IRQ might be unnecessary.

0 value alarm-irq
false value enable-alarm-irq?

defer alarm-hook  ' noop to alarm-hook

: disable-alarm  ( -- )
   enable-alarm-irq?  if  alarm-irq disable-interrupt  then
   h# b cmos@ h# 20 invert and h# b cmos!  
;

: rtc-handler  ( -- )
   disable-alarm
   h# c cmos@ drop	\ Clear RTC interrupt flags
   alarm-hook   
;

: enable-alarm   ( -- )
   ['] rtc-handler 8 interrupt-handler!
   enable-alarm-irq?  if  alarm-irq disable-interrupt  then
   h# c cmos@ drop				\ Clear RTC interrupt flags
   h# b cmos@ h# 20 or h# b cmos!  
;

: set-alarm  ( [ handler-xt ] secs -- )  \ No handler-xt if secs is 0
   disable-alarm
   ?dup  0=  if  exit  then                     ( handler-xt secs )
   swap to alarm-hook                           ( secs )
   now						( secs s m h )
   d# 60 * d# 60 * swap d# 60 * + + +		( s )
   d# 60 /mod d# 60 /mod d# 24 mod		( s m h )
   h# c0 cmos-alarm-month cmos!			( s m h )	\ Any day
   h# c0 cmos-alarm-day cmos!			( s m h )	\ Any month
   5 bcd!  3 bcd!  1 bcd!	( )
   enable-alarm
;

dend

: show-rtc-wake  ." R"  ;

d# 1 constant rtc-alarm-delay
: pm-sleep-rtc  ( -- )
   0 acpi-l@ h# 400.0000 or  0 acpi-l!	\ Enable RTC SCI
   ['] show-rtc-wake  rtc-alarm-delay " set-alarm" clock-node @ $call-method
   s
   0 acpi-l@ h# 400.0000 invert and  0 acpi-l!	\ Disable RTC SCI
;
: rtc-wackup
   0
   begin  pm-sleep-rtc space dup . (cr 1+  key? until
   key drop
;

\ Check if the 'x' was pressed 
: test-exit?
   key? if
      ." Key:  "                  
      key dup h# 78 = if -1 else 0 then
      swap .x cr
   else 0 
   then                      
;

: autowack-test ( ms -- )
   autowack-delay
   autowack-on
   0 begin
      s 
      dup space .d (cr 1+ 
      test-exit?
   until
   drop
   autowack-off
;

\ for testing wakeups from the EC
: wackup-test-ec  ( ms -- )
   ." Press x to exit" cr
   d# 3000 autowack-delay     \ At small ms delays the host can miss the SCI so this
                              \ is the back up.
   0 begin                    ( ms count )
      autowack-on swap dup    ( count ms ms )
      ec-wackup               ( count ms  )
      s
      swap dup                ( ms count count )
      space .d (cr 1+ 
      test-exit?              ( ms count+1 )
   until                      ( ms count+1 )
   2drop
   autowack-off
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
