\ See license at end of file
purpose: Init UTMI USB Phy in Marvell SoC

: +utmi  ( offset -- offset' )  h# 20.7000 +  ;

h# 04 +utmi constant utmi-ctrl
h# 08 +utmi constant utmi-pll
h# 0c +utmi constant utmi-tx
h# 10 +utmi constant utmi-rx
h# 14 +utmi constant utmi-ivref
h# 18 +utmi constant utmi-t0

: wait-cal  ( spins -- )
   0  do
      utmi-pll io@  h# 0080.0000 and  if  unloop exit  then
   loop
   ." PLL calibrate timeout" cr
;
\ h# 7e03.ffff value pll-clr  \ PLLCALI12, PLLVDD18, PLLVDD12, KVCO, ICP, FBDIV, REFDIV, 
\ h# 7e01.aeeb value pll-set  \         3         3         3     3    2     ee       b
h# 0003.ffff value pll-clr  \                                KVCO, ICP, FBDIV, REFDIV, 
h# 7e01.aeeb value pll-set  \         3         3         3     5    1     ee       b

h# 00df.c000 value tx-clr   \ TXVDD12, CK60_PHSEL, IMPCAL_VTH
h# 00c9.4000 value tx-set   \       3           4           5

h# 0000.00f0 value rx-clr   \ RX_SQ_THRESH
h# 0000.00a0 value rx-set   \            a

: init-usb-phy  ( -- )
[ifdef] notdef
   ." Interacting before USB PHY init." cr
   ." Change pll-set, tx-set, rx-set as desired then type 'resume'" cr
   interact
[then]

   \ Turn on the USB PHY power
   h# 1810.0000 utmi-ctrl io-set  \ INPKT_DELAY_SOF, PU_REF
   h#         2 utmi-ctrl io-set  \ PLL_PWR_UP
   d# 10 ms
   h#         1 utmi-ctrl io-set  \ PWR_UP
   1 ms

   \ Linux code does this, perhaps redundantly
   h# 1800.0000 utmi-ctrl io-set  \ INPKT_DELAY_SOF, PU_REF

   h# 0000.8000 utmi-t0   io-clr  \ REG_FIFO_SQ_RST

   \ Configure the PLLs
   pll-clr utmi-pll  io-clr  \ PLLCALI12, PLLVDD18, PLLVDD12, KVCO, ICP, FBDIV, REFDIV, 
   pll-set utmi-pll  io-set  \         3         3         3     3    1     ee       b
   1 ms

   tx-clr  utmi-tx   io-clr  \ TXVDD12, CK60_PHSEL, IMPCAL_VTH
   tx-set  utmi-tx   io-set  \       3           4           0

   rx-clr  utmi-rx   io-clr  \ RX_SQ_THRESH
   rx-set  utmi-rx   io-set  \            7

   d# 1000 wait-cal

   d# 200 us
   h# 0020.0000 utmi-pll  io-set  \ VCOCAL_START
   d# 40 us
   h# 0020.0000 utmi-pll  io-clr

   d# 200 us
   h# 0000.1000 utmi-tx   io-set  \ REG_RCAL_START
   d# 40 us
   h# 0000.1000 utmi-tx  io-clr

   d# 1000 wait-cal
\   ." UTMI calibration done" cr
;
