\ See license at end of file
purpose: Zoom and pan the text scroller with touchscreen gestures

dev screen
: dst-size@  ( -- w h )  h# 108 lcd@  lwsplit  ;
: dst-size!  ( w h -- )  wljoin h# 108 lcd!  ;
: dst-offset@  ( -- x y )  h# 100 lcd@  lwsplit  ;
: dst-offset!  ( x y -- )  wljoin h# 100 lcd!  ;
: scr-size@  ( -- w h )  h# 104 lcd@  lwsplit  ;
: half-size  ( -- w h )  dst-size@ swap 2/ swap 2/  ;
: image-center-xy  ( -- x y )  half-size  dst-offset@ xy+  ;

: xy-max  ( x1 y1 x2 y2 -- xmax ymax  )  rot max  >r  max r>  ;
: xy-min  ( x1 y1 x2 y2 -- xmin ymin  )  rot min  >r  min r>  ;
d# 60 d# 80 2constant min-wh
: set-dst-size  ( w h -- )
   scr-size@ xy-min  min-wh xy-max  dst-size!
;
\ This is an attempt to delay the operation until "retrace", but
\ it doesn't work very well; it's currently worse than nothing.
: wait-frame  ( -- )
   0 h# 1c4 lcd!  begin  h# 1c4 lcd@  until 
;
: set-dst-offset  ( x y -- )
   \ Keep the full image on-screen
   0 0  xy-max          ( x' y' )

   2dup dst-size@ xy+   ( x y  extent-x extent-y )
   scr-size@ 2swap xy-  ( x y  margin-x margin-y )
   \ A negative margin means part of the image is off the screen
   \ Positive margin is okay; we only adjust if margin is negative.
   0 0  xy-min          ( x y  adjust-x adjust-y )
   xy+                  ( x' y' )

   dst-offset!          ( )
;
: resize-image  ( xnum ynum xdenom ydenom old-w old-h -- )
   2>r             ( xnum xdenom  ynum ydenom  r: w h )
   rot swap        ( xnum xdenom  ynum ydenom  r: w h )
   2r>             ( xnum xdenom  ynum ydenom  w h )
   swap >r         ( xnum xdenom  ynum ydenom  h  r: w )
   -rot */         ( xnum xdenom  h'  r: w )
   r> swap >r      ( xnum xdenom  w   r: h' )
   -rot */         ( w'  r: h' )
   r>              ( w' h' )
   set-dst-size    ( )
;
: rx  ( 6*n -- 6*n )  0 5  do i pick .d -1 +loop  cr resize-image  ;
: arx ." A "  rx resize-image  ;
: brx ." B "  rx resize-image  ;

0 0 2value p0
0 0 2value p1
0 0 2value base-distance
0 0 2value base-wh
0 0 2value base-touch-xy
0 0 2value base-center-xy

\ Try to keep the center of the image in the same place after resizing
: recenter-image  ( -- )
   base-center-xy  half-size xy-
   set-dst-offset
;

0 value down0?
0 value down1?

: distance  ( -- x y )   p1 p0 xy-  ;

: xy-abs  ( x y -- abs-x abs-y )  swap abs  swap abs  ;

0 value touch-ih
: open-touch  ( -- )
   touch-ih 0=  if
      " /touchscreen" open-dev to touch-ih
   then
   touch-ih 0=  abort" Can't open touchscreen"
;
: close-touch  ( -- )  touch-ih  ?dup  if  close-dev  0 to touch-ih  then  ;

: mark-touch  ( point -- )
   to base-touch-xy
   image-center-xy to base-center-xy
;
: mark-size  ( -- )
   dst-size@ to base-wh
   distance xy-abs  to base-distance
;
: move-image  ( newx,y -- )
\  wait-frame
   base-touch-xy xy-  base-center-xy half-size xy-  xy+  set-dst-offset
;
: resize&recenter  ( -- )
\  wait-frame
   distance xy-abs base-distance base-wh resize-image \ brx 
   recenter-image
;
: do-touch0  ( x y down? -- )
   -rot to p0  if      ( )    \ Down
      down1?  if              \ Double-touch - resize
         down0?  if           \ Not the initial touch pair - resize the image
            resize&recenter
         else                 \ Initial touch pair - establish the baseline size
            mark-size

            \ Retouch of first finger - reestablish the base position
            \ in case the image was moved by the other finger
            p1 mark-touch
         then
      else                    \ The other finnger is up, so this is a move
         down0?  if           \ Not the initial touch - move the image
            p0 move-image
         else                 \ Initial touch - establish the base position
            p0 mark-touch
         then
      then

      true to down0?
   else                       \ Up
      \ When this finger goes up, reestablish the base position on the other
      \ finger so its subsequent movement will cause stable image movement
      p1 mark-touch
      false to down0?
   then
;
: do-touch1  ( x y down? -- )
   -rot to p1  if      ( )    \ Down
      down0?  if              \ Double-touch - resize
         down1?  if           \ Not the initial touch pair - resize the image
            resize&recenter
         else                 \ Initial touch pair - establish the baseline size
            mark-size

            \ Initial or re-touch of second finger - reestablish the base position
            \ in case the image was moved by the other finger
            p0 mark-touch
         then
      else                    \ The other finnger is up, so this is a move
         down1?  if           \ Not the initial touch - move the image
            p1 move-image
         else                 \ Initial touch - establish the base position
            p1 mark-touch
         then
      then

      true to down1?
   else                       \ Up
      \ When this finger goes up, reestablish the base position on the other
      \ finger so its subsequent movement will cause stable image movement
      p0 mark-touch
      false to down1?
   then
;
: touch>screen  ( x y -- x' y' )
   scr-size@ 1 1 xy-  xy*
   swap d# 15 rshift  swap d# 15 rshift
;
: do-gesture  ( -- )
   " get-touch?" touch-ih $call-method  0=  if  exit  then  ( x y z down? touch# )
   2>r      ( x y z  r: down? touch# )
   drop     ( x y  r: down? touch# )
   \ Convert from touchscreen to pixel coordinates
   touch>screen     ( x y  r: down? touch# )
   2r>      ( x y  down? touch# )
   case
      0 of  do-touch0  endof
      1 of  do-touch1  endof
      ( default ) >r 3drop r>
   endcase
;
: pinch
   ." Use one and two finger gestures to resize and move the scroller." cr
   ." Type a key to exit."  cr
   open-touch
   begin do-gesture key? until
   close-touch
;
dend

\ LICENSE_BEGIN
\ Copyright (c) 2011 FirmWorks
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
