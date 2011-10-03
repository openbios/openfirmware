\ See license at end of file
purpose: Driver for MMP2 internal RTC

\ Interrupt 5 combines two interrupt inputs, RTC INT (bit 1) and RTC ALARM (bit 0)
: int5-mask  ( -- offset )  h# 16c +icu  ;
: int5-status@  ( -- value )  h# 154 icu@  ;

: enable-rtc  ( -- )  h# 81 0 apbc!  ;  \ Turn on the clock for the internal RTC
: enable-rtc-wakeup  ( -- )
   h# 2.0010  h# 104c +mpmu  io-set
;
: soc-rtc@  ( offset -- value )  h# 01.0000 + io@  ;
: soc-rtc!  ( value offset -- value )  h# 01.0000 + io!  ;
: cancel-alarm  ( -- )
   0 8 soc-rtc!
   1 int5-mask io-set  \ Mask alarm
;
: take-alarm  ( -- )  ." Alarm fired" cr  cancel-alarm  ;
: rtc-wake  ( handler-xt #seconds -- )
   enable-rtc                          ( handler-xt #seconds )  \ Turn on clocks
   
   1 int5-mask io-clr                  ( handler-xt #seconds )  \ Unmask alarm
   enable-rtc-wakeup                   ( handler-xt #seconds )
   0 soc-rtc@  +  4 soc-rtc!           ( handler-xt )           \ Set alarm for 2 seconds from now
   7 8 soc-rtc!                        ( handler-xt )           \ Ack old interrupts and enable new ones
   5 interrupt-handler!                ( )
   5 enable-interrupt                  ( )
;
: wake1  ( -- )  ['] cancel-alarm 1 rtc-wake  ;
: alarm-in-3  ( -- )  ['] take-alarm 3 rtc-wake  ;
: wakeup-loop  ( -- )
   d# 1000000 0 do
      0 d# 13 at-xy  i .d
      5 0  do
         cr i .
         wake1  strp
         d# 500 ms
         key? if unloop unloop exit  then
      loop
   5 +loop
;
alias test4 wakeup-loop

: s3-selftest  ( -- error? )
   \ The general failure mode here is that it won't wake up, so
   \ it's hard to return a real error code.  We just have to rely
   \ on the operator.
   ." Testing suspend/resume"  cr
   ." Sleeping for 3 seconds .. "  d# 100 ms
   ec-rst-pwr ['] cancel-alarm 3 rtc-wake  str  ec-max-pwr  ( power )
   \ Negative power is consumed from battery, positive is supplied to battery
   dup  d# -250 <  if                                       ( power )
      ." System used too much power during suspend - "  negate .d ." mW" cr  ( )
      true                                                  ( error? )
   else                                                     ( power )
      drop  false                                           ( error? )
   then                                                     ( error? )
;
dev /memory
[ifdef] test-s3  ' s3-selftest to test-s3  [then]
dend

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
