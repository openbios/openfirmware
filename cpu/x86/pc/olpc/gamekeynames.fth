purpose: Symbolic names for game key bitmasks

\ These bitmasks directly match the values returned by the EC
\ "game-key@" command on XO-1 and XO-1.5 hardware.  For later
\ hardware with different game key access methods, the hardware
\ bit masks are translated into these values.

h#   1 constant button-square
h#   2 constant button-check
h#   4 constant rocker-up
h#   8 constant rocker-down
h#  10 constant rocker-left
h#  20 constant rocker-right
h#  40 constant button-rotate
h#  80 constant button-o
h# 100 constant button-x
