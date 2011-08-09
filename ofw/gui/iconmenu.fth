\ See license at end of file
purpose: Icon Menu graphical user interface

headerless

\ See insticon.fth for an example of how to define the master screen layout
\ Execute "menu" to start the GUI.


\ creates a rectangular array of squares, each of which
\ may contain an icon, a label, and a function
\ user can select an icon, and execute its function

\ notes
\ screen is max-x >= 1200 by max-y >= 900 (can assume 1200x900 for now)
\ 0,0 is left,top; 12 boxes 128x128 begin at 48,48
\ each may contain a 128x128 icon, centered, and a string below
\ mouse or keyboard can select, and run associated function
\ moving mouse cursor into occupied square changes selection
\ keyboard input removes mouse cursor and moves mouse to selected square
\ keyboard input (arrows) always moves to an occupied square

\ need:
\ put text into square

\ have:
\ fill-rectangle ( color x y w h - )	color is 0..255
\ draw-rectangle ( address x y w h - )  address of 128x128 pixmap
\ read-rectangle ( address x y w h - )
\ move-mouse-cursor ( x y - )
\ remove-mouse-cursor ( - )
\ poll-mouse  ( -- x y buttons )
\ get-event  ( #msecs -- false | x y buttons true )

hex

\ Icon layout parameters

headers
d# 32 			value    version-height
5 value rows
7 value cols
headerless
: squares  rows cols *	;
d# 180			value sq-size
d# 128                  value image-size \ on file
d# 128			value icon-size  \ on screen
d# 100			value title-area

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
  /n   field >border
2 /n * field >help	\ Brief description
\ 32 field >label	\ later...
dup constant /entry
squares * buffer: squarebuf
: /icon  icon-size dup * 2 *  ;
: /image  image-size dup * 2 * 8 +  ;
   
: sq  ( sq - a )  sq?	/entry * squarebuf +  ;

: set-sq  ( help$ 'function 'icon sq - )
   sq background over >border !  tuck >icon !  tuck >function !  ( help$ 'entry )
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

: draw-border  ( color sq - )
   sq>xy  ( color left top )
   sq-size icon-size -  thickness 3 * -  2/  tuck + -rot + swap 
   icon-size thickness 3 * +  dup  thickness 2/  box
;

: hilite   ( color - )  current-sq draw-border  ;

headers
: emphasize  ( - )  ready-color hilite  ;
: highlight  ( - )  selected-color hilite  ;
: lowlight   ( - )  current-sq sq >border @ hilite  ;

headerless
: ?lowlight  ( -- )  current-sq valid? if  lowlight  then  ;
: ?emphasize  ( flag -- )  if  emphasize  else  highlight  then  ;

: describe  ( -- )
   current-sq sq >help 2@ show-description
;

[ifdef] 386-assembler
code expand-rect  ( src dst w h --- )
   dx  pop              \ Height of source image in pixels
   4 [sp] edi xchg
   8 [sp] esi xchg
   begin
      0 [sp]  cx mov    \ Width of source image in pixels
      begin
         op: ax lods                \ Get a pixel
         op: ax d# 256 [edi] mov    \ Write to next line
         op: ax stos                \ Write to this line + increment
         op: ax d# 256 [edi] mov    \ Write to next line
         op: ax stos                \ Write to this line + increment
      loopa
      d# 256 # edi add              \ Skip the next output line - already written
      edx dec
   0= until
   eax pop   \ Discard source width
   edi pop   \ Restore EDI
   esi pop   \ Restore ESI
c;
[then]

[ifdef] arm-assembler
code expand-rect  ( src dst w h --- )
   mov    r0,tos             \ r0: Height of source image in pixels
   ldmia  sp!,{r1,r2,r3,tos} \ r1: Width of source, r2: dst address, r3: src address
   begin
      add  r5,r3,r1,lsl #2          \ End address for this line
      begin
         ldrh r4,[r3]               \ Get pixel value
         inc  r3,#2                 \ Increment src
         strh r4,[r2]               \ Write pixel to dst
         strh r4,[r2,#2]            \ Duplicate pixel on this line
         inc  r2,#256               \ Next destination line
         strh r4,[r2]               \ Write pixel to next line
         strh r4,[r2,#2]            \ Duplicate pixel on next line
         dec  r2,#256               \ Back to original destination line
         inc  r2,#4                 \ Next destination pixel
         cmp  r3,r5                 \ End?
      = until
      inc r2,#256                   \ Skip the next output line - already written
      decs r0,#1
   0= until
c;
[then]

: expand-icon  ( adr - eadr )
   /icon alloc-mem tuck  ( eadr adr eadr )
   dup /icon 0 fill \ temp - clear old data
   icon-size 2/ icon-size 2/ expand-rect  ( eadr )
;

alias /pix* /w*

0 value src-w
0 value src-h

: center-icon  ( hdr-adr -- eadr )
   /icon alloc-mem >r                     ( hdr-adr r: eadr )
   r@ /icon  2 pick 8 + le-w@  wfill      ( hdr-adr )
   dup 4 + le-w@ to src-w                 ( hdr-adr )
   dup 6 + le-w@ to src-h                 ( hdr-adr )
   8 +                                    ( src-adr )
   
   \ Calculate offset in dest array for centering
   icon-size src-h -  2/  icon-size *     ( src-adr line-offset )
   icon-size src-w -  2/  +  /pix*        ( src-adr byte-offset )
   r@ +                                   ( src-adr dst-adr )

   \ Copy rectangle from source to destination
   swap src-h src-w * /pix*  bounds  ?do  ( dst-adr )
      i over  src-w /pix*  move           ( dst-adr )
      icon-size /pix* +                   ( dst-adr' )
   src-w /pix* +loop                      ( dst-adr )
   drop                                   ( )
   r>                                     ( eadr )
;

: load-pixels ( device$ -- pix-adr )
   r/o open-file  abort" error opening icon file"
   >r                                        (          r: fileid )
   r@ fsize dup alloc-mem  swap              ( adr len  r: fileid )
   2dup  r@ fgets                            ( adr len  actual  r: fileid )
   over <>  abort" error reading icon data"  ( adr len )
   r> fclose                                 ( adr len )

   over 4 + le-l@  h# 0040.0040 =  if        ( hdr-adr len )
      over 8 + expand-icon                   ( hdr-adr len pix-adr )
      -rot  free-mem                         ( pix-adr )
   else                                      ( hdr-adr len )
      over 4 + le-l@  h# 0080.0080 =  if     ( hdr-adr len )
         drop  8 +                           ( pix-adr )
      else                                   ( hdr-adr len )
         over center-icon                    ( hdr-adr len pix-adr )
         -rot free-mem                       ( pix-adr )
      then
   then
;

: (icon>pixels)  ( apf -- 'pixels )
   ta1+ dup @  ?dup  if            ( 'icon 'pixels  )
      nip                          ( 'pixels )
   else                            ( 'icon )
      dup na1+ count  load-pixels  ( 'icon 'pixels )
      tuck swap !                  ( 'pixels )
   then
;

\ Defining word for icon images
: icon:  ( "name" "devicename" -- ) ( child: -- 'pixels )
   create  ['] (icon>pixels) token,  0 ,  parse-word ",
;
: icon>pixels  ( icon-apf -- 'pixels )  dup token@ execute  ;

: draw-sq  ( sq -- )
   dup -1 = if exit then                              ( sq )
   background over sq>xy sq-size dup fill-rectangle   ( sq )
   dup sq >border @  over draw-border                 ( sq )
   dup sq >icon @ ?dup  if                            ( sq 'icon )
      icon>pixels                                     ( sq 'pixels )
      swap sq>xy  sq-size icon-size - 2/              ( 'pixels  x y  size )
      tuck + -rot + swap                              ( 'pixels  x' y' )
      icon-size dup  draw-rectangle                   ( )
      lowlight \ draw border                          ( )
   else                                               ( sq )
      drop
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
   squares 0  ?do  i draw-sq  loop
   set-description-region
   highlight describe
;

: run-menu-item  ( - )
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
         carret    of  run-menu-item    endof
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
      swap 0=  and  if  false to ready?  run-menu-item  then  ( )
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
   begin  mouse-event?  while         ( x y buttons )
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

: ?open-screen  ( -- )
   screen-ih  0=  if
      " screen" open-dev is screen-ih
   then
;
 
true config-flag menu?
0 value default-selection

: set-default-selection  ( row col -- )  rc>sq to default-selection  ;
headers
: selected  ( row col -- row col )  2dup set-default-selection  ;
headerless

: .menu  ( -- )  ." Type 'menu' to return to the menu" cr  ;

: wait-buttons-up  ( -- )
   begin
      mouse-event?  if   ( x y buttons )
	 nip nip  0=  if  exit  then
      then
   again
;
headers
: wait-return  ( -- )
   ." ... Press any key to return to the menu ... "
   cursor-off
   gui-alerts
   begin
      key?  if  key drop  refresh exit  then
      mouse-ih  if
         mouse-event?  if
            \ Ignore movement, act only on a button down event
            nip nip  if  wait-buttons-up  refresh exit  then
         then
      then
   again
;
headerless

defer run-menu
: menu-interact  ( -- )
   default-selection set-current-sq
   refresh  false to ready?
   draw-mouse-cursor
 
   false to done?
   begin   do-mouse  do-key   done? until
   false to done?
 
   remove-mouse-cursor
;
' menu-interact to run-menu

: setup-graphics  ( -- )
   ?open-screen  set-menu-colors
;
: setup-menu  ( -- )
   setup-graphics
   ?open-mouse
   cursor-off
   gui-alerts
;
: unsetup-menu  ( -- )  ?close-mouse  restore-scroller  ;

defer current-menu  ' clear to current-menu
: set-menu  ( xt -- )  to current-menu  current-menu  ;

headers
defer root-menu  ' noop to root-menu

: nest-menu  ( new-menu -- r: old-menu )
   ['] current-menu behavior  current-sq 2>r


   set-menu  run-menu

   2r> to current-sq set-menu refresh
;

: (menu)  ( -- )
   setup-menu

   ['] root-menu ['] nest-menu catch drop

   f			( color )
   0 0			( color x y )
   screen-wh		( color x y w y )
   fill-rectangle-noff	( )

   unsetup-menu
;

\ Note that menu establishes a new return stack state. Be sure to
\ clear any installed handler chain and establish a new base catch frame.

: menu  ( -- )  recursive
   rp0 @ rp!
   0 handler !
   ['] menu to user-interface

   (menu)

   .menu
   ['] quit to user-interface
   quit
;

\ headerless
: menu-or-quit  ( -- )
   menu?  if  screen-ih  if  menu exit  then  then
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
