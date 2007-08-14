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

: gshow-erasing ( #eblocks -- )
   cursor-off  " erase-screen" $call-screen  0 status-line at-xy
   ." Erasing  "

   " bbt0" $call-nand nand-pages/block /  bbt-color show-state
   " bbt1" $call-nand nand-pages/block /  bbt-color show-state

   h# ff h# ff h# ff rgb>565   ( #eblocks color )
   swap 0  ?do  i over show-state  loop
   drop
;

: gshow-erased  ( eblock# -- )  0 0 0 rgb>565  show-state  ;

: gshow-bad  ( eblock# -- )  h# ff 0 0 rgb>565  show-state  ;

: gshow-cleaning ( -- )  ." Cleanmarkers"  cr  cursor-on  ;
: gshow-clean  ( eblock# -- )  h# 0 0 ff rgb>565  show-state  ;

: gshow-writing  ( #eblocks -- )
   ." Writing  "
   h# ff h# ff 0 rgb>565   ( #eblocks color )
   0  rot 0  ?do           ( color eblock# )
      dup nand-pages/block * " block-bad?" $call-nand  0=  if  ( color eblock# )
         2dup swap show-state
         1
      else
         0
      then
      swap 1+ swap
   +loop
   drop
;

: gshow-written  ( eblock# -- )  0 h# ff 0 rgb>565  show-state  ;

: gshow
   ['] gshow-erasing to show-erasing
   ['] gshow-erased to show-erased
   ['] gshow-bad to show-bad
   ['] gshow-clean to show-clean
   ['] gshow-cleaning to show-cleaning
   ['] gshow-writing to show-writing
   ['] gshow-written to show-written
;

gshow
