: button-symbol  ( x y -- )
   2dup  18 18 boxat
   swap 9 +  swap 9 +  6 circleat
;
: top-outline
   153 360 moveto
   153 324 lineto  441 324 lineto  441 360 lineto  585 360 lineto
   585  36 lineto  531  36 lineto  531   0 lineto  234   0 lineto
   234  99 lineto  144  99 lineto  144   0 lineto   63   0 lineto
    63  36 lineto    9  36 lineto    9 360 lineto  153 360 lineto 
;
: hph
   2 95   7 18  boxat
   9 91  45 28  boxat
   headphones-logo
;
: mic
   9 54  45 28  boxat
   24 20 rmove  mic-logo
   2 59   7 18  boxat
;
: acin  0 307  36 27  boxat  ;
: int-mic-conn
   70 146  18 18  boxat
   28 15 rmove  mic-logo
;
: usb0
   7 128  45 27  boxat
   usb-logo
;
: usb1
   543 55  45 27  boxat
   usb-logo
;
: usb2
   543 100  45 45  boxat
   0 9 rmove  usb-logo
;
: display-conn  252 1  89 18  boxat  ;
: camera-conn  540 154  36 18  boxat  ;
: backlight-conn  63 46  27 17  boxat  ;
: above-int-mic-conn
   79 87  18 27  boxat
   81 82  9 5  boxat
   81 114  9 5  boxat
;
: pwr-but  543 338  button-symbol  ;
: rotate-but  30 338  button-symbol  ;
: up-but  37 237  button-symbol  ;
: down-but  37 278  button-symbol  ;
: left-but  14 258  button-symbol  ;
: right-but  57 258  button-symbol  ;
: o-but  543 239  button-symbol  ;
: x-but
   543 279  18 18  boxat
   548 283 moveto 557 292 lineto 548 292 moveto 557 283 lineto 
;
: square-but
   521 260  18 18  boxat
   525 264 moveto 534 264 lineto 534 273 lineto 525 273 lineto 525 264 lineto 
;
: check-but
   564 259  18 18  boxat
   570 269 moveto 573 273 lineto 578 263 lineto 
;
: led0-top  518 348  led-symbol  ;
: led1-top  491 348  led-symbol  ;
: led2-top  72 348  led-symbol  ;
: led3-top  99 348  led-symbol  ;
: mic-led  31 45   led-symbol  ;
: camera-led  569 45  led-symbol  ;
: wlan-conn-top  144 82  90 27  boxat  ;
: wlan-card-top  152 7  75 75  boxat  ;
: ext-sd-slot  497 360  81 9  boxat  ;

: draw-top  ( -- )
   clear-drawing
   top-outline
   hph
   mic
   acin
   int-mic-conn
   usb0 usb1 usb2
   display-conn
   camera-conn
   backlight-conn
   above-int-mic-conn
   pwr-but
   rotate-but
   up-but
   down-but
   left-but
   right-but
   o-but
   x-but
   square-but
   check-but
   led0-top
   led1-top
   led2-top
   led3-top
   mic-led
   camera-led
   wlan-conn-top
   wlan-card-top
   ext-sd-slot
;
