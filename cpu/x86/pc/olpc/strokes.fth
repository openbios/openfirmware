dev screen

5 value fg
h# f value bg

: halve  ( n -- n/2 )  dup 1 and  swap u2/ +  ;

defer (point)           ( x y -- )
defer subpixel-(point)  ( xf yf -- )

0 0 2value dot-offset
: offsetat  ( x y -- )  to dot-offset  ;

: draw-dot  ( x y -- )
   dot-offset d+
   bytes/line *  swap pixel+  frame-buffer-adr +  fg swap pixel!
;
: subpixel-draw-dot  ( xf yf -- )
   swap halve swap halve
   draw-dot
;
: single-drawing  ( -- )
   ['] draw-dot to (point)
   ['] subpixel-draw-dot to subpixel-(point)
;
single-drawing

: subpixel-double-dot  ( x y -- )
   over 1+  over     draw-dot
   over 1+  over 1+  draw-dot
   over     over 1+  draw-dot
   draw-dot
;
: double-dot  ( x y -- )
   swap 2* swap 2*     ( x' y' )
   subpixel-double-dot
;
: double-drawing  ( -- )
   ['] double-dot to (point)
   ['] subpixel-double-dot to subpixel-(point)
;

variable curx  variable cury
: moveto   ( x y -- )  cury !  curx !  ;
: rmove    ( dx dy -- )  cury +!  curx +!  ;
: rpoint  ( -- )  curx @ cury @ (point)  ;
: pointat  ( x y -- )  moveto  rpoint  ;

2variable bump  2variable nobump
: bresenham  ( incr reload -- )
   tuck dup 2/   ( reload incr reload delta )
   swap  0  do               ( reload incr delta )
      rpoint                ( reload incr delta )
      over -  dup 0<  if     ( reload incr delta' )
         2 pick +            ( reload incr delta' )
         bump                ( reload incr delta var )
      else                   ( reload incr delta )
         nobump              ( reload incr delta var )
      then                   ( reload incr delta )
      2@  cury +!  curx +!   ( reload incr delta )
   loop                      ( reload incr delta )
   3drop   rpoint           ( )
;

: rline  ( dx dy -- )
   dup 0<  if              ( dx dy- )
      negate               ( dx |dy| )
      over 0<  if          ( dx- |dy| )
         swap negate swap  ( |dx| |dy| )
         2dup <  if  0 -1  else  swap  -1 0  then  -1
      else                 ( dx+ |dy| )
         2dup <  if  0 -1  else  swap  1 0   then   1
      then                 ( incr reload  nobump-xy  bump-x )
      -1                   ( incr reload  nobump-xy  bump-xy )
   else                    ( dx dy+ )
      over 0<  if          ( dx- dy+ )
         swap negate swap  ( |dx| dy )
         2dup <  if  0 1  else  swap  -1 0  then   -1
      else                 ( dx+ dy+ )
         2dup <  if  0 1  else  swap   1 0  then    1
      then                 ( incr reload  nobump-xy  bump-x )
      1                    ( incr reload  nobump-xy  bump-xy )
   then                    ( incr reload  nobump-xy  bump-xy )
   bump 2!  nobump 2!      ( incr reload )
   bresenham               ( )
;

0 [if]
\ Divide-and-conquer line drawing.  Bresenham above is about twice
\ as fast, but this is less code.
: xy+  ( x1 y1 x2 y2 -- x3 y3 )  rot +  >r  +  r>  ;
: (rxline)  ( x y dx dy -- )
   2dup or  if                 ( x y dx dy )
      swap 2/ swap 2/          ( x y dx/2 dy/2 )
      2over 2over recurse      ( x y dx/2 dy/2 )
      2swap 2over xy+ 2dup (point)  2swap  recurse  ( )
   else                        ( x y dx dy )
      4drop                    ( )
   then                        ( )
;
: rxline  ( dx dy -- )  curx @  cury @  2swap  (rxline)  ;
[then]

: lineto  ( x y -- )  swap curx @ -  swap cury @ -  rline  ;

: rbox  ( w h -- )
   0 over rline         ( w h )  \ Up
   over 0 rline         ( w h )  \ Right
   0 swap negate rline  ( w )    \ Down
   negate 0  rline      ( )      \ Left
;
: boxat  ( x y w h -- )  2swap moveto  rbox  ;

1 [if]
\ Test for line drawing
d# 240 value gey0  d# 240 value gex0
: godseye  ( -- )
   gex0  0  do
      i            gey0         moveto
      gex0         gey0 i -     lineto
      gex0 2* i -  gey0         lineto
      gex0         gey0 i +     lineto
      i            gey0         lineto
   3 +loop
;
: godseye1  ( -- )
   gex0  0  do
      i  gey0       moveto
      gex0 i -      i           ( x0-i i )
      negate  2dup  rline       ( x0-i -i )
      negate  2dup  rline       ( x0-i i )
      swap negate swap          ( i-x0 i )
              2dup  rline       ( x0-i -i )
      negate        rline       ( )
   3 +loop
;
[then]
3 value subpixel-shift
: >point  ( x y -- )  swap subpixel-shift lshift  swap subpixel-shift lshift  wljoin  ;

: bezier-point  ( p -- )
   lwsplit
   swap subpixel-shift 1- rshift  swap subpixel-shift 1- rshift    ( x y )
   subpixel-(point)                           ( )
;

: mid  ( p0 p1 -- mid )
   +  lwsplit halve  swap halve swap wljoin
;   
: close-coord?  ( n0 n1 -- flag )  - abs 1 subpixel-shift lshift  <=  ;
: close-point?   ( p0 p1 -- flag )
   lwsplit  rot lwsplit   ( x1 y1 x0 y0 )
   rot close-coord? -rot  close-coord? and
;

\ Bezier curve rendering by the midpoint method - see, for example,
\ http://web.cs.wpi.edu/~matt/courses/cs563/talks/surface/bez_surf.html
: bezier-steps  ( p0 p1 p2 p3 -- )
   dup 4 pick close-point?  if  4drop exit  then
   2over mid  >r      ( p0 p1 p2 p3                  r: p01 )
   -rot tuck          ( p0 p3 p2 p1 p2               r: p01 )
   mid >r             ( p0 p3 p2                     r: p01 p12 )
   over mid           ( p0 p3  p23                   r: p01 p12 )
   dup r@ mid         ( p0 p3  p23 p123              r: p01 p12 )
   r> r@ mid          ( p0 p3  p23 p123 p012         r: p01 )
   2dup mid           ( p0 p3  p23 p123 p012 p0123   r: p01 )
   dup bezier-point   ( p0 p3  p23 p123 p012 p0123   r: p01 )

   \ For convenience of stack manipulation, we calculate the right half "backwards"
   \ This gives equivalent results due to the symmetry of the calculation 
   tuck 2>r           ( p0  p3 p23 p123 p0123        r: p01 p012 p0123 )
   recurse            ( p0                           r: p01 p012 p0123 )

   2r> r> -rot        ( p0 p01 p012 p0123 )
   recurse            ( )
;
: bezier  ( p0 p1 p2 p3 -- )
   dup bezier-point  3 pick bezier-point  bezier-steps
;

: curveto  ( x1 y1 x2 y2 x3 y3 -- )
   2>r                                     ( x1 y1 x2 y2 x3 y3  r: x3 y3 )
   2r@  >point >r  >point >r  >point >r    ( r: x3 y3 p3 p2 p1 )
   curx @ cury @ >point  r> r> r>          ( p0 p1 p2 p3 r: x3 y3 )
   bezier                                  ( r: x3 y3 )
   2r> cury !  curx !
;
: +curxy  ( dx dy -- x y )  swap curx @ +  swap cury @ +  ;
: rcurve  ( dx1 dy1 dx2 dy2 dx3 dy3 -- )
   2dup 2>r                         ( dx,y1 dx,y2 dx,y3  r: dx,y3 )
   +curxy >point >r                 ( dx,y1 dx,y2        r: dx,y3 p3 )
   +curxy >point >r                 ( dx,y1              r: dx,y3 p3 p2 )
   +curxy >point >r                 ( p0                 r: dx,y3 p3 p2 p1 )
   curx @ cury @ >point  r> r> r>   ( p0 p1 p2 p3        r: dx,y3 )
   bezier                           (                    r: dx,y3 )
   2r> cury +!  curx +!             ( )
;

0 value kappa  \ Control point offset for Bezier curve circle approximation
\ See http://www.whizkidtech.redprince.net/bezier/circle/
: rcircle  ( radius -- )  \ current point is the center
   >r  curx @ r@ -  cury @  moveto        ( r: radius )
   r@ d# 36195 * d# 16 rshift  to kappa   ( r: radius )
   0 kappa          r@ kappa -  r@         r@ r@         rcurve   ( r: radius )
   kappa 0          r@  kappa r@ -         r@ r@ negate  rcurve   ( r: radius )
   0 kappa negate   kappa r@ -  r@ negate  r@ negate r@ negate  rcurve  ( r: r)
   kappa negate 0   r@ negate  r@ kappa -  r@ negate r@  rcurve   ( r: radius )
   curx @ r> +  cury @  moveto
;
: circleat  ( x y radius -- )  >r  moveto  r> rcircle  ;

: set-fg  ( fg -- )  convert-color  to fg  ;
: set-bg  ( bg -- )  convert-color  to bg  ;

dend

: set-fg  ( fg -- )  " set-fg" $call-screen  ;
: set-bg  ( bg -- )  " set-bg" $call-screen  ;
: rpoint  ( -- )  " rpoint" $call-screen  ;
: pointat  ( x y -- )  " pointat" $call-screen  ;
: moveto  ( x y -- )  " moveto" $call-screen  ;
: lineto  ( x y -- )  " lineto" $call-screen  ;
: curveto  ( x,y1 x,y2, x,y3 -- )  " curveto" $call-screen  ;
: rmove    ( dx dy -- )  " rmove" $call-screen  ;
: rline    ( dx dy -- )  " rline" $call-screen  ;
: rcurve   ( dxy1 dxy2 dxy3 -- )  " rcurve" $call-screen  ;
: rcircle  ( r -- )  " rcircle" $call-screen  ;
: circleat  ( x y r -- )  " circleat" $call-screen  ;
: rbox  ( w h -- )  " rbox" $call-screen  ;
: boxat  ( x y w h -- )  " boxat" $call-screen  ;
: offsetat  ( x y -- )  " offsetat" $call-screen  ;
: clear-drawing  ( -- )  " erase-screen" $call-screen  ;
: double-drawing  ( -- )  " double-drawing" $call-screen  ;
: single-drawing  ( -- )  " single-drawing" $call-screen  ;
