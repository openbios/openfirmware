purpose: Load file for SDHCI (Secure Digital Host Controller Interface)

0 0  " "  " /"  begin-package

   fload ${BP}/cpu/arm/olpc/sdregs.fth
   fload ${BP}/dev/mmc/sdhci/sdhci.fth

   " simple-bus" +compatible
   h# d4280000 encode-int  h# d4280000 encode-int encode+  h# 2000 encode-int encode+  " ranges" property
   1 " #address-cells" integer-property
   1 " #size-cells" integer-property

   d# 1 to power-off-time  \ A2 and A3 have turn-off clamps
\   true to avoid-high-speed?

   hex
   : slot#  ( -- n )  slot h# d4280000 -  h# 800 /  1+  ;
   : olpc-card-inserted?  ( -- flag )
      slot# 1 =  if  d# 31 gpio-pin@ 0=  else  true  then
   ;
   ' olpc-card-inserted? to card-inserted?

   \ Slot:power_GPIO - 1:35, 2:34, 3:33
   : gpio-power-on  ( -- )
      sdhci-card-power-on
\ The CL3 version below actually works for CL2 >= B1
\+ olpc-cl2  d# 36 slot# - gpio-set
\+ olpc-cl3  slot# 2 =  if  d# 34 gpio-set  then
   ;
   ' gpio-power-on to card-power-on

   : gpio-power-off  ( -- )
\+ olpc-cl2  d# 36 slot# - gpio-clr
\+ olpc-cl3  slot# 2 =  if  d# 34 gpio-clr  then
      sdhci-card-power-off
   ;
   ' gpio-power-off to card-power-off

\+ olpc-cl2   new-device
\+ olpc-cl2      h# d428.0000 h# 800 reg
\+ olpc-cl2      8 encode-int " bus-width" property
\+ olpc-cl2      " mrvl,pxav3-mmc" encode-string  " compatible" property
\+ olpc-cl2      d# 31 encode-int " clk-delay-cycles" property
\+ olpc-cl2      fload ${BP}/dev/mmc/sdhci/slot.fth
\+ olpc-cl2      d# 39 " interrupts" integer-property

\+ olpc-cl2      " /pmua" encode-phandle 3 encode-int encode+ " clocks" property
\+ olpc-cl2      " PXA-SDHCLK" " clock-names" string-property

\+ olpc-cl2      new-device
\+ olpc-cl2         fload ${BP}/dev/mmc/sdhci/sdmmc.fth
\+ olpc-cl2         fload ${BP}/dev/mmc/sdhci/selftest.fth
\+ olpc-cl2         " external" " slot-name" string-property
\+ olpc-cl2      finish-device
\+ olpc-cl2   finish-device

   new-device
      h# d428.0800 h# 800 reg
      8 encode-int " bus-width" property
      " sdhci-pxav3" +compatible
      " mrvl,pxav3-mmc" +compatible
      d# 31 encode-int " clk-delay-cycles" property
      0 0  " non-removable" property
      d# 52 " interrupts" integer-property

      " /pmua" encode-phandle 4 encode-int encode+ " clocks" property
      " PXA-SDHCLK" " clock-names" string-property

      fload ${BP}/dev/mmc/sdhci/slot.fth
      new-device
         fload ${BP}/dev/mmc/sdhci/mv8686/loadpkg.fth
      finish-device
   finish-device

   new-device
      h# d428.1000 h# 800 reg
      0 0  " non-removable" property
      8 encode-int " bus-width" property
      " sdhci-pxav3" +compatible
      " mrvl,pxav3-mmc" +compatible
      d# 31 encode-int " clk-delay-cycles" property
      d# 53 " interrupts" integer-property

      " /pmua" encode-phandle d# 14 encode-int encode+ " clocks" property
      " PXA-SDHCLK" " clock-names" string-property

      fload ${BP}/dev/mmc/sdhci/slot.fth
      new-device
         fload ${BP}/dev/mmc/sdhci/sdmmc.fth
         fload ${BP}/dev/mmc/sdhci/selftest.fth
         " internal" " slot-name" string-property
      finish-device
   finish-device

end-package

stand-init: SDHC clocks
   h# 41b h# 282854 io!   \ SD0 (external SD) clocks, plus set master clock divisor
   h#  1b h# 282858 io!   \ SD1 (WLAN) clocks
   h#  1b h# 2828e8 io!   \ SD2 (internal microSD) clocks
   h# 70a h# 200104 io!  \ Clock gating
   h# 70a h# 201104 io!  \ Clock gating
;
