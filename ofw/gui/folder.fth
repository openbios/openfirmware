\ See license at end of file
purpose: GUI folders

headers
hex

: >list     ( node -- adr )  >private @  ;	\ folder's list
: >id#      ( node -- adr )  >list 1 na+  ;	\ folder's id#
: >#folder  ( node -- adr )  >list 2 na+  ;	\ folder's folder count
/n 3 * constant /folder-private

white      constant folder-hilight-color
light-gray constant folder-light-color
dark-gray  constant folder-dark-color

0 value folder#
0 value #folder
0 value fw
0 value fh
0 value fx
0 value fy
0 value flen
0 value flc
0 value fdc

: def-folder-wh  ( -- w h )  flen t-char-height 2*  ;
: leftmost-folder?  ( -- leftmost? )  folder# 1+ #folder =  ;
: draw-folder-box  ( x y w h max cur lc dc -- )
   to fdc to flc to folder# to #folder
   to fh to fw to fy to fx
   fw #folder / to flen

   \ Erase horizontal bar at the bottom of the folder label
   background fx fy t-char-height 2* + fw bt fill-rectangle

   \ Draw the lighter edges of the folder
   flc fx flen folder# * + fy leftmost-folder?  if  fw 2 pick -  else  flen bt 2* +  then  bt fill-rectangle
   flc fx flen folder# * + fy bt t-char-height 2* fill-rectangle
   flc fx fy t-char-height 2* + flen folder# * bt fill-rectangle
   flc fx fy t-char-height 2* + bt fh t-char-height 2* - fill-rectangle

   \ Draw the darker edges of the folder
   fdc leftmost-folder?  if  fw bt -  else  fx flen folder# 1+ * +  then
   fy bt t-char-height 2* fill-rectangle
   leftmost-folder? 0=  if
      fdc fx flen folder# 1+ * bt + + fy t-char-height 2* + fw 2 pick - bt fill-rectangle
   then
   fdc fw bt - fy t-char-height 2* + bt fh t-char-height 2* - fill-rectangle
   fdc fx fh bt - fy + fw bt fill-rectangle

   \ Erase the folder content
   background fx bt + fy t-char-height 2* + bt +
   fw bt 2* - fh bt 2* - t-char-height 2* - 
   fill-rectangle
;

: display-folder-label  ( title$ -- )
   flen t-char-width / 2- min
   flc background
   fx flen folder# * + t-char-width +  fy t-char-height 2/ +
   text-at-xy
;
: draw-lo-folder-box  ( x y w h max cur title$ -- )
   2>r folder-light-color folder-dark-color draw-folder-box
   2r> display-folder-label
;
: draw-hi-folder-box  ( x y w h max cur title$ -- )
   2>r folder-hilight-color folder-light-color draw-folder-box
   2r> display-folder-label
;

: def-folder-xywh  ( -- x y w h )
   def-edit-col-row alert-box-xywh
   t-char-height 3 * - 2swap
   t-char-height 3 * + 2swap
;
: (display-folder)  ( node -- )
   >r
   def-folder-xywh r@ >#folder @ r@ >id# @ r@ >label 2@
   r@ selected?  if
      draw-hi-folder-box
      r@ >list " place-items" evaluate
   else
      draw-lo-folder-box
   then
   r> drop
;

: update-interact-list  ( list -- )
   ['] selected?  find-node nip >list  to  interact-list
;

vocabulary folder-methods
also folder-methods definitions
headers
: count-folder  ( n node -- n+1 )  2dup >id# ! drop  1+  ;
: set-#folder   ( n node -- n )    2dup >#folder ! drop  ;
: lowlight   ( node -- )  (display-folder)  ;
: highlight  ( node -- )  (display-folder)  ;
: up  ( node -- )
   dup >myself @ ['] unselect-node find-node  2drop
   dup highlight-node
   >list  to  interact-list
;
: moused?  ( node -- flag )  >xy 2@ def-folder-wh in-rect?  ;
: done?    ( node -- flag )  drop false  ;
: do-key?  ( node -- flag )  drop false  ;
: release  ( node -- )
   dup >list free-buttons
   >private @ /folder-private free-mem
;
: pgup  ( list node -- )  drop dup select-previous update-interact-list  ;
: pgdn  ( list node -- )  drop dup select-next update-interact-list  ;
headerless
previous definitions

: display-lo-folder  ( node -- false )
   dup >methods @  ['] folder-methods  <>  if  drop false exit  then
   dup selected?  if  drop false exit  then
   dup (display-folder)
   fx flen folder# * + fy rot >xy 2!
   false
;
: display-hi-folder  ( node -- false )
   dup >methods @  ['] folder-methods  <>  if  drop false exit  then
   dup selected? 0=  if  drop false exit  then
   dup (display-folder)
   fx flen folder# * + fy rot >xy 2!
   false
;

: count-folder  ( n node -- n+1 false )  " count-folder" run-method  false  ;
: set-#folder  ( n node -- n false )  " set-#folder" run-method  false  ;
: find-selected-folder  ( list -- node )  ['] selected? find-node nip  ;
: get-folder-list  ( list -- folder )  ['] selected? find-node nip >my-parent @  ;

warning @ warning off
: pgup  ( list -- )
   get-folder-list ?dup  if
      dup find-selected-folder
      " pgup" run-method
   then
;
: pgdn  ( list -- )
   get-folder-list ?dup  if
      dup find-selected-folder
      " pgdn" run-method
   then
;

: place-items  ( list -- )
   dup place-items     ( list )
   0 over ['] count-folder find-node 2drop
   over ['] set-#folder find-node 3drop
   dup ['] display-lo-folder find-node 2drop
   ['] display-hi-folder find-node 2drop
;
warning !

: add-folder  ( parent list xt label$ hook ... -- parent list )
   control-node allocate-node >r              ( parent list xt label$ hook )
   r@ >hook !  r@ >label 2!		      ( parent list xt )
   0 r@ >char c!			      ( parent list xt )
   ['] folder-methods r@ >methods !	      ( parent list xt )

   /folder-private alloc-mem r@ >private !    ( parent list xt )
   0 r@ >list ! r@ >list swap execute drop    ( parent list )

   2dup r@ >myself !  r@ >my-parent !	      ( parent list )
   dup >next-node 0=  r@ >sel? c!	\ Select the first node
   r>  over last-node  insert-after	      ( parent list )
;

: )folder-controls  ( parent list -- ??? )
   >r drop
   r@ " place-items" evaluate
   draw-mouse-cursor
   r@ find-selected-folder >list  interact-with-buttons
   remove-mouse-cursor
   r> free-buttons
;

: dialog-folder  ( xt adr len -- ok? )
   asterisks /asterisks ascii * fill
   blanks /blanks blank
   dialog-edit? on
   ['] skey behavior to save-skey
   ['] edit-skey to skey
   def-edit-col-row alert-text-box display-edit-title
   >r controls(
      r> execute
   )folder-controls
   save-skey to skey
   dialog-edit? off
   set-description-region
;

\ LICENSE_BEGIN
\ Copyright (c) 2006 FirmWorks
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
