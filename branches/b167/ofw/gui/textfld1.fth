\ See license at end of file
purpose: GUI text edit fields for use within dialog boxes

\ Editing line and label are on the same line like this:
\ 	label	edit-line
\ This file requires textfld.fth to be included earlier.

headerless

ascii : constant colon
2 constant edit1-vspacing
2 constant edit1-hspacing
d# 22 constant edit1-label-#cols
d# 50 constant edit1-#cols
: def-edit1-wh  ( -- w h )  t-char-width  edit1-#cols *  t-char-height  ;
: edit1-text-xy+  ( x y -- x' y' )
   edit1-label-#cols edit1-hspacing + t-char-width * 0  xy+
;

edit1-label-#cols buffer: edit1-label-buf
: label-edit1  ( label$ x y -- )
   2swap			( x y label$ )
   dup 1+ edit1-label-#cols min edit1-label-#cols swap -
				( x y label$ x' )
   edit1-label-buf over blank	( x y label$ x' )
   edit1-label-buf + swap move  ( x y )
   colon edit1-label-buf edit1-label-#cols 1- + c!
   edit1-label-buf edit1-label-#cols 2swap
				( label$' x y )
   edit-tt-color background 2swap text-at-xy  
;
: blank-text-edit1  ( x y -- )
   blanks edit1-#cols 1- 2swap
   edit-lf-color background 2swap text-at-xy
;
: text-edit1  ( text$ x y -- )
   2dup blank-text-edit1
   2swap edit1-#cols 1- min 2swap
   edit-lf-color background 2swap text-at-xy  
;
: hitext-edit1  ( text$ x y -- )
   2dup blank-text-edit1
   2swap edit1-#cols 1- min 2swap
   edit-hf-color background 2swap text-at-xy  
;
: highlight-edit1  ( x y -- )
   -4 -4 xy+ edit-hf-color -rot  def-edit1-wh  8 8 xy+  1  box  
; 
: lowlight-edit1   ( x y -- )
   -4 -4 xy+ edit-lf-color -rot  def-edit1-wh  8 8 xy+  1  box  
;

: do-edit1-node  ( node -- )
   dup >echo? c@ to echo?
   goto-next? on  pgdn? off  pgup? off  edit-moused? off
   redraw-mouse-cursor? off
   save-text-region
   edit-hf-color edit-hb-color
   2 pick >xy 2@  edit1-text-xy+  def-edit1-wh  set-text-region
   dup >xy 2@ edit1-text-xy+ blank-text-edit1
   cursor-on

   dup >edit 2@  2 pick >edit-len @  swap

   [ also hidden ]
   ['] my-open-display  to open-display
   ['] one-line-display to close-display
   echo? 0=  if
      ['] asterisks  ['] line-start-adr   ['] wtype  (patch
   then

   1 to window-height  edit1-#cols to window-width
   edit-line
   window-x -rot

   echo? 0=  if
      ['] line-start-adr  ['] asterisks  ['] wtype  (patch
   then
   [ previous ]			( idx node len )

   2dup swap >edit-len !
   2dup swap >edit 2@ rot dup >r - swap r> + swap erase

   cursor-off
   restore-text-region

   rot >r			( node len )  ( r: idx )
   echo?  if
      over >edit 2@ drop
   else
      asterisks
   then 			( node len adr )  ( r: idx )

   r@ + swap r> -		( node adr' len' )
   rot >xy 2@  edit1-text-xy+  text-edit1

   true to echo?
;

vocabulary edit1-methods
also edit1-methods definitions
headers
: highlight  ( node -- )  >xy 2@ edit1-text-xy+ highlight-edit1  ;
: lowlight   ( node -- )  >xy 2@ edit1-text-xy+ lowlight-edit1   ;
: up         ( node -- )
   dup >myself @ ['] unselect-node find-node 2drop  highlight-node
;
: moused?    ( node -- flag )  >xy 2@ edit1-text-xy+  def-edit1-wh in-rect?  ;
: done?      ( node -- flag )  drop false  ;
: do-key?    ( node -- flag )  do-edit1-node true  ;
: release    ( node -- )   >private @ /edit-private free-mem   ;
headerless
previous definitions

: display-edit1  ( x y node -- x' y' false )
   dup >methods @  ['] edit1-methods  <>  if  drop false exit  then
   >r
   2dup r@ >xy 2!	( x y )
   0 t-char-height edit1-vspacing *  xy+  false
   r@ >label 2@  r@ >xy 2@  label-edit1
   r@ >echo? c@  if  r@ >edit 2@ drop  else  asterisks  then   
   r@ >edit-len @  r@ >xy 2@ edit1-text-xy+  text-edit1
   r@ >xy 2@  edit1-text-xy+
   r> selected?  if  highlight-edit1  else  lowlight-edit1  then
;
[ifdef] no-enum-type
warning @ warning off
: place-items  ( list -- )
   dup place-items     ( list )

   t-char-width edit1-hspacing * t-char-height edit1-vspacing 5 + *
   rot ['] display-edit1 find-node 2drop 2drop
;
warning !
[then]

: add-edit1-item  ( parent list edit$ len echo? label$ hook -- parent list )
   control-node allocate-node >r              ( parent list edit$ len echo? label$ hook )
   r@ >hook !  r@ >label 2!		      ( parent list edit$ len echo? )
   0 r@ >char c!			      ( parent list edit$ len echo? )
   ['] edit1-methods r@ >methods !	      ( parent list edit$ len echo? )

   /edit-private alloc-mem r@ >private !      ( parent list edit$ len echo? )
   r@ >echo? c! r@ >edit-len ! r@ >edit 2!    ( parent list )

   2dup r@ >myself !  r@ >my-parent !	      ( parent list )
   dup >next-node 0=  r@ >sel? c!	\ Select the first node
   r>  over last-node  insert-after	      ( parent list )
;

headers
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
