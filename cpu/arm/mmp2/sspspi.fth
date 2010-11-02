\ See license at end of file
\ Access primitives for SPI FLASH using Marvell MMP2 SSP

\ Some chips (e.g. Spansion) don't work in hardware mode, so we do
\ everything in "firmware mode", where we have control over the SPI bus.
\ Every spicmd! clocks out 8 bits.  To read, you have to do a dummy
\ write of the value 0, then you can read the data from the spidata register.

h# d4035000 value ssp-base  \ SSP1
: ssp-sscr0  ( -- adr )  ssp-base  ;
: ssp-sscr1  ( -- adr )  ssp-base  la1+  ;
: ssp-sssr   ( -- adr )  ssp-base  2 la+  ;
: ssp-ssdr   ( -- adr )  ssp-base  4 la+  ;


: ssp-spi-start  ( -- )
   h# 07 ssp-sscr0 l!
   0 ssp-sscr1 l!
   h# 87 ssp-sscr0 l!   
   d# 46 gpio-set
   d# 46 gpio-dir-out
   h# c0 d# 46 af!
;
: ssp-spi-cs-on   ( -- )  d# 46 gpio-clr  ;
: ssp-spi-cs-off  ( -- )  d# 46 gpio-set  ;

: ssp-spi-out-in  ( bo -- bi )
   begin  ssp-sssr l@ 4 and  until  \ Tx not full
   ssp-ssdr l!
   begin  ssp-sssr l@ 8 and  until  \ Rx not empty
   ssp-ssdr l@
;

: ssp-spi-out  ( b -- )  ssp-spi-out-in drop  ;
: ssp-spi-in  ( -- b )  0 ssp-spi-out-in  ;

: safe-spi-start
   ssp-spi-start
   \ The following clears out some glitches so the chip will respond
   \ to the ab-id command.
   0 spi-cmd spi-cs-off
   0 spi-cmd spi-cs-off
;

: use-ssp-spi  ( -- )
   ['] safe-spi-start to spi-start
   ['] ssp-spi-in     to spi-in
   ['] ssp-spi-out    to spi-out
   ['] ssp-spi-cs-on  to spi-cs-on
   ['] ssp-spi-cs-off to spi-cs-off
   ['] ssp-spi-reprogrammed to spi-reprogrammed
   use-spi-flash-read
;
use-ssp-spi

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
