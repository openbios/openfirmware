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

: reset-sensor  ( -- )  d# 73 gpio-clr  1 ms  d# 73 gpio-set  ;

: sensor-power-on   ( -- )  d# 145 gpio-set  ;
: sensor-power-off  ( -- )  d# 145 gpio-clr  ;

\ CAM_HSYNC is on GPIO67, CAM_VSYNC is on GPIO68
\ PIXMCLK on GPIO69, PIXCLK on GPIO70, PIXDATA[7:0] on GPIO[59:66]
\ CAM_SCL on GPIO108, CAM_SDA on GPIO109 (bitbang)

: cl!  ( l adr -- )  h# d420a000 + rl!  ;
: cl@  ( adr -- l )  h# d420a000 + rl@  ;

