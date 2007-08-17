\ Suspend/resume test with RTC wakeup
d# 2 value rtc-alarm-delay

h# 41 constant cmos-alarm-day    \ CMOS offset of day alarm
h# 40 constant cmos-alarm-month  \ CMOS offset of month alarm
cmos-alarm-day   0  h# 5140.0055 msr!
cmos-alarm-month 0  h# 5140.0056 msr!

: enable-rtc-alarm   ( -- )
   h# c cmos@ drop				\ Clear RTC interrupt flags
   h# b cmos@ h# 20 or h# b cmos!  
;
: disable-rtc-alarm  ( -- )
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

: rs  ( -- )
   rtc-alarm-delay set-rtc-alarm
   s
   disable-rtc-alarm
;
patch 500.0000 100.0000 s3  \ Turn on RTC wakeup too
: rss  begin  d# 50 ms rs  ." ."  key? until  ;

.( 'rs' does it once, 'rss' does it until you type a key) cr
