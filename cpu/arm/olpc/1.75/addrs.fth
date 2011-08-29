\ Platform design choices

fload ${BP}/cpu/arm/mmuparams.fth

h# 2000.0000 constant /ram-total  \ Total size of memory

h# 0040.0000 constant /fb-mem  \ The screen uses a little more than 3 MiB at 1200x900x24
/ram-total /fb-mem - constant fb-mem-pa  \ e.g. h# 1fc0.0000

fb-mem-pa constant /available-mem

: (memory?)  ( phys -- flag )  /ram-total u<  ;

\ OFW implementation choices
h# 0020.0000            constant /fw-mem
fb-mem-pa /fw-mem -     constant fw-mem-pa     \ e.g. h# 1fa0.0000

h# 0020.0000            constant /extra-mem
fw-mem-pa /extra-mem -  constant extra-mem-pa  \ e.g. h# 1f80.0000 

h# 0080.0000            constant /dma-mem
extra-mem-pa /dma-mem - constant dma-mem-pa      \ e.g. h# 1f00.0000

h# fd00.0000 constant dma-mem-va
h# fd80.0000 constant extra-mem-va
h# fda0.0000 constant fw-mem-va
h# fdc0.0000 constant fb-mem-va

h# fe00.0000 constant io-va  \ We map IO (APB + AXI) space at this virtual address

[ifdef] virtual-mode
h# f700.0000 constant fw-virt-base
h# 0100.0000 constant fw-virt-size  \ 16 megs of mapping space
[else]
fw-mem-va value fw-virt-base
/fw-mem   value fw-virt-size
[then]

/fw-mem /page-table -  constant page-table-offset
page-table-offset      constant stack-offset  \ Stack is below this

fw-mem-pa page-table-offset + constant page-table-pa

\ h# 0110.0000 constant def-load-base
h# 0800.0000 constant def-load-base

\ The heap starts at RAMtop, which on this system is "fw-mem-pa /fw-mem +"

h#  10.0000 constant heap-size
heap-size constant initial-heap-size

\ RAM address where the Security Processor code places the subset of the dropin module
\ image that it copies out of SPI FLASH.
h#  900.0000 constant 'dropins  \ Must agree with 'compressed in cforth/src/app/arm-xo-1.75/

h#  20000 constant dropin-offset   \ Offset to dropin driver area in SPI FLASH

[ifdef] use-flash-nvram
h# d.0000 constant nvram-offset
[then]

h#  e.0000 constant mfg-data-offset     \ Offset to manufacturing data area in SPI FLASH
h#  f.0000 constant mfg-data-end-offset \ Offset to end of manufacturing data area in SPI FLASH
h#  f.ffd8 constant crc-offset

h# 10.0000 constant /rom           \ Total size of SPI FLASH

\ SRAM usage

sram-pa  constant sram-va

sram-va h# 2.0000 + constant 'ddr-recal
sram-va h# 2.0100 + constant 'ddr-self-refresh

sram-pa h# 2.4000 + constant diagfb-pa           \ Low-resolution frame buffer for startup numbers
