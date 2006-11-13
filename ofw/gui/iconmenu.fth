\ See license at end of file
purpose: Icon Menu graphical user interface

headerless

\ See insticon.fth for an example of how to define the master screen layout
\ Execute "menu" to start the GUI.


\ creates a rectangular array of squares, each of which
\ may contain an icon, a label, and a function
\ user can select an icon, and execute its function

\ notes
\ screen is max-x >= 640 by max-y >= 480 (can assume 640x480 for now)
\ 0,0 is left,top; 12 boxes 128x128 begin at 48,48
\ each may contain a 64x64 icon, centered, and a string below
\ mouse or keyboard can select, and run associated function
\ moving mouse cursor into occupied square changes selection
\ keyboard input removes mouse cursor and moves mouse to selected square
\ keyboard input (arrows) always moves to an occupied square

\ need:
\ put text into square

\ have:
\ fill-rectangle ( color x y w h - )	color is 0..255
\ draw-rectangle ( address x y w h - )  address of 64x64 pixmap
\ read-rectangle ( address x y w h - )
\ move-mouse-cursor ( x y - )
\ remove-mouse-cursor ( - )
\ poll-mouse  ( -- x y buttons )
\ get-event  ( #msecs -- false | x y buttons true )

hex

\ Icon layout parameters

headers
d# 32 			value    version-height
3 constant rows
5 constant cols
headerless
rows cols *		constant squares
d# 100			constant sq-size
d# 64			constant icon-size
d# 100			constant title-area

: sq-max-y  ( -- pixels )  sq-size rows *   ;

: top-row  ( -- row# )
   max-y  scroller-height -  version-height -  title-area -  ( available-y )
   sq-max-y -  2/
   title-area +
;
: bottom-row  ( -- row# )  top-row sq-max-y +  ;
: left-col  ( -- col# )  max-x  sq-size cols * - 2/  ;
: right-col  ( -- col# )  sq-size cols * left-col +  ;


\ \\\\\\\\\\\\
\ Icon Array \
\ \\\\\\\\\\\\

\ number the squares 0 1 2 3, 4 5 6 7, 8 9 10 11
: sq>rc  ( sq - row col )  cols /mod  swap  ;
: rc>sq  ( row col - sq )  swap cols * +  ;

: valid?  ( sq - )  0 squares within  ;
: sq?  ( sq - sq )  dup valid? 0= abort" That's not a square! "  ;

: sq>xy  ( sq - x y )
   sq?  sq>rc sq-size * left-col + swap sq-size * top-row + 
;

: mouse-sq  ( - sq )	\ -1 for no square
   ypos  top-row bottom-row within 0= if   -1 exit  then
   xpos  left-col right-col within 0= if   -1 exit  then
   ypos top-row - sq-size / cols *  xpos left-col - sq-size / +
;

: in-icon?  ( offset - in? )
   sq-size dup icon-size - 2/ tuck - within
;

\ each square needs:
\   the address of an icon, the address of a function, a label

struct
  /n   field >icon
  /n   field >function
2 /n * field >help	\ Brief description
\ 32 field >label	\ later...
dup constant /entry
squares * buffer: squarebuf

: sq  ( sq - a )  sq?	/entry * squarebuf +  ;

: set-sq  ( help$ 'function 'icon sq - )
   sq tuck >icon !  tuck >function !  ( help$ 'entry )
   >r
   ?save-string  r> >help 2!
;

\ Install an icon at grid position "row col" (0 0 is the upper left position)
\ 'icon is the address of the 64x64x8 icon image,
\ 'function is the execution-token of the word to execute if the icon is chosen
\ help$ is the string (in adr,len format) to display when the icon is
\    highlighted (ready for selection with a mouse click or "Enter")

headers
: install-icon  ( help$ 'function 'icon row col -- )  rc>sq set-sq  ;
headerless

: clear-sq  ( sq - )  >r  null$  ['] noop  0  r> set-sq  ;
headers
: clear-menu  ( - )  squares 0 do  i clear-sq  loop  ;
headerless

: active?  ( sq - active? )
   dup -1 = if  drop 0 exit  then
   sq >icon @ 0<>  
;


8 value current-sq

: set-current-sq   ( sq - )   0 squares 1- clamp to current-sq  ;

d# 10 constant thickness

: hilite   ( color - )
   current-sq sq>xy  ( color left top )
   sq-size icon-size - 2/ thickness -  tuck + -rot + swap 
   icon-size thickness 2* +  dup  thickness  box
;

headers
: emphasize  ( - )  ready-color hilite  ;
: highlight  ( - )  selected-color hilite  ;
: lowlight   ( - )  background hilite  ;

headerless
: ?lowlight  ( -- )  current-sq valid? if  lowlight  then  ;
: ?emphasize  ( flag -- )  if  emphasize  else  highlight  then  ;

: describe  ( -- )
   current-sq sq >help 2@ show-description
;
: draw-sq  ( sq - )
   dup -1 = if exit then
   background over sq>xy sq-size dup fill-rectangle
   dup sq >icon @ dup  if
      swap sq>xy sq-size icon-size - 2/ tuck + -rot + swap
      icon-size dup  draw-rectangle
   else
      2drop
   then
;

: scroller-lines  ( -- n )  max-y char-wh nip /  ;
: (restore-scroller)  ( fg bg -- )

   ( fg bg )  0 0  max-x max-y  set-text-region
   " "(9b)1;1H"(9b)J" screen-write
   0 #line !
   ['] scroller-lines to lines/page
   cursor-on
   text-alerts
;

: restore-scroller-bg   ( -- )  0 background  (restore-scroller)  ;
: restore-scroller-white  ( -- )  0 f  (restore-scroller)  ;
headers
defer restore-scroller
' restore-scroller-white to restore-scroller

defer do-title  ' noop to do-title
headerless

: draw-background  ( -- )
   background 0 0 max-x max-y fill-rectangle
   do-title
;
: refresh  ( - )
   draw-background
   squares 0 do  i draw-sq  loop
   set-description-region
   highlight describe
;

: doit  ( - )
   current-sq dup valid?  if
      sq >function @ ?dup  if
         guarded
\         refresh
      then
   else
      drop
   then
;

: highlight+  ( -- )  highlight describe  ;

: go-horizontal  ( delta-columns -- )
   ?lowlight              ( delta-columns )
   current-sq  begin      ( delta square' )
      over + squares mod dup active?
   until                  ( delta square )
   set-current-sq  drop
   highlight+
;

\ Try has a desireable side-effect of setting current-sq
: try  ( r c -- active? )
   dup 0 cols within  0=  if  2drop false exit  then
   rc>sq dup  set-current-sq  active?
;

: go-vertical  ( delta-rows -- )

   ?lowlight                      ( delta-rows )
   \ Loop over all rows, starting at the row below the current one
   \ and wrapping around when we reach the bottom.

   current-sq sq>rc  begin        ( delta-rows  row current-col )
      -rot over +  rows mod  rot  ( delta-rows  row' current-col )

      \ For this row, begin at the current column and expand the search
      \ outward until either an active square is found or all columns have
      \ been checked.  When an active square is found, exit the entire word.

      cols 0  do
         2dup  i - try  if  3drop unloop highlight+  exit  then
         2dup  i + try  if  3drop unloop highlight+  exit  then
      loop
   again
;

false value done?
headers
: menu-done  ( -- )  true to done?  ;
headerless

: do-csi  ( char -- )
   case
      [char] A  of  -1 go-vertical    endof
      [char] B  of   1 go-vertical    endof
      [char] C  of   1 go-horizontal  endof
      [char] D  of  -1 go-horizontal  endof
   endcase
;

: do-key	( -- )
   key? if
      remove-mouse-cursor
      get-key-code  case
         [char]  q of  menu-done        endof
         control C of  menu-done        endof
         tab       of  1 go-horizontal  endof
         carret    of  doit             endof
         esc       of  menu-done        endof
         csi       of  ( c ) do-csi     endof
     endcase
     draw-mouse-cursor
   then
;

0 value ready?
: new-sq?  ( buttons -- )
   mouse-sq  dup current-sq =  if                 ( buttons square )
      \ The mouse is in the currently-selected square; highlight
      \ it if the button is up, emphasize it if the button is down.
      \ It is tempting to try to optimize this by painting the
      \ highlight/emphasis only on a button transition, but that
      \ would miss mouse movements between the selected square and
      \ unoccupied areas.
      drop  dup ?emphasize                        ( buttons )
      ready?                                      ( buttons was-ready? )
      over 0<> to ready?                          ( buttons was-ready? )
      \ Execute the square's function on the button's up transition
      swap 0=  and  if  false to ready?  doit  then  ( )
   else                                           ( buttons new-square )
      over 0<> to ready?                          ( buttons new-square )
      dup active?  if                             ( buttons new-square )
         \ The mouse has moved into an occupied square, so deselect
	 \ the current square and select the new one
         lowlight                      		  ( buttons new-square )
         set-current-sq				  ( buttons )
	 ?emphasize  describe                     ( )
      else                                        ( buttons new-square )
         \ The mouse is not in an occupied square; highlight
	 \ the current square in case it was previously emphasized
         2drop  highlight                         ( )
      then                                        ( )
   then                                           ( )
;

: do-mouse  ( - )
   mouse-ih 0=  if  exit  then
   begin  10 get-event  while         ( x y buttons )
      remove-mouse-cursor
      -rot  update-position           ( buttons )
      new-sq?
      draw-mouse-cursor
   repeat
;

headers
: centered  ( adr y w h -- )
   max-x 2 pick - 2/ -rot  2swap swap 2swap  draw-rectangle
;
headerless

: set-menu-colors  ( -- )
   e3 b6 77  10 set-color  \ Salmon
   66 2f  0  11 set-color  \ brown
   ec 1a 3a  12 set-color  \ More subdued red
   63 98 9e  13 set-color  \ nice bluish background
   33 33 aa  14 set-color  \ A good shade of blue for the left side of MacOS
   bb bb bb  15 set-color  \ Bright gray for CD-ROM icon
;

: open-devices  ( -- )
   " screen" open-dev is screen-ih
   mouse-ih  0=  if
      " mouse"  open-dev to mouse-ih    \ Try alias first
      mouse-ih  0=  if
         " /mouse" open-dev to mouse-ih
      then
   then
;

true config-flag menu?
0 value default-selection

: set-default-selection  ( row col -- )  rc>sq to default-selection  ;
headers
: selected  ( row col -- row col )  2dup set-default-selection  ;
headerless

: .menu  ( -- )  ." Type 'menu' to return to the menu" cr  ;

: wait-buttons-up  ( -- )  begin  0 get-event drop nip nip  0= until  ;
headers
: wait-return  ( -- )
   ." ... Press any key to return to the menu ... "
   cursor-off
   gui-alerts
   begin
      key?  if  key drop  refresh exit  then
      mouse-ih  if
         10 get-event  if
            \ Ignore movement, act only on a button down event
            nip nip  if  wait-buttons-up  refresh exit  then
         then
      then
   again
;
headerless

: menu-interact  ( -- )
   default-selection set-current-sq
   refresh  false to ready?
   draw-mouse-cursor
 
   false to done?
   begin   do-mouse  do-key   done? until
   false to done?
 
   remove-mouse-cursor
;

: setup-graphics  ( -- )
   screen-ih  0=  if  open-devices set-menu-colors  then
;
: setup-menu  ( -- )
   setup-graphics
   cursor-off
   gui-alerts
;

defer current-menu  ' clear to current-menu
: set-menu  ( xt -- )  to current-menu  current-menu  ;

headers
defer root-menu  ' noop to root-menu

: nest-menu  ( new-menu -- r: old-menu )
   ['] current-menu behavior  current-sq 2>r


   set-menu  menu-interact

   2r> to current-sq set-menu refresh
;

\ Note that menu establishes a new return stack state. Be sure to
\ clear any installed handler chain and establish a new base catch frame.

: menu  ( -- )  recursive
   rp0 @ rp!
   0 handler !
   ['] menu to user-interface
   setup-menu

   ['] root-menu ['] nest-menu catch drop

   f			( color )
   0 0			( color x y )
   screen-wh		( color x y w y )
   fill-rectangle-noff	( )
   
   restore-scroller
   .menu
   ['] quit to user-interface
   quit
;

\ headerless
: menu-or-quit  ( -- )
   menu?  if
      " device_type"  stdout @ ihandle>phandle get-package-property  0=  if
         get-encoded-string  " display" $=  if
            menu  exit
         then
      then
   then
   quit
;
\ Install menu-or-quit in the "user-interface" defer word later,
\ when a root menu is defined.
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
