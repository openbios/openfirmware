\ See license at end of file
purpose: Low-level graphics for graphical user interface

hex

headerless

0 constant black
4 constant red
2 constant green
1 constant blue
7 constant gray
h# f constant white

h# ff h# ff h# ff rgb>565 value background
\ h# 0010 value selected-color
    0     0 h# 80 rgb>565 value selected-color
h# ff h# ff h# ff rgb>565 value ready-color

\ \\\\\\\\\\\\\\\\
\ Device Support \
\ \\\\\\\\\\\\\\\\

\needs screen-ih 0 value screen-ih
0 value mouse-ih

d# 1200 d# 900 2value max-xy
: max-x  ( -- n )  max-xy drop  ;
: max-y  ( -- n )  max-xy nip   ;

: xy=  ( x1 y1 x2 y2 -- equal? )
   >r			( x1 y1 x2 ) ( r: y2 )
   swap r> = >r		( x1 x2 ) ( r: equal> )
   = r> and		( equal? )
;

: xy+  ( x y dx dy -- x' y' )  rot +  -rot +  swap  ;
: xy-  ( x1 y1 x2 y2  -- x3 y3 )
   >r swap r> - >r - r>
;

: $call-screen  ( ??? adr len -- ??? )  screen-ih $call-method  ;
: screen-execute  ( ?? xt -- ?? )  screen-ih package( execute )package  ;

\ : screen-wh  ( -- x y )
\    screen-ih package( screen-width screen-height )package
\ ;
: screen-wh  ( -- x y )  " dimensions" $call-screen  ;

: (inset-xy)  ( x y -- x' y' )  screen-wh max-xy xy-  swap 2/ swap 2/  ;
defer inset-xy		' (inset-xy) to inset-xy
: inset  ( x y w h -- x' y' w h )  2swap inset-xy xy+ 2swap  ;
: ?inset  ( x y w h -- x' y' w h | x y w' h')
   2dup max-xy xy=  if
      2drop screen-wh
   else
      inset
   then
;

: get-event  ( #msecs -- false | x y buttons true )
   " get-event" mouse-ih $call-method
;

: screen-color!  ( r g b color# -- )  " color!" $call-screen  ;
: screen-color@  ( color# -- r g b )  " color@" $call-screen  ;
: screen-set-colors  ( clut color# #colors -- )
   over to color#  dup to #colors
   " set-colors" $call-screen
;

: alloc-pixels  ( #pixels -- adr )  ['] pix* screen-execute  alloc-mem  ;
: free-pixels   ( adr #pixels -- )  ['] pix* screen-execute  free-mem   ;

: fill-rectangle  ( color x y w h - )
   ?inset " fill-rectangle" $call-screen
;

: fill-rectangle-noff  ( color x y w h - )
   " fill-rectangle" screen-ih $call-method
;

headers
: draw-rectangle  ( address x y w h - )
   ?inset " draw-rectangle" $call-screen
;

: read-rectangle  ( address x y w h - )
   ?inset " read-rectangle" $call-screen
;
: screen-write  ( adr len -- )
   " write" $call-screen drop
;
: show-description  ( adr len -- )
   " "(9b)1;1H"(9b)K" screen-write
   screen-write
;

: cursor-off  ( -- )  " "(9b)25l" screen-write  ;
: cursor-on   ( -- )  " "(9b)25h" screen-write  ;

\ Width and height of text characters
: char-wh  ( -- x y )
   screen-ih package( char-width char-height )package
;

: set-text-region  ( fg-color bg-color x y w h -- )
   screen-ih package(
   0 to line#  0 to column#
   char-height / to #lines  char-width / to #columns
   to window-top  to window-left
   to background-color
   to foreground-color
   )package
;

: getchar  ( -- byte )  key  ;

\ use getchar or keyboard package read ( a n - actual ) to get input
\ arrows return 9B,char: up A, down B, right C, left D

\ Screen dimensions

\ Convenience variables

0 value w0
0 value h0
0 value x0
0 value y0

: box  ( color x y  w h  thickness  -- )
   >r  to h0  to w0  to y0  to x0
   dup  x0             y0            w0 r@   fill-rectangle
   dup  x0             y0            r@ h0   fill-rectangle
   dup  x0 w0 + r@ -   y0            r@ h0   fill-rectangle
        x0             y0 h0 + r@ -  w0 r>   fill-rectangle
;

\ Symbolic names for keys

    9 constant tab
h# 9b constant csi
h# 1b constant esc

\ 

d# 16  constant text-height

: border ( -- #pixels )  text-height 2/  ;

: set-description-region  ( -- )
   cursor-off
   0 background
   border  max-y text-height -   max-x border -  text-height
   inset  set-text-region
;
: set-color  ( r g b color# -- )  " color!"  screen-ih $call-method  ;

: scroller-height  ( -- #pixels )  text-height 2 *  ;

: small-scroller  ( -- )
   cursor-off
   0 background                               ( fg bg )
   border  max-y scroller-height -            ( fg bg x y )
   max-x border -  scroller-height            ( fg bg x y w h )
   inset  set-text-region
   " "(9b)1;1H"(9b)2JK"(9b)2;1H" screen-write
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
