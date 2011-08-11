\ See license at end of file
purpose: Recalibrate DDR3 DRAM

\ This code must be executed from SRAM because it touches the DRAM memory controller
label ddr-recal  ( r0: memctrl-va -- )
   mov   r1, #0x80000000       \ PHY Sync Enable (WO) - Synchronize dclk2x and dclk in the PHY
   str   r1, [r0, #0x240]      \ PHY_CTRL14

   \ The value "f" for the reset timer is in units of 256 (memory clock?) cycles, thus
   \ the timer is set to 256*15 
   ldr   r1, [r0, #0x230]
   orr   r1, r1, #0xf0000000   \ DLL Reset timer
   str   r1, [r0, #0x230]      \ PHY_CTRL13

   \ Block all Memory Controller accesses until the DLL Reset timer expires
   mov   r1, #0x20000000       \ PHY DLL Reset (WO)
   str   r1, [r0, #0x240]      \ PHY_CTRL14

   mov   r1, #0x40000000       \ DLL Update enable
   str   r1, [r0, #0x240]      \ PHY_CTRL14

   mov   r1, #0x80             \ Exit self-refresh
   str   r1, [r0, #0x120]      \ USER_INITIATED_COMMAND0

   ldr   r1, [r0, #0x80]       \ SDRAM_CTRL1
   orr   r1, r1, #0x40         \ DLL_RESET
   str   r1, [r0, #0x80]       \ SDRAM_CTRL1

   mov   r1, #0x01000000       \ Chip select 0
   orr   r1, r1, #0x00000100   \ Initiate Mode Register Set
   str   r1, [r0, #0x120]      \ USER_INITIATED_COMMAND0

   mov   r1, #0x01000000       \ Chip select 0
   orr   r1, r1, #0x00001000   \ Initiate ZQ calibration long
   str   r1, [r0, #0x120]      \ USER_INITIATED_COMMAND0

   \ ZQ calibration long takes 512 memory clock cycles after a reset
   \ At 400 MHz, that's a little more than 2 us.  We spin here to
   \ ensure that the recal is complete before we touch the DRAM again.
   mov   r1, #0x100000         \ 512K spins, takes about 2.6 us
   begin
      decs r1, #1
   0= until

   mov   r1, #0x0              \ Normal operation (unblock data requests)
   str   r1, [r0, #0x7e0]      \ SDRAM_CTRL14

   mov   pc,lr 
end-code
here ddr-recal - constant /ddr-recal

h# d000.0000 constant memctrl-pa
h# d000.0000 constant memctrl-va
h# d100.0000 constant sram-pa
h# d100.0000 constant sram-va
sram-va h# 2.0000 + constant 'ddr-recal

: ddr-recal-to-sram  ( -- )
   memctrl-pa h# c02 or  memctrl-va map-section  \ Map the memory controller
   sram-pa    h# c0e or  sram-va    map-section  \ Make the code cacheable
   ddr-recal 'ddr-recal /ddr-recal move
;

stand-init: Setup DDR3 recalibration
   ddr-recal-to-sram
;

\ Call this from OFW to perform a recalibration
code do-recal  ( -- )
   set r0,`memctrl-va #`   \ Memory controller virtual address
   set r1,`'ddr-recal #`   \ Address of ddr-recal routine in SRAM
   mov lr,pc
   mov pc,r1
c;

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
