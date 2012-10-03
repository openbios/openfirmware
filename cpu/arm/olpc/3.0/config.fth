create debug-startup
create olpc
create olpc-cl3
create use-null-nvram
create use-elf
create use-screen-kbd
create use-small-font

fload ${BP}/cpu/arm/mmp2/soc-config.fth
fload ${BP}/cpu/arm/mmp2/hwaddrs.fth
fload ${BP}/cpu/arm/olpc/addrs.fth

[ifdef] use-flash-nvram
h# d.0000 constant nvram-offset
[then]

h#  e.0000 constant mfg-data-offset     \ Offset to manufacturing data area in SPI FLASH
h#  f.0000 constant mfg-data-end-offset \ Offset to end of manufacturing data area in SPI FLASH
h#  f.ffd8 constant crc-offset
h#  f.ffc0 constant signature-offset

h# 10.0000 constant /rom           \ Total size of SPI FLASH

: signature$   " CL3"  ;
: model$       " olpcXO-3.0"  ;
: compatible$  " olpcxo-3.0"  ;
: ec-platform$  ( -- adr len )  " 5"  ;
: bundle-suffix$  ( -- adr len )  " 3"  ;

d# 10000 constant machine-type  \ Backwards compatibility with non-device-tree kernel

char 4 constant expected-ec-version
h# 8000 value /ec-flash

h# 18000 constant console-uart-base

fload ${BP}/cpu/arm/olpc/3.0/gpiopins.fth
