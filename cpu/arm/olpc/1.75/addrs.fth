\ Platform design choices
h# 2000.0000 constant total-ram-size

h# 1fc0.0000 constant fb-pa
h#   40.0000 constant fb-size  \ The screen use a little more than 3 MiB at 1200x900x24

fb-pa constant available-ram-size


: (memory?)  ( phys -- flag )  total-ram-size u<  ;
' (memory?) to memory?

\ OFW implementation choices
\ h# 1fe0.0000 constant fw-pa
0 constant fw-pa

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

\ Defined by CPU core
h# 1000 to pagesize
d# 12   to pageshift
h# 10.0000 constant /section
h# 4000 constant /page-table
