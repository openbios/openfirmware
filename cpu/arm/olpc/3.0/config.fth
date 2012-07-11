create debug-startup
create olpc
create olpc-cl3
create use-null-nvram
create use-elf
create use-screen-kbd
create use-small-font

fload ${BP}/cpu/arm/mmp2/hwaddrs.fth
fload ${BP}/cpu/arm/olpc/addrs.fth

[ifdef] use-flash-nvram
h# d.0000 constant nvram-offset
[then]

h#  e.0000 constant mfg-data-offset     \ Offset to manufacturing data area in SPI FLASH
h#  f.0000 constant mfg-data-end-offset \ Offset to end of manufacturing data area in SPI FLASH
h#  f.ffd8 constant crc-offset

h# 10.0000 constant /rom           \ Total size of SPI FLASH

: signature$   " CL3"  ;
: model$       " olpcXO-3.0"  ;
: compatible$  " olpcxo-3.0"  ;

d# 10000 constant machine-type  \ Backwards compatibility with non-device-tree kernel

char 4 constant expected-ec-version
h# 8000 value /ec-flash

h# 10000 constant l2-#sets

d#  56 constant boot-dev-sel-gpio#

d#   4 constant cam-scl-gpio#
d#   5 constant cam-sda-gpio#

d#  10 constant cam-rst-gpio#
d# 150 constant cam-pwr-gpio#
d#   9 constant cam-pwrdn-gpio#

d#  46 constant spi-flash-cs-gpio#

d# 155 constant ec-spi-cmd-gpio#
d# 125 constant ec-spi-ack-gpio#

\ CL3 has no DCON

d#  34 constant en-wlan-pwr-gpio#
d#  57 constant wlan-pd-gpio#
d#  58 constant wlan-reset-gpio#

d# 146 constant usb-hub-reset-gpio#

d# 149 constant emmc-rst-gpio#

d# 142 constant sec-trg-gpio#

d#  53 constant rtc-scl-gpio#
d#  54 constant rtc-sda-gpio#

d# 104 constant ec-edi-cs-gpio#
d# 105 constant ec-edi-mosi-gpio#
d# 106 constant ec-edi-clk-gpio#

d# 143 constant mic-ac/dc-gpio#
d#   8 constant audio-reset-gpio#
d#  97 constant hp-plug-gpio#
d#  11 constant vid2-gpio#
