\ See license at end of file
purpose: GUI enumerated strings for use within dialog boxes

\ Editing line and label are on the same line like this:
\ 	label	enumerated-string
\ This file requires textfld.fth and textfld1.fth to be included earlier.

headerless

: >enum-list  ( node -- adr )  >private @  ;	\ enum's list
/n  constant /enum-private

listnode
   /n 2* field >enum$
   /n    field >enum$-hook		( node -- )
   /c    field >enum$-sel?
nodetype: enum$-node

white      constant eb-hilight
dark-gray  constant eb-color
light-gray constant eb-light

0 value (hi-enum-button)
0 value (lo-enum-button)

: def-enum-button-wh  ( -- w h )
   t-char-width t-char-height 8 +
;
: /eb  ( -- size )  def-enum-button-wh *  ;
: enum$1-button-xy+  ( x y -- x' y' )
   edit1-text-xy+ -4 -4 xy+ def-edit1-wh drop 0 xy+
;

: make-enum-button  ( rim adr -- )
   /eb rot fill				\ May want to make it pretty.
;
: hi-enum-button  ( -- adr )
   (hi-enum-button)  0=  if
       /eb alloc-mem to (hi-enum-button)
       eb-hilight (hi-enum-button) make-enum-button
   then
   (hi-enum-button)
;
: lo-enum-button  ( -- adr )
   (lo-enum-button)  0=  if
       /eb alloc-mem to (lo-enum-button)
       eb-light (lo-enum-button) make-enum-button
   then
   (lo-enum-button)
;

: draw-enum-button  ( x y adr -- )
   -rot enum$1-button-xy+  def-enum-button-wh draw-rectangle
;

: enum$-selected?  ( node -- flag )  >enum$-sel? c@ 0<>  ;
: enum$-unselect-node  ( node -- flag )
   dup enum$-selected?  if   ( node )
      false swap >enum$-sel? c!
      true
   else
      drop false
   then
;
: find-selected-enum$  ( node -- enum-list-node )
   ['] enum$-selected?  find-node  nip
;
: enum$-select-next  ( enum-list -- )
   dup ['] enum$-unselect-node find-node  nip  ( this|0 )
   ?dup  if                                ( this )
      \ If we're at the end of the list, wrap around to the beginning
      dup >next-node  if  nip  else  drop  then
   then                                    ( predecessor )
   >next-node
   true swap >enum$-sel? c!
;
: enum$-select-prev  ( enum-list -- )
   dup ['] enum$-unselect-node find-node  ( list prev this|0 )
   if                                     ( list prev )
      \ If we're at the beginning of the list, go to the end
      2dup  =  if  drop last-node  else  nip  then   ( new-node )
   else  \ No node was selected           ( list prev )
      drop >next-node                     ( new-node )
   then                                   ( new-node )
   true swap >enum$-sel? c!
;

: highlight-enum$1  ( node -- )
   dup >xy 2@ 2dup edit1-text-xy+ 2tuck highlight-edit1
   hi-enum-button draw-enum-button
   rot >enum-list find-selected-enum$
   dup dup >enum$-hook @ execute
   >enum$ 2@ 2swap hitext-edit1
; 
: lowlight-enum$1   ( node -- )
   dup >xy 2@ 2dup edit1-text-xy+ 2tuck lowlight-edit1
   lo-enum-button draw-enum-button
   rot >enum-list find-selected-enum$
   >enum$ 2@ 2swap text-edit1
;

: free-enum$  ( enum-list -- )
   >next-node
   begin  dup  while
      dup >next-node swap
      enum$-node free-node
   repeat
   drop
;

false value enum$1-next?
false value enum$1-prev?

vocabulary enum$1-methods
also enum$1-methods definitions
headers
: highlight  ( node -- )  highlight-enum$1  ;
: lowlight   ( node -- )  lowlight-enum$1   ;
: up         ( node -- )
   dup >myself @ ['] unselect-node find-node 2drop
   enum$1-next?  if
      dup >enum-list enum$-select-next
      false to enum$1-next?
   then
   enum$1-prev?  if
      dup >enum-list enum$-select-prev
      false to enum$1-prev?
   then
   highlight-node
;
: moused?    ( x y node -- flag )
   >r 2dup				( x y )  ( r: node )
   r@ >xy 2@ edit1-text-xy+  def-edit1-wh in-rect? -rot
					( flag x y )  ( r: node )
   r> >xy 2@ enum$1-button-xy+  def-enum-button-wh in-rect?
   dup to enum$1-next?
   or
;
: done?      ( node -- flag )  drop false  ;
: do-key?    ( node -- flag )  drop false  ;
: release    ( node -- )   
   dup >enum-list free-enum$
   >private @ /enum-private free-mem  
;
: next-enum  ( node -- )
   dup >enum-list enum$-select-next highlight-node
;
headerless
previous definitions

: display-enum$1  ( x y node -- x' y' false )
   dup >methods @  ['] enum$1-methods  <>  if  drop false exit  then
   >r
   2dup r@ >xy 2!	( x y )
   0 t-char-height edit1-vspacing *  xy+  false
   r@ >label 2@  r@ >xy 2@  label-edit1
   r> dup selected?  if  highlight-enum$1  else  lowlight-enum$1  then
;
: display-enum/edit$1  ( x y node -- x' y' false )
   dup  >methods @  ['] edit1-methods =  if
      display-edit1
   else
      dup >methods @  ['] enum$1-methods =  if
         display-enum$1
      else
         drop false
   then then
;
warning @ warning off
: place-items  ( list -- )
   dup place-items     ( list )

   t-char-width edit1-hspacing * t-char-height edit1-vspacing 5 + *
   rot ['] display-enum/edit$1 find-node 2drop 2drop
;
warning !

false value enum-sel?
: add-enum$1-items  ( parent list xt label$ hook -- parent list )
   control-node allocate-node >r              ( parent list xt label$ hook )
   r@ >hook !  r@ >label 2!		      ( parent list xt )
   0 r@ >char c!			      ( parent list xt )
   ['] enum$1-methods r@ >methods !	      ( parent list xt )

   /enum-private alloc-mem r@ >private !      ( parent list xt )
   false to enum-sel?			      ( parent list xt )
   0 r@ >enum-list !			      ( parent list xt )
   r@ >enum-list swap execute drop	      ( parent list )

   \ Select the first enumerated item if none was selected by xt.
   enum-sel? 0=  if
      true r@ >enum-list >next-node >enum$-sel? c!
   then

   2dup r@ >myself !  r@ >my-parent !	      ( parent list )
   dup >next-node 0=  r@ >sel? c!	\ Select the first node
   r>  over last-node  insert-after	      ( parent list )
;

: add-enum$-item  ( list enum$ sel? hook -- list )
   enum$-node allocate-node >r		( list enum$ sel? hook )
   r@ >enum$-hook !			( list enum$ sel? )
   dup  if  true to enum-sel?  then	( list enum$ sel? )
   r@ >enum$-sel? c! r@ >enum$ 2!	( list )
   r> over last-node insert-after	( list )
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
