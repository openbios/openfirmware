create debug-startup
create olpc
create olpc-cl4
create trust-ec-keyboard
create use-null-nvram
create use-elf
create has-sp-kbd
create has-dcon

fload ${BP}/cpu/arm/mmp2/hwaddrs.fth
fload ${BP}/cpu/arm/olpc/addrs.fth

h# 1f.0000 constant mfg-data-offset     \ Offset to manufacturing data area in SPI FLASH
h# 20.0000 constant mfg-data-end-offset \ Offset to end of manufacturing data area in SPI FLASH
h# 1e.ffd0 constant crc-offset
h# 1e.ffc0 constant signature-offset

h# 20.0000 constant /rom           \ Total size of SPI FLASH

: signature$   " CL4"  ;
: model$       " olpc,XO-CL4"  ;
: compatible$  " olpc,xo-cl4"  ;
: ec-platform$  ( -- adr len )  " 6"  ;

d# 10001 constant machine-type  \ Backwards compatibility with non-device-tree kernel

char 5 constant expected-ec-version
h# ec00 constant /ec-flash
h# eb80 constant ec-flags-offset   \ don't program or verify this page

fload ${BP}/cpu/arm/mmp3/soc-config.fth

fload ${BP}/cpu/arm/olpc/cl4/gpiopins.fth
