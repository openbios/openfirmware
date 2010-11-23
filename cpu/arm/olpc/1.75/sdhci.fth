purpose: Load file for SDHCI (Secure Digital Host Controller Interface)

0 0  " d4280000"  " /"  begin-package

   fload ${BP}/cpu/arm/olpc/1.75/sdregs.fth
   fload ${BP}/dev/mmc/sdhci/sdhci.fth

\   true to avoid-high-speed?

   hex
   : olpc-card-inserted?  ( -- flag )
      slot 1 =  if  d# 31 gpio-pin@ 0=  else  true  then
   ;
   ' olpc-card-inserted? to card-inserted?

   \ Slot:power_GPIO - 1:35, 2:34, 3:33
   : gpio-power-on  ( -- )  sdhci-card-power-on  d# 36 slot - gpio-set  ;
   ' gpio-power-on to card-power-on

   : gpio-power-off  ( -- )  d# 36 slot - gpio-clr  sdhci-card-power-off  ;
   ' gpio-power-off to card-power-off

   new-device
      1 encode-int " reg" property
      fload ${BP}/dev/mmc/sdhci/sdmmc.fth
      fload ${BP}/dev/mmc/sdhci/selftest.fth
      " external" " slot-name" string-property
   finish-device

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
   h# 41b h# d4282854 l!   \ SD0 (external SD) clocks, plus set master clock divisor
   h#  1b h# d4282858 l!   \ SD1 (WLAN) clocks
   h#  1b h# d42828e8 l!   \ SD2 (internal microSD) clocks
   h# 70a h# d4200104 l!  \ Clock gating
   h# 70a h# d4201104 l!  \ Clock gating
;
