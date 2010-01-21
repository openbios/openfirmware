decimal
: headphones-logo
   24 5 rmove  -6 0  -10 6  -10 13 rcurve
   10 -13 rmove  6 0  10 6  10 13 rcurve
   -16 4 rmove  -2 0  -3 -1  -3 -2 rcurve  0 -3  1 -3  3 -3 rcurve  0 5 rline   
   12 -5 rmove  2 0  3 0  3 2  rcurve  0 3  -1 3  -3 3 rcurve  0 -5 rline
;

: led-symbol  ( x y -- )
   moveto  5 5 rline  5 -5 rline  -5 -5 rline  -5 5 rline
;
: usb-logo
   14 11  rmove
   1 1  1 3  0 4  rcurve
   -1 1  -2 1  -3 0  rcurve
   -1 -1  -1 -3  0 -4  rcurve
   1 -1  2 -1  3 0  rcurve

   10 -4  rmove
   1 -1  1 -2  0 -2  rcurve
   0 -1  -1 -1  -1 0  rcurve
   0 0  0 1  0 2  rcurve
   0 0  1 0  1 0  rcurve

   -12 6  rmove  18 0  rline  
   5 0  rmove   -5 -2  rline  0 4  rline  5 -2  rline  
   -7 6  rmove   2 0  rline  0 3  rline  -2 0  rline  0 -3  rline  
   -11 -6  rmove
   1 -2  2 -5  3 -6  rcurve
   1 -2  2 -1  3 -1  rcurve

   -2 7  rmove
   2 2  2 5  4 7  rcurve
   1 1  3 0  5 0  rcurve
;
: mic-logo
   -4 0  -6 -3  -6 -5  rcurve
   6 5  rmove   3 0  6 -3  6 -5  rcurve
   -4 -8  rmove
   0  8  rline  0  1  -1  2  -2  2  rcurve  -1 0  -2 -1  -2 -2  rcurve
   0 -8  rline  0 -1   1 -2   2 -2  rcurve   1 0   2  1   2  2  rcurve
   -2 13  rmove  0 3  rline   3 0  rmove  -7 0  rline  
;

: rantenna  ( -- )
   -5 -5 rmove  10 10 rbox  5 5 rmove  rpoint  5 rcircle
;
: wlan-card
   362 6  75 74 boxat
   10  9 rmove  rantenna
   55  0 rmove  rantenna
;

: board-outline 
     4  36 moveto
    58  36 lineto   58   0 lineto  355   0 lineto  355  99 lineto
   445  99 lineto  445   0 lineto  526   0 lineto  526  36 lineto
   580  36 lineto  580 360 lineto  436 360 lineto  436 324 lineto
   148 324 lineto  148 360 lineto    4 360 lineto    4  36 lineto 
;

: mic-conn
  535 52  45 28 boxat
  24 20 rmove  mic-logo
  580 58   8 16 boxat
;
: headphone-conn
  535 90  45 28 boxat
  headphones-logo
  580 96   8 16 boxat
;
: ac-conn  553 306  36 27 boxat  ;
: ext-sd-slot  13 270  81 90 boxat ;
: kbd-conn   175 279  13 27 boxat  ;

: ext-sd-card
   20 283 moveto 20 369 lineto 87 369 lineto 87 294 lineto 76 283 lineto 20 283 lineto 
;

: usb0-conn
   537 126  45 27 boxat
   usb-logo
;
: usb1-conn
   0 54  45 27 boxat
   usb-logo   
;
: usb2-conn
   0 99  45 45 boxat
   0 9 rmove  usb-logo
;
: battery-conn
   444 306  27 27 boxat
   427 279  18 18 boxat
;   

: led0  105 349 led-symbol  ;
: led1  131 349 led-symbol  ;
: led2  446 349 led-symbol  ;
: led3  473 349 led-symbol  ;
: cmos-battery-conn
   304  85  12 18 boxat
   306  81   8  4 boxat
   306 103   8  4 boxat
;

: cmos-battery
   262 60  22 circleat
   \ Wires
   243 71 moveto
     238  75   228  81   229  86 curveto
     229  90   242  99   249 100 curveto
     255 100   262  89   269  89 curveto
     275  89   280 100   286 100 curveto
     292 100   297  93   303  90 curveto
   247 76 moveto
     241  81   231  89   229  93 curveto
     226  96   230  99   234  99 curveto
     237  99   244  90   250  91 curveto
     255  91   261 101   268 101 curveto
     274 100   280  90   286  90 curveto
     292  90   298  96   304  99 curveto
;

: rspkr-conn
   22 154  18 16 boxat
   18 159  4 8 boxat
   40 159  4 8 boxat
;
: lspkr-conn
   544 171  18 16 boxat
   540 175  4 8 boxat
   562 175  4 8 boxat
;

: wlan-conn  350 81  100 28 boxat  ;

: serial-conn
   72 51  18 27 boxat
   76 47  8 4 boxat
   76 78  8 4 boxat
;

: int-sd-slot  411 159  51 45 boxat  ;

: int-sd-card
   404 200 moveto
   404 164 lineto  458 164 lineto  458 191 lineto  440 191 lineto  431 200 lineto
   427 200 lineto  427 195 lineto  423 195 lineto  418 199 lineto  404 200 lineto 
;

: draw-board  ( -- )
   clear-drawing
   d# 10 d# 20 offsetat
   double-drawing

   board-outline
   mic-conn
   headphone-conn
   ac-conn
   ext-sd-slot
   kbd-conn
   usb0-conn
   usb1-conn
   usb2-conn
   battery-conn
   led0  led1  led2  led3
   cmos-battery-conn
   cmos-battery
   rspkr-conn
   lspkr-conn
   wlan-conn
   serial-conn
   int-sd-slot

   wlan-card
   int-sd-card
   ext-sd-card
;
