\ XXX do we need to set the internal SD for fast drive in boardgpio.fth ?
: select-internal-sd  ( -- )
   ." Using internal SD" cr
   h# 18c3 d# 113 af!  \ SD_CMD
   h# 18c3 d# 126 af!  \ SD_DATA2
   h# 18c3 d# 127 af!  \ SD_DATA0
   h# 18c3 d# 130 af!  \ SD_DATA3
   h# 18c3 d# 135 af!  \ SD_DATA1
   h# 18c3 d# 138 af!  \ SD_CLK
   h# c1   d# 111 af!  \ eMMC_D0 as GPIO
   h# c1   d# 112 af!  \ eMMC_CMD as GPIO
   h# c1   d# 151 af!  \ eMMC_CLK as GPIO
   h# c1   d# 162 af!  \ eMMC_D6 as GPIO
   h# c1   d# 163 af!  \ eMMC_D4 as GPIO
   h# c1   d# 164 af!  \ eMMC_D2 as GPIO
   h# c1   d# 165 af!  \ eMMC_D7 as GPIO
   h# c1   d# 166 af!  \ eMMC_D5 as GPIO
   h# c1   d# 167 af!  \ eMMC_D3 as GPIO
   h# c1   d# 168 af!  \ eMMC_D1 as GPIO
;
: select-emmc  ( -- )
   ." Using eMMC" cr
   h# c1 d# 113 af!  \ SD_CMD as GPIO
   h# c1 d# 126 af!  \ SD_DATA2 as GPIO
   h# c0 d# 127 af!  \ SD_DATA0 as GPIO
   h# c0 d# 130 af!  \ SD_DATA3 as GPIO
   h# c0 d# 135 af!  \ SD_DATA1 as GPIO
   h# c0 d# 138 af!  \ SD_CLK as GPIO

   \ XXX perhaps 18c2 for fast?
   h# 18c2   d# 111 af!  \ eMMC_D0
   h# 18c2   d# 112 af!  \ eMMC_CMD
   h# 18c2   d# 151 af!  \ eMMC_CLK
   h# 18c2   d# 162 af!  \ eMMC_D6
   h# 18c2   d# 163 af!  \ eMMC_D4
   h# 18c2   d# 164 af!  \ eMMC_D2
   h# 18c2   d# 165 af!  \ eMMC_D7
   h# 18c2   d# 166 af!  \ eMMC_D5
   h# 18c2   d# 167 af!  \ eMMC_D3
   h# 18c2   d# 168 af!  \ eMMC_D1

   d# 149 gpio-set     \ Release eMMC_RST#

   d# 34 gpio-set  \ This is for the case where the eMMC power is rewired to the WLAN
;
\ Says COMM - is RST#
\ Says RESET - is CMD

stand-init:
   d# 56 gpio-pin@  if
      select-emmc
   else
      select-internal-sd
   then
;
