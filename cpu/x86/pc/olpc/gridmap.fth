
d# 24 d# 24 2value ulhc

8 constant glyph-w
8 constant glyph-h

9 constant grid-w
9 constant grid-h

d# 128 value #cols
d# 90 value #rows
: max-grid  ( -- n )  #rows #cols *  ;

\needs xy+ : xy+  ( x1 y1 x2 y2 -- x3 y3 )  rot + -rot  + swap  ;
\needs xy* : xy*  ( x y w h -- x*w y*h )  rot *  >r  * r>  ;

: do-fill  ( color x y w h -- )  " fill-rectangle" $call-screen  ;

1 value scale-factor
: scale-block#  ( eblock# -- )  scale-factor /  ;
: set-grid-scale  ( #eblocks -- )
   d# 1000 1  do     ( #eblocks )
      dup i /  max-grid <=  if   ( #eblocks )
         drop                    ( )
         i to scale-factor       ( )
         unloop exit
      then                       ( #eblocks )
   loop
   true abort" Grid map scale factor too large"
;

\ States:  0:erased  1:bad  2:waiting for write  3:written

: >loc  ( eblock# -- x y )  scale-block# #cols /mod  grid-w grid-h xy*  ulhc xy+  ;

: show-state  ( eblock# state -- )  swap >loc  glyph-w glyph-h  do-fill  ;

[ifdef] 386-assembler
code map-color  ( color24 -- color565 )
   bx pop
   bx ax mov  3 # ax shr  h#   1f # ax and            \ Blue in correct place
   bx cx mov  5 # cx shr  h#  7e0 # cx and  cx ax or  \ Green and blue in place
              8 # bx shr  h# f800 # bx and  bx ax or  \ Red, green and blue in place
   ax push   
c;
[then]
[ifdef] arm-assembler
code map-color  ( color24 -- color565 )
   mov  r0,tos,lsr #3
   and  r0,r0,#0x1f     \ Blue

   mov  r1,tos,lsr #5
   and  r1,r1,#0x7e0
   orr  r0,r0,r1        \ Green

   mov  tos,tos,lsr #8
   and  tos,tos,#0xf800
   orr  tos,tos,r0      \ Red
c;
[then]

: show-color  ( eblock# color32 -- )  map-color show-state  ;

dev screen  : erase-screen erase-screen ;  dend
