h# d102.0000 constant video-sram-pa  \ Base of Video SRAM
h#    1.0000 constant /video-sram

dev /
new-device
   " vsram" device-name
   video-sram-pa /video-sram reg

   " marvell,mmp-vsram" +compatible
   d# 64 " granularity" integer-property
finish-device
device-end

dev /display
new-device
   " panel" device-name
   " mrvl,dumb-panel" +compatible

   " OLPC DCON panel" model
   : +i  encode-int encode+  ;

   decimal
   0 0 encode-bytes
   \ xres,  yres, refresh,       clockhz,  left, right,  top, bottom, hsync, vsync, flags, widthmm, heightmm 
   1200 +i 900 +i    50 +i  56,930,000 +i  24 +i  26 +i  5 +i    4 +i  6 +i    3 +i   0 +i   152 +i   115 +i
   hex
   " linux,timing-modes" property

   " 1200x900@50"  " linux,mode-names" string-property

   h# 2000000d " lcd-dumb-ctrl-regval" integer-property
   h# 08001100 " lcd-pn-ctrl0-regval"  integer-property

\ In MMP3, the SCLK_SOURCE_SELECT field moved from bit 30 to bit 29,
\ so the high nibble changed from 4 (MMP2) to 2 (MMP3) for the same
\ field value 1.
[ifdef] mmp3  h# 20001102  [else]  h# 40001102  [then]  " clock-divider-regval" integer-property

finish-device
device-end

[ifdef] has-dcon
fload ${BP}/dev/olpc/dcon/mmp2dcon.fth        \ DCON control

dev /display/panel
   " /dcon" encode-phandle  " control-node" property
device-end
[then]

