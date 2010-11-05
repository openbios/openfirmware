\ Platform design choices
h# 2000.0000 constant total-ram-size

h# 1fc0.0000 constant fb-pa
h#   40.0000 constant fb-size  \ The screen use a little more than 3 MiB at 1200x900x24

fb-pa constant available-ram-size

h#  20000 constant dropin-offset   \ Offset to dropin driver area in SPI FLASH
[ifdef] use-flash-nvram
h# d.0000 constant nvram-offset
[then]

h#  e.0000 constant mfg-data-offset     \ Offset to manufacturing data area in SPI FLASH
h#  f.0000 constant mfg-data-end-offset \ Offset to end of manufacturing data area in SPI FLASH
h#  f.ffd8 constant crc-offset

h# 10.0000 constant /rom           \ Total size of SPI FLASH

: (memory?)  ( phys -- flag )  total-ram-size u<  ;

\ OFW implementation choices
\ h# 1fe0.0000 constant fw-pa
h# 1fa0.0000 constant fw-pa

[ifdef] virtual-mode
h# f700.0000 constant fw-virt-base
h# 0100.0000 constant fw-virt-size  \ 16 megs of mapping space
[else]
fw-pa value fw-virt-base
0 value fw-virt-size
[then]

h# 0020.0000 constant /fw-ram

h# 0110.0000 constant def-load-base

\ The heap starts at RAMtop, which on this system is "fw-pa /fw-ram +"

h#  10.0000 constant heap-size
heap-size constant initial-heap-size

h# 40.0000 constant page-table-pa
