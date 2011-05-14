\ See license at end of file
purpose: Init UTMI USB Phy in Marvell SoC

h# d4207004 constant utmi-ctrl
h# d4207008 constant utmi-pll
h# d420700c constant utmi-tx
h# d4207010 constant utmi-rx
h# d4207014 constant utmi-ivref
h# d4207018 constant utmi-t0

: regset  ( mask adr -- )  tuck l@  or               swap l!  ;
: regclr  ( mask adr -- )  tuck l@  swap invert and  swap l!  ;

: wait-cal  ( spins -- )
   0  do
      utmi-pll rl@  h# 0080.0000 and  if  unloop exit  then
   loop
   ." PLL calibrate timeout" cr
;
\ h# 7e03.ffff value pll-clr  \ PLLCALI12, PLLVDD18, PLLVDD12, KVCO, ICP, FBDIV, REFDIV, 
\ h# 7e01.aeeb value pll-set  \         3         3         3     3    2     ee       b
h# 0003.ffff value pll-clr  \                                KVCO, ICP, FBDIV, REFDIV, 
h# 7e01.9eeb value pll-set  \         3         3         3     3    1     ee       b

h# 00df.c000 value tx-clr   \ TXVDD12, CK60_PHSEL, IMPCAL_VTH
h# 00c8.0000 value tx-set   \       3           4           0

h# 0000.00f0 value rx-clr   \ RX_SQ_THRESH
h# 0000.0070 value rx-set   \            7

: init-usb-phy  ( -- )
[ifdef] notdef
   ." Interacting before USB PHY init." cr
   ." Change pll-set, tx-set, rx-set as desired then type 'resume'" cr
   interact
[then]

   \ Turn on the USB PHY power
   h# 1010.0000 utmi-ctrl regset  \ INPKT_DELAY_SOF, PU_REF
   h#         2 utmi-ctrl regset  \ PLL_PWR_UP
   d# 10 ms
   h#         1 utmi-ctrl regset  \ PWR_UP
   1 ms

   \ Linux code does this, perhaps redundantly
   h# 1000.0000 utmi-ctrl regset  \ INPKT_DELAY_SOF, PU_REF

   h# 0000.8000 utmi-t0   regclr  \ REG_FIFO_SQ_RST

   \ Configure the PLLs
   pll-clr utmi-pll  regclr  \ PLLCALI12, PLLVDD18, PLLVDD12, KVCO, ICP, FBDIV, REFDIV, 
   pll-set utmi-pll  regset  \         3         3         3     3    1     ee       b
   1 ms

   tx-clr  utmi-tx   regclr  \ TXVDD12, CK60_PHSEL, IMPCAL_VTH
   tx-set  utmi-tx   regset  \       3           4           0

   rx-clr  utmi-rx   regclr  \ RX_SQ_THRESH
   rx-set  utmi-rx   regset  \            7

   d# 1000 wait-cal

   d# 200 us
   h# 0020.0000 utmi-pll  regset  \ VCOCAL_START
   d# 40 us
   h# 0020.0000 utmi-pll  regclr

   d# 200 us
   h# 0000.1000 utmi-tx   regset  \ REG_RCAL_START
   d# 40 us
   h# 0000.1000 utmi-tx  regclr

   d# 1000 wait-cal
\   ." UTMI calibration done" cr
;
