\ See license at end of file
purpose: EC Commands for XO-1.75 and later

0 value ec-ih
: $call-ec  ( ... adr len -- ... )  ec-ih $call-method  ;
: do-ec-cmd  ( [ args ] #args #results cmd-code -- [ results ] )
   " ec-command" $call-ec  abort" EC command failed"
;
stand-init: EC
   " /ec-spi" open-dev to ec-ih   
;

: too-many-retries  ( -- )  true abort" Too many EC command retries"  ;
d# 10 constant #ec-retries

: ec-cmd  ( cmd -- )   0 0 rot do-ec-cmd  ;
: ec-cmd-b@  ( cmd -- w )   0 1 rot do-ec-cmd  bwjoin  ;
: ec-cmd-w@  ( cmd -- w )   0 2 rot do-ec-cmd  bwjoin  ;
: ec-cmd-l@  ( cmd -- l )   0 4 rot do-ec-cmd  bljoin  ;
: ec-cmd-b!  ( b cmd -- )   1 0 rot do-ec-cmd  ;
: ec-cmd-w!  ( w cmd -- )   >r wbsplit 2 0 r> do-ec-cmd  ;
: ec-cmd-l!  ( l cmd -- )   >r lbsplit 4 0 r> do-ec-cmd  ;

: ec-api-ver@    ( -- b )  h# 08 ec-cmd-b@  ;
: bat-voltage@   ( -- w )  h# 10 ec-cmd-w@  ;
: bat-current@   ( -- w )  h# 11 ec-cmd-w@  ;
: bat-acr@       ( -- w )  h# 12 ec-cmd-w@  ;
: bat-temp@      ( -- w )  h# 13 ec-cmd-w@  ;
: ambient-temp@  ( -- w )  h# 14 ec-cmd-w@  ;
: bat-status@    ( -- b )  h# 15 ec-cmd-b@  ;
: bat-soc@       ( -- b )  h# 16 ec-cmd-b@  ;

: (bat-gauge-id@)  ( -- sn0 .. sn7 )  0 8 h# 17 do-ec-cmd  ;
: bat-gauge-id@  ( -- sn0 .. sn7 )
   #ec-retries  0  do
      ['] (bat-gauge-id@) catch  0=  if  unloop exit  then
   loop
   too-many-retries
;
: (bat-gauge@)   ( -- b )  h# 31 1 1 h# 18 do-ec-cmd  ;  \ 31 is the EEPROM address
: bat-gauge@  ( -- b )
   #ec-retries  0  do
      ['] (bat-gauge@) catch  0=  if  unloop exit  then
   loop
   too-many-retries
;

: (bat-type@)    ( -- b )  h# 5f 1 1 h# 18 do-ec-cmd  ;  \ 5f is the EEPROM address
: bat-type@  ( -- b )
   #ec-retries  0  do
      ['] (bat-type@) catch  0=  if  unloop exit  then
   loop
   too-many-retries
;

: board-id  ( -- n )  h# 19 ec-cmd-w@  ;
: reset-ec  ( -- )  h# 28 ec-cmd  ;

: autowack-on      ( -- )         1 33 ec-cmd-b! ;
: autowack-off     ( -- )         0 33 ec-cmd-b! ;

: ec-echo  ( ... n -- ... )  dup h# 52 do-ec-cmd  ;

[ifdef] notdef
#define CMD_READ_BATT_ERR_CODE           0x1f
#define CMD_READ_BATTERY_TYPE            0x2c
#define CMD_SET_EC_WAKEUP_TIMER          0x36
#define CMD_READ_EXT_SCI_MASK            0x37
#define CMD_WRITE_EXT_SCI_MASK           0x38
#define CMD_CLEAR_EC_WAKEUP_TIMER        0x39
#define CMD_ENABLE_RUNIN_DISCHARGE       0x3B
#define CMD_DISABLE_RUNIN_DISCHARGE      0x3C
#define CMD_READ_MPPT_ACTIVE             0x3d
#define CMD_READ_MPPT_LIMIT              0x3e
#define CMD_SET_MPPT_LIMIT               0x3f
#define CMD_DISABLE_MPPT                 0x40
#define CMD_ENABLE_MPPT                  0x41
#define CMD_READ_VIN                     0x42
#define CMD_EXT_SCI_QUERY                0x43
#define CMD_READ_LOCATION                0x44
#define CMD_WRITE_LOCATION               0x45
#define CMD_KEYBOARD_CMD                 0x46
#define CMD_TOUCHPAD_CMD                 0x47
#define RSP_KEYBOARD_DATA                0x48
#define RSP_TOUCHPAD_DATA                0x49
#define CMD_GET_FW_VER                   0x4a
#define CMD_POWER_CYCLE                  0x4b
#define CMD_POWER_OFF                    0x4c
#define CMD_RESET_EC_SOFT                0x4d
#define CMD_READ_GUAGE_U16               0x4e
#define CMD_ENABLE_MOUSE                 0x4f
[then]

\ LICENSE_BEGIN
\ Copyright (c) 2010 FirmWorks
\ 
\ Permission is hereby granted, free of charge, to any person obtaining
\ a copy of this software and associated documentation files (the
\ "Software"), to deal in the Software without restriction, including
\ without limitation the rights to use, copy, modify, merge, publish,
\ distribute, sublicense, and/or sell copies of the Software, and to
\ permit persons to whom the Software is furnished to do so, subject to
\ the following conditions:
\ 
\ The above copyright notice and this permission notice shall be
\ included in all copies or substantial portions of the Software.
\ 
\ THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
\ EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
\ MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
\ NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
\ LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
\ OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
\ WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
\
\ LICENSE_END
