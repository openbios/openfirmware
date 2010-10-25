purpose: Load file for SDHCI (Secure Digital Host Controller Interface)

0 0  " d4280000"  " /"  begin-package

   fload ${BP}/cpu/arm/olpc/1.75/sdregs.fth
   fload ${BP}/dev/mmc/sdhci/sdhci.fth

   true to avoid-high-speed?

   hex
   \ The new clock divisor layout is low 8 bits in [15:8] and high 2 bits in [7:6]
   \ The resulting 10-bit value is multiplied by 2 to form the divisor for the
   \ 200 MHz base clock.
   patch 403  103 card-clock-25    \ n is 4, divisor is 8, clk is 25 MHz
   patch 203  003 card-clock-50    \ n is 2, divisor is 4, clk is 50 MHz
   patch 043 8003 card-clock-slow  \ n is h# 100 (high 2 bits in [7:6], for divisor of 512 from 200 MHz clock

   : gpio-card-inserted?  ( -- flag )  d# 31 gpio-pin@ 0=  ;
   ' gpio-card-inserted? to card-inserted?

   : gpio-power-on  ( -- )  sdhci-card-power-on  d# 35 gpio-set  ;
   ' gpio-power-on to card-power-on

   : gpio-power-off  ( -- )  d# 35 gpio-clr  sdhci-card-power-off  ;
   ' gpio-power-off to card-power-off

\  new-device
\     2 encode-int " reg" property
\     " mv8686" " $load-driver" eval drop
\  finish-device

   new-device
      1 encode-int " reg" property
      fload ${BP}/dev/mmc/sdhci/sdmmc.fth
      \ fload ${BP}/dev/mmc/sdhci/selftest.fth
      " external" " slot-name" string-property
   finish-device

end-package

0 0  " d4281000"  " /"  begin-package

   fload ${BP}/cpu/arm/olpc/1.75/sdregs.fth
   fload ${BP}/dev/mmc/sdhci/sdhci.fth

   true to avoid-high-speed?

   hex
   \ The new clock divisor layout is low 8 bits in [15:8] and high 2 bits in [7:6]
   \ The resulting 10-bit value is multiplied by 2 to form the divisor for the
   \ 200 MHz base clock.
   patch 403  103 card-clock-25    \ n is 4, divisor is 8, clk is 25 MHz
   patch 203  003 card-clock-50    \ n is 2, divisor is 4, clk is 50 MHz
   patch 043 8003 card-clock-slow  \ n is h# 100 (high 2 bits in [7:6], for divisor of 512 from 200 MHz clock

   ' true to card-inserted?

   : gpio-power-on  ( -- )  sdhci-card-power-on d# 33 gpio-set  ;
   ' gpio-power-on to card-power-on

   : gpio-power-off  ( -- )  d# 33 gpio-clr  sdhci-card-power-off  ;
   ' gpio-power-off to card-power-off


   new-device
      1 encode-int " reg" property
      fload ${BP}/dev/mmc/sdhci/sdmmc.fth
      \ fload ${BP}/dev/mmc/sdhci/selftest.fth
      " internal" " slot-name" string-property
   finish-device

end-package

stand-init: \ SDHC clocks
   h# 41b h# d4282854 l!   \ SD0 (external SD) clocks, plus set master clock divisor
   h#  1b h# d42828e8 l!   \ SD2 (internal microSD) clocks
   h# 70a h# d4200104 l!  \ Clock gating
   h# 70a h# d4201104 l!  \ Clock gating
;
