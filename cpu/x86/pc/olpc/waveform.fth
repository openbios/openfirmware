dev screen

9 constant wave-scale
1  d# 15 wave-scale - << 2+  constant wave-height

: pitch*  ( #lines -- #pixels )  bytes/line *  ;
: wave-top  ( -- adr )
   screen-height wave-height 2* -  pitch*  frame-buffer-adr +
;

: wave0  ( -- )  screen-height wave-height -  ;

5 value fg
h# f value bg

: pointat  ( x y -- )
   bytes/line *  swap wa+  frame-buffer-adr +  fg swap w!
;

variable curx  variable cury
: moveto  ( x y -- )  cury !  curx !  ;
: rmove  ( dx dy -- )  cury +!  curx +!  ;
: point  ( -- )  curx @ cury @ pointat  ;

2variable bump  2variable nobump
: bresenham  ( incr reload -- )
   tuck dup 2/   ( reload incr reload delta )
   swap  0  do               ( reload incr delta )
      point                  ( reload incr delta )
      over -  dup 0<  if     ( reload incr delta' )
         2 pick +            ( reload incr delta' )
         bump                ( reload incr delta var )
      else                   ( reload incr delta )
         nobump              ( reload incr delta var )
      then                   ( reload incr delta )
      2@  cury +!  curx +!   ( reload incr delta )
   loop                      ( reload incr delta )
   3drop   point             ( )
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
      2swap 2over xy+ 2dup pointat  2swap  recurse  ( )
   else                        ( x y dx dy )
      4drop                    ( )
   then                        ( )
;
: rxline  ( dx dy -- )  curx @  cury @  2swap  (rxline)  ;
[then]

: lineto  ( x y -- )  swap curx @ -  swap cury @ -  rline  ;


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

: plot0  ( -- x y )  0  screen-height 10 -  ;
: clear-plot  ( width height -- )
   2>r
   bg  plot0  2r>    ( bg plot0-xy wh )
   rot over - -rot   ( bg plot0-xy' wh )
   fill-rectangle
;

variable ylim  variable ymin
1 value stretch
: clip-y  ( value -- value' )  ymin @ -  0 max  ylim @ min  ;
: plot  ( xt xmin xmax xscale ymin ymax -- )
   over - ylim !  ymin !  to stretch  ( xt xmin xmax )
   over 3 pick execute clip-y  ( xt xmin xmax y-at-xmin )
   plot0 2 pick -  moveto      ( xt xmin xmax y-at-xmin )
   -rot  swap 1+  ?do          ( xt last )
      i 2 pick execute clip-y  ( xt last value )
      tuck -                   ( xt value delta )
      stretch swap rline       ( xt value )
   loop                        ( xt last )
   2drop                       ( )
;

: clear-waveform  ( -- )
   bg
   0  wave0 wave-height -  screen-width wave-height 2*
   fill-rectangle
;
: waveform-start  ( -- )  0  wave0  moveto  ;
: draw-wave  ( adr )
   0 swap   ( last adr )
   screen-width  0  do  ( last adr )
      tuck <w@          ( adr last this-unscaled )
      wave-scale >>a    ( adr last this )
      tuck swap -       ( adr this distance )
      1 swap rline      ( adr this )
      swap wa1+         ( this adr )
   loop                 ( last adr )
   2drop
;
: waveform  ( adr -- )  clear-waveform  waveform-start  draw-wave  ;
: set-fg  ( fg -- )  to fg  ;
: set-bg  ( bg -- )  to bg  ;
: vgrid  ( width height interval -- )
   rot  0  ?do               ( height interval )
      i plot0 nip  moveto    ( height interval )
      0 2 pick negate rline  ( height interval )
   dup +loop                 ( height interval )
   2drop                     ( )
;
: hgrid  ( width height interval -- )
   swap  0  ?do              ( width interval )
      plot0 i -  moveto      ( width interval )
      over 0  rline          ( width interval )
   dup +loop                 ( width interval )
   2drop                     ( )
;

dend

: $call-screen  ( ? name$ -- ? )  stdout @ $call-method  ;
: wave  ( adr -- )  " waveform" $call-screen  ;
: clear-plot  ( width height -- )  " clear-plot"  $call-screen  ;
: lineplot  ( xt xmin xmax xscale  ymin ymax  -- )  " plot" $call-screen  ;
: set-fg  ( fg -- )  " set-fg" $call-screen  ;
: set-bg  ( bg -- )  " set-bg" $call-screen  ;
: vgrid  ( width height interval -- )  " vgrid" $call-screen  ;
: hgrid  ( width height interval -- )  " hgrid" $call-screen  ;
