\ See license at end of file
purpose: SoC-specific low-level power management factors

\ First some tools for managing the DRAM reconfiguration table

0 value table#
0 value entry#
0 value mc-cs-map

0 value mc#
: set-mc  ( mc# -- )  to mc#  ;
: +mc  ( offset -- adr )  h# d000.0000 +   mc#  if  h# 1.0000 +  then  ;
: mc@  ( offset -- value )  +mc  l@  ;
: mc!  ( value offset -- )  +mc  l!  ;

: +pause  ( reg# -- reg#' )  h# 1.0000 or  ;
: +last   ( reg# -- reg#' )  h# 2.0000 or  ;

: +mct  ( value register#+flags -- )
   entry# d# 32 = abort" DRAM init table overflow"
   swap h# 1c8 mc!  ( data1-value )
   h# 1cc mc!       ( )
   table# 5 lshift
   entry# or
   h# 8000.0000 or       ( ctrl-value )
   h# 1c0 mc!            ( )
   entry# 1+ to entry#
;
: mc-table(  ( mc# table# -- )
   to table#  set-mc  0 to entry#

   0
   h# 10 mc@  1 and  if  h# 1000.0000 or  then
   h# 14 mc@  1 and  if  h# 2000.0000 or  then
   to mc-cs-map
;
: )mc-table  ( -- )
   table#  5 lshift
   mc#  if  3 lshift  h# 700  else  h# e0  then   ( field mask )
   invert  h# 11c pmua@  and   or  h# 11c pmua!
;

: +phy-dll  ( -- )
   4 0  do  i h# 300 +mct  h# 1080 h# 304 +mct  loop
;
: +read-leveling  ( -- )
   4 0  do  h# 100 i + h# 380 +mct  h# 200 h# 390 +mct  loop
;
: +reset-dll  ( -- )
   h# 2000.0000 h# 24c +mct  \ DLL reset
   h# 0003.0001 h# 160 +mct  \ SDRAM INIT
   h# 4000.0000 h# 24c +mct  \ DLL update via pulse mode
;
: +update-mode  ( -- )
   mc-cs-map h# 100 or  h# 160 +mct
   mc-cs-map h# 400 or  h# 160 +mct
;
: +reset-sdram-dll  ( -- )  h# 50 mc@  h# 40 or  h# 50 +mct  ;
: +zq-cal  ( -- )  mc-cs-map h# 1000 or  h# 160 +mct  ;
: +halt-pause  ( -- )   2 h# 68 +pause +mct  ;

: +halt  ( -- )   2 h# 68  +mct  ;    \ SDRAM_CTRL14 - Halt scheduler
: +restart  ( -- )  0 h# 68 +last +mct  ;  \ SDRAM_CTRL14 - Resume scheduler

: +cmd0   ( lowbits -- )  mc-cs-map or  h# 160 +mct  ;

: make-ddr3-recal-table  ( mc# -- )
   0 mc-table(
      +halt
      h# 2000.0000 h# 24c         +mct    \ PHY_CTRL14 - PHY DLL reset
      h# 4000.0000 h# 24c         +mct    \ PHY_CTRL14 - PHY DLL update
      h# 8000.0000 h# 24c  +pause +mct    \ PHY_CTRL14 - Sync 2x clock
      h# 50 mc@ h# 40 or
                   h#  50         +mct    \ SDRAM_CTRL1 - set DLL_RESET bit
      h# 0000.0100 +cmd0                  \ USER_COMMAND0 - Send LMR0 DLL
      h# 0000.0400 +cmd0                  \ USER_COMMAND0 - Send LMR2 DLL
      h# 0000.1000 +cmd0                  \ USER_COMMAND0 - ZQ Calibration
      +restart
   )mc-table
;
: mc2-enabled?  ( -- flag )   h# 6c pmua@ 2 and  0<>  ;
: make-ddr3-recal-tables  ( -- )
   0 make-ddr3-recal-table
   mc2-enabled?  if
      1 make-ddr3-recal-table
   else
      2 h# 190 pmua-set  \ PMUA_DEBUG2 - don't wait for ack from MC2
   then
;

0 value old-ccic
0 value old-gc
0 value old-vmeta
0 value old-aclk
0 value old-adsa
0 value old-aisl
: power-islands-off  ( -- )
   h#  50 pmua@ to old-ccic   0 h#  50 pmua!  \ Camera
   h#  cc pmua@ to old-gc     0 h#  cc pmua!  \ Graphics
   h#  a4 pmua@ to old-vmeta  0 h#  a4 pmua!  \ Vmeta
   h# 10c pmua@ to old-aclk   0 h# 10c pmua!  \ Audio clock
   h# 164 pmua@ to old-adsa   0 h# 164 pmua!  \ Audio DSA
   h# 1e4 pmua@ to old-aisl   0 h# 1e4 pmua!  \ Audio Island
   h# fc0  h# 240 pmua-set  \ Retain audio SRAM state  (0 to power them off)
;
: power-islands-on  ( -- )
   old-aisl   h# 1e4 pmua!
   old-adsa   h# 164 pmua!
   old-aclk   h# 10c pmua!
   old-vmeta  h#  a4 pmua!
   old-gc     h#  cc pmua!
   old-ccic   h#  50 pmua!
;

: +ciu  ( adr -- adr' )  h# 282c00 +  ;
: ciu!  ( l adr -- )  +ciu io!  ;
: ciu@  ( adr -- l )  +ciu io@  ;

: sp-c1-on  ( -- )
   h# 1000.0000 0 mpmu-set  \ Allow SP clock shutdown in IDLE (can't DMA to TCM)
;

: idle-cfg@  ( -- n )  h# 18 pmua@  ;   \ Core-dependent
: idle-cfg!  ( -- n )  h# 18 pmua!  ;   \ Core-dependent
: idle-cfg-clr  ( mask -- )  h# 18 pmua-clr  ;
: idle-cfg-set  ( mask -- )  h# 18 pmua-set  ;

: cc2-set  ( mask -- )  h# 150 pmua-set  ;  \ PMUA_CC2_PJ
: cc2-clr  ( mask -- )  h# 150 pmua-clr  ;

: cc3-set  ( mask -- )  h# 188 pmua-set  ;  \ PMUA_CC3_PJ

: cc4-set  ( mask -- )  h# 248 pmua-set  ;  \ PMUA_PJ_C0_CC4
: cc4-clr  ( mask -- )  h# 248 pmua-clr  ;

\ PXA2128_Registers_Manual_revF.pdf says to always write 0 to bits [14:0]
\ of MPMU+0x1000, but, empirically, that prevents deep sleep.  Apparently
\ bits [14:13] are legacy bits like in MPMU+0x0
: pcr!       ( value -- )  dup h# 00 mpmu!  h# 1000 mpmu!  ;
: pcr-set    ( mask -- )  dup h# 00 mpmu-set  h# 1000 mpmu-set  ;

0 [if]
: pj-c1  ( -- )
   h# 62 idle-cfg-clr  \ light sleep after WFI
   wfi
;
: pj-c1-extclk
   h# 62 idle-cfg-clr  \ light sleep after WFI
   h# 02 idle-cfg-set  \ Allow core clock shutdown (won't respond to snoops)
   h# 01 cc4-set  \ Mask off GIC interrupts
   wfi
;
: pj-c2
   ( clean&invalidate-l1 )  \ Must do this if coherency is enabled
   h# 8000.0062 idle-cfg-clr  \ light sleep after WFI

   \ To set the 40 bit, you must first clean&invalidate the l1 cache
   h# 22 idle-cfg-set         \ Allow core clock shutdown and core powerdown

   \ Also set the 8000 bit to keep L2 cache powered on
   h# 01 cc4-set  \ Mask off GIC interrupts
   wfi
;
[then]

0 value apcr
: deep-sleep-on  ( -- )
   h# 1000 mpmu@ to apcr

   \ Wakeup ports will be handler at a higher level
   h# be086000 pcr-set    \ AXISD, SPLEN, SPSD, DDRCORSD, APBSD, RSVD, VCXOSD, MSASLPEN, UDR_POWER_OFF_EN  \ Step 11
;
: deep-sleep-off  ( -- )
   apcr  h# 1000 mpmu!
;

\ D2_L2_PWD           462
\ C2_L1_L2_PWD   820004e2 \ 80 might be L2 power down bit
\ C2_L1_PWD      82000462 \ Power off SRAM by setting 40 bit
\ C2_L1R_L2_PWD  820004a2 \ Retain SRAM by not setting 40 bit
: set-idle  ( mask -- )
   h# e2 and                    ( mask' )     \ Mask with 62 for other cores
   idle-cfg@ h# 0def.fc1d and   ( mask kept )
   or  idle-cfg!                ( )
;
code outer-flush-all  ( -- )
c;
code flush-cache-all
   mcr  p15, 0, r0, cr8, cr5, 0       \ instruction tlb
   mcr  p15, 0, r0, cr8, cr6, 0       \ data tlb
   mcr  p15, 0, r0, cr8, cr7, 0       \ unified tlb

   mcr  p15, 0, r0, cr7, cr5, 0       \ invalid I cache
   mcr  p15, 0, r0, cr7, cr5, 6       \ invalid branch predictor array
   mcr  p15, 0, r0, cr7, cr5, 4       \ instruction barrier
   mcr  p15, 0, r0, cr7, cr14, 0      \ flush entire d cache
   mcr  p15, 0, r0, cr7, cr5, 4       \ flush prefetch buffer
   isb
   dsb
c;
code fw-off
   mrc  p15, 0, r0, cr1, cr0, 1
   bic  r0,r0,1
   mcr  p15, 0, r0, cr1, cr0, 1
   isb
   dsb
c;
code fw-on
   mrc  p15, 0, r0, cr1, cr0, 1
   orr  r0,r0,1
   mcr  p15, 0, r0, cr1, cr0, 1
   isb
   dsb
c;
code mp-off
   mrc  p15, 0, r0, cr1, cr0, 1
   bic  r0,r0,#0x40
   mcr  p15, 0, r0, cr1, cr0, 1
   isb
   dsb
c;
code mp-on
   mrc  p15, 0, r0, cr1, cr0, 1
   orr  r0,r0,#0x40
   mcr  p15, 0, r0, cr1, cr0, 1
   isb
   dsb
c;
: wakeup-irqs-on  ( -- )
\ 2f is high priority (f), directed to PJ (20)
\  h# 2f  h# 10 icu!  \ IRQ  4 - PMIC
   h# 2f  h# 14 icu!  \ IRQ  5 - RTC
\  h# 2f  h# c4 icu!  \ IRQ 49 - GPIO
;
: wakeup-irqs-off  ( -- )
\  h#  0  h# 10 icu!  \ IRQ  4 - PMIC
   h#  0  h# 14 icu!  \ IRQ  5 - RTC
\  h#  0  h# c4 icu!  \ IRQ 49 - GPIO
;
: global-irqs-off  ( -- )
   \ disable global irq of ICU for MP1, MP2, MM
   1 h#  110 icu!  \ ICU_GBL_IRQ1_MSK
   1 h#  114 icu!  \ ICU_GBL_IRQ2_MSK
   1 h# 210c icu!  \ ICU_GBL_IRQ3_MSK
   1 h# 2110 icu!  \ ICU_GBL_IRQ4_MSK
   1 h# 2114 icu!  \ ICU_GBL_IRQ5_MSK
   1 h# 2190 icu!  \ ICU_GBL_IRQ6_MSK
;

: setup-sleep-state  ( -- )
   sp-c1-on

   make-ddr3-recal-tables
   
   deep-sleep-on

   h# 462 set-idle   \ D2_L2_PWD

   \ Workaround - shut down AT clock
   h# 8000.0000 idle-cfg-clr

   \ I don't think we need this because L2 is off
   \ h# 8000 cc4-set  \ workaround: keep SL2 power on

   global-irqs-off

   flush-cache-all
   \ outer-flush-all

   \ fw-off
   \ mp-off
;
: restore-run-state  ( -- )
   \  fw-on
   \  mp-on

   \ I don't think we need this because L2 is off
   \ h# 8000 cc4-clr  \ workaround: keep SL2 power on

   deep-sleep-off

   h# 8000.0000 idle-cfg-set  \ Workaround: restore AT clock

   0 set-idle  \ C1_INCG
;

alias do-wfi wfi

\ a reset handler for second core
code spin
   set  r1,#0xd4282c24                  \ address of __sw_branch register
   mov  r0,#0x0
   str  r0,[r1]                         \ clear register
   begin
      mov  r3, #0x4000                  \ delay loop constant
      begin
         subs  r3, r3, #1               \ delay loop
      = until
      ldr  r0, [r1]                     \ read __sw_branch register
      cmp  r0, #0x0                     \ contains an address?
      movne  pc, r0                     \ yes, then branch
   again                                \ infinite loop
c;

: enable-smp  ( -- )
   ['] spin >physical 0  hw-install-handler  0 d# 4096 sync-cache

   \ enable mapping of PMR peripherals, so that PGU and GIC can be used,
   \ using the moltres peripheral space configuration register
   h# e000.0000 h# 94 ciu!  \ set periphbase_addr
   h# ffff.e001 h# 9c ciu!  \ set periphbase_size, set periphbase_enable

   0 h# d428.2c24 l!  \ clear __sw_branch register
   h# 0200.0000 cc2-clr d# 1 ms h# 0200.0000 cc2-set  \ reset mpcore2
;

: unused-core-off  ( -- )  \ mmcore
   h# e320f003 0 instruction!  \ Put WFI instruction in reset vector
   h# 2000.0062 h# 204 pmua!   \ PMUA_PJ_IDLE_CFG3, power down on WFI
   h# 0400.0000 cc2-set        \ release reset
;

\ LICENSE_BEGIN
\ Copyright (c) 2012 FirmWorks
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
