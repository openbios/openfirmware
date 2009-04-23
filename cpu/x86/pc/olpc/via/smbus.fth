h# xxx constant smbus-io-base
: smb-reg@  ( reg# -- value )  smbus-io-base + c@  ;
: smb-reg!  ( value reg# -- )  smbus-io-base + c!  ;

: smb-hostdata0@  ( -- byte )  5 smb-reg@  ;
: smb-hostdata0!  ( byte -- )  5 smb-reg!  ;
: smb-hostctl!    ( byte -- )  2 smb-reg!  ;
: smb-hostcmd!    ( byte -- )  3 smb-reg!  ;
: smb-xmitadr!    ( byte -- )  4 smb-reg!  ;
: smbus-delay  ( -- )  1 us  ;
: smbus-wait  ( -- )
   d# 1,000,000 0  do
      smbus-delay
      0 smb-reg@ 1 and 0=  if  unloop exit  then
   loop
   ." SMBUS timeout" cr
;
: smbus-reset  ( -- )
   h# ff 0 smb-reg!
   0 smb-hostdata0!   \ Clear host data port
   smbus-wait
;
: smb-fill ( adr len -- )
;

: ics-value0  ( -- adr len dev )
   " "(0d 00 3f cd 7f bf 1a 2a 01 0f 0b 80 8d 9b)" h# d2
;
: ics-value1  ( -- adr len dev )
   " "(08 ff 3f 00 00 ff ff ff ff)" h# d4
;
: smbus-write  ( adr len dev -- )
   smbus-reset
   0 smb-reg@ drop  \ Read to reset block transfer counter
   dup smb-xmitadr!   ( adr len )     \ Set transmit address
   tuck  bounds  ?do  i c@ 7 smb-reg!  loop  ( len )
   0 smb-hostcmd!      ( len )        \ Host command
   smb-hostdata0!      ( )            \ Length
   h# 74 smb-hostctl!  ( )
   smbus-wait          ( )
   smbus-reset         ( )
;
: get-spd-data  ( offset dimm -- byte )
   smbus-reset
   7 and 2* h# a1 or   ( offset dev )
   smb-xmitadr!        ( offset )
   smb-hstcmd!         ( )
   h# 48 smb-hstctl!   ( )
   smbus-wait         
   smb-hostdata0@      ( byte )
;
: enable-smbus  ( -- )
   h# 8894 config-b@  h# 80 invert and  h# 8894 config-b!  \ Clock from 14 MHz divider
   smbus-io-base 1 or  h# 88d0 config-w!
   5 h# 88d2 config-b!   \ Clock source (bit meaning is unclear), enable SMBUS HC
   3 h# 8804 config-w!   \ Enable in PCI command register
   smbus-reset
;
