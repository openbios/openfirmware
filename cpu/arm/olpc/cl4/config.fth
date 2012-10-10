create debug-startup
create olpc
create olpc-cl4
create trust-ec-keyboard
create use-null-nvram
create use-elf
create has-sp-kbd
create has-dcon

fload ${BP}/cpu/arm/mmp3/soc-config.fth
fload ${BP}/cpu/arm/mmp2/hwaddrs.fth
fload ${BP}/cpu/arm/olpc/addrs.fth

h# 10.0000 constant /rom           \ Total size of SPI FLASH

: mfg-data-offset  /rom h# 1.0000 - ;      \ Offset to start of manufacturing data area in SPI FLASH
: mfg-data-end-offset  /rom  ;             \ Offset to end of manufacturing data area in SPI FLASH
: crc-offset  mfg-data-offset h# 30 - ;    \ e.g. 1e.ffd0
: signature-offset  crc-offset  h# 10 - ;  \ e.g. 1e.ffc0

: signature$   " CL4"  ;
: model$       " olpc,XO-CL4"  ;
: compatible$  " olpc,xo-cl4"  ;
: ec-platform$  ( -- adr len )  " 7"  ;
: bundle-suffix$  ( -- adr len )  " 4"  ;

d# 10001 constant machine-type  \ Backwards compatibility with non-device-tree kernel

char 7 constant expected-ec-version
h# ec00 constant /ec-flash
d#    1 constant ec-scale
h# eb80 constant ec-flags-offset   \ don't program or verify this page

fload ${BP}/cpu/arm/olpc/cl4/gpiopins.fth
