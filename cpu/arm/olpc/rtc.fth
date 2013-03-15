purpose: Driver for external IDT1388 RTC chip on XO-1.75

dev /i2c@d4031000  \ TWSI2
new-device

" rtc" name
" idt,idt1338-rtc" +compatible
h# 68 1 reg

: rtc@  ( reg# -- byte )  " reg-b@" $call-parent  ;
: rtc!  ( byte reg# -- )  " reg-b!" $call-parent  ;

headerless

: ?clear
   h# 3f rtc@  h# 3e rtc@  bwjoin  h# 55aa  <>  if
      h# 20 h#  8 rtc!                 \ century
      h# 13 h#  9 rtc!                 \ year
      h#  1 h#  8 rtc!                 \ month
      h#  1 h#  7 rtc!                 \ day
      h# 20 h# 10  do  0 i rtc!  loop  \ wipe cmos@ cmos! area
      h# 55aa  wbsplit  h# 3e rtc!  h# 3f rtc!
      ." RTC SRAM cleared" cr
   then
;

headers
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

   \ manage legacy RTC CMOS usage
   ?clear

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
