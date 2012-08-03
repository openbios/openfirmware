\ Platform design choices

fload ${BP}/cpu/arm/mmuparams.fth

h# 0040.0000 constant /fb-mem  \ The screen uses a little more than 3 MiB at 1200x900x24

\ OFW implementation choices
h# 0020.0000 constant /fw-mem
h# 0020.0000 constant /extra-mem
h# 0080.0000 constant /dma-mem

h# fd00.0000 constant dma-mem-va
h# fd80.0000 constant extra-mem-va
h# fda0.0000 constant fw-mem-va
h# fdc0.0000 constant fb-mem-va

h# fe00.0000 constant io-va  \ We map IO (APB + AXI) space at this virtual address
h# fe30.0000 constant io2-va \ Mapping area for AXI2 space

h# fe40.0000 constant mmp3-audio-va \ Used only if mmp3-audio-pa is defined
: audio-sram-va  ( -- )  audio-sram-pa  ;

[ifdef] virtual-mode
h# f700.0000 constant fw-virt-base
h# 0100.0000 constant fw-virt-size  \ 16 megs of mapping space
[else]
fw-mem-va value fw-virt-base
/fw-mem   value fw-virt-size
[then]

/fw-mem /page-table -  constant page-table-offset
page-table-offset      constant stack-offset  \ Stack is below this

\ fw-mem-pa page-table-offset + constant page-table-pa

\ h# 0110.0000 constant def-load-base
h# 0c00.0000 constant def-load-base

\ The heap starts at RAMtop, which on this system is "fw-mem-pa /fw-mem +"

h#  10.0000 constant heap-size
heap-size constant initial-heap-size

\ RAM address where the Security Processor code places the subset of the dropin module
\ image that it copies out of SPI FLASH.
h#  900.0000 constant 'dropins  \ Must agree with 'compressed in cforth/src/app/arm-xo-1.75/

h#  20000 constant dropin-offset   \ Offset to dropin driver area in SPI FLASH

\ SRAM usage

sram-pa  constant sram-va

sram-va h# 2.0000 + constant 'ddr-recal
sram-va h# 2.0100 + constant 'ddr-self-refresh
sram-va h# 2.0400 + constant 'ddr-self-refresh-sp

sram-pa h# 2.4000 + constant diagfb-pa           \ Low-resolution frame buffer for startup numbers
