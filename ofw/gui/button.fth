\ See license at end of file
purpose: GUI pushbuttons for use within dialog boxes

6 constant button-y-border
d# 10 constant button-#cols
d# 12 constant button-spacing
: def-button-wh   ( -- w h )
   t-char-width  button-#cols *
   t-char-height button-y-border 2* +
;

2variable button-wh
2variable button-xy

black      constant button-hilight
light-gray constant button-color
white      constant button-light
dark-gray  constant button-shadow
black      constant button-border

: button-width   ( -- w )  button-wh 2@ drop  ;
: button-height  ( -- h )  button-wh 2@ nip   ;

: interior-xy  ( -- x y )  button-xy 2@  2 2 xy+  ;
: up-lighting  ( -- )
   \ Left highlight
   button-light   interior-xy               ( color x y )
   3dup           button-height 4 -  vline
   3dup 1 0 xy+   button-height 5 -  vline

   \ Top highlight
   3dup           button-width  4 -  hline
   3dup 0 1 xy+   button-width  5 -  hline
   3drop

   \ Bottom shadow
   button-shadow  interior-xy              ( color x y )
   3dup           button-height + 5 -  button-width 4 -  hline
   3dup 1 0 xy+   button-height + 6 -  button-width 5 -  hline

   \ Right shadow
   ( color x y )  button-width 5 - 0 xy+        ( color x' y )
   3dup           button-height 4 -  vline
   3dup -1 1 xy+  button-height 5 -  vline
   3drop
;
: draw-button  ( -- )
   button-hilight  button-xy 2@  1 1 xy+  button-wh 2@  -2 -2 xy+  1  box

   button-color    button-xy 2@  2 2 xy+  button-wh 2@  -4 -4 xy+  fill-rectangle

   up-lighting
;
: button-text-loc  ( len -- x y )
   button-width  swap t-char-width * -  2/  ( left-offset )
   button-xy 2@                             ( offset x0 y0 )
   -rot +   swap button-y-border +
;
: (button)  ( adr len x y w h -- )
   button-wh 2!  button-xy 2!    ( adr len )
   draw-button                   ( adr len )
   dup button-text-loc           ( adr len x y )
   button-hilight button-color 2swap text-at-xy
;
: text-button  ( adr len x y -- )  def-button-wh (button)  ;
: highlight-button  ( x y -- )  button-hilight -rot  def-button-wh  1  box  ;
: lowlight-button   ( x y -- )  background -rot  def-button-wh  1  box  ;
: (down-button)  ( x y w h -- )
   button-wh 2!  button-xy 2!
   button-wh 2@  -8 -8 xy+  * dup >r  alloc-pixels >r
   r@  button-xy 2@  4 4 xy+  button-wh 2@  -8 -8 xy+  read-rectangle
   r@  button-xy 2@  5 5 xy+  button-wh 2@  -8 -8 xy+  draw-rectangle
   r> r> free-pixels

   button-color   interior-xy  button-wh 2@ -4 -4 xy+  2  box
   button-shadow  interior-xy  button-width   4 - hline
   button-shadow  interior-xy  button-height  4 - vline
;
: (up-button)  ( x y w h -- )
   button-wh 2!  button-xy 2!

   button-wh 2@  -8 -8 xy+  * dup >r  alloc-pixels >r
   r@  button-xy 2@  5 5 xy+  button-wh 2@  -8 -8 xy+  read-rectangle
   r@  button-xy 2@  4 4 xy+  button-wh 2@  -8 -8 xy+  draw-rectangle
   r> r> free-pixels

   button-color   interior-xy  button-wh 2@ -4 -4 xy+  2  box
   button-shadow  interior-xy  button-width   4 - hline
   button-shadow  interior-xy  button-height  4 - vline

   up-lighting
;
: down-button  ( x y -- )  def-button-wh (down-button)  ;
: up-button    ( x y -- )  def-button-wh (up-button)    ;

vocabulary button-methods
also button-methods definitions
headers
: count-button  ( n node -- n+1 )  drop 1+  ;
: highlight     ( node -- )  >xy 2@ highlight-button  ;
: lowlight      ( node -- )  >xy 2@ lowlight-button   ;
: down          ( node -- )  >xy 2@ down-button       ;
: up            ( node -- )  >xy 2@ up-button         ;
: moused?       ( node -- flag )  >xy 2@ def-button-wh in-rect?  ;
: done?         ( node -- flag )  drop true  ;
: do-key?       ( node -- flag )  drop false  ;
headerless
previous definitions

: display-button  ( x y node -- x' y' false )
   dup >methods @  ['] button-methods <>  if  drop false exit  then
   >r
   2dup r@ >xy 2!	( x y )
   t-char-width button-spacing *  0  xy+  false
   r@ >label 2@  r@ >xy 2@  text-button
   r@ selected?  if  r@ >xy 2@ highlight-button  then
   r> drop
;

: count-button  ( n node -- n+1 false )  " count-button" run-method  false  ;
: place-items  ( list -- )
   >r
   0 r@ ['] count-button find-node 2drop     ( #buttons )
   button-spacing * t-char-width *           ( button-cell-width )   
   back-wh 2@                                ( button-cell-width w,h )
   -rot swap - 2/ t-char-width +  swap       ( left-button-dx bottom-dy ) 
   t-char-height 5 2 */ -                    ( left-button-dx,dy )

   back-xy 2@ xy+                            ( left-button-x,y )

   r> ['] display-button find-node 2drop 2drop
;
: button  ( parent list label$ char hook -- parent list )
   control-node allocate-node >r              ( parent list label$ char hook )
   ['] button-methods r@ >methods !	      ( parent list label$ char hook )
   0 r@ >private !			      ( parent list label$ char hook )
   r@ >hook !  upc r@ >char c!  r@ >label 2!  ( parent list )
   2dup r@ >myself !  r@ >my-parent !	      ( parent list )
   dup >next-node 0=  r@ >sel? c!	\ Select the first node
   r>  over last-node  insert-after           ( parent list )
;

\ Some common dialog boxes that use only button controls

\needs msg01  : msg01  ( -- $ )  " Ok"  ;
\needs msg02  : msg02  ( -- $ )  " Cancel"  ;
\needs msg03  : msg03  ( -- $ )  " Yes"  ;
\needs msg04  : msg04  ( -- $ )  " No"  ;

: yes&no-buttons  ( -- )
   msg03  [char] y  ['] true   button
   msg04  [char] n  ['] false  button
;
: no&yes-buttons  ( -- )
   msg04  [char] n  ['] false  button
   msg03  [char] y  ['] true   button
;

: ok&cancel-buttons  ( -- )
   msg01  [char] y  ['] true   button
   msg02  h# 1b     ['] false  button
;

: dialog-confirm  ( adr len -- ok? )
   def-alert-col-row alert-text-box  center-text
   controls(
      ok&cancel-buttons
   )controls
   restore-rectangle
;
: dialog-yes  ( adr len -- ok? )
   def-alert-col-row alert-text-box  center-text
   controls(
      yes&no-buttons
   )controls
   restore-rectangle
;
: dialog-no  ( adr len -- ok? )
   def-alert-col-row alert-text-box  center-text
   controls(
      no&yes-buttons
   )controls
   restore-rectangle
;


headers
: dialog-alert  ( adr len -- )
   def-alert-col-row alert-text-box  center-text
   controls(
      msg01  h# 1b     ['] noop   button
   )controls
   restore-rectangle
;
headerless

: dialog-.error  ( throw-code -- )
   case
     d# -13  of  collect( abort-message type  ."  ?" )collect  endof
     d#  -2  of  abort-message  endof
     d#  -1  of  " "   endof
     ( default )
     dup in-dictionary?  if  count  else  drop collect( .error# )collect  then
     0
   endcase    ( adr len )
   dup  if  alert  else  2drop  then
;
: gui-alerts  ( -- )
   ['] show-description to progress
   ['] noop to progress-done  \ Perhaps    " Done" show-description
   ['] dialog-alert to alert
   ['] dialog-confirm to confirm
   ['] dialog-.error to .error
;
[ifdef] notdef
\ XXX test code follows
: test-panel  ( adr len -- )
   def-alert-col-row alert-text-box  center-text  key drop  restore-rectangle
;
: setup  ( -- )
   ?open-screen  set-menu-colors  ?open-mouse
   clear-menu install-menu cursor-off  refresh
;
[then]
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
