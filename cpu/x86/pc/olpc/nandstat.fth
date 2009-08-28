purpose: Graphical status display of NAND FLASH updates
\ See license at end of file

d# 24 d# 24 2value ulhc

8 constant glyph-w
8 constant glyph-h

9 constant grid-w
9 constant grid-h

d# 128 value #cols
: xy+  ( x1 y1 x2 y2 -- x3 y3 )  rot + -rot  + swap  ;
: xy*  ( x y w h -- x*w y*h )  rot *  >r  * r>  ;

: do-fill  ( color x y w h -- )  " fill-rectangle" $call-screen  ;

\ States:  0:erased  1:bad  2:waiting for write  3:written

: >loc  ( eblock# -- x y )  #cols /mod  grid-w grid-h xy*  ulhc xy+  ;

: show-state  ( eblock# state -- )  swap >loc  glyph-w glyph-h  do-fill  ;

dev screen  : erase-screen erase-screen ;  dend

h# 80 h# 80 h# 80  rgb>565 constant bbt-color      \ gray
    0     0     0  rgb>565 constant erased-color   \ black
h# ff     0     0  rgb>565 constant bad-color      \ red
    0     0 h# ff  rgb>565 constant clean-color    \ blue
h# ff h# ff     0  rgb>565 constant pending-color  \ yellow
    0 h# ff     0  rgb>565 constant written-color  \ green
    0 h# ff h# ff  rgb>565 constant strange-color  \ cyan
h# ff h# ff h# ff  rgb>565 constant starting-color \ white

0 value nand-block-limit
d# 22 constant status-line

: gshow-init  ( #eblocks -- )
   #nand-pages nand-pages/block /  to nand-block-limit

   cursor-off  " erase-screen" $call-screen

   " bbt0" $call-nand nand-pages/block /  bbt-color show-state
   " bbt1" $call-nand nand-pages/block /  bbt-color show-state

   starting-color   ( #eblocks color )
   swap 0  ?do  i over show-state  loop
   drop
   0 status-line at-xy  
;

: gshow-erasing ( #eblocks -- )   drop  ." Erasing  "  ;

: gshow-erased    ( eblock# -- )  erased-color  show-state  ;
: gshow-bad       ( eblock# -- )  bad-color     show-state  ;
: gshow-bbt-block ( eblock# -- )  bbt-color     show-state  ;
: gshow-clean     ( eblock# -- )  clean-color   show-state  ;
: gshow-strange   ( eblock# -- )  strange-color show-state  ;

: gshow-cleaning ( -- )  d# 26 status-line at-xy  ." Cleanmarkers"  cr  ;
: gshow-done  ( -- )  cursor-on  ;

: gshow-pending  ( eblock# -- )  pending-color  show-state  ;

: gshow-writing  ( #eblocks -- )
   ." Writing  "
   0  swap 0  ?do              ( eblock# )
      dup nand-pages/block * " block-bad?" $call-nand  0=  if  ( eblock# )
         dup show-pending      ( eblock# )
         1                     ( eblock# increment )
      else                     ( eblock# )
         0                     ( eblock# increment )
      then                     ( eblock# increment )
      swap 1+ swap             ( eblock#' increment )
   +loop                       ( eblock#' )
   drop
;

: gshow-written  ( eblock# -- )
   dup  written-color  show-state
   d# 20 status-line at-xy   .x
;

: gshow
   ['] gshow-init      to show-init
   ['] gshow-erasing   to show-erasing
   ['] gshow-erased    to show-erased
   ['] gshow-bad       to show-bad
   ['] gshow-bbt-block to show-bbt-block
   ['] gshow-clean     to show-clean
   ['] gshow-cleaning  to show-cleaning
   ['] gshow-pending   to show-pending
   ['] gshow-writing   to show-writing
   ['] gshow-written   to show-written
   ['] gshow-strange   to show-strange
   ['] gshow-done      to show-done
;

gshow

\ 0 - marked bad block : show-bad
\ 1 - unreadable block : show-bad
\ 2 - jffs2 w/  summary: show-written
\ 3 - jffs2 w/o summary: show-pending
\ 4 - clean            : show-clean
\ 5 - non-jffs2 data   : show-strange
\ 6 - erased           : show-erased
\ 7 - primary   bad-block-table  : show-bbt-block
\ 8 - secondary bad-block-table  : show-bbt-block
: show-block-status  ( status eblock# -- )
   swap case
      0  of  show-bad        endof
      1  of  show-bad        endof
      2  of  show-written    endof
      3  of  show-pending    endof
      4  of  show-clean      endof
      5  of  show-strange    endof
      6  of  show-erased     endof
      7  of  show-bbt-block  endof
      8  of  show-bbt-block  endof
   endcase
;

0 value nand-map
0 value working-page
: classify-block  ( page# -- status )
   to working-page

   \ Check for block marked bad in bad-block table
   working-page  " block-bad?" $call-nand  if  0 exit  then

   \ Try to read the first few bytes
   load-base 4  working-page  0  " pio-read" $call-nand

   \ Check for a JFFS2 node at the beginning
   load-base w@ h# 1985 =  if
      \ Look for a summary node
      load-base 4  working-page h# 3f +  h# 7fc  " pio-read" $call-nand
      load-base " "(85 18 85 02)" comp  if  3  else  2  then
      exit
   then

   \ Check for non-erased, non-JFFS2 data
   load-base l@ h# ffff.ffff <>  if  5 exit  then

   \ Check for various signatures in the OOB area
   working-page " read-oob" $call-nand  d# 14 +  ( adr )

   \ .. Cleanmarker
   dup  " "(85 19 03 20 08 00 00 00)" comp  0=  if  drop 4 exit  then

   \ .. Bad block tables
\ These can't happen because the BBT table blocks are marked "bad"
\ so they get filtered out at the top of this routine.
\   dup  " Bbt0" comp  0=  if  drop 7 exit  then
\   dup  " 1tbB" comp  0=  if  drop 8 exit  then
   drop

   \ See if the whole thing is really completely erased
   load-base  working-page  nand-pages/block  ( adr block# #blocks )
   " read-pages" $call-nand  nand-pages/block  <>  if  1 exit  then

   \ Not completely erased
   load-base  load-base h# 100000 +  /nand-block  comp  if  5 exit  then

   \ Erased
   6
;

0 value current-block
0 value examine-done?

string-array status-descriptions
   ," Marked bad in Bad Block Table"  \ 0
   ," Read error"                     \ 1
   ," JFFS2 data with summary"        \ 2
   ," JFFS2 data, no summary"         \ 3
   ," Clean (erased with JFFS2 cleanmarker)"  \ 4
   ," Dirty, with non-JFFS2 data"     \ 5 
   ," Erased, no cleanmarker"         \ 6
   ," Primary Bad Block Table"        \ 7
   ," Secondary Bad Block Table"      \ 8
end-string-array

: show-block-status  ( block# -- )
   d# 20 status-line at-xy   
   dup .x
   nand-map + c@  status-descriptions count type  kill-line
;

: cell-border  ( block# color -- )
   swap >loc      ( color x y )
   -1 -1 xy+
   3dup  grid-w 1   do-fill                    ( color x y )
   3dup  grid-w 0 xy+  1 grid-h  do-fill  ( color x y )
   3dup  0 1 xy+  1 grid-h do-fill            ( color x y )
   1 grid-h xy+  grid-w 1  do-fill
;
: lowlight-block  ( block# -- )  background-rgb rgb>565 cell-border  ;
: highlight-block  ( block# -- )  0 cell-border  ;
: point-block  ( block# -- )
   current-block lowlight-block
   to current-block
   current-block highlight-block
;
: +block  ( offset -- )
   current-block +  nand-block-limit mod  ( new-block )
   point-block
   current-block  show-block-status
;

: process-key  ( char -- )
   case
      h# 9b     of  endof
      [char] A  of  #cols negate +block  endof  \ up
      [char] B  of  #cols        +block  endof  \ down
      [char] C  of  1            +block  endof  \ right
      [char] D  of  -1           +block  endof  \ left
      [char] ?  of  #cols 8 * negate +block  endof  \ page up
      [char] /  of  #cols 8 *        +block  endof  \ page down
      [char] K  of  8                +block  endof  \ page right
      [char] H  of  -8               +block  endof  \ page left
      h# 1b     of  d# 20 ms key?  0=  if  true to examine-done?  then  endof
   endcase
;

: examine-nand  ( -- )
   0 status-line 1- at-xy  red-letters ." Arrows, fn Arrows to move, Esc to exit" black-letters cr
   0 to current-block
   current-block highlight-block
   false to examine-done?
   begin key  process-key  examine-done? until
   current-block lowlight-block
;

: (scan-nand)  ( -- )
   open-nand
   nand-map 0=  if
      #nand-pages nand-pages/block /  alloc-mem  to nand-map
   then

   \ Something to compare against
   load-base h# 100000 +  /nand-block  h# ff  fill

   " usable-page-limit" $call-nand   
   dup  nand-pages/block /  show-init  ( page-limit )

   7 " bbt0" $call-nand  nand-pages/block /  nand-map + c!
   8 " bbt1" $call-nand  nand-pages/block /  nand-map + c!

   0  ?do
      i classify-block       ( status )
      i nand-pages/block /   ( status eblock# )
      2dup nand-map + c!     ( status eblock# )
      show-block-status
   nand-pages/block +loop  ( )

   show-done
   close-nand-ihs
;
: scan-nand  ( -- )  (scan-nand) examine-nand  ;

\ LICENSE_BEGIN
\ Copyright (c) 2007 FirmWorks
\ 
\ Permission is hereby granted, free of charge, to any person obtaining
\ a copy of this software and associated documentation files (the
\ "Software"), to deal in the Software without restriction, including
\ without limitation the rights to use, copy, modify, merge, publish,
\ distribute, sublicense, and/or sell copies of the Software, and to
\ permit persons to whom the Software is furnished to do so, subject to
\ the following conditions:
\ 
\ The above copyright notice and this permission notice shall be
\ included in all copies or substantial portions of the Software.
\ 
\ THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
\ EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
\ MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
\ NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
\ LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
\ OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
\ WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
\
\ LICENSE_END
