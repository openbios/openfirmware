\ See license at end of file
purpose: Init USB2 Phy in Marvell SoC

: +usb2  ( offset -- offset' )  h# 20.7000 +  ;

  h# 04 +usb2 constant pll-reg0
  h# 08 +usb2 constant pll-reg1
  h# 10 +usb2 constant tx-reg0
  h# 14 +usb2 constant tx-reg1
  h# 18 +usb2 constant tx-reg2
  h# 20 +usb2 constant rx-reg0
  h# 24 +usb2 constant rx-reg1
  h# 28 +usb2 constant rx-reg2
\ h# 30 +usb2 constant ana-reg0
  h# 34 +usb2 constant ana-reg1
\ h# 38 +usb2 constant ana-reg2
\ h# 3c +usb2 constant dig-reg0
\ h# 40 +usb2 constant dig-reg1
\ h# 44 +usb2 constant dig-reg2
\ h# 48 +usb2 constant dig-reg3
\ h# 4c +usb2 constant test-reg0
\ h# 50 +usb2 constant test-reg1
\ h# 54 +usb2 constant test-reg2
\ h# 58 +usb2 constant charger-reg0
  h# 5c +usb2 constant otg-reg0
\ h# 60 +usb2 constant phy-mono
  h# 64 +usb2 constant reserve-reg0
\ h# 78 +usb2 constant icid-reg0
\ h# 7c +usb2 constant icid-reg1

: wait-cal  ( spins -- )
   0  do
      pll-reg1 io@  h# 8000 and  if  unloop exit  then \ PLL_READY_MASK
      1 ms
   loop
   ." PLL calibrate timeout" cr
;

: init-usb-phy  ( -- )
   h# f00  h# 100 +pmua  io-clr
\  h# d00  h# 100 +pmua  io-set   \ Select 26 MHz VCXO clock
   h# 000  h# 100 +pmua  io-set   \ Select crystal

\  h# ca60 is the value to use for a 25 MHz crystal
   h# daf0 pll-reg0 io!    \ REFDIV: 0xd << 9, FBDIV: 0xf0 << 0

   h# 3000 reserve-reg0 io! \ Program PLLVDD12 per Marvell email

\  h# 2773 pll-reg1 io-clr  \ PU_PLL_MASK 2000, (LOCK_BYPASS) 1000, ICP_MASK 700, KVCO_MASK 70, CALI12_MASK 3
\  h# 3333 pll-reg1 io-set  \             1                   1              3              3               3

   h# 1433 pll-reg1 io!
   d# 100 ms
   h# 3433 pll-reg1 io!

\  h# 0700 tx-reg0 io-clr   \ TX_IMPCAL_VTH_MASK 0700
\  h# 0200 tx-reg0 io-set   \                     2
   h# 0588 tx-reg0 io!   \                     2

\  h# 037f tx-reg1 io-clr   \ TX_VDD12_MASK 300 , TX_AMP_MASK 70, TX_CK60_PHSEL_MASK f
\  h# 0344 tx-reg1 io-set   \               3                 4                      4
   h# 07c4 tx-reg1 io!

\  h# 0c00 tx-reg2 io-clr   \ TX_DRV_SLEWRATE_MASK c00
\  h# 0800 tx-reg2 io-set   \  2 << 10
   h# 0eff tx-reg2 io!

\  h# 00f0 rx-reg0 io-clr   \ RX_SQ_THRESH_MASK 00f0
\  h# 00a0 rx-reg0 io-set   \                     a
   h# aaa1 rx-reg0 io!

   h# 5000 ana-reg1 io-set  \ Power up Analog Port
   h# 0008 otg-reg0 io-set  \ Power up OTG Port

\   h# 0008 rx-reg1 io-set   \ 1 << OTG_PU_OTG_SHIFT (3)

   \ Calibrate PHY
   d# 200 us
   h# 0004 pll-reg1 io-set  \ 1 << PLL_VCOCAL_START_SHIFT (2)
   d# 400 us
   h# 2000 tx-reg0  io-set  \ 1 << TX_RCAL_START_SHIFT (13)
   d# 40 us
   h# 2000 tx-reg0  io-clr  \ 1 << TX_RCAL_START_SHIFT (13)
   d# 400 us

   d# 100 wait-cal
;
