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

: show-key  ( mask x y -- )
   at-xy game-key-mask and if  ." *" else  ." ."  then
;
: update-game-keys  ( mask -- )
   dup game-key-mask or  to game-key-mask
   rocker-up      2 2 show-key
   rocker-left    0 3 show-key
   rocker-right   4 3 show-key
   rocker-down    2 4 show-key
   button-rotate  2 6 show-key

   button-o       9 2 show-key
   button-square  7 3 show-key
   button-check   d# 11 3 show-key
   button-x       9 4 show-key
;

: read-game-keys  ( -- )
[ifdef] lx-devel  false exit  [then]
   board-revision h# b18 <  if
      button-x to game-key-mask  \ Force slow boot
      exit
   then

   game-key@  dup to game-key-mask  if
      ." Release the game keys to continue" cr
      begin  d# 100 ms  game-key@ dup update-game-keys 0=  until
      0 7 at-xy
   then
;
: game-key?  ( mask -- flag )  game-key-mask and 0<>  ;
