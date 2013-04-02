purpose: Driver for external IDT1388 RTC chip on XO-1.75

dev /i2c@d4031000  \ TWSI2
new-device

" rtc" name
" idt,idt1338-rtc" +compatible
h# 68 1 reg

: rtc@  ( reg# -- byte )  " reg-b@" $call-parent  ;
: rtc!  ( byte reg# -- )  " reg-b!" $call-parent  ;

headerless

\ if the oscillator stop flag is set the RTC counter and RTC SRAM
\ contents cannot be trusted.

: stopped?  ( -- stopped? )  \ check the oscillator stop flag
   7 rtc@ h# 20 and
;

: unstop  ( -- )  \ clear the oscillator stop flag
   7 rtc@ h# 20 invert and 7 rtc!
;

: reinit  \ reinitialise the RTC counter
   h# 20 h#  8 rtc! \ century
   h# 13 h#  6 rtc! \ year
   h#  1 h#  5 rtc! \ month
   h#  1 h#  4 rtc! \ day of month
   h#  2 h#  3 rtc! \ day of week, monday
   h#  0 h#  2 rtc! \ hours
   h#  0 h#  1 rtc! \ minutes
   h#  0 h#  0 rtc! \ seconds
   ." RTC cleared" cr
;

h# 55aa value sram-marker  \ our magic marker for RTC SRAM

: sram-corrupt?  ( -- corrupt? )  \ is the RTC SRAM corrupt?
   h# 3f rtc@  h# 3e rtc@  bwjoin  sram-marker  <>
;

: sram-reinit  ( -- )  \ reinitialise the RTC SRAM
   h# 20 h# 10  do  0 i rtc!  loop  \ wipe cmos@ cmos! area
   sram-marker  wbsplit  h# 3e rtc!  h# 3f rtc!
   ." RTC SRAM cleared" cr
;

headers
: verify  ( -- )  \ check RTC for loss of data and reinitialise if so
   stopped?  if
      \ RTC says data is lost
      [ifndef] olpc-cl2  reinit  [then]  \ requested by Daniel Drake
      unstop
   then
   sram-corrupt?  if  sram-reinit  reinit  then
;

: open  ( -- okay )
   my-unit " set-address" $call-parent

   0 ['] rtc@ catch  if        ( x )
      drop false  exit         ( -- false )
   then                        ( value )

   \ Ensure that the Clock Halt bit is off
   dup h# 80 and  if           ( value )
      \ Turn off Clock Halt
      h# 7f and 0 rtc!         ( )
      \ Verify that it went off
      0 rtc@ h# 80 and         ( error? )
      dup  if  ." RTC Clock Halt is stuck on" cr  then  ( error? )
      0=                       ( okay? )
   else                        ( value )
      drop true                ( true )
   then                        ( okay? )

   \ enable 32kHz clock output
   h# b3 7 rtc!
;
: close  ( -- )
;

headerless
: bcd>  ( bcd -- binary )  dup h# f and  swap 4 >>  d# 10 *  +  ;
: >bcd  ( binary -- bcd )  d# 10 /mod  4 << +  ;

: bcd-time&date  ( -- s m h d m y century )
   0 1 9 " bytes-out-in" $call-parent  ( s m h dow d m y control c )
   nip             ( s m h dow d m y c )
   4 roll drop     ( s m h d m y c )
;
: bcd!  ( n offset -- )  swap >bcd  swap rtc!  ;

headers
: get-time  ( -- s m h d m y )
   bcd-time&date  >r >r >r >r >r >r
   bcd>  r> bcd>  r> bcd>  r> bcd>  r> bcd>  r> bcd>  r> bcd> ( s m h d m y c )

   d# 20 max
   d# 100 * +  		\ Merge century with year
;
: set-time  ( s m h d m y -- )
   d# 100 /mod  h# 8 bcd!  6 bcd!  5 bcd!  4 bcd!  2 bcd!  1 bcd!  0 bcd!
;

: selftest  ( -- flag )
   open  0=  if  true  close exit  then
   0 rtc@  d# 1100 ms  0 rtc@  =  if
      ." RTC did not tick" cr
      true  close  exit
   then
   get-time .date space .time cr
   get-time 2nip 2nip nip
   d# 2011 < dup  if  ." Date in RTC is too early" cr  then	( -- flag )
   close
;

finish-device
device-end
