\ See license at end of file
purpose: Copy a file onto the NAND FLASH

0 value fileih
0 value nandih

h# 20000 value /nand-block
h#   200 value /nand-page
/nand-block /nand-page / value nand-pages/block
0 value #nand-pages

0 value #image-eblocks

: $call-nand  ( ?? method$ -- ?? )  nandih $call-method  ;

: close-image-file  ( -- )
   fileih  ?dup  if  0 to fileih  close-dev  then
;
: close-nand  ( -- )
   nandih  ?dup  if  0 to nandih  close-dev  then
;
: close-nand-ihs  ( -- )
   close-image-file
   close-nand
;

: ?nand-abort  ( flag msg$ -- )
   rot  if
      close-nand-ihs  $abort
   else
      2drop
   then
;

: ?key-stop  ( -- )
    key?  dup  if  key drop  then           ( stop? )
    " Stopped by keystroke"   ?nand-abort
;

: set-nand-vars  ( -- )
   " size" $call-nand  /nand-page  um/mod nip to #nand-pages
;
: open-nand  ( -- )
   " fsdisk" open-dev to nandih
   nandih 0=  " Can't open disk device"  ?nand-abort
   set-nand-vars
;

h# 100 buffer: image-name-buf
: image-name$  ( -- adr len )  image-name-buf count  ;

: get-img-filename  ( -- )  safe-parse-word  image-name-buf place  ;

: open-img  ( "devspec" -- )
   image-name$  open-dev  to fileih
   fileih 0= " Can't open NAND image file"  ?nand-abort
   " size" fileih $call-method               ( d.size )

   2dup  h# 20000 um/mod  swap  if  1+  then   ( d.size #eblocks )
   nip nip                                     ( #eblocks )

   to #image-eblocks

   #image-eblocks 0= " Image file is empty" ?nand-abort
;

: read-image-block  ( -- )
   load-base /nand-block " read" fileih $call-method   ( len )
   dup /nand-block <>  if                               ( len )
      load-base over +   /nand-page rot -  h# ff fill
   else
      drop
   then
;

: check-mem-hash  ( record# -- )
   drop  \ XXX
;


defer show-init  ( #eblocks -- )
' drop to show-init

defer show-erasing  ( #blocks -- )
: (show-erasing)  ( #blocks -- )  ." Erasing " . ." blocks" cr  ;
' (show-erasing) to show-erasing

defer show-erased  ( block# -- )
: (show-erased)  ( block# -- )  (cr .  ;
' (show-erased) to show-erased

defer show-bad  ( block# -- )
' drop to show-bad

defer show-bbt-block  ( block# -- )
' drop to show-bbt-block

defer show-clean  ( block# -- )
' drop to show-clean

defer show-cleaning  ( -- )
: (show-cleaning)  ( -- )  cr ." Cleanmarkers"  ;
' (show-cleaning) to show-cleaning

defer show-writing  ( #blocks -- )
: (show-writing)  ." Writing " . ." blocks" cr  ;
' (show-writing) to show-writing

defer show-pending  ( block# -- )
' drop to show-pending

defer show-written
: (show-written)  ( block# -- )  (cr .  ;
' (show-written) to show-written

defer show-strange
' drop to show-strange

defer show-done
' cr to show-done

: written?  ( adr len -- flag )  h# ffffffff lskip 0<>  ;

h# 80 h# 80 h# 80  rgb>565 constant bbt-color      \ gray
    0     0     0  rgb>565 constant erased-color   \ black
h# ff     0     0  rgb>565 constant bad-color      \ red
    0     0 h# ff  rgb>565 constant clean-color    \ blue
h# ff     0 h# ff  rgb>565 constant partial-color  \ magenta
h# ff h# ff     0  rgb>565 constant pending-color  \ yellow
    0 h# ff     0  rgb>565 constant written-color  \ green
    0 h# ff h# ff  rgb>565 constant strange-color  \ cyan
h# ff h# ff h# ff  rgb>565 constant starting-color \ white

d# 22 constant status-line

: gshow-init  ( #eblocks -- )
   cursor-off  " erase-screen" $call-screen

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
      dup show-pending         ( eblock# )
      1                        ( eblock# increment )
      swap 1+ swap             ( eblock#' increment )
   +loop                       ( eblock#' )
   drop
;

: show-eblock#  ( eblock# -- )  d# 20 status-line at-xy .x  ;
: gshow-written  ( eblock# -- )
   dup  written-color  show-state
   show-eblock#
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
: show-block-type  ( status eblock# -- )
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

   working-page /nand-page um*  " seek" $call-nand drop

   \ Try to read the first few bytes
   load-base /l  " read" $call-nand

   \ Check for non-erased, non-JFFS2 data
   load-base l@ h# ffff.ffff <>  if  5 exit  then

   \ See if the whole thing is really completely erased
   load-base /l +  /nand-block /l -  " read" $call-nand  /nand-block /l - <>  if  1 exit  then

   \ Not completely erased
   load-base  /nand-block  written?  if  5 exit  then

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

0 value nand-block-limit
: +block  ( offset -- )
   current-block +   nand-block-limit mod  ( new-block# )
   dup point-block                         ( new-block# )
   dup show-eblock#                        ( new-block# )
   nand-map + c@  status-descriptions count type  kill-line
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
   #nand-pages nand-pages/block /  to nand-block-limit
   0 to current-block
   current-block highlight-block
   false to examine-done?
   begin key  process-key  examine-done? until
   current-block lowlight-block
;

: (scan-nand)  ( -- )
   nand-map 0=  if
      #nand-pages nand-pages/block /  alloc-mem  to nand-map
   then

   " usable-page-limit" $call-nand   
   dup  nand-pages/block /  show-init  ( page-limit )

   0  ?do
      i classify-block       ( status )
      i nand-pages/block /   ( status eblock# )
      2dup nand-map + c!     ( status eblock# )
      show-block-type        ( )
   nand-pages/block +loop  ( )

   show-done
;

: scan-nand  ( -- )
   open-nand (scan-nand) close-nand-ihs
   examine-nand
;

\ LICENSE_BEGIN
\ Copyright (c) 2009 FirmWorks
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
