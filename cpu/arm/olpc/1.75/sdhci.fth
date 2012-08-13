fload ${BP}/cpu/arm/olpc/emmc.fth

\ Device node for external SD
dev /sd
   new-device
      h# d428.0000 h# 800 reg
      8 encode-int " bus-width" property
      " mrvl,pxav3-mmc" encode-string  " compatible" property
      d# 31 encode-int " clk-delay-cycles" property
      fload ${BP}/dev/mmc/sdhci/slot.fth
      d# 39 " interrupts" integer-property

      " /pmua" encode-phandle 3 encode-int encode+ " clocks" property
      " PXA-SDHCLK" " clock-names" string-property
      d# 40 encode-int  1 encode-int encode+  " power-delay-ms" property

      new-device
         fload ${BP}/dev/mmc/sdhci/sdmmc.fth
         fload ${BP}/dev/mmc/sdhci/selftest.fth
         " external" " slot-name" string-property
      finish-device
   finish-device
device-end

\ mmc1 is set in common code, always to the WLAN device
devalias mmc0 /sd/sdhci@d4281000  \ Primary boot device
devalias mmc2 /sd/sdhci@d4280000  \ External SD

devalias int /sd/sdhci@d4281000/disk
devalias ext /sd/sdhci@d4280000/disk
