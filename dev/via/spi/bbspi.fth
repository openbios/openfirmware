\ See license at end of file
purpose: SPI driver for tethered SPI FLASH programming

\ It is tempting to use the Via's SPI hardware instead of
\ bitbanging, but that turns out to be slower because the
\ special FLASH mode to make 256-byte write cycles possible
\ only work if the host system boots from SPI FLASH.
\ Without that mode, you can only send 12 data bytes per
\ "program page" transaction.  That ends up being slower
\ overall than bitbanging.  Bitbanging loses on the per-bit
\ time, but lets you do an efficient 256-byte page program.

: gpo-port  ( -- port# )  acpi-io-base h# 4c +  ;
: gpi-port  ( -- port# )  acpi-io-base h# 48 +  ;

h# 20000 constant clk-mask
h#  0008 constant cs-mask
h#  0002 constant do-mask
h#  0001 constant di-mask

\ DI:GPI0, CLK:GPIO6, DO:GPO1, SS0#:GPO3
: bb-spi-cs-on   ( -- )  gpo-port dup pc@ 8 invert and  swap pc!  ;
: bb-spi-cs-off  ( -- )  gpo-port dup pc@ 8 or          swap pc!  ;

code bb-spi-out  ( b -- )
   bx pop

   gpo-port # dx mov          \ Base value for register
   dx ax in

   8 # cx mov
   begin
      clk-mask do-mask +  invert #  ax  and   \ Clk low for first half-cycle
      h# 80 # bl test  0<>  if
         do-mask # ax or         \ Possibly set DO
      then
      ax dx out                  \ CLK low period
      clk-mask #  ax  or         \ CLK high period
      ax dx out
      bl bl add                  \ Shift left
   loopa
c;

code bb-spi-in  ( -- b )
   bp push

   gpo-port # dx mov          \ Out port
   dx ax in                   \ Base value for out register
   clk-mask do-mask +  invert #  ax  and   \ Clk low for first half-cycle
   ax bp mov                  \ Save base value in BP

   bx bx xor

   8 # cx mov
   begin
      bp ax mov                  \ Base value
      gpo-port # dx mov          \ Out port
      ax dx out                  \ CLK low
      clk-mask #  ax  or         \ CLK high
      ax dx out                  \ Push it out

      gpi-port # dx mov          \ In port
      dx ax in
      bx bx  add                 \ Shift left
      di-mask #  ax  test  0<>  if
         bx inc
      then
   loopa
   bp pop
   bx push
c;

: bb-spi-start  ( -- )
   ['] bb-spi-in     to spi-in
   ['] bb-spi-out    to spi-out
   ['] bb-spi-cs-on  to spi-cs-on
   ['] bb-spi-cs-off to spi-cs-off
   d# 12 to spi-us
   ['] noop to spi-reprogrammed
\  use-spi-flash-read           \ Readback with SPI commands, not memory ops
   use-hw-spi-flash-read

   gpo-port dup pc@  clk-mask invert and  do-mask invert and  cs-mask or  swap pc!     \ CLK, DO low, CS# high
   h# 88e4 config-b@ 2 or  h# 88e4 config-b!
;

: use-bb-spi  ( -- )  ['] bb-spi-start  to spi-start  ;

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
