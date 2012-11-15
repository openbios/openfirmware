dev /sd  \ MMC1 - External SD
   new-device
      h# d428.0000 h# 800 reg
      8 encode-int " bus-width" property
      " sdhci-pxav3" +compatible
      " mrvl,pxav3-mmc" +compatible
      d# 15 encode-int " clk-delay-cycles" property
      fload ${BP}/dev/mmc/sdhci/slot.fth
      d# 39 " interrupts" integer-property

      " /pmua" encode-phandle 3 encode-int encode+ " clocks" property
      " PXA-SDHCLK" " clock-names" string-property
      d# 40 encode-int  1 encode-int encode+  " power-delay-ms" property
      \ Active low
      " /gpio" encode-phandle  d# 31 encode-int encode+  1 encode-int encode+  " cd-gpios"  property
      \ Active low
      " /gpio" encode-phandle  sd-pwroff-gpio# encode-int encode+  1 encode-int encode+  " power-gpios" property

      \ MMP3 
      0 0  " wp-inverted" property
      : write-protected?  ( -- flag )  write-protected? 0=  ;

      new-device
         fload ${BP}/dev/mmc/sdhci/sdmmc.fth
         fload ${BP}/dev/mmc/sdhci/selftest.fth
         " external" " slot-name" string-property
      finish-device
   finish-device
device-end

dev /sd  \ MMC5 - internal micro-SD
   new-device
      h# d421.7000 h# 800 reg

      8 encode-int " bus-width" property
      " sdhci-pxav3" +compatible
      " mrvl,pxav3-mmc" +compatible
      d# 15 encode-int " clk-delay-cycles" property
      fload ${BP}/dev/mmc/sdhci/slot.fth
      " /interrupt-controller/interrupt-controller@184" encode-phandle " interrupt-parent" property
      d# 0 " interrupts" integer-property

      " /pmua" encode-phandle d# 27 encode-int encode+ " clocks" property
      " PXA-SDHCLK" " clock-names" string-property
      d# 40 encode-int  1 encode-int encode+  " power-delay-ms" property
      0 0 " broken-cd" property

      new-device
         fload ${BP}/dev/mmc/sdhci/sdmmc.fth
         fload ${BP}/dev/mmc/sdhci/selftest.fth
         " internal" " slot-name" string-property
      finish-device
   finish-device
device-end

\ mmc1 is set in common code, always to the WLAN device
devalias mmc2    /sd/sdhci@d4280000       \ External SD

devalias ext     /sd/sdhci@d4280000/disk
\ MMC2 @d4280800 is WLAN
devalias emmc    /sd/sdhci@d4281000/disk
\ Nothing on channel 4
devalias int-sd  /sd/sdhci@d4217000/disk

stand-init:
   \ The BOOT_DEV_SEL strap lets you choose either eMMC or microSD, both internal,
   \ as the primary boot device.
   boot-dev-sel-gpio# gpio-pin@  if
      " int"  " /sd/sdhci@d4281000/disk" $devalias  \ eMMC
      " mmc0" " /sd/sdhci@d4281000" $devalias  \ eMMC is primary storage
      " mmc3" " /sd/sdhci@d4217000" $devalias  \ Micro-SD is auxiliary device
   else
      " int"  " /sd/sdhci@d4217000/disk" $devalias  \ micro-SD
      " mmc0" " /sd/sdhci@d4217000" $devalias  \ Micro-SD is primary storage
      " mmc3" " /sd/sdhci@d4281000" $devalias  \ eMMC is auxiliary storage
   then
;
