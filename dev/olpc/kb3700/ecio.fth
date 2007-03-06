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
   h# 6c pc!  begin  h# 6c pc@  3 and  1 =  until  h# 68 pc@
   h# ff h# 6c pc!   \ Release ownership
;

: kb3920?  ( -- flag )  h# 6c pc@ h# ff =  if  true exit  then   9 ec-cmd 9 =  ;

\ While accessing the SPI FLASH, we have to turn off the keyboard controller,
\ because it continuously fetches from the SPI FLASH when it's on.  That
\ interferes with our accesses.

0 value kbc-off?
: kbc-off  ( -- )
   kbc-off?  if  exit  then  \ Fast bail out
   h# d8  h# 66  pc!
   d# 500000 0  do  h# 66 pc@ 2 and ?leave  loop
   h# ff14 ec@  1 or  h# ff14 ec!
   true to kbc-off?
;

\ Unfortunately, since the system reset is mediated by the keyboard
\ controller, turning the keyboard controller back on resets the system.

: kbc-on  ( -- )
   h# ff14 ec@  1 invert and  h# ff14 ec!  \ Innocuous if already on
   false to kbc-off?
;

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

: io-spi-start  ( -- )
   ['] io-spi@  to spi@
   ['] io-spi!  to spi!
   ['] io-spi-out to spi-out
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
