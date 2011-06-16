\ See license at end of file
purpose: EC Commands for XO-1.75 and later

0 value ec-ih
: $call-ec  ( ... adr len -- ... )  ec-ih $call-method  ;
: do-ec-cmd  ( [ args ] #args #results cmd-code -- [ results ] )
   " ec-command" $call-ec
;
: do-ec-cmd-buf  ( [ args ] #args #results cmd-code -- buf-adr )
   " ec-command-buf" $call-ec
;
stand-init: EC
   " /ec-spi" open-dev to ec-ih   
;

: too-many-retries  ( -- )  true abort" Too many EC command retries"  ;
d# 10 constant #ec-retries

: ec-cmd  ( cmd -- )   0 0 rot do-ec-cmd  ;
: ec-cmd-b@  ( cmd -- b )   0 1 rot do-ec-cmd          ;
: ec-cmd-w@  ( cmd -- w )   0 2 rot do-ec-cmd  bwjoin  ;
: ec-cmd-l@  ( cmd -- l )   0 4 rot do-ec-cmd  bljoin  ;
: ec-cmd-b!  ( b cmd -- )   1 0 rot do-ec-cmd  ;
: ec-cmd-w!  ( w cmd -- )   >r wbsplit 2 0 r> do-ec-cmd  ;
: ec-cmd-l!  ( l cmd -- )   >r lbsplit 4 0 r> do-ec-cmd  ;

fload ${BP}/dev/olpc/kb3700/eccmdcom.fth  \ Common commands 

\ Commands that are different for XO-1.75
: board-id@      ( -- n )  h# 19 ec-cmd-w@  ;
: bat-cause@     ( -- b )  h# 1f ec-cmd-b@  ;

: (bat-gauge-id@)  ( -- sn0 .. sn7 )  0 8 h# 17 do-ec-cmd  ;
: bat-gauge-id@  ( -- sn0 .. sn7 )
   #ec-retries  0  do
      ['] (bat-gauge-id@) catch  0=  if  unloop exit  then
   loop
   too-many-retries
;

: bat-type@  ( -- b )  h# 2c ec-cmd-b@  ;

: ec-wackup  ( ms -- )  lbsplit 4 0 h# 36 do-ec-cmd  ;

: bat-gauge@  ( -- w )  h# 4e ec-cmd-w@  ;

: cscount-max  ( adr maxlen -- adr len )
   dup 0  ?do        ( adr maxlen )
      over i + c@ 0=  if
         drop i unloop exit
      then
   loop
;
: ec-name$  ( -- adr len )
   0 d# 16 h# 4a do-ec-cmd-buf   ( adr )
   d# 16 cscount-max
;

: ec-power-cycle ( -- ) h# 4b ec-cmd ;
: ec-power-off   ( -- ) h# 4c ec-cmd ;

: ec-echo  ( ... n -- ... )  dup h# 52 do-ec-cmd  ;

: ec-date$  ( -- adr len )
   0 d# 16 h# 53 do-ec-cmd-buf   ( adr )
   d# 16 cscount-max
;

: ec-user$  ( -- adr len )
   0 d# 16 h# 54 do-ec-cmd-buf   ( adr )
   d# 16 cscount-max
;

: ec-hash$  ( -- adr len )
   0 d# 16 h# 55 do-ec-cmd-buf   ( adr )
   d# 16 cscount-max
;

: als@      ( -- w )  h# 56 ec-cmd-w@  ;

[ifdef] notdef  \ These commands are awaiting documentation on their interfaces
#define CMD_READ_EXT_SCI_MASK            0x37
#define CMD_WRITE_EXT_SCI_MASK           0x38
#define CMD_CLEAR_EC_WAKEUP_TIMER        0x39
#define CMD_ENABLE_RUNIN_DISCHARGE       0x3B
#define CMD_DISABLE_RUNIN_DISCHARGE      0x3C
#define CMD_EXT_SCI_QUERY                0x43
#define CMD_READ_LOCATION                0x44
#define CMD_WRITE_LOCATION               0x45
#define RSP_KEYBOARD_DATA                0x48
#define RSP_TOUCHPAD_DATA                0x49
#define CMD_RESET_EC_SOFT                0x4d
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
