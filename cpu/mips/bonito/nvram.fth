purpose: Driver for upper RAM portion of the PC97307
copyright: Copyright 2001 FirmWorks  All Rights Reserved

d# 128 value /nvram

0 instance value nvram-ptr

: nvram-bank-setup  ( -- saved-a )
   a rtc@
   dup h# 8f and h# 30 or a rtc!
;
: nvram-bank-restore  ( saved-a -- )  a rtc!  ;
: upper@  ( offset -- n )  50 rtc!  53 rtc@  ;
: upper!  ( n offset -- )  50 rtc!  53 rtc!  ;

: nvram@  ( offset -- n )  nvram-bank-setup >r upper@ r> nvram-bank-restore  ;
: nvram!  ( n offset -- )  nvram-bank-setup >r upper! r> nvram-bank-restore  ;
' nvram@ to nv-c@
' nvram! to nv-c!

\ headers
: clip-size  ( adr len -- len' adr len' )
   nvram-ptr +   /nvram min  nvram-ptr -     ( adr len' )
   tuck
;
: update-ptr  ( len' adr -- len' )
   drop  dup nvram-ptr +  to nvram-ptr
;

\ external
: seek  ( d.offset -- status )
   0<>  over /nvram u>  or  if  drop true  exit	 then  \ Seek offset too large
   to nvram-ptr
   false
;
: read  ( adr len -- actual )
   clip-size  0  ?do           ( len' adr )
      i nvram-ptr +  nvram@    ( len' adr value )
      over i + c!              ( len' adr )
   loop                        ( len' adr )
   update-ptr                  
;
: write  ( adr len -- actual )
   clip-size  0  ?do           ( len' adr )
      dup i + c@               ( len' adr value )
      i nvram-ptr +  nvram!    ( len' adr )
   loop                        ( len' adr )
   update-ptr                  ( len' )
;
: size  ( -- d )  /nvram 0  ;

