\ See license at end of file
purpose: Platform specifics for OLPC camera connected to Marvell MMP2 CMOS Camera Interface Controller (CCIC)

headers
hex

0 value camera-smb-slave
: camera-smb-setup  ( -- )
   1 to smb-dly-us
\+ olpc-cl2   d# 108 to smb-clock-gpio#
\+ olpc-cl2   d# 109 to smb-data-gpio#
\+ olpc-cl3   d#   4 to smb-clock-gpio#
\+ olpc-cl3   d#   5 to smb-data-gpio#
   camera-smb-slave to smb-slave
;
: camera-smb-on  ( -- )  camera-smb-setup  smb-on  ;
: ov@  ( reg -- data )  camera-smb-setup  smb-byte@  ;
: ov!  ( data reg -- )  camera-smb-setup  smb-byte!  ;

: reset-sensor  ( -- )
\+ olpc-cl3   d#  10 gpio-clr  1 ms  d#  10 gpio-set
\+ olpc-cl2   d# 102 gpio-clr  1 ms  d# 102 gpio-set
;

[ifdef] cl2-a1
: sensor-power-on   ( -- )  d# 145 gpio-set  ;
: sensor-power-off  ( -- )  d# 145 gpio-clr  ;
[else]
: sensor-power-on   ( -- )
   d# 150 gpio-set
\+ olpc-cl2  d# 144 gpio-clr
\+ olpc-cl3  d#   9 gpio-clr
;
: sensor-power-off  ( -- )  ( d# 144 gpio-set )  d# 150 gpio-clr  ;  \ Leave low for Linux
[then]

\ CAM_HSYNC is on GPIO67, CAM_VSYNC is on GPIO68
\ PIXMCLK on GPIO69, PIXCLK on GPIO70, PIXDATA[7:0] on GPIO[59:66]
\ CAM_SCL on GPIO108, CAM_SDA on GPIO109 (bitbang)
\ CAM_PWRDN on GPIO144

\ LICENSE_BEGIN
\ Copyright (c) 2011 FirmWorks
\ 
\ Permission is hereby granted, free of charge, to any person obtaining
\ a copy of this software and associated documentation files (the
\ "Software"), to deal in the Software without restriction, including
\ without limitation the rights to use, copy, modify, merge, publish,
\ distribute, sublicense, and/or sell copies of the Software, and to
\ permit persons to whom the Software is furnished to do so, subject to
\ the following conditions:
\ 
\ The above copyright notice and this permission notice shall be
\ included in all copies or substantial portions of the Software.
\ 
\ THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
\ EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
\ MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
\ NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
\ LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
\ OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
\ WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
\
\ LICENSE_END
