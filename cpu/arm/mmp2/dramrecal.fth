\ See license at end of file
purpose: Recalibrate DDR3 DRAM

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
   mov   r1, #0x100000         \ 512K spins, takes about 2.6 us
   begin
      decs r1, #1
   0= until

   mov   r1, #0x0              \ Normal operation (unblock data requests)
   str   r1, [r0, #0x7e0]      \ SDRAM_CTRL14

   mov   pc,lr 
end-code
here ddr-recal - constant /ddr-recal

label ddr-self-refresh  ( r0:memctrl-va -- )
        dsb
        mcr     p15,0,r0,cr8,cr5,0 \ Invalidate TLB
        mcr     p15,0,r0,cr7,cr10,4 \ Write data synchronization barrier

        mov     r1, #0x1          \ Block all data requests
        str     r1, [r0, #0x7e0]  \ SDRAM_CTRL14

        ldr     r1, [r0, #0x120]  \ USER_INITIATED_COMMAND0
        bic     r1, r1, #0xc0     \ USER_SR_REQUEST field
        orr     r1, r1, #0x40     \ Enter Self Refresh value
        str     r1, [r0, #0x120]  \ USER_INITIATED_COMMAND0

        \ This block was commented-out in the Linux code, and the value is incorrect for OLPC in any case
        \ mov   r1, #0x03000000   \ PAD_TERM_SWITCH_MODE: Termination disabled
        \ orr   r1, r1, #0x000a   \ ODT{1,0}_SWITCH_MODE: Termination controlled by Read and Write enables
        \ str   r1, [r0, #0x770]  \ SDRAM_CTRL7_SDRAM_ODT_CTRL2

\ Store registers in SRAM so CForth can see them, for debugging
        set     r2, #0xd102.0400
        stmia   r2, {r0-r15}

        \ Linux sets the register to 0x860
        ldr     r1, [r0, #0x1e0]  \ PHY_CTRL8
        bic     r1,r1,#0x07700000 \ PHY_ADCM_ZPDRV: 0 PHY_ADCM_ZNDRV: 0 (Disable drivers 6:0)
        str     r1, [r0, #0x1e0]  \ PHY_CTRL8

\       mov     r1, #0x00070000   \ PHY_SYNC_EN
\       str     r1, [r0, #0x110]  \ MMAP_CS1

        dsb                       \ Data Synchronization Barrier
        wfi                       \ Wait for interrupt

        \ Linux sets the register to 0x07700860, hardcoding the drive strength
        ldr     r1, [r0, #0x1e0]  \ PHY_CTRL8
        orr     r1,r1,#0x07700000 \ PHY_ADCM_ZPDRV: 7 PHY_ADCM_ZNDRV: 7 (Enable drivers 6:0)
        str     r1, [r0, #0x1e0]  \ PHY_CTRL8

        \ This block was commented-out in the Linux code, and the value is incorrect for OLPC in any case
        \ mov   r1, #0x02000000   \ PAD_TERM_SWITCH_MODE: Termination enabled during all reads
        \ orr   r1, r1, #0x000a   \ ODT{1,0}_SWITCH_MODE: Termination controlled by Read and Write enables
        \ str   r1, [r0, #0x770]  \ SDRAM_CTRL7_SDRAM_ODT_CTRL2

        mov     r1, #0x80000000   \ PHY_SYNC_EN
        str     r1, [r0, #0x240]  \ PHY_CTRL14

        \ There used to be code to set register 230, but Marvell says it is unnecessary.

        mov     r1, #0x20000000   \ PHY_DLL_RESET
        str     r1, [r0, #0x240]  \ PHY_CTRL14

        mov     r1, #0x40000000   \ DLL_UPDATE_EN
        str     r1, [r0, #0x240]  \ PHY_CTRL14

        ldr     r1, [r0, #0x120]  \ USER_INITIATED_COMMAND0
        bic     r1, r1, #0xc0     \ USER_SR_REQUEST field
        orr     r1, r1, #0x80     \ Exit Self Refresh value
        str     r1, [r0, #0x120]  \ USER_INITIATED_COMMAND0

        ldr     r1, [r0, #0x80]   \ SDRAM_CTRL1
        orr     r1, r1, #0x40     \ DLL_RESET
        str     r1, [r0, #0x80]   \ SDRAM_CTRL1

        mov     r1, #0x01000000   \ Chip select 0
        orr     r1, r1, #0x0100   \ USER_LMR0_REQ - Initiate Mode Register Set
        str     r1, [r0, #0x120]  \ USER_INITIATED_COMMAND0

        \ ldr   r1, [r0, #0x120]  \ USER_INITIATED_COMMAND0
        \ bic   r1, r1, #0xc0     \ USER_SR_REQUEST field
        \ orr   r1, r1, #0x80     \ Exit Self Refresh value
        \ str   r1, [r0, #0x120]  \ USER_INITIATED_COMMAND0

        mov     r1, #0x0          \ Unblock data requests
        str     r1, [r0, #0x7e0]  \ SDRAM_CTRL14

        mov     pc, lr
end-code
here ddr-self-refresh - constant /ddr-self-refresh

memctrl-pa constant memctrl-va

: ddr-code-to-sram  ( -- )
   memctrl-pa h# c02 or  memctrl-va map-section  \ Map the memory controller

\ sram is already mapped by initmmu.fth
\  sram-pa    h# c0e or  sram-va    map-section  \ Make the code cacheable

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
   mov r7,sp
   set sp,`'ddr-self-refresh-sp #`
   mov lr,pc
   mov pc,r1
   mov sp,r7
c;

: apbc-clr-rst  ( offset -- )  +apbc  4 swap io-clr  ;
: apbc-set-rst  ( offset -- )  +apbc  4 swap io-set  ;

: disable-apbc-clks  ( -- )
   \ 3 h# 38 +apbc io-clr   \ GPIO
   3 h# 74 +apbc io-clr   \ MPMU
   3 h# 78 +apbc io-clr   \ IPC
   3 h# 90 +apbc io-clr   \ THSENS1

   \ h# 38 apbc-set-rst
   h# 74 apbc-set-rst   \ MPMU
   h# 78 apbc-set-rst   \ IPC
   h# 90 apbc-set-rst   \ THSENS1
;
: enable-apbc-clks  ( -- )
   \ 3 h# 38 +apbc io-set   \ GPIO
   3 h# 74 +apbc io-set   \ MPMU
   3 h# 78 +apbc io-set   \ IPC
   3 h# 90 +apbc io-set   \ THSENS1

   \ h# 38 apbc-clr-rst
   h# 74 apbc-clr-rst   \ MPMU
   h# 78 apbc-clr-rst   \ IPC
   h# 90 apbc-clr-rst   \ THSENS1
;
: disable-scu-clks  ( -- )
   0 h# 64 +scu io!  \ SCU_AXIFAB_CKGT_CTRL0  - Close AXI fabric clock gate
   0 h# 68 +scu io!  \ SCU_AXIFAB_CKGT_CTRL1
   h# f0 h# 1c +scu io-set  \ SCU_MCB_CONF
;
: enable-scu-clks  ( -- )
   h# 3003003 h# 64 +scu io!  \ SCU_AXIFAB_CKGT_CTRL0  - Open AXI fabric clock gate
   h# 0303030 h# 68 +scu io!  \ SCU_AXIFAB_CKGT_CTRL1
   h# f0 h# 1c +scu io-clr    \ SCU_MCB_CONF
;
: disable-apmu-clks  ( -- )
   h#    1b h#  54 +pmua io-clr  \ PMUA_SDH0_CLK_RES_CTRL
   h#    1b h#  58 +pmua io-clr  \ PMUA_SDH1_CLK_RES_CTRL
   h#    1b h#  e8 +pmua io-clr  \ PMUA_SDH2_CLK_RES_CTRL
   h#    1b h#  d4 +pmua io-clr  \ PMUA_SMC_CLK_RES_CTRL
   h#    3f h#  60 +pmua io-clr  \ PMUA_NF_CLK_RES_CTRL
   h#    3f h#  d8 +pmua io-clr  \ PMUA_MSPRO_CLK_RES_CTRL - XO does not use MSPRO
   h#    12 h# 10c +pmua io-clr  \ PMUA_AUDIO_CLK_RES_CTRL
   h# 1fffd h#  dc +pmua io-clr  \ PMUA_GLB_CLK_RES_CTRL
\  0        h#  68 pmua!         \ PMUA_WTM_CLK_RES_CTRL
   h#     9 h#  5c +pmua io-clr  \ PMUA_USB_CLK_RES_CTRL
;
: enable-apmu-clks  ( -- )
   h#    1b h#  54 +pmua io-set  \ PMUA_SDH0_CLK_RES_CTRL
   h#    1b h#  58 +pmua io-set  \ PMUA_SDH1_CLK_RES_CTRL
   h#    1b h#  e8 +pmua io-set  \ PMUA_SDH2_CLK_RES_CTRL
   h#    1b h#  d4 +pmua io-set  \ PMUA_SMC_CLK_RES_CTRL \ ??? what is this and why is it on?
   h#    3f h#  60 +pmua io-set  \ PMUA_NF_CLK_RES_CTRL \ Should this be on?
\  h#    3f h#  d8 +pmua io-set  \ PMUA_MSPRO_CLK_RES_CTRL
   h#    12 h# 10c +pmua io-set  \ PMUA_AUDIO_CLK_RES_CTRL
   h# 1fffd h#  dc +pmua io-set  \ PMUA_GLB_CLK_RES_CTRL
\  h#    1b h#  68 pmua!         \ PMUA_WTM_CLK_RES_CTRL
   h#     9 h#  5c +pmua io-set  \ PMUA_USB_CLK_RES_CTRL
;
: disable-mpmu-clks  ( -- )
   h#      a010 h# 1024 mpmu!         \ MPMU_ACGR

   h#      a010 h# 0024 mpmu!         \ MPMU_CGR_SP ???

\  h# 2000.0000 h#  414 +mpmu io-clr  \ MPMU_PLL2_CTRL1
   h# 8000.0000 h# 0040 +mpmu io-clr  \ MPMU_ISCCR1
   h# 8000.0000 h# 0044 +mpmu io-clr  \ MPMU_ISCCR2
;
: enable-mpmu-clks  ( -- )
   h# dffe.fffe h# 1024 mpmu!         \ MPMU_ACGR
\  h# 2000.0000 h# 0414 +mpmu io-set  \ MPMU_PLL2_CTRL1
   h# 8000.0000 h# 0040 +mpmu io-set  \ MPMU_ISCCR1
   h# 8000.0000 h# 0044 +mpmu io-set  \ MPMU_ISCCR2
;
: disable-twsi-clks  ( -- )
   \ set RST in APBC_TWSIx_CLK_RST registers

[ifdef] notdef
   \ just disable TWSI1 clk rather than reset it since it's needed to access PMIC onkey
   \ when system is waken up from low power mode */
   0 4 +apbc io!   \ Disable TWSI1 clock
[else]
   h# 04 apbc-set-rst  \ TWSI1
[then]
   h# 08 apbc-set-rst  \ TWSI2
   h# 0c apbc-set-rst  \ TWSI3
   h# 10 apbc-set-rst  \ TWSI4
   h# 7c apbc-set-rst  \ TWSI5
   h# 80 apbc-set-rst  \ TWSI6
;
: enable-twsi-clks  ( -- )
[ifdef] notdef
   3 4 +apbc io!   \ Enable TWSI1 clock
[else]
   h# 04 apbc-clr-rst  \ TWSI1
[then]
   h# 08 apbc-clr-rst  \ TWSI2
   h# 0c apbc-clr-rst  \ TWSI3
   h# 10 apbc-clr-rst  \ TWSI4
   h# 7c apbc-clr-rst  \ TWSI5
   h# 80 apbc-clr-rst  \ TWSI6
;
: disable-clks  ( -- )
   disable-twsi-clks
   disable-apbc-clks
   disable-scu-clks
   disable-apmu-clks
   disable-mpmu-clks
;
: enable-clks  ( -- )
   enable-mpmu-clks
   enable-apmu-clks
   enable-scu-clks
   enable-apbc-clks
   enable-twsi-clks
;

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

\ XXX we might need to set GPIOs 71 and 160 (ps2 clocks), and perhaps the dat lines too,
\ for non-sleep-mode control - or maybe for sleep mode control as inputs.
\ We also may need to enable falling edge detects.
: disable-int40  ( -- )  d# 40 disable-interrupt  ;

: gpio-wakeup?  ( gpio# -- flag )
   h# 019800 over 5 rshift la+ l@  ( gpio# mask )
   swap h# 1f and                  ( mask bit# )
   1 swap lshift  and  0<>         ( flag )
;

: icu@  ( offset -- value )  h# 28.2000 + io@  ;
: .masked  ( irq# -- )
   dup /l* h# 10c + icu@  ( irq# masked )
   1 and  if              ( irq# )
      ." IRQ" .d ." is masked off" cr
   else                   ( irq# )
      drop                ( )
   then                   ( )
;
: .selected  ( irq# -- )
   dup /l* h# 100 + icu@  ( irq# n )
   dup h# 40 and  if      ( irq# n )
      ." IRQ" swap .d     ( n )
      ." selected INT" h# 3f and .d  cr  ( )
   else                   ( irq# n )
      2drop               ( )
   then                   ( )
;
: (.pending)  ( d -- )
   ." pending INTs: "                      ( d )
   d# 64 0  do                             ( d )
      over 1 and  if  i .d  then           ( d )
      d2/                                  ( d' )
   loop                                    ( d )
   2drop                                   ( )
;
: .pending  ( irq# -- )
   dup 2* /l* h# 130 +  dup icu@  swap la1+ icu@   ( irq# d )
   2dup d0=  if                                    ( irq# d )
      3drop                                        ( )
   else                                            ( irq# d )
      ." IRQ " rot .d   (.pending)  cr             ( )
   then                                            ( )
;

: bit?  ( n bit# -- n flag )  1 swap lshift over and  0<>  ;
: .ifbit  ( n bit# msg$ -- n )
   2>r  bit?  if       ( n r: msg$ )
      2r> type  space  ( n )
   else                ( n r: msg$ )
      2r> 2drop        ( n )
   then                ( n )
;
: .enabled-ints  ( -- )
   d# 64 0  do                           ( )
      i /l* icu@  dup h# 70 and  if      ( n )
         ." INT" i .d ." -> IRQ"         ( n )
         4 " 0" .ifbit                   ( n )
         5 " 1" .ifbit                   ( n )
         6 " 2" .ifbit                   ( n )
         ."  Pri " h# f and .d  cr       ( )
      else                               ( n )
         drop                            ( )
      then                               ( )
   loop                                  ( )
;
: .int4  ( -- )
   ." INT4 - mask "  h# 168 icu@ .x
   ." status " h# 150 icu@ dup .x
   0   " USB " .ifbit
   1   " PMIC" .ifbit
   drop  cr
;
: .int5  ( -- )
   ." INT5 - mask "  h# 16c icu@ .x
   ." status " h# 154 icu@  dup .x
   0   " RTC " .ifbit
   1   " RTC_Alarm" .ifbit
   drop cr
;
: .int9  ( -- )
   ." INT9 - mask "  h# 17c icu@ .x
   ." status " h# 180 icu@  dup .x
   0   " Keypad " .ifbit
   1   " Rotary " .ifbit
   2   " Trackball" .ifbit
   drop cr
;
: .int17  ( -- )
   ." INT17 - mask " h# 170 icu@ .x
   ." status " h# 158 icu@  dup .x  ( n )
   7 2 do              ( n )
      dup 1 and  if    ( n )
	." TWSI" i .d  ( n )
      then             ( n )
      u2/              ( n' )
   loop                ( n )
   drop  cr            ( )
;
: .int35  ( -- )
   ." INT5 - mask "  h# 174 icu@ .x
   ." status " h# 15c icu@  dup  .x
   d#  0  " PJ_PerfMon" .ifbit
   d#  1 " L2_PA_ECC"   .ifbit
   d#  2 " L2_ECC"      .ifbit
   d#  3 " L2_UECC"     .ifbit
   d#  4 " DDR"         .ifbit
   d#  5 " Fabric0"     .ifbit
   d#  6 " Fabric1"     .ifbit
   d#  7 " Fabric2"     .ifbit
   d#  9 " Thermal"     .ifbit
   d# 10 " MainPMU"     .ifbit
   d# 11 " WDT2"        .ifbit
   d# 12 " CoreSight"   .ifbit
   d# 13 " PJ_Commtx"   .ifbit
   d# 14 " PJ_Commrx"   .ifbit
   drop
   cr
;
: .int51  ( -- )
   ." INT51 - mask " h# 178 icu@ .x
   ." status " h# 160 icu@  dup  .x
   0 " HSI_CAWAKE1 "  .ifbit
   1 " MIPI_HSI1"     .ifbit
   drop cr
;
: .int55  ( -- )
   ." INT55 - mask " h# 184 icu@ .x
   ." status " h# 188 icu@  dup  .x
   0 " HSI_CAWAKE0 "  .ifbit
   1 " MIPI_HSI0"     .ifbit
   drop cr
;

: .fiq  ( -- )
   h# 304 icu@  if  ." FIQ is masked off"  cr  then
   h# 300 icu@  dup  h# 40 and  if  ." FIQ selected INT" h# 3f and .d cr  else  drop  then
   h# 310 icu@  h# 314 icu@  2dup d0=  if  ( d )
      2drop                                ( )
   else                                    ( d )
      ." FIQ " (.pending) cr               ( )
   then                                    ( )
;
  
: .icu  ( -- )
   .enabled-ints
   3 0 do  i .masked  i .selected  i .pending  loop
   \ XXX should handle DMA interrupts too
   .fiq
   .int4  .int5  .int9  .int17  .int35  .int51  .int55
;
string-array wakeup-bit-names
   ," WU0 "
   ," WU1 "
   ," WU2 "
   ," WU3 "
   ," WU4 "
   ," WU5 "
   ," WU6 "
   ," WU7 "
   ," TIMER_1_1 "
   ," TIMER_1_2 "
   ," TIMER_1_3 "
   ," MSP_INS "
   ," AUDIO "
   ," WDT1 "
   ," TIMER_2_1 "
   ," TIMER_2_2 "
   ," TIMER_2_3 "
   ," RTC_ALARM "
   ," WDT2 "
   ," ROTARY "
   ," TRACKBALL "
   ," KEYPRESS "
   ," SDH3_CARD "
   ," SDH1_CARD "
   ," FULL_IDLE "
   ," ASYNC_INT "
   ," SSP1_SRDY "
   ," CAWAKE "
   ," resv28 "
   ," SSP3_SRDY "
   ," ALL_WU "
   ," resv31 "
end-string-array

string-array wakeup-mask-names
   ," WU0 "
   ," WU1 "
   ," WU2 "
   ," WU3 "
   ," WU4 "
   ," WU5 "
   ," WU6 "
   ," WU7 "
   ," TIMER_1_1 "
   ," TIMER_1_2 "
   ," TIMER_1_3 "
   ," "
   ," "
   ," "
   ," TIMER_2_1 "
   ," TIMER_2_2 "
   ," TIMER_2_3 "
   ," RTC_ALARM "
   ," WDT2 "
   ," ROTARY "
   ," TRACKBALL "
   ," KEYPRESS "
   ," SDH3_CARD "
   ," SDH1_CARD "
   ," FULL_IDLE "
   ," ASYNC_INT "
   ," WDT1 "
   ," SSP3_SRDY "
   ," SSP1_SRDY "
   ," CAWAKE "
   ," MSP_INS "
   ," resv31 "
end-string-array

: .active-wakeups  ( -- )
   ." Wakeups: "
   h# 1048 mpmu@    ( n )
   d# 31 0  do      ( n )
      dup 1 and  if  i wakeup-bit-names count type  then  ( n )
      u2/           ( n' )
   loop             ( n )
   drop cr          ( )
;
: .wakeup-mask  ( -- )
   ." Enabled wakeups: "
   h# 4c mpmu@  h# 104c or   ( n )
   d# 31 0  do               ( n )
      dup 1 and  if  i wakeup-mask-names count type  then  ( n )
      u2/                    ( n' )
   loop                      ( n )
   drop cr                   ( )
;
: .edges  ( -- )
   ." Wakeup edges: "           ( )
   d# 6 0  do                   ( )
      h# 19800 i la+ io@        ( n )
      d# 32  0  do              ( n )
         dup 1 and  if          ( n )
	    j d# 32 *  i +  .d  ( n )
         then                   ( n )
         u2/                    ( n' )
      loop                      ( n )
      drop                      ( )
   loop                         ( )
   cr                           ( )
;
: .edge-enables  ( -- )
   ." Enabled edges: "
   d# 160  0  do
      i af@ dup  h# 70 and  h# 40 <>   if  ( n )
         dup h# 10 and  if  ." R"  then    ( n )
         dup h# 20 and  if  ." F"  then    ( n )
         dup h# 40 and  if  ." C"  then    ( n )
	 i .d                              ( n )
      then                                 ( n )
      drop                                 ( )
   loop
;
: .wakeup  ( -- )   .active-wakeups  .wakeup-mask  .edges .edge-enables  ;

: .irqstat  ( -- )  h# 148 h# 130 do  i icu@ .  4 +loop   ;
\ !!! The problem right now is that I have woken from keyboard, but the interrupt is still asserted
\ So perhaps the interrupt handler didn't fire
: rotate-wakeup? ( -- flag )  d#  15 gpio-wakeup?   ;
: kbd-wakeup?    ( -- flag )  d#  71 gpio-wakeup?   ;
: tpd-wakeup?    ( -- flag )  d# 160 gpio-wakeup?   ;
\ We need to do this in the SP interrupt handler
: clear-wakeup  ( gpio# -- )
   dup af@                 ( gpio# value )
   2dup h# 40 or swap af!  ( gpio# value )
   swap af!
;
\ How to wakeup from SP:
: setup-key-wakeup  ( -- )
   d# 24 d# 16 do  h# b1 i af!  loop  \ Wake SP on game keys
   h# b0 d# 15 af!    \ Wake SP on rotate key
   h# 220 d#  71 af!  \ Wake SP on KBD CLK falling edge
   h# 221 d# 160 af!  \ Wake SP on TPD CLK falling edge
   h# 4c mpmu@  h# 20.0000 or h# 4c mpmu!  \ Keypress wakes SP
   ['] disable-int40 d# 40 interrupt-handler!
   d# 40 enable-interrupt  \ SP to PJ4 communications interrupt
   h# 2900cc io@ 1 invert and h# 2900cc io!  \ Unmask the communications interrupt
;

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
   h# 0010.0000 or                 ( apcr idle' )  \ PJ_MC_WAKE_EN - wake memory controller when core wakes

   0 h# b0 pmua!                   ( apcr idle )   \ PMUA_MC_HW_SLP_TYPE - self-refresh power down

   h# 18 pmua!                     ( apcr )        \ Set IDLE_CFG register
   h# 1000 mpmu!                   ( )             \ Set APCR register

   \ end mmp2_pm_enter_lowpower_mode(state)
;

: keyboard-power-on   ( -- )  d# 148 gpio-clr  ;
: keyboard-power-off  ( -- )  d# 148 gpio-set  ;
: wlan-power-on   ( -- )  d# 34 gpio-set  ;
: wlan-power-off  ( -- )  d# 34 gpio-clr  ;
0 value sleep-mask
: screen-off
   sleep-mask 1 and  if            \ DCON power down
      dcon-freeze
   else
      " dcon-suspend" $call-screen
   then
   " suspend" $call-screen
   " set-ack" $call-ec

   \ 0 h# 54 pmua!  \ Kill the SDIO 0 clocks - insignificant savings
   \ 0 h# 58 pmua!  \ Kill the SDIO 1 clocks - insignificant savings
   sleep-mask 2 and  0=  if  keyboard-power-off  then  \ Should save about 17 mW
   sleep-mask 4 and  0=  if  wlan-power-off      then  \ saves 100 mW
;
: screen-on  ( -- )
   sleep-mask 4 and  0=  if  wlan-power-on       then
   sleep-mask 2 and  0=  if  keyboard-power-on   then 
   " clr-ack" $call-ec
   " resume" $call-screen
   sleep-mask 1 and  if            \ DCON power up
      dcon-unfreeze
   else
      " dcon-resume" $call-screen
   then
;

: stdin-idle-on   ['] safe-idle to stdin-idle  d# 15 enable-interrupt  ;
: stdin-idle-off  ['] noop to stdin-idle  ( install-uart-io ) d# 15 disable-interrupt  ;

: timers-off  ( -- )
   0 h# 14048 io!    \ Disable interrupts from the tick timer
   7 h# 1407c io!    \ Clear any pending interrupts
   h# f disable-interrupt  \ Block timer interrupt
;
: timers-on  ( -- )
   1 h# 14048 io!    \ Enable interrupts from the tick timer
   7 h# 1407c io!    \ Clear any pending interrupts
   h# f enable-interrupt  \ Unblock timer interrupt
   reschedule-tick
;

: power-islands-off  ( -- )
   0 h# 10c pmua!   \ Turn off audio power island
;
: power-islands-on  ( -- )
   h# 712 h# 10c pmua!   \ Turn on audio power island
;

: str  ( -- )
   disable-interrupts
   timers-off

   screen-off
   stdin-idle-off
   5 h# 38 mpmu!    \ Use 32 kHz clock instead of VCXO for slow clock

\ OLPC: Unmask main PMU interrupt - don't know if this is necessary
\   h# 400 h# 174 +icu io-clr
\   d# 35 enable-interrupt

\ The PMIC_INT line is unconnected on XO-1.75.  Normally it would come from the EC,
\ presumably for the purpose of waking on a keystroke.
\  4 enable-interrupt   \ Route PMIC interrupt to PJ4 IRQ
\  2 h# 168 +icu io-clr \ Enable PMIC interrupt

   setup-sleep-state

   h# 000c.0000 h# 8c +pmua io-set  \ Power down CoreSight SRAM

   \ TODO - need to power down sram/l2$
   \ mmp2_cpu_disable_l2(0);
   \ outer_cache.flush_range(0, -1ul);

   power-islands-off

   disable-clks

   \ begin mmp2_cpu_do_idle()
   block-irqs                    ( )  \ Block IRQs - will be cleared by PMU
   do-self-refresh               ( )

   restore-run-state
   \ end mmp2_cpu_do_idle()

   enable-clks

   power-islands-on

   \ mmp2_cpu_enable_l2(0);

   \ idle_cfg &= (~PMUA_MOH_SRAM_PWRDWN);
   stdin-idle-on
   screen-on
   timers-on
   enable-interrupts
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
