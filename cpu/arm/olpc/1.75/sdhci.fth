fload ${BP}/cpu/arm/olpc/emmc.fth

\ Device node for internal microSD
dev /sd
   new-device
      1 encode-int " reg" property
      fload ${BP}/dev/mmc/sdhci/sdmmc.fth
      fload ${BP}/dev/mmc/sdhci/selftest.fth
      " external" " slot-name" string-property
   finish-device
device-end

devalias int /sd/disk@3
devalias ext /sd/disk@1
