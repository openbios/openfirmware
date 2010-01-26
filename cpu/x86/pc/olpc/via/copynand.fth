\ See license at end of file
purpose: Copy a file onto the NAND FLASH

0 value filefd
0 value nandih

h# 20000 value /nand-block
h#   200 value /nand-page
/nand-block /nand-page / value nand-pages/block
0 value #nand-pages

0 value #image-eblocks

: $call-nand  ( ?? method$ -- ?? )  nandih $call-method  ;

: close-image-file  ( -- )
   filefd  ?dup  if  0 to filefd  close-file drop  then
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

defer show-init  ( #eblocks -- )
' drop to show-init

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

h# ff     0 h# ff  rgb>565 constant partial-color  \ magenta
h# ff h# ff     0  rgb>565 constant pending-color  \ yellow
    0 h# ff     0  rgb>565 constant written-color  \ green
    0 h# ff h# ff  rgb>565 constant strange-color  \ cyan
h# e8 h# e8 h# e8  rgb>565 constant starting-color \ very light gray

d# 26 constant status-line

: gshow-init  ( #eblocks -- )
   suspend-logging
   dup set-grid-scale
   cursor-off  " erase-screen" $call-screen

   starting-color   ( #eblocks color )
   over 0  ?do  i over show-state  scale-factor +loop  ( #eblocks color )
   drop                                  ( #eblocks )
   1 status-line at-xy  
   ." Blocks/square: " scale-factor .d  ." Total blocks: " .d
;

: gshow-strange   ( eblock# -- )  strange-color show-state  ;

: gshow-done  ( -- )  cursor-on  resume-logging  ;

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

: show-eblock#  ( eblock# -- )  d# 40 status-line at-xy .d  ;
: gshow-written  ( eblock# -- )
   dup  written-color  show-state
   show-eblock#
;

: gshow
   ['] gshow-init      to show-init
   ['] gshow-pending   to show-pending
   ['] gshow-writing   to show-writing
   ['] gshow-written   to show-written
   ['] gshow-strange   to show-strange
   ['] gshow-done      to show-done
;

gshow

0 value current-block

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
