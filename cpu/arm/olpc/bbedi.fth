\ See license at end of file
purpose: Bit-banged SPI bus driver for KB3731 EC "EDI" interface

: edi-cs-on   ( -- )  ec-edi-cs-gpio# gpio-clr  ;
: edi-cs-off  ( -- )  ec-edi-cs-gpio# gpio-set  ;

: edi-clk-lo  ( -- )  ec-edi-clk-gpio# gpio-clr  ;
: edi-clk-hi  ( -- )  ec-edi-clk-gpio# gpio-set  ;

\ This must be done in code to satisfy the stringent timing requirements of the EDI hardware
code edi-out  ( byte -- )
   mov   r2,#8
   mov   r0,#0x200           \ MOSI mask
   set   r1,`h# 19100 +io #` \ GPIO register address
   mov   r4,#0x400           \ CLK mask
   begin
      ands  r3,tos,#0x80   \ Test bit

[ifdef] olpc-cl4
      strne r0,[r1,#0x18]  \ Set MOSI if bit is non0
      streq r0,[r1,#0x24]  \ Clr MOSI if bit is 0
[else]
      strne r0,[r1,#0x18]  \ Set MOSI if bit is non0
      strne r0,[r1,#0x18]  \ Set MOSI if bit is non0  \ Twice for delay - setup time to CLK
      streq r0,[r1,#0x24]  \ Clr MOSI if bit is 0
      streq r0,[r1,#0x24]  \ Clr MOSI if bit is 0  \ Twice for delay - setup time to CLK
[then]

      str   r4,[r1,#0x18]  \ Set CLK
      str   r4,[r1,#0x24]  \ Clr CLK

      add   tos,tos,tos    \ Left shift TOS      
   decs r2,1
   0= until

   pop tos,sp
c;
code edi-in  ( -- byte )
   psh   tos,sp
   mov   tos,#0               \ Initial byte value
   mov   r2,#8
   mov   r3,#0x100
   set   r1,`h# 19100 +io #`  \ GPIO register address
   mov   r4,#0x400            \ CLK mask
   begin
      add   tos,tos,tos    \ Left shift byte

      str   r4,[r1,#0x18]  \ Set CLK

      \ This delay is necessary to let the MMP2 GPIO pin clock in the
      \ data value.  Without the delay, bit values get lost.
      mov   r7,#0x400      \ Delay spins
      begin
         decs r7,#1
      0= until

      ldr   r0,[r1]        \ Read pin register
      str   r0,[r3],#4
      str   r4,[r1,#0x24]  \ Clr CLK
      mov   r7,#0x400      \ Delay spins
      begin
         decs r7,#1
      0= until

      ands  r0,r0,#0x80    \ Test MISO bit
      incne tos,1          \ Set bit in byte

   decs r2,1
   0= until
c;

: edi-spi-start  ( -- )
   ['] edi-in      to spi-in
   ['] edi-out     to spi-out
   ['] edi-cs-on   to spi-cs-on
   ['] edi-cs-off  to spi-cs-off
   d# 16 to spi-us
   ['] noop to spi-reprogrammed

\  use-edi-flash-read   \ Defined later

   edi-clk-lo  edi-cs-off
;

: use-edi-spi  ( -- )  ['] edi-spi-start  to spi-start  ;


\ LICENSE_BEGIN
\ Copyright (c) 2011 FirmWorks
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
