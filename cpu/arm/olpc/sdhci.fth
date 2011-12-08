purpose: Load file for SDHCI (Secure Digital Host Controller Interface)

0 0  " d4280000"  " /"  begin-package

   fload ${BP}/cpu/arm/olpc/sdregs.fth
   fload ${BP}/dev/mmc/sdhci/sdhci.fth

   d# 1 to power-off-time  \ A2 and A3 have turn-off clamps
\   true to avoid-high-speed?

   hex
   : olpc-card-inserted?  ( -- flag )
      slot 1 =  if  d# 31 gpio-pin@ 0=  else  true  then
   ;
   ' olpc-card-inserted? to card-inserted?

   \ Slot:power_GPIO - 1:35, 2:34, 3:33
   : gpio-power-on  ( -- )
      sdhci-card-power-on
\ The CL3 version below actually works for CL2 >= B1
\+ olpc-cl2  d# 36 slot - gpio-set
\+ olpc-cl3  slot 2 =  if  d# 34 gpio-set  then
   ;
   ' gpio-power-on to card-power-on

   : gpio-power-off  ( -- )
\+ olpc-cl2  d# 36 slot - gpio-clr
\+ olpc-cl3  slot 2 =  if  d# 34 gpio-clr  then
      sdhci-card-power-off
   ;
   ' gpio-power-off to card-power-off

\+ olpc-cl2   new-device
\+ olpc-cl2      1 encode-int " reg" property
\+ olpc-cl2      fload ${BP}/dev/mmc/sdhci/sdmmc.fth
\+ olpc-cl2      fload ${BP}/dev/mmc/sdhci/selftest.fth
\+ olpc-cl2      " external" " slot-name" string-property
\+ olpc-cl2   finish-device

   new-device
      2 encode-int " reg" property
      fload ${BP}/dev/mmc/sdhci/mv8686/loadpkg.fth
   finish-device

   new-device
      3 encode-int " reg" property
      fload ${BP}/dev/mmc/sdhci/sdmmc.fth
      fload ${BP}/dev/mmc/sdhci/selftest.fth
      " internal" " slot-name" string-property
   finish-device

end-package

stand-init: SDHC clocks
   h# 41b h# 282854 io!   \ SD0 (external SD) clocks, plus set master clock divisor
   h#  1b h# 282858 io!   \ SD1 (WLAN) clocks
   h#  1b h# 2828e8 io!   \ SD2 (internal microSD) clocks
   h# 70a h# 200104 io!  \ Clock gating
   h# 70a h# 201104 io!  \ Clock gating
;
