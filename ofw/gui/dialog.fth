\ See license at end of file
purpose: Basic framework for GUI dialog boxes

headerless

7 constant light-gray
8 constant dark-gray

1 constant bt

light-gray constant alert-light-color
dark-gray  constant alert-dark-color
black      constant alert-text-color

: alert-box  ( x y w h -- )
   to h0  to w0  to y0  to x0

   alert-light-color  x0             y0            w0   bt       fill-rectangle
   alert-light-color  x0             y0 bt +       bt   h0 bt -  fill-rectangle

   alert-dark-color  x0 w0 + bt -   y0            bt       h0   fill-rectangle
   alert-dark-color  x0 bt +        y0 h0 + bt -  w0 bt -  bt   fill-rectangle
;
: alert-panel  ( x y w h -- )
   alert-box 
   background  x0 bt +   y0 bt +  w0 bt 2* -  h0 bt 2* -  fill-rectangle
;

: t-char-width  ( -- n )
   my-self >r  screen-ih to my-self  char-width  r> to my-self
;
: t-char-height  ( -- n )
   my-self >r  screen-ih to my-self  char-height  r> to my-self
;

\needs : screen-write  ( adr len -- )  " write" screen-ih $call-method drop  ;

0 value backing-adr
2variable back-xy
2variable back-wh
: save-rectangle  ( x y w h -- )
   back-wh 2!   back-xy 2!
   back-wh 2@ * alloc-pixels to backing-adr
   backing-adr back-xy 2@ back-wh 2@  read-rectangle
;
: restore-rectangle  ( -- )
   backing-adr  back-xy 2@ back-wh 2@  draw-rectangle
   backing-adr  back-wh 2@ * free-pixels
   set-description-region
;

: alert-box-xywh  ( cols rows -- x y w h )
   swap 2+ t-char-width *  swap 2+ t-char-height *  ( w h )
   max-x 2 pick - 2/  -rot                          ( x w h )
   max-y over   - 2/  -rot                          ( x y w h )
;
: alert-text-box  ( cols rows -- )
   alert-box-xywh				    ( x y w h )

   2over 2over  save-rectangle

   2over 2over  alert-panel                         ( x y w h )
   2swap  swap t-char-width +     swap t-char-height +
   2swap  swap t-char-width 2* -  swap t-char-height 2* -
   2>r  alert-text-color background  2swap 2r>  set-text-region
;

: hline  ( color x y w -- )  1 fill-rectangle  ;
: vline  ( color x y h -- )  1 swap fill-rectangle  ;

: save-text-region  ( -- r: fg bg left top #columns #lines column# line# )
   r>  my-self  screen-ih to my-self             ( r0 my-self )

   foreground-color >r  background-color >r
   window-left >r  window-top >r
   #columns    >r  #lines     >r
   column#     >r  line#      >r

\  hide-text-cursor
   to my-self  >r
;
: restore-text-region  ( r: fg bg left top #columns #lines column# line# -- )
   r>  my-self  screen-ih to my-self             ( r0 my-self )

   r> to line#  r> to column#
   r> to #lines  r> to #columns
   r> to window-top  r> to window-left
   r> to background-color  r> to foreground-color

\  hide-text-cursor
   to my-self  >r
;
: text-at-xy  ( adr len  fg-color bg-color x y -- )
   save-text-region
   max-x t-char-width  set-text-region  screen-write
   restore-text-region
;

listnode
    /n 2* field >xy		\ control's xy coordinates
    /n 2* field >label		\ control's label
    /n    field >myself		\ control's list head
    /n    field >my-parent	\ control's parent list
    /n    field >hook		\ control's action
    /n    field >methods        \ control's display methods
    /n    field >private        \ control's private data
    /c    field >char		\ control's select char
    /c    field >sel?		\ control selected?
nodetype: control-node

: in-range?   ( n low size -- flag )  over + within  ;
: in-rect?  ( test-x,y rect-x,y rect-w,h -- flag )
   swap >r rot >r         ( test-x,y rect-y rect-h )
   in-range?              ( test-x flag )
   swap r> r>             ( flag test-x rect-x rect-w )
   in-range?  and
;

list: controls-list
: controls(  ( -- parent list )  0 controls-list !  0  controls-list  ;

: run-method  ( node method$ -- )
   2 pick >methods @ search-wordlist  if  execute  else  drop  then
;

: selected?  ( node -- flag )  >sel? c@ 0<>  ;

: unselect-node  ( node -- flag )
   dup selected?  if   ( node )
      false over >sel? c!
      " lowlight"  run-method
      true
   else
      drop false
   then
;
: highlight-node  ( node -- )  true over >sel? c!  " highlight" run-method  ;
: select-previous  ( list -- )
   dup ['] unselect-node find-node        ( list prev this|0 )
   if                                     ( list prev )
      \ If we're at the beginning of the list, go to the end
      2dup  =  if  drop last-node  else  nip  then   ( new-node )
   else  \ No node was selected           ( list prev )
      drop >next-node                     ( new-node )
   then                                   ( new-node )

   highlight-node
;
: select-next  ( list -- )
   dup ['] unselect-node find-node  nip  ( list this|0 )
   ?dup  if                              ( list this )
      \ If we're at the end of the list, wrap around to the beginning
      dup >next-node  if  nip  else  drop  then
   then                             ( predecessor )
   >next-node highlight-node
;
: pgdn  ( list -- )  drop  ;
: pgup  ( list -- )  drop  ;
: select-pgdn  ( list -- )  " pgdn" evaluate  ;
: select-pgup  ( list -- )  " pgup" evaluate  ;

: do-hook  ( node -- ??? )  >hook @ execute  ;
: do-selected-node  ( list -- ??? exit? )
   dup >r				( list )  ( r: list )
   ['] selected?  find-node  nip	( node )  ( r: list )
   dup >r do-hook			( ??? )  ( r: list node )
   r> " done?" run-method		( ??? exit? )  ( r: list )
   r> over  if  drop  else  select-next  then	( ??? exit? )
;

defer edit-moused		['] false to edit-moused
variable edit-moused?
variable goto-next?
variable pgdn?
variable pgup?
: do-selected-edit-node  ( list -- exit? )
   dup ['] selected?  find-node  nip   ( list node )
   " do-key?" run-method  if           ( list )
      edit-moused? @  if  drop edit-moused exit  then
      pgdn? @  if  select-pgdn false exit  then
      pgup? @  if  select-pgup false exit  then
      goto-next? @  if  select-next  else  select-previous  then  false
   else                                ( list )
      drop false		       ( false )
   then
;
: keyed?  ( char node -- char flag )  >char c@ over =  ;
: dialog-csi  ( char list -- )
   swap  case
      [char] A  of  select-previous  endof
      [char] B  of  select-next      endof
      [char] C  of  select-next      endof
      [char] D  of  select-previous  endof
      [char] /  of  select-pgdn      endof
      [char] ?  of  select-pgup      endof
      ( default )  nip
   endcase
;

: do-next-enum  ( list -- )
   ['] selected?  find-node  nip       ( node )
   " next-enum" run-method             ( )
;
: controls-key  ( list -- done? )
   key?  if
      >r
      get-key-code  upc           ( char [ csi ] )
      r@  ['] keyed?  find-node   ( char [ csi ] prev this|0 )
      ?dup  if
         nip nip do-hook
         r> drop true exit
      then                                           ( char [ csi ] prev )
      drop                                           ( char [ csi ] )
      case
         tab     of  r> select-next  false          endof
         csi     of  ( char ) r>  dialog-csi false  endof
         carret  of  r> do-selected-node            endof
         ( default ) r> do-next-enum  false swap
      endcase
   else
      drop false
   then
;

\ The node that contained the mouse cursor at the previous event
0 value moused-node

\ True if the dialog button was left in the down state by the previous event
0 value moused-node-down?

: depress-current   ( -- )
   moused-node-down? 0=  if
      moused-node  ?dup  if  " down" run-method  then
      true to moused-node-down?
   then
;
: release-current   ( -- )
   moused-node-down?  if
      moused-node  ?dup  if  " up" run-method  then
      false to moused-node-down?
   then
;
: ?depress  ( flag -- )  if  depress-current  else  release-current  then  ;
0 value dialog-ready?
: moused?  ( node -- flag )  >r  xpos  ypos  r> " moused?" run-method  ;

\ The node that contains the mouse cursor, if any
: mouse-node  ( list -- nodeid | 0 )
   dup ['] moused? find-node  nip  ?dup  if
      nip
   else
      ['] selected? find-node nip
      >my-parent @ dup  if  recurse  then
   then
;

: mouse-buttons  ( buttons list -- )
   mouse-node dup  if                                ( buttons dbutton )
      dup moused-node =  if                          ( buttons dbutton )
         \ The mouse is in the currently-selected button;
         \ depress or release it according to the state of the mouse buttons.
         drop  moused-node-down?                     ( buttons was-down? )
         over ?depress                               ( buttons was-down? )
         \ Execute the dialog button's function when the mouse button's goes up
         swap 0=  and  if                            ( )
            moused-node dup " done?" run-method to dialog-ready?  ( node )
            do-hook
         then                                        ( )
      else                                           ( buttons dbutton )
         \ The mouse has moved into a button;
	 \ deselect the previous button and select the new one
         release-current               		     ( buttons dbutton )
         to moused-node				     ( buttons )
	 ?depress                                    ( )
      then
   else                                              ( buttons dbutton=0 )
      \ The mouse is not in a button.
      \ Release the current button in case it was previously emphasized
      false to dialog-ready?                         ( buttons dbutton=0 )
      release-current                                ( buttons dbutton=0 )
      to moused-node                                 ( buttons )
      drop                                           ( )
   then                                              ( )
;

: controls-mouse  ( list -- ?? flag )
   mouse-ih 0=  if  drop false exit  then
   >r
   false to dialog-ready?
   begin  10 get-event  while         ( x y buttons )
      remove-mouse-cursor             ( x y buttons )
      -rot  update-position           ( buttons )
      r@ mouse-buttons                ( ?? )
      draw-mouse-cursor               ( ?? )
   repeat                             ( ?? )
   r> drop                            ( ?? )
   dialog-ready?                      ( ?? flag )
;
0 value interact-list
: interact-with-buttons  ( list -- ?? )
   to interact-list
   0 to moused-node  
   begin
      interact-list do-selected-edit-node  if  exit  then
      interact-list controls-key    if  exit  then
      interact-list controls-mouse  if  exit  then
   again
;

: free-buttons  ( list -- )
   >next-node
   begin  dup  while		( node )
      dup >next-node swap	( node' node )
      dup " release" run-method	( node' )
      control-node free-node	( node' )
   repeat
   drop
;
: )controls  ( parent list -- ??? )
   >r drop
   r@ " place-items" evaluate
   r@ draw-mouse-cursor interact-with-buttons remove-mouse-cursor
   r> free-buttons
;

3 constant #button-rows

: split-line  ( adr len -- rem$ line$ )
   linefeed split-before
   2 pick  if  2swap 1 /string  2swap 1+  then  ( rem$'' line$' )

   \ Remove any trailing carriage return
   dup  if  2dup + 1- c@  carret =  if  1-  then  then
;

: count-lines  ( adr len -- #lines )
   0 -rot                                ( 0 adr len )
   begin  dup  while                     ( #lines adr len )
      split-line 2drop  rot 1+ -rot      ( #lines' adr' len' )
   repeat                                ( #lines adr 0 )
   2drop                                 ( #lines )
;
: screen-at-xy  ( col# row# -- )
   push-decimal   ( col# row# )
   1+ swap 1+     ( row#+1 col#+1 )
   <#  [char] H hold  u#s drop  [char] ; hold  u#s  h# 9b hold  u#>
   screen-write
   pop-base
;

d# 40 d# 10 2constant def-alert-col-row

: center-line  ( adr len row# -- )
   >r
   def-alert-col-row drop  over - 2/  0 max
   r> screen-at-xy
   screen-write
;
: center-text  ( adr len -- )
   2dup count-lines        ( adr len #lines )

   def-alert-col-row nip #button-rows -  over -  2/  ( adr len #lines #above )
   swap bounds  ?do                                  ( adr len )
      split-line i center-line                       ( adr' len' )
   loop                                              ( adr' 0 )
   2drop
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
