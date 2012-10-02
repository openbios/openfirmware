purpose: Load file for SDHCI (Secure Digital Host Controller Interface)

0 0  " "  " /"  begin-package

   fload ${BP}/cpu/arm/olpc/sdregs.fth
   fload ${BP}/dev/mmc/sdhci/sdhci.fth

   " simple-bus" +compatible
   h# d4280000 encode-int  h# d4280000 encode-int encode+  h# 2000 encode-int encode+  
   h# d4217000 encode-int encode+  h# d4217000 encode-int encode+  h# 800 encode-int encode+  
" ranges" property
   1 " #address-cells" integer-property
   1 " #size-cells" integer-property

   d# 1 to power-off-time  \ A2 and A3 have turn-off clamps
\   true to avoid-high-speed?

   hex
   : olpc-card-inserted?  ( -- flag )
      base-addr h# d428.0000 =  if  d# 31 gpio-pin@ 0=  else  true  then
   ;
   ' olpc-card-inserted? to card-inserted?

   \ Base-addr:power_GPIO - 1:35, 2:34, 3:33
   : gpio-power-on  ( -- )
      sdhci-card-power-on
[ifdef] en-emmc-pwr-gpio#
      base-addr h# d428.1000 =  if  en-emmc-pwr-gpio# gpio-clr  then
[then]
[ifdef] en-wlan-pwr-gpio#
      base-addr h# d428.0800 =  if  en-wlan-pwr-gpio# gpio-set  then
[then]
   ;
   ' gpio-power-on to card-power-on

   : gpio-power-off  ( -- )
[ifdef] en-emmc-pwr-gpio#
      base-addr h# d428.1000 =  if  en-emmc-pwr-gpio# gpio-set  then
[then]
[ifdef] en-wlan-pwr-gpio#
      base-addr h# d428.0800 =  if  en-wlan-pwr-gpio# gpio-clr  then
[then]
      sdhci-card-power-off
   ;
   ' gpio-power-off to card-power-off

   new-device  \ MMC2 - WLAN
      h# d428.0800 h# 800 reg
      8 encode-int " bus-width" property
      " sdhci-pxav3" +compatible
      " mrvl,pxav3-mmc" +compatible
      d# 31 encode-int " clk-delay-cycles" property
      0 0  " non-removable" property
      d# 52 " interrupts" integer-property

      " /pmua" encode-phandle 4 encode-int encode+ " clocks" property
      " PXA-SDHCLK" " clock-names" string-property
      d# 50 encode-int  d# 500 encode-int encode+  " power-delay-ms" property
      0 0 " broken-cd" property
[ifdef] en-wlan-pwr-gpio#
      \ Active high
      " /gpio" encode-phandle  en-wlan-pwr-gpio# encode-int encode+  0 encode-int encode+  " power-gpios" property
[then]

      fload ${BP}/dev/mmc/sdhci/slot.fth
      new-device
         fload ${BP}/dev/mmc/sdhci/mv8686/loadpkg.fth
      finish-device
   finish-device

   new-device  \ MMC3 - Internal eMMC
      h# d428.1000 h# 800 reg
      0 0  " non-removable" property
      8 encode-int " bus-width" property
      " sdhci-pxav3" +compatible
      " mrvl,pxav3-mmc" +compatible
      d# 31 encode-int " clk-delay-cycles" property
      d# 53 " interrupts" integer-property

      " /pmua" encode-phandle d# 14 encode-int encode+ " clocks" property
      " PXA-SDHCLK" " clock-names" string-property
      d# 40 encode-int  1 encode-int encode+  " power-delay-ms" property
      0 0 " broken-cd" property
[ifdef] en-emmc-pwr-gpio#
      \ Active low
      " /gpio" encode-phandle  en-emmc-pwr-gpio# encode-int encode+  1 encode-int encode+  " power-gpios"  property
[then]

      fload ${BP}/dev/mmc/sdhci/slot.fth
      : write-protected?  false  ;
      new-device
         fload ${BP}/dev/mmc/sdhci/sdmmc.fth
         fload ${BP}/dev/mmc/sdhci/selftest.fth
         " internal" " slot-name" string-property
      finish-device
   finish-device

end-package

\ mmc0 is the internal storage device, which may depend on BOOT_DEV_SEL, so its
\ devalias is set in platform-dependent code

\ The WLAN device is always mmc1
devalias mmc1 /sd/sdhci@d4280800

stand-init: SDHC clocks
   h# 400 h# 54 pmua!    \ Master SDH clock divisor
;
