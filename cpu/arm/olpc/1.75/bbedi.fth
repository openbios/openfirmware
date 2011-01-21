\ See license at end of file
purpose: Bit-banged SPI bus driver for KB3731 EC "EDI" interface

d# 103 constant edi-miso-gpio#
d# 104 constant edi-cs-gpio#
d# 105 constant edi-mosi-gpio#
d# 106 constant edi-clk-gpio#

: edi-cs-on   ( -- )  edi-cs-gpio# gpio-clr  ;
: edi-cs-off  ( -- )  edi-cs-gpio# gpio-set  ;

: edi-clk-lo  ( -- )  edi-clk-gpio# gpio-clr  ;
: edi-clk-hi  ( -- )  edi-clk-gpio# gpio-set  ;

0 [if]
\ All this timing stuff is pointless because the GPIOs are so slow
\ that the problem is to make the clock go fast enough to satisfy
\ the initial connection speed requirement.

\ We need to run at between 1 and 2 MHz for the initial connection,
\ and then we can go faster, up to 16 Mhz.
\ The half-cycle period for 1-2 MHz is between 250 ns and 500 ns.
\ Timer0 runs at 6.5 MHz so each tick is about 150 ns.
\ Two ticks is 300 ns, three is 450 ns.
code spins  ( count -- )
   cmp     tos,#0
   <>  if
      begin
         subs    tos,tos,#1
      0= until
   then
   pop     tos,sp 
c;

d# 150 value edi-dly-spins
: edi-dly  ( -- )  edi-dly-spins spins  ;

\ CPU clock is 800 Mhz, so 1.25 ns/clock
\ spins is 2 clocks/spin, so 2.5 ns/spin
\ Slow clock must be between 1 and 2 MHz, so period is between 1000 and 500 ns.
\ edi-dly is a half cycle, so edi-dly for slow clock is between 500 and 250 ns.
\ So we need between 200 and 100 spins for slow edi-dly
\ Fast clock can be up to 16 Mhz, so full-cycle period of 62.5 ns, half-cycle
\ period of >= 31.25 ns, so >= 12.5 spins at 2.5. ns/spin.

: slow-edi-clock  ( -- )  d# 150 to edi-dly-spins  ;
: fast-edi-clock  ( -- )  d# 13 to edi-dly-spins  ;

code edi-bit!  ( flag -- )
   mov   r0,#0x200
   set   r1,#0xd4019100
   cmp   tos,#0
   streq r0,[r1,#0x24]  \ Clr MOSI if flag is 0
   strne r0,[r1,#0x18]  \ Set MOSI if flag is non0
   mov   r0,#0x400
   str   r0,[r1,#0x18]  \ Set CLK
   str   r0,[r1,#0x24]  \ Clr CLK
   pop tos,sp
c;

[ifndef] edi-bit!
: edi-bit!  ( flag -- )
   edi-mosi-gpio#  swap  if  gpio-set  else  gpio-clr  then
   edi-clk-hi
   edi-dly
   edi-clk-lo
   edi-dly
;
[then]

[ifndef] edi-bit!
: edi-bit!  ( flag -- )
   if
      [ edi-mosi-gpio# >gpio-pin h# 18 + ] dliteral l!  \ Fast gpio-set
   else
      [ edi-mosi-gpio# >gpio-pin h# 24 + ] dliteral l!  \ Fast gpio-clr
   then
   [ edi-clk-gpio# >gpio-pin h# 18 + ] dliteral l!  \ Fast gpio-set
\   edi-dly
   [ edi-clk-gpio# >gpio-pin h# 24 + ] dliteral l!  \ Fast gpio-set
\   edi-dly
;
[then]

: edi-out  ( b -- )
   8 0  do                   ( b )
      dup h# 80 and edi-bit! ( b )
      2*                     ( b' )
   loop                      ( b )
   drop                      ( )
;   
: edi-bit@  ( -- flag )
   edi-clk-hi
   edi-dly
   edi-miso-gpio# gpio-pin@
   edi-clk-lo
   edi-dly
;
: edi-in-h  ( b -- )
   0                         ( b )
   8 0  do                   ( b )
      2* edi-bit@ 1 and or   ( b' )
   loop                      ( b )
;   
[else]
code edi-out0  ( byte -- )
   mov   r2,#8
   mov   r0,#0x200         \ MOSI mask
   set   r1,#0xd4019100    \ GPIO register address
   mov   r4,#0x400         \ CLK mask
   begin
      ands  r3,tos,#0x80   \ Test bit

      strne r0,[r1,#0x18]  \ Set MOSI if bit is non0
      streq r0,[r1,#0x24]  \ Clr MOSI if bit is 0

      str   r4,[r1,#0x18]  \ Set CLK
      str   r4,[r1,#0x24]  \ Clr CLK

      add   tos,tos,tos    \ Left shift TOS      
   decs r2,1
   0= until

   pop tos,sp
c;
code edi-out  ( byte -- )
   mov   r2,#8
   mov   r0,#0x200         \ MOSI mask
   set   r1,#0xd4019100    \ GPIO register address
   mov   r4,#0x400         \ CLK mask
   mov   r5,#0x600         \ CLK and MOSI mask
   begin
      ands  r3,tos,#0x80   \ Test bit

      strne r5,[r1,#0x18]  \ Set MOSI and CLK in the same operation if bit is non0
      streq r0,[r1,#0x24]  \ Clr MOSI
      streq r4,[r1,#0x18]  \ Set CLK

      str   r4,[r1,#0x24]  \ Clr CLK

      add   tos,tos,tos    \ Left shift TOS      
   decs r2,1
   0= until

   pop tos,sp
c;
code edi-in  ( -- byte )
   psh   tos,sp
   mov   tos,#0            \ Initial byte value
   mov   r2,#8
   mov   r3,#0x100
   set   r1,#0xd4019100    \ GPIO register address
   mov   r4,#0x400         \ CLK mask
   begin
      add   tos,tos,tos    \ Left shift byte

      str   r4,[r1,#0x18]  \ Set CLK

      \ This delay is necessary to let the MMP2 GPIO pin clock in the
      \ data value.  Without the delay, bit values get lost.
      mov   r7,#0x160      \ Delay spins
      begin
         decs r7,#1
      0= until

      ldr   r0,[r1]        \ Read pin register
      str   r0,[r3],#4
      str   r4,[r1,#0x24]  \ Clr CLK
      ands  r0,r0,#0x80    \ Test MISO bit
      incne tos,1          \ Set bit in byte

   decs r2,1
   0= until
c;

[then]


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
