\ See license at end of file
purpose: Driver for "EC" (KB3700) chip

\ EC access primitives

h# 380 constant iobase

: ec@  ( index -- b )  wbsplit iobase 1+ pc!  iobase 2+ pc!  iobase 3 + pc@  ;
: ec!  ( b index -- )  wbsplit iobase 1+ pc!  iobase 2+ pc!  iobase 3 + pc!  ;

: ec-dump  ( offset len -- )
   ." Addr   0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f" cr  cr
   push-hex
   bounds  ?do
      i 4 u.r space
      i h# 10 bounds  do  i ec@ 3 u.r  loop  cr
      exit? ?leave
   h# 10 +loop
   pop-base
;

\ EC internal addresses

h# fc2a	constant GPIO5

: flash-write-protect-on  ( -- )  GPIO5 ec@  h# 80 invert and  GPIO5 ec!  ;

: flash-write-protect-off  ( -- )  GPIO5 ec@  h# 80 or  GPIO5 ec!  ;


: ec-cmd  ( cmd -- response )
   h# 6c pc!  begin  1 ms  h# 6c pc@  3 and  1 =  until  1 ms  h# 68 pc@
   h# ff h# 6c pc!   \ Release ownership
;

: ec-cmd66  ( byte -- )
   h# 66  pc! 
   \ It typically requires about 200 polls
   d# 4000 0  do  1 ms  h# 66 pc@ 2 and 0=  if  unloop exit  then  loop
   true abort" EC didn't respond to port 66 command"
;

: ec-cmd@  ( -- b )  h# 6c pc@  ;

: ec-release  ( -- )  h# ff h# 6c pc!  1 ms  h# 68 pc@  drop  ;
: ec-wait-wr  ( -- )
   d# 140 0  do
      ec-cmd@ 2 and  0=  if  unloop exit  then
      5 ms
   loop
   ." EC write timed out" cr
;
\ Empirically, it can take a long time for the EC to sense the game
\ keys when several are down at once.  500 mS is not enough.
: ec-wait-rd  ( -- )
   d# 700 0  do
      ec-cmd@ 1 and  if  unloop exit  then
      d# 1 ms
   loop
   ." EC read timed out" cr
;
: flush-ec  ( -- )
   begin  ec-cmd@  dup h# 80 and  while
      drop  ." EC release" cr  ec-release  d# 10 ms
   repeat  ( 6c-val )

   begin  1 and  while            ( )
      h# 68 pc@ drop              ( )
      d# 200 us                   ( )
      ec-cmd@                     ( 6c-val )
   repeat                         ( 6c-val )
;
: ec-cmd!  ( b -- )  ec-wait-wr  h# 6c pc!  ec-wait-wr  ;

: ec-dat@  ( -- b )  ec-wait-rd  h# 68 pc@  ;
: ec-dat!  ( b -- )  ec-wait-wr  h# 68 pc!  ;

: ec-rb    ( -- b )  0 ec-dat!  ec-dat@  ;
: ec-rw    ( -- w )  ec-rb ec-rb swap bwjoin  ;
: ec-wb    ( -- w )  ec-dat!  ;
: ec-ww    ( -- w )  wbsplit ec-wb ec-wb  ;

: ec-cmda  ( b -- )  flush-ec  ec-cmd!  ec-dat@ drop  ;
: ec-cmd0  ( -- )  ec-cmda ec-release  ;

: ec-cmd-w@  ( cmd -- w )  ec-cmda  ec-rw  ec-release  ;
: ec-cmd-b@  ( cmd -- w )  ec-cmda  ec-rb  ec-release  ;
: ec-cmd-b!  ( b cmd -- )  ec-cmda  ec-wb  ec-release  ;

: bat-voltage@   ( -- w )  h# 10 ec-cmd-w@  ;
: bat-current@   ( -- w )  h# 11 ec-cmd-w@  ;
: bat-acr@       ( -- w )  h# 12 ec-cmd-w@  ;
: bat-temp@      ( -- w )  h# 13 ec-cmd-w@  ;
: ambient-temp@  ( -- w )  h# 14 ec-cmd-w@  ;
: bat-status@    ( -- b )  h# 15 ec-cmd-b@  ;
: bat-soc@       ( -- b )  h# 16 ec-cmd-b@  ;
: bat-gauge-id@  ( -- sn0 .. sn7 )
   h# 17 ec-cmda
   8 0  do ec-rb  loop
   ec-release
;
: bat-gauge@     ( -- b )  h# 18 ec-cmda  h# 31 ec-wb  ec-dat@  ec-release  ;  \ 31 is the EEPROM address
: board-id@      ( -- b )  h# 19 ec-cmd-b@  ;
: sci-source@    ( -- b )  h# 1a ec-cmd-w@  ;
: sci-mask!      ( b -- )  h# 1b ec-cmd-b!  ;
: sci-mask@      ( -- b )  h# 1c ec-cmd-b@  ;
: game-key@      ( -- w )  h# 1d ec-cmda  ec-rw  ec-release  ;
: ec-date!       ( day month year -- )  h# 1e ec-cmda  ec-wb ec-wb ec-wb  ec-release  ;
: ec-abnormal@   ( -- b )  h# 1f ec-cmd-b@  ;  \ XXX is this byte or word?

: bat-init-lifepo4 ( -- )  h# 21 ec-cmd0  ;
: bat-init-nimh    ( -- )  h# 22 ec-cmd0  ;
: wlan-off         ( -- )  0 h# 23 ec-cmd-b!  ;
: wlan-on          ( -- )  1 h# 23 ec-cmd-b!  ;
: wlan-wake        ( -- )  h# 24 ec-cmd0  ;
: wlan-rst         ( -- )  h# 25 ec-cmd0  ;
: dcon-disable     ( -- )  0 h# 26 ec-cmd-b!  ;
: dcon-enable      ( -- )  1 h# 26 ec-cmd-b!  ;
: reset-ec-warm    ( -- )  h# 27 ec-cmd0  ;
: reset-ec         ( -- )  h# 28 ec-cmd0  ;
: write-protect-fw ( -- )  h# 29 ec-cmd0  ;
\ : disable-ec-io    ( -- )  h# 2a ec-cmd0  ;  \ ???

\ EC mailbox access words

: ec-mb-adr@   ( -- w )  h# 80 ec-cmda  ec-rw  ;
: ec-mb-adr!   ( w -- )  h# 81 ec-cmda  ec-ww  ;
: ec-mb-setup  ( cmd w -- )  ec-mb-adr!  ec-cmda  ;

: ec-mb-b@    ( adr -- b )  h# 8a ec-mb-setup  h# 84 ec-cmd-b@  ;
: ec-mb-w@    ( adr -- w )  h# 88 ec-mb-setup  h# 82 ec-cmd-w@  ;
: ec-mb-b!    ( b adr -- )  h# 85 ec-mb-setup  ec-wb  h# 8b ec-cmda  ec-release  ;
: ec-mb-w!    ( w adr -- )  h# 83 ec-mb-setup  ec-ww  h# 89 ec-cmda  ec-release  ;

\ SCI source codes:
\ SCI_WAKEUP_EVENT             0x01   // Game button,
\ SCI_BATTERY_STATUS_CHANGE    0x02   // AC plugged/unplugged, ...
\    Battery inserted/remove, Battery Low, Battery full, Battery destroy
\ SCI_SOC_CHANGE               0x04   // SOC Change
\ SCI_ABNORMAL_EVENT           0x08                              
\ SCI_EB_MODE_CHANGE           0x10

\ This command hard-resets the EC deeply enough for the SP write-protect to
\ be off when the system is powered up again.

: ec-reset  ( -- )  5  ec-cmd  ;

: kb3920?  ( -- flag )  h# 6c pc@ h# ff =  if  true exit  then   9 ec-cmd 9 =  ;

: snoop-board-id@  ( -- id )  h# fa20 ec@  ;

\ While accessing the SPI FLASH, we have to turn off the keyboard controller,
\ because it continuously fetches from the SPI FLASH when it's on.  That
\ interferes with our accesses.

0 value kbc-off?
: kbc-off  ( -- )
   kbc-off?  if  exit  then  \ Fast bail out
   h# d8 ec-cmd66      \ Prepare for reset
   h# ff14 ec@  1 or  h# ff14 ec!
   true to kbc-off?
;

\ Unfortunately, since the system reset is mediated by the keyboard
\ controller, turning the keyboard controller back on resets the system.

: kbc-on  ( -- )
   h# ff14 ec@  1 invert and  h# ff14 ec!  \ Innocuous if already on
   false to kbc-off?
;

\ kbc-pause temporarily halts execution of the keyboard controller microcode.
\ kbc-resume makes it run again, picking up where it left off.
\ This is useful for accessing the SPI FLASH in cases where you do not
\ overwrite the keyboard controller microcodes.

: kbc-pause  ( -- )   h# dd ec-cmd66  ;
: kbc-resume  ( -- )  h# df ec-cmd66  ;



: kbd-led-on  ( -- )  h# fc21 ec@  1 invert and  h# fc21 ec!  ;
: kbd-led-off ( -- )  h# fc21 ec@  1 or  h# fc21 ec!  ;

: wlan-reset  ( -- )
   \ WLAN reset is EC GPIOEE, controlled by EC registers fc15 and fc25
   h# fc15 ec@   h# fc25 ec@           ( enable data )
   dup  h# 40 invert and  h# fc25 ec!  ( enable data )  \ WLAN_RESET data output low
   over h# 40 or          h# fc15 ec!  ( enable data )  \ Assert output enable
   1 ms
   h# 40 or          h# fc25 ec!       ( enable )       \ Drive data high
   h# 40 invert and  h# fc15 ec!       ( )              \ Release output enable
;

: io-spi@  ( reg# -- b )  h# fea8 +  ec@  ;
: io-spi!  ( b reg# -- )  h# fea8 +  ec!  ;

\ We need the spi-cmd-wait because the data has to go out
\ serially on the SPI bus and that is a bit slower than
\ the IO port access.  We must wait to avoid overwriting
\ the command register during the serial tranfer.

: io-spi-out  ( b -- )  spicmd!  spi-cmd-wait  ;

: io-spi-reprogrammed  ( -- )
   ." Powering off..."  d# 2000 ms  cr
   power-off
;

: io-spi-start  ( -- )
   ['] io-spi@  to spi@
   ['] io-spi!  to spi!
   ['] io-spi-out to spi-out
   ['] io-spi-reprogrammed to spi-reprogrammed
   h# fff0.0000 to flash-base

   7 to spi-us   \ Measured time for "1 fea9 ec!" is 7.9 uS

   kbc-off
;
: use-local-ec  ( -- )  ['] io-spi-start to spi-start  ;
use-local-ec
\ LICENSE_BEGIN
\ Copyright (c) 2006 FirmWorks
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
