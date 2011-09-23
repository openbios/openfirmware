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
: cancel-alarm  ( -- )
   0 8 soc-rtc!
   int5-mask@ 1 or int5-mask!  \ Mask alarm
;
: take-alarm  ( -- )
   ." Alarm fired" cr
   cancel-alarm
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
: alarm-in-1  ( -- )
   enable-rtc                          \ Turn on clocks
   
   int5-mask@ 1 invert and int5-mask!  \ Unmask alarm
   enable-rtc-wakeup
   0 soc-rtc@  d# 1 +  4 soc-rtc!      \ Set alarm for 3 seconds from now
   7 8 soc-rtc!                        \ Ack old interrupts and enable new ones
   ['] cancel-alarm 5 interrupt-handler!
   5 enable-interrupt
;
: wake1  ( -- )
   enable-rtc                          \ Turn on clocks
   
   int5-mask@ 1 invert and int5-mask!  \ Unmask alarm
   enable-rtc-wakeup
   0 soc-rtc@  d# 1 +  4 soc-rtc!      \ Set alarm for 3 seconds from now
   7 8 soc-rtc!                        \ Ack old interrupts and enable new ones
   ['] cancel-alarm 5 interrupt-handler!
   5 enable-interrupt
;
: alarm1  ( -- )
   enable-rtc                          \ Turn on clocks
   
   int5-mask@ 1 invert and int5-mask!  \ Unmask alarm
   enable-rtc-wakeup
   0 soc-rtc@  d# 1 +  4 soc-rtc!      \ Set alarm for 3 seconds from now
   7 8 soc-rtc!                        \ Ack old interrupts and enable new ones
   ['] take-alarm 5 interrupt-handler!
   5 enable-interrupt
;
: test1
   0
   begin
      alarm1
      str
      (cr dup . 1+
      d# 500 ms
   key? until
;
: test2
   0
   begin
      wake1
      str
      (cr dup . 1+
      d# 500 ms
   key? until
;
: test3
   0
   begin
      wake1
      str
      cr dup . 1+
      d# 500 ms
   key? until
;
: test4
   begin
      0 d# 13 at-xy
      5 0  do
         wake1  str
         cr i .
         d# 500 ms
         key? if unloop exit  then
      loop
   again
;

\ test3
\ wake1 str cr

\ patch noop cr take-alarm test1
\ patch (cr cr take-alarm test1

\ : cx cr d# 400 ms ; patch cx cr take-alarm test1
