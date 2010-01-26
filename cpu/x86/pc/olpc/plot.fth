dev screen
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

9 constant wave-scale
1  d# 15 wave-scale - << 2+  constant wave-height

: pitch*  ( #lines -- #pixels )  bytes/line *  ;
: wave-top  ( -- adr )
   screen-height wave-height 2* -  pitch*  frame-buffer-adr +
;

: wave0  ( -- )  screen-height wave-height -  ;

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

\ : $call-screen  ( ? name$ -- ? )  stdout @ $call-method  ;
: wave  ( adr -- )  " waveform" $call-screen  ;
: clear-plot  ( width height -- )  " clear-plot"  $call-screen  ;
: lineplot  ( xt xmin xmax xscale  ymin ymax  -- )  " plot" $call-screen  ;
: vgrid  ( width height interval -- )  " vgrid" $call-screen  ;
: hgrid  ( width height interval -- )  " hgrid" $call-screen  ;

: setup-plot  ( -- )
   h# ffff set-fg  0 set-bg
   d# 1200 d# 900 clear-plot
   d# 1200 d# 900 d# 100 hgrid
   d# 1200 d# 900 d# 100 vgrid
;
