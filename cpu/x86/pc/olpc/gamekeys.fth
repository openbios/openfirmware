purpose: Access to game keys (buttons on front panel)

h#   1 constant button-square
h#   2 constant button-check
h#   4 constant rocker-up
h#   8 constant rocker-down
h#  10 constant rocker-left
h#  20 constant rocker-right
h#  40 constant button-rotate
h#  80 constant button-o
h# 100 constant button-x

0 value game-key-mask

: read-game-keys  ( -- )
[ifdef] lx-devel  false exit  [then]
   board-revision h# b18 <  if
      button-x to game-key-mask  \ Force slow boot
      exit
   then

   game-key@  dup to game-key-mask  if
      ." Release the game key to continue" cr
      begin  d# 100 ms  game-key@ 0=  until
   then
;
: game-key?  ( mask -- flag )  game-key-mask and 0<>  ;
