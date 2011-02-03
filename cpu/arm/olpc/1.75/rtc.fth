0 0  " "  " /" begin-package
" rtc" name

[ifdef] cl2-a1
: set-address  ( -- )
   d# 97 to smb-clock-gpio#
   d# 98 to smb-data-gpio#
   h# d0 to smb-slave
;
: rtc@  ( reg# -- byte )  set-address  smb-byte@  ;
: rtc!  ( byte reg# -- )  set-address  smb-byte!  ;
[else]
: set-address  ( -- )   h# d0 2 set-twsi-target  ;
: rtc@  ( reg# -- byte )  set-address  twsi-b@  ;
: rtc!  ( byte reg# -- )  set-address  twsi-b!  ;
[then]

headerless

headerless

headers
: open  ( -- true )
   true
;
: close  ( -- )
;

headerless
: bcd>  ( bcd -- binary )  dup h# f and  swap 4 >>  d# 10 *  +  ;
: >bcd  ( binary -- bcd )  d# 10 /mod  4 << +  ;

: bcd-time&date  ( -- s m h d m y century )
   set-address
[ifdef] cl2-a1
   7 0 smb-read-n  ( s m h dow d m y )
[else]
   0 1 7 twsi-get  ( s m h dow d m y )
[then]
   3 roll drop     ( s m h dow d m y )
   d# 20
;
: bcd!  ( n offset -- )  swap >bcd  swap rtc!  ;

headers
: get-time  ( -- s m h d m y )
   bcd-time&date  >r >r >r >r >r >r
   bcd>  r> bcd>  r> bcd>  r> bcd>  r> bcd>  r> bcd>  r> bcd> ( s m h d m y c )

   d# 100 * +  		\ Merge century with year
;
: set-time  ( s m h d m y -- )
   d# 100 /mod  h# 1a bcd!  9 bcd!  8 bcd!  7 bcd!  4 bcd!  2 bcd!  0 bcd!
;

: selftest  ( -- flag )
   open  0=  if  true  close exit  then
   0 rtc@  d# 1100 ms  0 rtc@  =  if
      ." RTC did not tick" cr
      true  close  exit
   then
   close
   false
;

end-package
