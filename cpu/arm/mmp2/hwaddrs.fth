\ Defined by MMP2 hardware
h# d000.0000 constant memctrl-pa

h# d100.0000 constant sram-pa        \ Base of SRAM
h# 0030.0000 constant /sram          \ Size of SRAM

h# d400.0000 constant apb-pa         \ Base of APB bus
h# d420.0000 constant axi-pa         \ Base of AXI bus

h# e000.0000 constant audio-sram-pa  \ Base of Audio SRAM
h# 0010.0000 constant /audio-sram    \ Size of Audio SRAM

apb-pa constant io-pa                \ We use this as the base for most IO accesses
h# 0040.0000 constant /io

\ The following are offsets from io-pa
\ AXI devices
h# 01.4000 constant timer-pa
h# 01.5000 constant clock-unit-pa
h# 01.9000 constant gpio-base
h# 05.0000 constant main-pmu-pa
h# 05.1024 constant acgr-pa

\ APB devices
h# 20.b800 constant dsi1-pa \ 4-lane controller
h# 20.ba00 constant dsi2-pa \ 3-lane controller
h# 20.b000 constant lcd-pa
h# 28.2800 constant pmua-pa       \ Application processor PMU register base

