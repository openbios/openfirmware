\ See license at end of file
purpose: Init UTMI USB Phy in Marvell SoC

h# d4207004 constant utmi-ctrl
h# d4207008 constant utmi-pll
h# d420700c constant utmi-tx
h# d4207010 constant utmi-rx
h# d4207014 constant utmi-ivref

: regset  ( mask adr -- )  tuck l@  or               swap l!  ;
: regclr  ( mask adr -- )  tuck l@  swap invert and  swap l!  ;

: wait-cal  ( spins -- )
   0  do
      utmi-pll rl@  h# 0080.0000 and  if  unloop exit  then
   loop
   ." PLL calibrate timeout" cr
;
h# 7e03.ffff value pll-clr  \ PLLCALI12, PLLVDD18, PLLVDD12, KVCO, ICP, FBDIV, REFDIV, 
h# 7e01.aeeb value pll-set  \         3         3         3     3    2     ee       b

h# 00df.c000 value tx-clr   \ TXVDD12, CK60_PHSEL, IMPCAL_VTH
h# 00c9.4000 value tx-set   \       3           4           5

h# 0001.80f0 value rx-clr   \ REG_SQ_LENGTH, RX_SQ_THRESH
h# 0001.000a value rx-set   \             2             a

: init-usb-phy  ( -- )
[ifdef] notdef
   ." Interacting before USB PHY init." cr
   ." Change pll-set, tx-set, rx-set as desired then type 'resume'" cr
   interact
[then]

   \ Turn on the USB PHY power
   h# 1010.0000 utmi-ctrl regset  \ INPKT_DELAY_SOF, PU_REF
   h#         2 utmi-ctrl regset  \ PLL_PWR_UP
   h#         1 utmi-ctrl regset  \ PWR_UP

   \ Configure the PLLs
   pll-clr utmi-pll  regclr  \ PLLCALI12, PLLVDD18, PLLVDD12, KVCO, ICP, FBDIV, REFDIV, 
   pll-set utmi-pll  regset  \         3         3         3     3    2     ee       b

   tx-clr  utmi-tx   regclr  \ TXVDD12, CK60_PHSEL, IMPCAL_VTH
   tx-set  utmi-tx   regset  \       3           4           5

   rx-clr  utmi-rx   regclr  \ REG_SQ_LENGTH, RX_SQ_THRESH
   rx-set  utmi-rx   regset  \             2             a

   d# 10000 wait-cal

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
