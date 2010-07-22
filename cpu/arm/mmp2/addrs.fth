\ Platform design choices
h# 2000.0000 constant total-ram-size

h# 1fc0.0000 constant fb-pa
h#   20.0000 constant fb-size  \ The screen use a little more than 1 MiB at 800x480x24

fb-pa constant available-ram-size


: (memory?)  ( phys -- flag )  total-ram-size u<  ;
' (memory?) to memory?

\ OFW implementation choices
h# 1fe0.0000 constant fw-pa

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

h# 4000 constant page-table-pa


\ Defined by CPU core
h# 1000 to pagesize
d# 12   to pageshift
h# 10.0000 constant /section
h# 4000 constant /page-table

\ Defined by MMP2 hardware
h# d401.9000 constant gpio-base
h# d405.1024 constant acgr-pa
h# d401.5000 constant clock-unit-pa
h# d405.0000 constant main-pmu-pa
h# d428.2800 constant pmua-pa       \ Application processor PMU register base
h# d420.b800 constant dsi1-pa \ 4-lane controller
h# d420.ba00 constant dsi2-pa \ 3-lane controller
h# d420.b000 constant lcd-pa
h# d401.4000 constant timer-pa

