dev /sd
   new-device
   1 encode-int " reg" property
   fload ${BP}/dev/mmc/sdhci/sdmmc.fth
   fload ${BP}/dev/mmc/sdhci/selftest.fth
   " external" " slot-name" string-property
   finish-device
device-end

dev /sd
   new-device
   5 encode-int " reg" property
   fload ${BP}/dev/mmc/sdhci/sdmmc.fth
   fload ${BP}/dev/mmc/sdhci/selftest.fth
   " internal" " slot-name" string-property
   finish-device
device-end

devalias ext     /sd/disk@1
\ 2 is WLAN
devalias int     /sd/disk@3
devalias emmc    /sd/disk@3
\ Nothing on channel 4
devalias int-sd  /sd/disk@5

stand-init:
   boot-dev-sel-gpio# gpio-pin@  0=  if
      " int" " /sd/disk@5"  $devalias
   then
;
