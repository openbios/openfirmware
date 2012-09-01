\ See license at end of file
purpose: Recalibrate DDR3 DRAM (SoC-specific low-level power management factors)

\ DDR3 DRAM requires periodic recalibration to cope with parameter drift from
\ temperature variation.  The recalibration below affects both the DLL and
\ the "ZQ" driver strength.

\ DDR3 recalibration will cause the display to glitch if done during display DMA.
\ The glitch can be avoided by doing the recal just after display frame done.
\ For example (from inside the screen driver):
\   : wait-frame-done  0 1c4 lcd!  begin 1c4 lcd@ cc00.0000 tuck and = until  ;

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
   mov   r1, #0x20             \ 32 spins, takes about 4 uS (from SRAM)
   begin
      decs r1, #1
   0= until

   mov   r1, #0x0              \ Normal operation (unblock data requests)
   str   r1, [r0, #0x7e0]      \ SDRAM_CTRL14

   mov   pc,lr 
end-code
here ddr-recal - constant /ddr-recal

create use-hw-s3
[ifdef] use-hw-s3
create use-auto-mc-wake  \ Let the PMU automatically wake the memory controller
[then]
create use-block           \ Block memory controller activity in low-level sleep code
create use-self-refresh    \ Manually issue self-refresh enter/exit
create use-drivers         \ Turn memory drivers off during sleep
create use-phy-dll-reset   \ Reset the PHY DLL upon wakeup
create use-phy-dll-update  \ Update the PHY DLL upon wakeup
create use-dram-dll-reset  \ Reset the DRAM DLL upon wakeup
\ create use-delay2        \ Long delay upon wakeup
\ create use-delay3        \ Short delay upon wakeup

label ddr-self-refresh  ( r0:memctrl-va -- )
[ifdef] use-gpio
   mov     r4, #0xfe000000
   orr     r4, r4, 0x19000   \ GPIO 3
   mov     r1, 0x8           \ GPIO 3
   str     r1, [r4, #0x18]   \ Set
[then]

[ifdef] use-block
   mov     r1, #0x1          \ Block all data requests
   str     r1, [r0, #0x7e0]  \ SDRAM_CTRL14
[then]

[ifdef] use-odt
   ldr   r2, [r0, #0x770]    \ SDRAM_CTRL7_SDRAM_ODT_CTRL2
   orr   r1, r2, #0x03000000 \ PAD_TERM_SWITCH_MODE: Termination disabled
   str   r1, [r0, #0x770]    \ SDRAM_CTRL7_SDRAM_ODT_CTRL2
[then]

[ifdef] use-self-refresh
   mov   r1, #0x40           \ Enter Self Refresh value
   str   r1, [r0, #0x120]    \ USER_INITIATED_COMMAND0
[then]

[ifdef] use-drivers
   ldr   r3, [r0, #0x1e0]    \ PHY_CTRL8
   bic   r1, r3, #0x0ff00000 \ PHY_ADCM_ZPDRV: f PHY_ADCM_ZNDRV: f (disable drivers)
   str   r1, [r0, #0x1e0]    \ PHY_CTRL8
[then]

   dsb                       \ Data Synchronization Barrier
   wfi                       \ Wait for interrupt

[ifdef] use-gpio
   mov     r1, 0x8           \ GPIO 3
   str     r1, [r4, #0x24]   \ Clr
[then]

[ifdef] use-drivers
   str   r3, [r0, #0x1e0]    \ PHY_CTRL8 - restore previous value  (all drivers)
[then]

[ifdef] use-delay1
   \ Delay to let the memory controller and DRAM DLLs settle
   mov   r1, #0x600  begin  decs r1,1  0= until
[then]

[ifdef] use-phy-dll-reset
   mov   r1, #0x20000000     \ PHY_DLL_RESET
   str   r1, [r0, #0x240]    \ PHY_CTRL14
[then]

[ifdef] use-phy-dll-update
   mov   r1, #0x40000000     \ DLL_UPDATE_EN
   str   r1, [r0, #0x240]    \ PHY_CTRL14
[then]

[ifdef] use-dram-dll-reset
   ldr   r1, [r0, #0x080]    \ PHY_CTRL1
   orr   r1, r1, #0x40       \ DLL_RESET
   str   r1, [r0, #0x080]    \ PHY_CTRL1
   mov   r1, #0x100          \ USER_LMR0_REQ
   orr   r1, r1, #0x03000000 \ CHIP_SELECT_0 | CHIP_SELECT_1
   str   r1, [r0, #0x120]    \ USER_INITIATED_COMMAND0
[then]

[ifdef] use-self-refresh
   mov   r1, #0x80           \ Exit Self Refresh value
   str   r1, [r0, #0x120]    \ USER_INITIATED_COMMAND0
[then]

[ifdef] use-odt
   str   r2, [r0, #0x770]    \ SDRAM_CTRL7_SDRAM_ODT_CTRL2 - restore previous value
[then]

[ifdef] use-zqcal
   mov   r1, #0x01000000       \ Chip select 0
   orr   r1, r1, #0x00001000   \ Initiate ZQ calibration long
   str   r1, [r0, #0x120]      \ USER_INITIATED_COMMAND0

   \ ZQ calibration long takes 512 memory clock cycles after a reset
   \ At 400 MHz, that's a little more than 2 us.  We spin here to
   \ ensure that the recal is complete before we touch the DRAM again.
   mov   r1, #0x20             \ 32 spins, takes about 16 uS (from SRAM)
   begin
      decs r1, #1
   0= until
[then]

[ifdef] use-gpio
   mov     r1, 0x8           \ GPIO 3
   str     r1, [r4, #0x18]   \ Set
[then]

[ifdef] use-delay2
   \ Delay to ensure that at least 512 DRAM NOP's happen before the first access
   mov   r1, #0x600  begin  decs r1,1  0= until
[then]

[ifdef] use-delay3
   \ Delay to ensure that at least 512 DRAM NOP's happen before the first access
   mov   r1, #0x20  begin  decs r1,1  0= until
[then]

[ifdef] use-gpio
   mov     r1, 0x8           \ GPIO 3
   str     r1, [r4, #0x24]   \ Clr
[then]

[ifdef] use-block
   mov     r1, #0x0          \ Unblock data requests
   str     r1, [r0, #0x7e0]  \ SDRAM_CTRL14
[then]

   mov     pc, lr
end-code
here ddr-self-refresh - constant /ddr-self-refresh

: ddr-code-to-sram  ( -- )
   ddr-recal 'ddr-recal /ddr-recal move
   'ddr-recal /ddr-recal sync-cache

   ddr-self-refresh 'ddr-self-refresh /ddr-self-refresh move
   'ddr-self-refresh /ddr-self-refresh sync-cache
;

stand-init: Setup DDR3 recalibration
   ddr-code-to-sram
;

\ Call this from OFW to perform a recalibration
code do-recal  ( -- )
   set r0,`memctrl-va #`   \ Memory controller virtual address
   set r1,`'ddr-recal #`   \ Address of ddr-recal routine in SRAM
   mov lr,pc
   mov pc,r1
c;

\ Call this from OFW to enter self-refresh
code do-self-refresh  ( -- )
   set r0,`memctrl-va #`   \ Memory controller virtual address

   set r1,`'ddr-self-refresh #`   \ Address of ddr-self-refresh routine in SRAM
   ldr r2,[r1]             \ Force the code translation into the TLB
   ldr r3,[r0,#0x110]      \ Force the memory controller translation into the TLB
   mov lr,pc
   mov pc,r1
c;

\ Wakeup ports - from datasheet page 718
\ WAKEUP0: CAWAKE (MIPI-HSI wakeup)
\ WAKEUP1: Audio Island
\ WAKEUP2: GPIO
\ WAKEUP3: Keypress,Trackball,Rotary
\ WAKEUP4: Timers, RTC ALARM, WDT
\ WAKEUP5: USB PHY
\ WAKEUP6: SDH1_CD, SDH3_CD, MSP_INS
\ WAKEUP7: PMIC INT
5 value sleep-depth
: setup-wakeup-sources  ( -- mask )
\  h# 0002.0094 h#   4c mpmu!  \ RTC_ALARM, WAKEUP7, WAKEUP4, WAKEUP2
\  h# 0002.0094 h# 104c mpmu!  \ RTC_ALARM, WAKEUP7, WAKEUP4, WAKEUP2
   h# ff08.7fff   ( mask )  \ Enable all wakeup ports
;
: block-irqs  ( -- )  1 h# 110 +icu io!  ;

: breadcrumb  ( n -- )  h# d000.0110 l!  ;

0 value save-apcr
0 value save-idlecfg

: restore-run-state  ( -- )
   save-apcr h# 1000 mpmu!     ( )             \ Restore APCR
   save-idlecfg h# 18 pmua!    ( )             \ Restore IDLE_CFG
;
\ Questions:
\ Meaning of various connect type options
\ do LP mode settings take effect immediately if SP is already at WFI, or only on entry to WFI
\ does WFI make any difference on SP?  I don't see any difference in power
\ Which WFI instruction on SP?
\ Which WFI instruction on PJ4?
\ Any undocumented bits that affect the situation?
\ What are the _INT versions of the XDB config files?
\ What does CS stand for in ARM/CS ?
\ When using XDB on XO with OFW, XDB can see entry to LP state - core Status stays running - LowPower Internal
\ How to recapture short of restarting XDB?
\ Pushing button on JTAG box often seems to have no effect

: setup-sleep-state  ( -- )
   \ begin mmp2_pm_enter_lowpower_mode(state)

   \ Security processor setup
   sleep-depth 4 >= if                        \ state at least POWER_MODE_CHIP_SLEEP (turn off most of SoC)
     h# fe08.6000 0 mpmu!                    \ In SP, set AXISD, resvd, SLPEN,  SPSD,   DDRCORSD, APBSD resvd, VCXOSD
     \ We keep PMUM_BBDP (bit 25) off because that saves 60 mW
\    h# fc08.6000 0 mpmu!                     \ In SP, set AXISD, resvd, SLPEN,  SPSD,   DDRCORSD, APBSD resvd, VCXOSD
   then

   sleep-depth 3 =  if                        \ state at least POWER_MODE_APPS_SLEEP (turn off slow IO)
\     h# de00.6000 0 mpmu!                    \ In SP, set AXISD, resvd,        SPSD,   DDRCORSD, APBSD resvd,
     \ We keep PMUM_BBDP (bit 25) off because that saves 60 mW
     h# dc00.6000 0 mpmu!                     \ In SP, set AXISD, resvd,        SPSD,   DDRCORSD, APBSD resvd,
   then

\ Linux value
\  h# 8030.0020 h# 14 pmua!                   \ IN PMUA_SP_IDLE_CFG, set , DIVIDER_RESET_EN, SP_DIS_MC_SW_REQ, SP_MC_WAKE_EN, TCM_STATE_RETAIN
   h# 8020.0020 h# 14 pmua!                   \ IN PMUA_SP_IDLE_CFG, set , DIVIDER_RESET_EN, SP_DIS_MC_SW_REQ,                TCM_STATE_RETAIN

   \ PJ4 setup

   h# 1000 mpmu@ to save-apcr
   h#   18 pmua@ to save-idlecfg

   save-apcr                       ( apcr )
   h# ac08.0000 invert and         ( apcr' )  \ Clear AXISD, SLPEN, DDRCORSD, APBSD, VCXOSD

   sleep-depth 5 >=  if                       \ state at least POWER_MODE_SYS_SLEEP  (turn off oscillator)
      h# 0008.0000 or              ( apcr' )  \ Set VCXOSD
   then

   sleep-depth 4 >= if                        \ state at least POWER_MODE_CHIP_SLEEP (turn off most of SoC)
      h# 2000.0000 or              ( apcr' )  \ Set SLPEN
      setup-wakeup-sources and     ( apcr' )
   then

   sleep-depth 3 >=  if                       \ state at least POWER_MODE_APPS_SLEEP (turn off slow IO)
      h# 0400.0000 or              ( apcr' )  \ Set APBSD
   then  

   sleep-depth 2 >=  if                       \ state at least POWER_MODE_APPS_IDLE  (turn off fast IO and DDR)
      h# 8800.0000 or              ( apcr' )  \ Set AXISD, DDRCORSD
   then

   h# 5200.0000 or                 ( apcr' )  \ Set DSPSD (bit 30, reserved), SPSD (bit 28), BBSD (bit 25, resvd)

   save-idlecfg 2 invert and       ( apcr idle )   \ Clear PMUA_MOH_IDLE (AKA PJ_IDLE)
\  h# 8000.0000 invert and         ( apcr idle' )  \ Clear PJ_DBG_CLOCK_EN

   sleep-depth 2 >=  if                            \ state at least POWER_MODE_APPS_IDLE
      h# 0000.0020 or              ( apcr idle' )  \ PJ_PWRDWN
   then

   sleep-depth 1 >=  if                            \ state at least POWER_MODE_CORE_EXTIDLE
      h# 3000.0000 invert and      ( apcr idle' )  \ PJ_ISO_MODE_CNTRL - isolation controlled by processor logic and active
      h# 000a.0002 or              ( apcr idle' )  \ 2 L2 power switches, 1 L1 power switch, 3 core power switches
   then

   h# 0020.0000 or                 ( apcr idle' )  \ PJ_DIS_MC_SW_REQ - disable idle entry using software register bits
[ifdef] use-auto-mc-wake
   h# 0010.0000 or                 ( apcr idle' )  \ PJ_MC_WAKE_EN - wake memory controller when core wakes
[then]

   0 h# b0 pmua!                   ( apcr idle )   \ PMUA_MC_HW_SLP_TYPE - self-refresh power down

   h# 18 pmua!                     ( apcr )        \ Set IDLE_CFG register
   h# 1000 mpmu!                   ( )             \ Set APCR register

   \ end mmp2_pm_enter_lowpower_mode(state)
   h# 000c.0000 h# 8c +pmua io-set  \ Power down CoreSight SRAM

   block-irqs
;

: power-islands-off  ( -- )
   \ TODO - need to power down sram/l2$
   \ mmp2_cpu_disable_l2(0);
   \ outer_cache.flush_range(0, -1ul);

[ifdef] use-gpio
   3 gpio-dir-out
[then]
   0 h# 10c pmua!   \ Turn off audio power island
;
: power-islands-on  ( -- )
   h# 712 h# 10c pmua!   \ Turn on audio power island
;
: do-wfi  ( -- )
   [ifdef] use-hw-s3
   wfi
[else]
   do-self-refresh
[then]
;

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
