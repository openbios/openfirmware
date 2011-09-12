\ See license at end of file
purpose: Driver for OLPC camera connected to Via VX855 Video Capture Port

headers
hex

" OV7670" " sensor" string-property

: ov-smb-setup  ( -- )
   1 to smb-dly-us
   d# 108 to smb-clock-gpio#
   d# 109 to smb-data-gpio#
   h# 42 to smb-slave
;

: reset-sensor  ( -- )  d# 102 gpio-clr  1 ms  d# 102 gpio-set  ;

[ifdef] cl2-a1
: sensor-power-on   ( -- )  d# 145 gpio-set  ;
: sensor-power-off  ( -- )  d# 145 gpio-clr  ;
[else]
: sensor-power-on   ( -- )  d# 150 gpio-set  ;
: sensor-power-off  ( -- )  d# 150 gpio-clr  ;
[then]

\ CAM_HSYNC is on GPIO67, CAM_VSYNC is on GPIO68
\ PIXMCLK on GPIO69, PIXCLK on GPIO70, PIXDATA[7:0] on GPIO[59:66]
\ CAM_SCL on GPIO108, CAM_SDA on GPIO109 (bitbang)

0 value camera-base
: cl!  ( l adr -- )  camera-base + rl!  ;
: cl@  ( adr -- l )  camera-base + rl@  ;
