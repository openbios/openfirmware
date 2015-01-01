purpose: Generic Interrupt Controller node for Marvell MMP3

0 0  " e0001000"  " /" begin-package
  " interrupt-controller" device-name
  " arm,arm11mp-gic" +compatible
  0 0 " interrupt-controller" property
  1 " #address-cells" integer-property
  1 " #size-cells" integer-property
  3 " #interrupt-cells" integer-property
  h# e0001000 encode-int  h# 1000 encode-int encode+
  h# e0000100 encode-int encode+  h# 100 encode-int encode+  " reg" property

  : encode-unit  ( phys -- adr len )  push-hex (u.) pop-base  ;
  : decode-unit  ( adr len -- phys )  push-hex $number if 0  then pop-base  ;

  : make-gmux-node  ( statreg maskreg irq# #irqs )
     new-device
     " interrupt-controller" name             ( maskreg statreg irq# #irqs )
     " mrvl,intc-nr-irqs" integer-property    ( maskreg statreg irq# )
     0 encode-int  rot encode-int encode+
     1 encode-int encode+
     " interrupts" property                 ( maskreg statreg )
     >r  4 encode-reg  r> 4 encode-reg encode+  " reg" property  ( )
     " mrvl,mmp3-mux-intc" +compatible
     0 0 " interrupt-controller" property
     1 " #interrupt-cells" integer-property
     " mux status" encode-string  " mux mask" encode-string  encode+ " reg-names" property
     finish-device
  ;

  \ create mux nodes
  h# 150 h# 168     4     4 make-gmux-node \ intcmux4 - USB_CHARGER, PMIC, SPMI, CHRG_DTC_OUT
  h# 154 h# 16c     5     2 make-gmux-node \ intcmux5 - RTC_ALARM, RTC
  h# 1bc h# 1a4     6     3 make-gmux-node \ intcmux6 - ETHERNET, res, HSI_INT_3
  h# 1c0 h# 1a8     8     4 make-gmux-node \ intcmux8 - GC2000, res, GC300, MOLTRES_NGIC_2
  h# 158 h# 170 d# 17     5 make-gmux-node \ intcmux17 - TWSI2,3,4,5,6
  h# 1c4 h# 1ac d# 18     3 make-gmux-node \ intcmux18 - Res, HSI_INT_2, MOLTRES_NGIC_1
  h# 1c8 h# 1b0 d# 30     2 make-gmux-node \ intcmux30 - ISP_DMA, DXO_ISP
  h# 15c h# 174 d# 35 d# 31 make-gmux-node \ intcmux35 - MOLTRES_(various)  (different from MMP2)
  h# 1cc h# 1b4 d# 42     2 make-gmux-node \ intcmux42 - CCIC2, CCIC1
  h# 160 h# 178 d# 51     2 make-gmux-node \ intcmux51 - SSP1_SRDY, SSP3_SRDY
  h# 184 h# 17c d# 55     4 make-gmux-node \ intcmux55 - MMC5, res, res, HSI_INT_1
  h# 188 h# 180 d# 57 d# 20 make-gmux-node \ intcmux57 - (various)
  h# 1d0 h# 1b8 d# 58     5 make-gmux-node \ intcmux58 - MSP_CARD, KERMIT_INT_0, KERMIT_INT_1, res, HSI_INT_0
  h# 128 h# 11c d# 48 d# 24 make-gmux-node \ DMA mux - 16 PDMA, 4 ADMA, 2 VDMA channels
end-package

dev /
  " /interrupt-controller@e0001000" encode-phandle " interrupt-parent" property
dend

: irqdef ( irq# -- )
  0 encode-int
  rot encode-int encode+
  4 encode-int encode+
  " interrupts" property
;

: irqdef2 ( irq# irq# -- )
  swap
  0 encode-int
  rot encode-int encode+
  1 encode-int encode+
  0 encode-int encode+
  rot encode-int encode+
  1 encode-int encode+
  " interrupts" property
;

\ modify all irqs to use 3 cells instead of 1
dev /timer  d irqdef  dend
\ dev /wakeup-rtc  1 0 irqdef2  dend
\ dev /thermal  b irqdef  dend
\ dev /audio  2 irqdef  dend
dev /sspa  3 irqdef  dend
\ dev /adma@c0ffd800  12 13 irqdef2  dend
\ dev /adma@c0ffd900  14 15 irqdef2  dend
\ dev /camera  1 irqdef  dend
dev /ap-sp  28 irqdef  dend
dev /usb  2c irqdef  dend
dev /ec-spi
  0 encode-int
  h# 14 encode-int encode+
  h# 4 encode-int encode+
  " interrupts" property
dend
\ dev /sd/sdhci@d4217000  0 irqdef  dend
dev /sd/sdhci@d4280000  27 irqdef  dend
dev /sd/sdhci@d4281000  35 irqdef  dend
dev /sd/sdhci@d4280800
  0 encode-int
  h# 34 encode-int encode+
  h# 4 encode-int encode+
  " interrupts" property
dend
\ dev /gpu  0 2 irqdef2  dend
dev /display  29 irqdef  dend
dev /vmeta  1a irqdef  dend
dev /flash  0 irqdef  dend
dev /uart@d4016000  2e irqdef  dend
dev /uart@d4030000  1b irqdef  dend
dev /uart@d4017000  1c irqdef  dend
dev /uart@d4018000  18 irqdef  dend
dev /i2c@d4034000  4 irqdef  dend
dev /i2c@d4033000  2 irqdef  dend
dev /i2c@d4031000  0 irqdef  dend
dev /i2c@d4011000  7 irqdef  dend
dev /dma  30 irqdef  dend
dev /gpio  31 irqdef  dend

\ modify all mux irq users to not point to ICU node
dev /sd/sdhci@d4217000
  " /interrupt-controller@e0001000/interrupt-controller@184" encode-phandle " interrupt-parent" property
dend
dev /camera@d420a000
  " /interrupt-controller@e0001000/interrupt-controller@1cc" encode-phandle " interrupt-parent" property
dend
dev /adma@c0ffd800
  " /interrupt-controller@e0001000/interrupt-controller@128" encode-phandle " interrupt-parent" property
dend
dev /adma@c0ffd900
  " /interrupt-controller@e0001000/interrupt-controller@128" encode-phandle " interrupt-parent" property
dend
dev /thermal
  " /interrupt-controller@e0001000/interrupt-controller@188" encode-phandle " interrupt-parent" property
dend
dev /wakeup-rtc
  " /interrupt-controller@e0001000/interrupt-controller@154" encode-phandle " interrupt-parent" property
dend
dev /gpu
  " /interrupt-controller@e0001000/interrupt-controller@1c0" encode-phandle " interrupt-parent" property
dend
dev /i2c@d4034000
  " /interrupt-controller@e0001000/interrupt-controller@158" encode-phandle " interrupt-parent" property
dend
dev /i2c@d4033000
  " /interrupt-controller@e0001000/interrupt-controller@158" encode-phandle " interrupt-parent" property
dend
dev /i2c@d4031000
  " /interrupt-controller@e0001000/interrupt-controller@158" encode-phandle " interrupt-parent" property
dend

: mmp3-gic  ." mmp3-gic" cr  ;  \ 92ms
