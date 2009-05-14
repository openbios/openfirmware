d#   5.00 value Tck
\ Compute ceil(ns/tck)
: ns>tck  ( ns -- tck )  Tck + 1-  Tck /  ;


[ifdef] xo-board
\ DDR-400 timings for HY5PS1G4831C
d#   5.00 to Tck

d# 127.50 constant Trfc
d#   7.50 constant Trrd
d#      3 constant TCL
d#  40.00 constant Tras
d#  15.00 constant Twr
d#   7.50 constant Trtp
d#  10.00 constant Twtr
d#  15.00 constant Trp
d#  15.00 constant Trcd

1 constant #ranks
8 constant #banks
[then]

[ifdef] demo-board
\ DDR-533 timings for Micron MT8HTF6464HDY DIMM
d#   3.75 to Tck

d# 105.00 constant Trfc
d#  10.00 constant Trrd
d#      4 constant TCL
d#  45.00 constant Tras
d#  15.00 constant Twr
d#   7.50 constant Trtp
d#   7.00 constant Twtr
d#  15.00 constant Trp
d#  15.00 constant Trcd

2 constant #ranks
4 constant #banks
[then]
