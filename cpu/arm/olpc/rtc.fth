purpose: Driver for MMP internal RTC block

0 0  " d4010000"  " /" begin-package
   " rtc" name
   " mrvl,mmp-rtc" +compatible
   my-address my-space  h# 1000 reg

   d# 1 encode-int  0 encode-int encode+ " interrupts" property
   " /interrupt-controller/interrupt-controller@154" encode-phandle " interrupt-parent" property

   " rtc 1Hz" encode-string " rtc alarm" encode-string  encode+ " interrupt-names" property

         
   " /apbc" encode-phandle 0 encode-int encode+ " clocks" property

[ifdef] cl2-a1
: set-address  ( -- )
   rtc-scl-gpio# to smb-clock-gpio#
   rtc-sda-gpio# to smb-data-gpio#
   h# 68 to smb-slave
;
: rtc@  ( reg# -- byte )  set-address  smb-byte@  ;
: rtc!  ( byte reg# -- )  set-address  smb-byte!  ;
[else]
: set-address  ( -- )   h# 68 2 set-twsi-target  ;
: rtc@  ( reg# -- byte )  set-address  twsi-b@  ;
: rtc!  ( byte reg# -- )  set-address  twsi-b!  ;
[then]

headerless

headerless

: ?clear
   h# 3f rtc@  h# 3e rtc@  bwjoin  h# 55aa  <>  if
      h# 20 8 rtc!                     \ century
      h# 20 h# 10  do  0 i rtc!  loop  \ wipe cmos@ cmos! area
      h# 55aa  wbsplit  h# 3e rtc!  h# 3f rtc!
      ." RTC SRAM cleared" cr
   then
;

headers
: open  ( -- okay )
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
   ?clear
;
: close  ( -- )
;

headerless
: bcd>  ( bcd -- binary )  dup h# f and  swap 4 >>  d# 10 *  +  ;
: >bcd  ( binary -- bcd )  d# 10 /mod  4 << +  ;

: bcd-time&date  ( -- s m h d m y century )
   set-address
[ifdef] cl2-a1
   9 0 smb-read-n  ( s m h dow d m y control c )
[else]
   0 1 9 twsi-get  ( s m h dow d m y control c )
[then]
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

end-package
