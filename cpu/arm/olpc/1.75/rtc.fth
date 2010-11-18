0 0  " "  " /" begin-package
" rtc" name

: set-address  ( -- )  h# d0 2 set-twsi-target  ;
: rtc@  ( reg# -- byte )  set-address  twsi-b@  ;
: rtc!  ( byte reg# -- )  set-address  twsi-b!  ;

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
   0 1 7 twsi-get   ( s m h dow d m y )
   3 roll drop      ( s m h dow d m y )
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
