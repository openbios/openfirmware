\ See license at end of file
purpose: Drawings of OLPC XO-1.5 board and components for test instructions

support-package: test-instructions

decimal

\ Common items

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

\ Board bottom items

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

: basic-layout  ( -- )
   clear-drawing
   d# 10 d# 20 offsetat
   double-drawing
;
: draw-board  ( -- )
   basic-layout
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

\ Board top items

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
: headphones-top
   2 95   7 18  boxat
   9 91  45 28  boxat
   headphones-logo
;
: mic-top
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
: ext-sd-slot-top  497 360  81 9  boxat  ;
: ext-sd-card-top
   504 369 moveto  0 -75 rline  11 -11 rline  56 0 rline  0 86 rline  -67 0 rline
;
: draw-top  ( -- )
   basic-layout

   top-outline
   headphones-top
   mic-top
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
   ext-sd-slot-top
;

: usb-key  ( -- )
   95 155 moveto  130 165 lineto 130 155 lineto  95 145 lineto 95 155 lineto
   130 155 moveto 150 140 lineto 150 150 lineto  130 165 lineto
   150 140 moveto 115 130 lineto 95 145 lineto
   146 153 moveto 155 155 lineto 155 135 lineto 110 122 lineto 110 133 lineto
   110 122 moveto 110 122  171 67  197 54 curveto  229 38 295 42 155 135 curveto
   155 156 moveto 218 111  229 100 241 81 curveto  248 65 239 51 239 51 curveto
;

: scanner  ( -- )
   195 98 moveto
   195 111  174 121  149 121 curveto
   123 121  103 111  102  98 curveto
   103  85  123  75  149  75 curveto
   174  75  195  85  195  98 curveto

   113 83 moveto
   193 40 228 48 239 61 curveto
   261 90 171 118 171 120 curveto

   235 85 moveto
   281 177 310 177 267 201 curveto
   251 209 227 200 235 189 curveto
   243 177 249 179 248 172 curveto
   239 121 196 109 200 109 curveto
;

: usb-ethernet
   130 212 moveto
   141 218 145 220 145 205 curveto 145 190 145 190 125 180 curveto
   105 170 105 171 105 185 curveto 105 190 105 185 105 190 curveto

   105 190 moveto
   106 190 105 192 105 185 curveto 105 170 105 170 135 155 curveto 165 140 165 140 185 150 curveto
   205 160 205 160 205 175 curveto 205 190 205 190 175 205 curveto 145 220 146 221 130 212 curveto

   125 190 moveto 135 195 lineto 115 205 lineto 95 195 lineto 115 185 lineto 120 188 lineto
   105 215 moveto 115 220 lineto 115 205 lineto 95 195 lineto 95 206 lineto
   115 220 moveto 135 210 lineto 135 195 lineto 115 205 lineto 115 220 lineto
   102 202 moveto  105 201 109 202 110 205 curveto  111 208 111 211 109 213 curveto
   109 213 moveto  78 232 38 242 38 242 curveto
   103 202 moveto  76 219 38 230 38 230 curveto
   130 188 moveto  121 193 lineto  115 190 lineto  125 185 lineto  130 188 lineto
   130 188 moveto  130 189 130 193 130 193 curveto
   115 185 moveto  120 188 lineto
   135 195 moveto  126 191 lineto

   321 96 moveto 321 106 lineto 322 106 308 124 287 118 curveto
   306 108 moveto 313 105 321 96 321 96 curveto 303 89 lineto 303 89 296 92 289 98 curveto 275 112 291 117 306 108 curveto
   327 90 moveto  327 96 lineto 321 101 lineto
   307 90 moveto 315 85 lineto 327 90 lineto 319 95 lineto
   283 111 moveto 284 114 287 112 288 113 curveto 289 114 289 116 288 117 curveto
   284 111 moveto 284 110 lineto

   287 111 moveto  250 134  198 157  198 157 curveto
   288 117 moveto  238 147  203 161  203 161 curveto
;


0 value blink-time
-1 value blink-state
0 value blink-color
h# ff0000 constant red-888
h# 00ff00 constant green-888
h# 0000ff constant blue-888
h# 000000 constant black-888
h# ffffff constant white-888
h# ff00ff constant magenta-888
magenta-888 to blink-color

: set-default-color  ( -- )  black-888 set-fg  ;

defer selected-object  ' noop to selected-object

: idle  ( -- )
   blink-state -1 =  if  exit  then
   1 ms
   get-msecs blink-time -  0>=  if
      blink-state 1 xor dup to blink-state  ( state )
      if  blink-color set-fg  else  white-888 set-fg  then
      selected-object
      get-msecs d# 400 +  to blink-time
   then
;

: highlight  ( xt color -- )
   to blink-color
   to selected-object
   get-msecs to blink-time
   0 to blink-state
   idle
;
: message-off  ( -- )  d# 2  d# 27  at-xy  kill-line  ;
: message  ( adr len -- )  cursor-off  message-off  red-letters  type  black-letters  ;

: performed  ( -- )
   -1 to blink-state
   message-off
   set-default-color
   selected-object
   cr
;

: connect-scanner  ( -- )
   basic-layout
   " Connect USB barcode scanner to continue.." message
   ['] scanner green-888 highlight
;

: connect-usb-key  ( -- )
   basic-layout
   " Connect USB stick to continue.." message
   ['] usb-key green-888 highlight
;

: connect-usb-ethernet  ( -- )
   basic-layout
   " Connect USB Ethernet to continue.." message
   ['] usb-ethernet green-888 highlight
;

: connect-headphones  ( -- )
   draw-top
   " Connect headphones to continue.." message
   ['] headphones-top h# 00e000  highlight  \ Green like headphone jack
;
: disconnect-headphones  ( -- )
   draw-top
   " Disconnect headphones to continue.." message
   ['] headphones-top red-888 highlight
;
: connect-microphone  ( -- )
   draw-top
   " Connect microphone to continue.." message
   ['] mic-top h# ff80c0 highlight \ Close enough to the pink of the mic jack
;
: disconnect-microphone  ( -- )
   draw-top
   " Disconnect microphone to continue.." message
   ['] mic-top red-888 highlight
;
: mic+phones-top  ( -- )  mic-top headphones-top  ;
: connect-loopback  ( -- )
   draw-top
   " Connect loopback cable to continue.." message
   ['] mic+phones-top green-888 highlight
;
: disconnect-loopback  ( -- )
   draw-top
   " Disconnect loopback cable to continue.." message
   ['] mic+phones-top red-888 highlight
;

: connect-int-sd  ( -- )
   draw-board
   " Connect internal SD card to continue.." message
   ['] int-sd-card green-888 highlight
;
: connect-ext-sd  ( -- )
   draw-top
   " Connect external SD card to continue.." message
   ['] ext-sd-card-top green-888 highlight
;

: disconnect-int-sd  ( -- )
   draw-board
   " Disconnect internal SD card to continue.." message
   ['] int-sd-card red-888 highlight
;
: disconnect-ext-sd  ( -- )
   draw-top
   " Disonnect external SD card to continue.." message
   ['] ext-sd-card-top red-888 highlight
;

: open  ( -- ok )  true  ;
: close  ( -- )  ;

end-support-package
0 value instructions-ih

: ($instructions)  ( name$ -- )
   instructions-ih 0=  if
      " "  " test-instructions" $open-package to instructions-ih
   then
   instructions-ih $call-method
;
' ($instructions) to $instructions

: (instructions-idle)  ( -- )  " idle" $instructions  ;
' (instructions-idle) to instructions-idle

: (instructions-done)  ( -- )  " performed" $instructions  ;
' (instructions-done) to instructions-done

: diag-mode  ( -- )  true to diag-switch?  ;

hex

\ LICENSE_BEGIN
\ Copyright (c) 2010 FirmWorks
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
