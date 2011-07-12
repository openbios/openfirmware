purpose: Driver for MMP2 internal RTC

\ This code was written as a test/demonstration of using
\ the MMP2 internal RTC to generate alarm interrupts.
\ It is not currently used by anything, and should it
\ ever be needed, it should be put in a device node.

: int5-mask!  ( value -- )  h# d428.216c l!  ;
: int5-mask@  ( -- value )  h# d428.216c l@  ;
: int5-status@  ( -- value )  h# d428.2154 l@  ;
: enable-rtc  ( -- )  h# 81 h# d401.5000 l!  ;
: soc-rtc@  ( offset -- value )  h# d401.0000 + l@  ;
: soc-rtc!  ( value offset -- value )  h# d401.0000 + l!  ;
: take-alarm  ( -- )
   ." Alarm fired" cr
    0 8 soc-rtc!
   int5-mask@ 1 or int5-mask!  \ Mask alarm
;
: alarm-in-5  ( -- )
   enable-rtc                          \ Turn on clocks
   int5-mask@ 1 invert and int5-mask!  \ Unmask alarm
   0 soc-rtc@  d# 5 +  4 soc-rtc!      \ Set alarm for 5 seconds from now
   7 8 soc-rtc!                        \ Ack old interrupts and enable new ones
   ['] take-alarm 5 interrupt-handler!
   5 enable-interrupt
;
