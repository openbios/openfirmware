purpose: Device node for MMP peripheral DMA

dev /
new-device
   " dma" device-name
   h# d4000000 h# 400 reg
   " marvell,pdma-1.0" +compatible
   d# 48 " interrupts" integer-property
   d# 16 " #dma-channels" integer-property
finish-device
device-end
