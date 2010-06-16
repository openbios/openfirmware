purpose: Load file for SDHCI (Secure Digital Host Controller Interface)

0 0  " d4280000"  " /"  begin-package

   fload ${BP}/cpu/arm/mmp2/sdregs.fth
   fload ${BP}/dev/mmc/sdhci/sdhci.fth

   new-device
      3 encode-int " reg" property
      fload ${BP}/dev/mmc/sdhci/sdmmc.fth
      \ fload ${BP}/dev/mmc/sdhci/selftest.fth
      " internal" " slot-name" string-property
   finish-device

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
