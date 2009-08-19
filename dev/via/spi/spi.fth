\ See license at end of file
purpose: Driver for Via VX8xx SPI controller, for FLASH reprogramming

[ifndef] spi0-mmio-base h# fed4.0000 constant spi0-mmio-base  [then]

0 0 " " " /" begin-package

" spi" device-name

0 value spi-base
0 value spi0-base
: spi-b@  ( offset -- b )  spi0-base + c@  ;
: spi-b!  ( b offset -- )  spi0-base + c!  ;
: spi-w@  ( offset -- w )  spi0-base + w@  ;
: spi-w!  ( w offset -- )  spi0-base + w!  ;
: spi-l@  ( offset -- l )  spi0-base + l@  ;
: spi-l!  ( l offset -- )  spi0-base + l!  ;

: set-spi-base  ( adr -- )
   dup  lbsplit  h# 88be config-b!  h# 88bd config-b!  h# 88bc config-b!  drop  ( adr )
   h# 1000 " map-in" $call-parent to spi-base
;
: set-spi0-base  ( adr -- )
   dup 1 or spi-base l!
   h# 1000 " map-in" $call-parent to spi0-base
;
: grab-spi  ( -- )
   h# 88e4 config-b@ 2 invert and  h# 88e4 config-b!  \ SPI mode for pins
;
: release-spi  ( -- )
   0 spi-base l!  \ Disable controller
   h# 88e4 config-b@ 2 or  h# 88e4 config-b!  \ GPIO mode for pins
;

: pio33mhz  ( -- )   \ Fastest PIO mode
   h# 00 h# 6c spi-b!    \ 33 MHz
   h# 04 h# 6e spi-b!    \ Sample on falling edge
   h# 08 h# 6d spi-b!    \ Dynamic clock, PIO mode, command posted write off   
;
: dma16mhz  ( -- )   \ Fastest DMA mode
   h# 01 h# 6c spi-b!    \ 33/(2*1) MHz
   h# 03 h# 6e spi-b!    \ Delay mode 3
   h# 48 h# 6d spi-b!    \ Dynamic clock, DMA mode, command posted write off   
;
: pio8mhz  ( -- )
   h# 02 h# 6c spi-b!    \ 33/(2*2) MHz
   h# 00 h# 6e spi-b!    \ No special clocking
   h# 08 h# 6d spi-b!    \ Dynamic clock, PIO mode, command posted write off   
;
: dma8mhz  ( -- )
   h# 02 h# 6c spi-b!    \ 33/(2*2) MHz
   h# 00 h# 6e spi-b!    \ No special clocking
   h# 48 h# 6d spi-b!    \ Dynamic clock, DMA mode, command posted write off   
;
: init-spi  ( -- )
   grab-spi
   spi-mmio-base set-spi-base
   spi0-mmio-base set-spi0-base
   h# 0c h# 00 spi-b!    \ Clear RW1C status bits
   h# 00 h# 70 spi-b!    \ All interrupts off
   h# ff h# 73 spi-b!    \ Clear DMA buffer interrupts
   pio8mhz
;

: rb spi-b@ . ;  : wb spi-b! ;
: rw spi-w@ . ;  : ww spi-w! ;
: rl spi-l@ . ;  : wl spi-l! ;

: open ( -- okay? )  init-spi true  ;
: close  ( -- )  release-spi  ;

: wait-ready  ( -- )  begin  0 spi-w@ 1 and 0=  until  ;
: wait-done  ( -- )  begin  0 spi-w@ 4 and  until  ;
: clear-done  ( -- )   4 0 spi-w!  ;
: spi-cmd!  ( bits -- )  2 spi-w!  ;

: spi-go  ( -- )
   2 spi-cmd!    ( )  \ Set go bit
   wait-done     ( )  \ Wait for done bit
   0 spi-cmd!    ( )  \ Clear go bit
   \ The go bit must be cleared before clear-done, otherwise clear-done will not work
   clear-done    ( )  \ Clear done bit
;

: dma-setup
   h#   200000 h# 74 spi-l!  \ Buffer to read from
   h#   100000 h# 78 spi-l!  \ Buffer to write to
   h# 10001000 h# 7c spi-l!  \ Buffer wraparound boundaries
;

h#  20 buffer: (out-buf)
h# 400 buffer:  (in-buf)

\ Prevent wrap-around; the DMA address register has issues with boundaries.
: out-buf  ( -- adr )  (out-buf) h# 10 round-up  ;
: in-buf   ( -- adr )  (in-buf) h# 200 round-up  ;

\ Return the largest length that does not fall in one of the
\ (undocumented) gaps where the DMA counter doesn't work right

: best-length  ( len -- len' )
   dup h# 1fc >  if  drop h# 1fc exit  then  ( len )
   dup h# 17d h# 183 between  if  drop h# 17c exit  then   ( len )
   dup h# 0fd h# 103 between  if  drop h# 0fc exit  then   ( len )
   dup h# 07d h# 083 between  if  drop h# 07c exit  then   ( len )
;

\ Read as many as possible up to len, accounting for unavailable lengths
: dma-read-some  ( adr len offset -- #read )
   swap best-length swap                 ( adr len' offset )
   dma16mhz                              ( adr len offset )
   wait-ready                            ( adr len offset )

   \ Setup command (3) and FLASH address
   3 out-buf c!                          ( adr len offset )
   lbsplit drop  out-buf 1+ c!  out-buf 2+ c! out-buf 3 + c!  ( adr len )
   
   \ Setup cycle control register with indicated read length (-1)
   \ and write length for 1 command byte plus 3 data bytes
   dup 1- 4 lshift  h# c003 or  h# 71 spi-w!    ( adr len )

   in-buf  >physical h# 78 spi-l!  \ Buffer to write to
   out-buf >physical h# 74 spi-l!  \ Buffer to read from
   h# 0200.0010 h# 7c spi-l!       \ Buffer wraparound boundaries

   spi-go                                ( adr len )
   tuck  in-buf -rot move                ( len )
;
: dma-read  ( adr len offset -- )
   begin  over  while                    ( adr len offset )
      3dup dma-read-some                 ( adr len offset #read )
      tuck +  >r                         ( adr len #read r: offset' )
      /string r>                         ( adr' len' offset' )   
   repeat                                ( adr len offset )
   3drop
;

[ifdef] notdef
: dma-out  ( len -- )
   h# 40 h# 6d spi-b!  0 2 spi-w!        ( len )
   wait-ready                            ( len )
   dma-setup

   \ Write to SPI mode
   h# 2000 h# 71 spi-w!                  ( len )
   
   spi-go
   2 2 spi-w!

   
   h# 200000 +                           ( endadr )
   begin  dup  h# 80 spi-l@  u<= until   ( endadr )
   drop                                  ( )
   0 2 spi-w!                            ( )
;
[then]

[ifdef] notdef

\ The following FLASH-mode commands don't work unless the Via chip
\ is hardware-strapped to use SPI FLASH as the boot ROM.  Without
\ that strapping, the SPI controller only works in device mode,
\ ignoring the atomic cycle bits, the address register, etc.
\ That fact is undocumented, but confirmed by Via.
: cmd-setup  ( -- )
   h# 06 h# 54 spi-b!  \ Write enable prefix   
   h# 06 h# 55 spi-b!  \ Write enable prefix (2)

   h# b9 h# 58 spi-b!  \ 0 Deep power down
   h# c7 h# 59 spi-b!  \ 1 Erase all
   h# d8 h# 5a spi-b!  \ 2 Erase 64K
   h# 02 h# 5b spi-b!  \ 3 Page Program
   h# 0b h# 5c spi-b!  \ 4 Fast Read
   h# 01 h# 5d spi-b!  \ 5 Write status register
   h# 05 h# 5e spi-b!  \ 6 Read status register
   h# ab h# 5f spi-b!  \ 7 Release power down

   h# f4 h# 56 spi-b!  \ 3WriteAddr, 2WriteAddr, 1Write, 0Read
   h# 46 h# 57 spi-b!  \ 7Write, 6Read, W5rite, 4ReadAddr
;

: spi-addr!  ( addr -- )  4 spi-l!  ;

: sector-erase  ( offset -- )
   wait-ready  spi-addr!  h# 0026 spi-cmd!
;
: erase-all  ( -- )  wait-ready  h# 0016 spi-cmd!  ;
: inject-bytes  ( adr len -- )
   0  ?do            ( adr )
      dup i + c@     ( adr byte )
      8 i + spi-b!   ( adr )
   loop              ( adr )
   drop              ( )
;
: program-bytes  ( adr len offset -- )
   wait-ready  spi-addr!  tuck   ( len adr len )
   inject-bytes
   1- 8 lshift h# 4036 or spi-cmd!
;
: program-page   ( adr len offset -- )
   wait-ready  spi-addr!                ( adr len )
   begin  dup  while                    ( adr len )
      2dup d# 16 min tuck               ( adr len thislen adr thislen )
      inject-bytes                      ( adr len thislen )
      dup 1- 8 lshift h# 4036 or        ( adr len thislen cmd )
      over d# 16 =  if  h# 80 or  then  ( adr len thislen cmd' )
      spi-cmd!                          ( adr len thislen )
      /string                           ( adr' len' )
   repeat                               ( adr' len' )
   2drop
;
: fast-read  ( adr len offset -- )
   wait-ready  spi-addr!                  ( adr len )
\  dup 1- 8 lshift  h# 6042 or  spi-cmd!  ( adr len )
   dup 1- 8 lshift  h# 4043 or  spi-cmd!  ( adr len )
   wait-done                              ( adr len )
   0  ?do                                 ( adr )
      8 i + spi-b@  dup i + c!            ( adr )
   loop  drop                             ( )
;
: power-down  ( -- )  wait-ready  h# 0006 spi-cmd!  ;
: power-up  ( -- )  wait-ready  h# 0072 spi-cmd!  ;
: sr!  ( value -- )  wait-ready  8 spi-b!  h# 4056 spi-cmd!  ;
: sr@  ( -- value )
   wait-ready h# 4062 spi-cmd!  wait-done  8 spi-b@
;
[then]

end-package

[ifdef] flash-read
: hw-flash-read  ( adr len offset -- )
   " /spi" open-dev >r          ( adr len offset )
   " dma-read" r@ $call-method  ( )
   r> close-dev                 ( )
;
: use-hw-spi-flash-read  ( -- )  ['] hw-flash-read to flash-read  ;
[then]

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
