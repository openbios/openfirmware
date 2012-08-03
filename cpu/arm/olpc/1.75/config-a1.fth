create cl2-a1
create debug-startup
create olpc
create olpc-cl2
create trust-ec-keyboard
create use-null-nvram
create use-elf
create has-sp-kbd
create has-dcon

fload ${BP}/cpu/arm/mmp2/hwaddrs.fth
fload ${BP}/cpu/arm/olpc/addrs.fth

[ifdef] use-flash-nvram
h# d.0000 constant nvram-offset
[then]

h#  e.0000 constant mfg-data-offset     \ Offset to manufacturing data area in SPI FLASH
h#  f.0000 constant mfg-data-end-offset \ Offset to end of manufacturing data area in SPI FLASH
h#  f.ffd8 constant crc-offset

h# 10.0000 constant /rom           \ Total size of SPI FLASH

: signature$    " CL2"  ;
: model$        " olpc,XO-1.75"  ;
: compatible$   " olpc,xo-1.75"  ;

: touchscreen-driver$  " ${BP}/cpu/arm/olpc/rm3150-touchscreen.fth"  ;
d#  9999 constant machine-type  \ Backwards compatibility with non-device-tree kernel

char 3 constant expected-ec-version
h# 10000 value /ec-flash

h# 10000 constant l2-#sets

d# 108 constant cam-scl-gpio#
d# 109 constant cam-sda-gpio#

d# 102 constant cam-rst-gpio#
d# 145 constant cam-pwr-gpio#

d#  46 constant spi-flash-cs-gpio#

d# 155 constant ec-spi-cmd-gpio#
d# 125 constant ec-spi-ack-gpio#

d# 162 constant dcon-scl-gpio#
d# 163 constant dcon-sda-gpio#

d# 124 constant dcon-irq-gpio#
d# 151 constant dcon-load-gpio#

d#  34 constant en-wlan-pwr-gpio#
d#  57 constant wlan-pd-gpio#
d#  58 constant wlan-reset-gpio#

d# 146 constant usb-hub-reset-gpio#

d# 149 constant emmc-rst-gpio#

d#  73 constant sec-trg-gpio#

d#  97 constant rtc-scl-gpio#
d#  98 constant rtc-sda-gpio#

d# 129 constant lid-switch-gpio#
d# 128 constant ebook-mode-gpio#

d# 143 constant mic-ac/dc-gpio#
d#   8 constant audio-reset-gpio#
d#  97 constant hp-plug-gpio#
d#  96 constant mic-plug-gpio#

d#  10 constant led-storage-gpio#
d#  11 constant vid2-gpio#

d# 160 constant soc-tpd-clk-gpio#
d# 107 constant soc-tpd-dat-gpio#

d#  71 constant soc-kbd-clk-gpio#
d#  72 constant soc-kbd-dat-gpio#
d# 148 constant soc-en-kbd-pwr-gpio#

d# 144 constant cam-pwrdn-gpio#

d#   4 constant compass-scl-gpio#
d#   5 constant compass-sda-gpio#

d#  20 constant rotate-gpio#
