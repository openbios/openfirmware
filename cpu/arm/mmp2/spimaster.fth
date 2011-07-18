\ See license at end of file
purpose: Driver for Marvell MMP2 SSP in SPI Master Mode

0 0  " d4035000"  " /" begin-package   	\ SPI interface using SSP1

headerless

" spi"     device-name

0 0 encode-bytes
   " Marvell,ssp-spi"  encode-string encode+
" compatible" property

my-address      my-space  h# 1000  encode-reg
" reg" property

\ 1 " #address-cells"  integer-property
\ 0 " #size-cells"     integer-property

3 /n* buffer: port-data
: init-queue  ( -- )  port-data  3 na+  bounds  ?do  -1 i !  /n +loop  ;

my-space value ssp-base
: ssp-sscr0  ( -- adr )  ssp-base  ;
: ssp-sscr1  ( -- adr )  ssp-base  la1+  ;
: ssp-sssr   ( -- adr )  ssp-base  2 la+  ;
: ssp-ssdr   ( -- adr )  ssp-base  4 la+  ;

: enable  ( -- )
   h# 87 ssp-sscr0 rl!   \ Enable, 8-bit data, SPI normal mode
;
: disable  ( -- )
   h# 07 ssp-sscr0 rl!   \ 8-bit data, SPI normal mode
;
\ Switch to master mode, for testing
: master  ( -- )
   disable
   h# 0000.0000 ssp-sscr1 rl!  \ master mode
   enable
;

: ssp1-clk-on  7 h# 015050 io!   3 h# 015050 io!  ;
\ : ssp2-clk-on  7 h# 015054 io!   3 h# 015052 io!  ;
\ : ssp3-clk-on  7 h# 015058 io!   3 h# 015058 io!  ;
\ : ssp4-clk-on  7 h# 01505c io!   3 h# 01505c io!  ;

: wb  ( byte -- )  ssp-ssdr rl!  ;
: rb  ( -- byte )  ssp-ssdr rl@ .  ;

: select-ssp1-pins  ( -- )  d# 47  d# 43  do  h# c3 i af!  loop  ;

\ Choose alternate function 4 (SSP3) for the pins we use
: init-ssp-in-master-mode  ( -- )
   select-ssp1-pins
   ssp1-clk-on
   disable   \ 8-bit data, SPI normal mode
   0 ssp-sscr1 rl!  \ master mode
   \ The enable bit must be set last, after all configuration is done
   enable   \ Enable, 8-bit data, SPI normal mode
;

: .ssr  ssp-sssr rl@  .  ;
: ssp-#bytes  ( -- n )  ssp-sssr rl@ d# 12 rshift h# f and  ;

0 value open-count
: open  ( -- flag )
   open-count  0=  if
      my-address my-space  h# 1000  " map-in" $call-parent  is ssp-base
      init-ssp-in-master-mode
   then
   open-count 1+ to open-count
   true
;
: close  ( -- )
   open-count 1 =  if
      ssp-base h# 1000  " map-in" $call-parent  0 is ssp-base
   then
   open-count 1- 0 max to open-count
;
end-package

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
