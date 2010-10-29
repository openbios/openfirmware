
: lcd@  ( offset -- l )  lcd-pa + l@  ;
: lcd!  ( l offset -- )  lcd-pa + l!  ;

: init-lcd  ( -- )
   \ Turn on clocks
   h# 08 pmua-disp-clk-sel + h# d428284c l!
   h# 09 pmua-disp-clk-sel + h# d428284c l!
   h# 19 pmua-disp-clk-sel + h# d428284c l!
   h# 1b pmua-disp-clk-sel + h# d428284c l!

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
   h# 2000000d h# 1b8 lcd!  \ Dumb panel controller - 18 bit RGB666 on LDD[17:0]
   h# 01330133 h# 13c lcd!  \ Panel VSYNC Pulse Pixel Edge Control
   clkdiv      h# 1a8 lcd!  \ Clock divider
   h# 00021100 h# 190 lcd!  \ DMA CTRL 0 - enable DMA, 24 bpp mode
;
