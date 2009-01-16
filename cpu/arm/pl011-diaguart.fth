purpose: Diagnostic console driver for ARM PL011 PrimeCell UART

\ The following value is correct for UART0 on the VersatilePB board
\ Override the value after loading this file for different boards
h# 101f1000 value pl011-base

d# 7372800 value uartclk  \ Override as necessary
d# 115200 value diaguart-baud

: pl011@  ( offset -- value )  pl011-base + l@  ;
: pl011!  ( value offset -- )  pl011-base + l!  ;

: pl011-set-baud  ( baud -- )
   d# 16 *                   ( 16xbaud )

   uartclk over /mod         ( 16xbaud rem quot )
   h# 24 pl011!              ( rem r: 16xbaud )

   \ The fractional divisor goes from 0 to 63.  We rescale the
   \ remainder so the implied denominator is 64, with rounding.
   d# 128 rot */ 1+ 2/       ( frac r: 16xbaud )
   h# 28 pl011!              ( )
;
: init-pl011  ( -- )
   h#   0 h# 30 pl011!  \ Disable while programming
   0          4 pl011!  \ Clear errors
   0      h# 48 pl011!  \ Disable DMA
   0      h# 38 pl011!  \ Clear interrupt mask bits
   h# 7ff h# 44 pl011!  \ Clear pending interrupts
   diaguart-baud pl011-set-baud
   h#  70 h# 2c pl011!  \ 8 bits, FIFOs enabled, no parity
   h# f01 h# 30 pl011!  \ RTS, DTR, RXE, TXE, UARTEN (re-enable)
;

: ukey?  ( -- flag )  h# 18 pl011@  h# 10 and  0=  ;
: ukey  ( -- char )
   begin  ukey?  until
   0 pl011@  h# ff and
;
: uemit  ( char -- )
   begin  h# 18  pl011@  h# 20 and  0=  until
   0 pl011!
;


\ LICENSE_BEGIN
\ Copyright (c) 2009 FirmWorks
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
