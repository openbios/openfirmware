\ See license at end of file
\ Implementations of EC SPI register access words for the serial
\ line recovery mode.  These in turn depend on serial line access
\ words that are common to most FirmWorks-derived Forth systems.

: serial-spi@  ( reg# -- b )  uemit  ukey  ;
: serial-spi!  ( b reg# -- )  h# 80 or  uemit  uemit  ;

: serial-spi-start  ( -- )
[ifdef] open-serial  open-serial  [then]

   ['] serial-spi@  to spi@
   ['] serial-spi!  to spi!
   ['] spicmd!      to spi-out

   d# 200 to spi-us  \ Approximate time to do serial-spi!

   d# 57600 baud
   h# 5a uemit    ( divisor )  \ ( wait-tx )
   h# 88 spicfg!  ( divisor )  \ Write enable for SPICMD register
   h# 45 spibaud! ( )
   d# 115200 baud

   -1 to flash-base
;
: use-serial-ec  ( -- )  ['] serial-spi-start to spi-start  ;
use-serial-ec  \ Install this as the start-spi implementation
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
