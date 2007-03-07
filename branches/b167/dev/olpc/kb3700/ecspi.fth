\ See license at end of file
\ Access primitives for SPI FLASH

\ These defer words are the interface to the access path to the EC.
\ There are two such paths - from onboard via I/O port accesses, and
\ from an external system via a serial line (with the EC in recovery mode).
\ The implementations of these access methods are defined in other files
\ because they depend on details of the host system.

-1 value flash-base            \ If not -1, memory mapped FLASH address
defer spi-start ( -- )         \ Init routine for the access path to the EC
defer spi@      ( reg# -- b )  \ Read an EC SPI register
defer spi!      ( b reg# -- )  \ Write an EC SPI register
defer spi-out   ( b -- )       \ Write SPI command and wait if necessary
1 value spi-us  ( -- n )       \ Approximate time in uS to do spi!
                               \ Used to optimize some routines

\ Symbolic names for the registers that control SPI access from the EC

: spidata@  ( -- b )  3 spi@  ;   : spidata!  ( b -- )  3 spi!  ;
: spicmd@   ( -- b )  4 spi@  ;   : spicmd!   ( b -- )  4 spi!  ;
: spicfg@   ( -- b )  5 spi@  ;   : spicfg!   ( b -- )  5 spi!  ;
: spidatr@  ( -- b )  6 spi@  ;

: spicon3@  ( -- b )  7 spi@  ;

\ Write: Baud rate - 0x89 for 57600, 0x45 for 115200 (for 8 MHz 8051 clock)
: spibaud!  ( b -- )  7 spi!  ;

[ifdef] spi-hw-mode
\ This is for hardware mode.  You set up the address and the
\ hardware pumps out the bytes.  But that apparently doesn't
\ work correctly for some SPI FLASH chips.  Bad timing or something.
: spiaddr!  ( addr -- )  lbsplit drop  2 spi!  1 spi!  0 spi!  ;

: enable-flash  ( -- )  spicfg@  8 or  spicfg!  ;  \ SPICMDWE
[then]

\ I'm not sure this delay is necessary, but the EnE code did it, so
\ I'm being safe.  The EnE code did 4 PCI reads of the base address
\ which should be around 800nS.  2 uS should cover it in case I'm wrong
: short-delay  ( -- )  2 us  ;

\ Some chips (e.g. Spansion) don't work in hardware mode, so we do
\ everything in "firmware mode", where we have control over the SPI bus.
\ Every spicmd! clocks out 8 bits.  To read, you have to do a dummy
\ write of the value 0, then you can read the data from the spidata register.

\ Turning on the firmware mode bit asserts SPICS#
\ Turning off the firmware mode bit deasserts SPICS#

: spi-cs-on   ( -- )  h# 18 spicfg!  short-delay  ;  \ 10 is the firmware mode bit
: spi-cs-off  ( -- )  h# 08 spicfg!  ;

\ Poll the spicfg register waiting for the busy bit to go away
\ This tells you when the hardware has finished sending the byte
\ out serially over the SPI lines.

: spi-cmd-wait  ( -- )
   begin
      h# 1000000 0  do
         spicfg@  2 and  0=  if  unloop  exit  then  \ SPIBUSY
         d# 1 us
      loop
      ." ."
   again
;

\ To read a byte from SPI, the EC has to pulse the clock while the
\ SPI flash device drives DO.  The "0 spi-out" is a "dummy write"
\ that pulses the clock 8 times.  The data can then be read from the
\ spidata register.

: spi-in  ( -- b )  0 spi-out  spidata@  ;
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
