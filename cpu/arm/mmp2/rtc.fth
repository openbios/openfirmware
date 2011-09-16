purpose: Driver for MMP2 internal RTC

\ This code was written as a test/demonstration of using
\ the MMP2 internal RTC to generate alarm interrupts.
\ It is not currently used by anything, and should it
\ ever be needed, it should be put in a device node.

: int5-mask!  ( value -- )  h# 28.216c io!  ;
: int5-mask@  ( -- value )  h# 28.216c io@  ;
: int5-status@  ( -- value )  h# 28.2154 io@  ;
: enable-rtc  ( -- )  h# 81 h# 01.5000 io!  ;
: enable-rtc-wakeup  ( -- )
   h# 004c mpmu@ h# 2.0010 or h# 004c mpmu!
   h# 104c mpmu@ h# 2.0010 or h# 104c mpmu!
;
: soc-rtc@  ( offset -- value )  h# 01.0000 + io@  ;
: soc-rtc!  ( value offset -- value )  h# 01.0000 + io!  ;
: take-alarm  ( -- )
   ." Alarm fired" cr
    0 8 soc-rtc!
   int5-mask@ 1 or int5-mask!  \ Mask alarm
;
: alarm-in-3  ( -- )
   enable-rtc                          \ Turn on clocks
   
   int5-mask@ 1 invert and int5-mask!  \ Unmask alarm
   enable-rtc-wakeup
   0 soc-rtc@  d# 3 +  4 soc-rtc!      \ Set alarm for 3 seconds from now
   7 8 soc-rtc!                        \ Ack old interrupts and enable new ones
   ['] take-alarm 5 interrupt-handler!
   5 enable-interrupt
;
