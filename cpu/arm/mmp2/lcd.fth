
: lcd@  ( offset -- l )  lcd-pa + io@  ;
: lcd!  ( l offset -- )  lcd-pa + io!  ;

: spi-clr-irq  ( -- )
   h# 1c4 lcd@  h# 00040000 invert and  h# 1c4 lcd!  \ Clear SPI_IRQ bit
;
: lcd-spi  ( w -- )
   spi-clr-irq
   1 us
   h# 180 lcd@  h# 40 or  h# 180 lcd!  \ Set CFG_KEEPXFER, set CS LOW
   ( w )  h# 184 lcd!  \ Set TX data
   h# 180 lcd@  1 or  h# 180 lcd!  \ Set SPI_START
   begin  h# 1c4 lcd@  h# 00040000 and  until
   spi-clr-irq
   h# 180 lcd@  h# 41 invert and  h# 180 lcd!  \ Clear CFG_KEEPXFER and SPI_START, set CS HITH
;
: init-tpo  ( -- )
   h# 0f000f0a h# 180 lcd!   \ Set LCD SPI controller for 16bit tranmit
   h# 080f lcd-spi  \ Invert pixel clockA
   h# 0c5f lcd-spi
   h# 1017 lcd-spi
   h# 1420 lcd-spi
   h# 1808 lcd-spi
   h# 1c20 lcd-spi
   h# 2020 lcd-spi
   h# 2420 lcd-spi
   h# 2820 lcd-spi
   h# 2c20 lcd-spi
   h# 3020 lcd-spi
   h# 3420 lcd-spi
   h# 3810 lcd-spi
   h# 3c10 lcd-spi
   h# 4010 lcd-spi
   h# 4415 lcd-spi
   h# 48aa lcd-spi
   h# 4cff lcd-spi
   h# 5086 lcd-spi
   h# 548d lcd-spi
   h# 58d4 lcd-spi
   h# 5cfb lcd-spi
   h# 602e lcd-spi
   h# 645a lcd-spi
   h# 6889 lcd-spi
   h# 6cfe lcd-spi
   h# 705a lcd-spi
   h# 749b lcd-spi
   h# 78c5 lcd-spi
   h# 7cff lcd-spi
   h# 80f0 lcd-spi
   h# 84f0 lcd-spi
   h# 8808 lcd-spi
;

: init-lcd  ( -- )
   0      h# 190 lcd!   \ Disable LCD DMA controller
   fb-pa               h# f4 lcd!  \ Frame buffer area 0
   0                   h# f8 lcd!  \ Frame buffer area 1
   hdisp bytes/pixel * h# fc lcd!  \ Pitch in bytes

   hdisp vdisp wljoin  dup h# 104 lcd!  dup h# 108 lcd!  h# 118 lcd!  \ size, size after zoom, disp

   htotal >chunks  vtotal wljoin  h# 114 lcd!  \ SPUT_V_H_TOTAL

   htotal >chunks  hdisp -  hbp >chunks -  6 -  ( low )
   hbp >chunks  wljoin  h# 11c lcd!
   
   vfp vbp wljoin  h# 120 lcd!
   h# 2000FF00 h# 194 lcd!  \ DMA CTRL 1
   h#        d h# 1b8 lcd!  \ Dumb panel controller
   h# 01330133 h# 13c lcd!  \ Panel VSYNC Pulse Pixel Edge Control
   h# 40001108 h# 1a8 lcd!  \ Clock divider
   h# 00021100 h# 190 lcd!  \ DMA CTRL 0 - enable DMA, 24 bpp mode
   init-dsi1
   init-tpo
   h# c0 lcd-backlight!
;
