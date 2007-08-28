purpose: Graphical status display of NAND FLASH updates
\ See license at end of file

d# 24 d# 24 2value ulhc

d# 22 constant status-line

8 constant glyph-w
8 constant glyph-h

9 constant grid-w
9 constant grid-h

d# 128 value #cols
: xy*  ( x y w h -- x*w y*h )  rot *  >r  * r>  ;

\ States:  0:erased  1:bad  2:waiting for write  3:written

: >loc  ( eblock# -- )  #cols /mod  grid-w grid-h xy*  ulhc d+  ;

: show-state  ( eblock# state -- )
   swap >loc  glyph-w glyph-h  " fill-rectangle" $call-screen
;

dev screen  : erase-screen erase-screen ;  dend

h# 80 h# 80 h# 80  rgb>565 constant bbt-color
    0     0     0  rgb>565 constant erased-color
h# ff     0     0  rgb>565 constant bad-color
    0     0 h# ff  rgb>565 constant clean-color
h# ff h# ff     0  rgb>565 constant writing-color
    0 h# ff     0  rgb>565 constant written-color
h# ff h# ff h# ff  rgb>565 constant starting-color

: gshow-erasing ( #eblocks -- )
   cursor-off  " erase-screen" $call-screen  0 status-line at-xy
   ." Erasing  "

   " bbt0" $call-nand nand-pages/block /  bbt-color show-state
   " bbt1" $call-nand nand-pages/block /  bbt-color show-state

   starting-color   ( #eblocks color )
   swap 0  ?do  i over show-state  loop
   drop
;

: gshow-erased    ( eblock# -- )  erased-color  show-state  ;
: gshow-bad       ( eblock# -- )  bad-color     show-state  ;
: gshow-bbt-block ( eblock# -- )  bbt-color     show-state  ;
: gshow-clean     ( eblock# -- )  clean-color   show-state  ;

: gshow-cleaning ( -- )  ." Cleanmarkers"  cr  cursor-on  ;

: gshow-writing  ( #eblocks -- )
   ." Writing  "
   writing-color   ( #eblocks color )
   0  rot 0  ?do           ( color eblock# )
      dup nand-pages/block * " block-bad?" $call-nand  0=  if  ( color eblock# )
         2dup swap show-state  ( color eblock# )
         1                     ( color eblock# increment )
      else                     ( color eblock# )
         0                     ( color eblock# increment )
      then                     ( color eblock# increment )
      swap 1+ swap             ( color eblock#' increment )
   +loop                       ( color eblock#' )
   2drop
;

: gshow-written  ( eblock# -- )  written-color  show-state  ;

: gshow
   ['] gshow-erasing   to show-erasing
   ['] gshow-erased    to show-erased
   ['] gshow-bad       to show-bad
   ['] gshow-bbt-block to show-bbt-block
   ['] gshow-clean     to show-clean
   ['] gshow-cleaning  to show-cleaning
   ['] gshow-writing   to show-writing
   ['] gshow-written   to show-written
;

gshow
