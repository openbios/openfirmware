purpose: Common uspend/resume code for OLPC XO ARM plaforms

: apbc-clr-rst  ( offset -- )  4  swap +apbc  io-clr  ;
: apbc-set-rst  ( offset -- )  4  swap +apbc  io-set  ;

: disable-apbc-clks  ( -- )
   \ 3 h# 38 +apbc io-clr   \ GPIO
   3 h# 74 +apbc io-clr   \ MPMU
   3 h# 78 +apbc io-clr   \ IPC
   3 h# 90 +apbc io-clr   \ THSENS1

   \ h# 38 apbc-set-rst
   \ h# 74 apbc-set-rst   \ MPMU  - resetting this kills TIMER2, used by the SP PS/2
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
: pll2?  ( -- flag )  h# 34 mpmu@ h# 100 and 0<>  ;
: disable-mpmu-clks  ( -- )
   pll2?  if  h# e010  else  h# a010  then    ( cgr-value )
   dup h# 1024 mpmu!                  \ MPMU_CGR_PJ
   h# 0024 mpmu!                      \ MPMU_CGR_SP

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

[ifdef] soc-en-kbd-pwr-gpio#
: keyboard-power-on   ( -- )  soc-en-kbd-pwr-gpio# gpio-clr  ;
: keyboard-power-off  ( -- )  soc-en-kbd-pwr-gpio# gpio-set  ;
[else]
: keyboard-power-on   ( -- )  ;
: keyboard-power-off  ( -- )  ;
[then]
: wlan-power-on   ( -- )  en-wlan-pwr-gpio# gpio-set  ;
: wlan-power-off  ( -- )  en-wlan-pwr-gpio# gpio-clr  h# 040 en-wlan-pwr-gpio# af!  h# 040 wlan-pd-gpio# af!  h# 040 wlan-reset-gpio# af!  ;
: wlan-stay-on  ( -- )  h# 140 en-wlan-pwr-gpio# af!  h# 140 wlan-pd-gpio# af!  h# 140 wlan-reset-gpio# af!  ;

0 value sleep-mask
: screen-sleep
   sleep-mask 1 and  if            \ DCON power down
      dcon-freeze
   else
      " dcon-suspend" $call-dcon
   then
   " sleep" $call-screen
   " set-ack" $call-ec

   \ 0 h# 54 pmua!  \ Kill the SDIO 0 clocks - insignificant savings
   \ 0 h# 58 pmua!  \ Kill the SDIO 1 clocks - insignificant savings
   sleep-mask 2 and  0=  if  keyboard-power-off  then  \ Should save about 17 mW
   sleep-mask 4 and  if
      wlan-stay-on
   else
      " /wlan" " sleep" execute-device-method drop
      wlan-power-off
   then  \ saves 100 mW
;
: screen-wake  ( -- )
   sleep-mask 4 and  0=  if
      wlan-power-on
      " /wlan" " wake" execute-device-method drop
   then
   sleep-mask 2 and  0=  if  keyboard-power-on   then 
   " clr-ack" $call-ec
   " wake" $call-screen
   sleep-mask 1 and  if            \ DCON power up
      dcon-unfreeze
   else
      " dcon-resume" $call-dcon
   then
;

: stdin-idle-on   ['] safe-idle to stdin-idle  d# 15 enable-interrupt  ;
: stdin-idle-off  ['] noop to stdin-idle  ( install-uart-io ) d# 15 disable-interrupt  ;

: timers-sleep  ( -- )
   0 h# 14048 io!    \ Disable interrupts from the tick timer
   7 h# 1407c io!    \ Clear any pending interrupts
   h# f disable-interrupt  \ Block timer interrupt
;
: timers-wake ( -- )
   1 h# 14048 io!    \ Enable interrupts from the tick timer
   7 h# 1407c io!    \ Clear any pending interrupts
   h# f enable-interrupt  \ Unblock timer interrupt
   reschedule-tick
;

: platform-off  ( -- )
   disable-interrupts
   suspend-usb
   timers-sleep

   screen-sleep
   stdin-idle-off

   disable-clks
   power-islands-off
;

: platform-on  ( -- )
   power-islands-on

   enable-clks

   stdin-idle-on

   screen-wake
   timers-wake
   resume-usb
   enable-interrupts
   init-thermal-sensor
;

: str  ( -- )
   platform-off

   setup-sleep-state
   do-wfi
   restore-run-state

   platform-on
;

: strp  ( -- )  ec-rst-pwr  str  ec-sus-pwr .d ." mW " soc .%  space  ;
