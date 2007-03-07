\ See license at end of file
purpose: Use ISA 8254 timer 0 or the RTC as the tick timer

: tick-interrupt  ( level -- )
   drop
[ifdef] level-interrupts
   " which-interrupt"  clock-node @  $call-method  drop  \ Clear the interrupt
[then]
   tick-msecs ms/tick +  to tick-msecs
   ?call-os
   check-alarm
;

\ If we are using the 8259 interrupt controller in level-triggered mode,
\ we must use the RTC instead of the ISA counter/timer to generate the tick
\ interrupt, because the interrupt output from the ISA timer is a square
\ wave with no provision for making it go away immediately after servicing it.

\ Unfortunately, the granularity of the RTC interrupt leaves something to
\ be desired.  You can set its interrupt period to power-of-two multiples
\ of 1/8192 seconds (approximately 122 usecs), resulting in periods like
\ 1.95 ms, 3.9 ms, 7.8 ms, 15.6 ms ...

[ifdef] level-interrupts
: (set-tick-limit)  ( #msecs -- )
   d# 1000 *                                      ( target-usecs/tick )
   " set-tick-usecs"  clock-node @  $call-method  ( actual-usecs/tick )
   d# 500 +  d# 1000 /  to ms/tick                ( )
   ['] tick-interrupt 8 interrupt-handler!
   8 enable-interrupt
;
\ This is a workaround for a bug in JavaOS; it apparently expects
\ the firmware to set the mode and period of ISA timer 0.
stand-init: ISA Timer
   d# 10 " /isa/timer" " set-tick-limit" execute-device-method drop
;
[else]
: (set-tick-limit)  ( #msecs -- )
   to ms/tick
   ms/tick " /isa/timer" " set-tick-limit" execute-device-method drop
   ['] tick-interrupt 0 interrupt-handler!
   0 enable-interrupt
;
[then]
' (set-tick-limit) to set-tick-limit
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
