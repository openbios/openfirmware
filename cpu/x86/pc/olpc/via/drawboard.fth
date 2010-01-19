erase-screen
decimal
: wlan-card
   362 6  75 74 boxat
   \ Antenna 0
   367 10  9 9 boxat
   374 11 moveto 376 13 376 16 374 17 curveto 372 19 370 19 368 17 curveto 366 16 366 13 368 11 curveto 370 9 372 9 374 11 curveto
   371 15 moveto 371 15 371 15 371 15 curveto 371 15 371 15 371 15 curveto 371 15 371 15 371 15 curveto 371 14 371 14 371 15 curveto
   \ Antenna 1
   423 10  9 9 boxat
   431 11 moveto 432 13 432 16 431 17 curveto 429 19 426 19 424 17 curveto 422 16 422 13 424 11 curveto 426 9 429 9 431 11 curveto 
   427 15 moveto 427 15 427 15 427 15 curveto 427 15 427 15 427 15 curveto 427 15 427 15 427 15 curveto 427 14 427 14 427 15 curveto 
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
  574 58  14 16 boxat
  \ Logo
  559 72 moveto 555 72 553 70 553 67 curveto
  559 72 moveto 562 72 565 70 565 67 curveto 
  561 59 moveto 561 67 lineto 561 68 560 69 559 69 curveto 558 69 557 68 557 67 curveto 557 59 lineto 557 58 558 58 559 58 curveto 560 58 561 58 561 59 curveto 
  559 72 moveto 559 75 lineto 
  562 75 moveto 555 75 lineto 
;
: headphone-conn
  535 90  45 28 boxat
  574 96  14 16 boxat
  \ Logo
  559 95 moveto 564 95 569 101 569 107 curveto 
  559 95 moveto 553 95 549 101 549 107 curveto 
  554 112 moveto 552 112 550 111 550 110 curveto 550 108 552 107 553 107 curveto 554 112 lineto 
  564 107 moveto 566 107 568 109 568 110 curveto 567 111 566 112 564 112 curveto 564 107 lineto 
;
: ac-conn  553 306  36 27 boxat  ;
: ext-sd-slot  13 270  81 90 boxat ;
: kbd-conn   175 279  13 27 boxat  ;

: ext-sd-card
   20 283 moveto 20 369 lineto 87 369 lineto 87 294 lineto 76 283 lineto 20 283 lineto 
;


: usb0-conn
   537 126  45 27 boxat
   \ Logo
   551 137 moveto 552 138 552 140 551 141 curveto 550 142 549 142 548 141 curveto 547 140 547 138 548 137 curveto 549 136 550 136 551 137 curveto
   561 133 moveto 562 132 562 131 561 131 curveto 561 130 560 130 560 131 curveto 560 131 560 132 560 133 curveto 560 133 561 133 561 133 curveto
   549 139 moveto 567 139 lineto
   572 139 moveto 567 137 lineto 567 141 lineto 572 139 lineto
   565 145 moveto 567 145 lineto 567 148 lineto 565 148 lineto 565 145 lineto
   554 139 moveto 555 137 556 134 557 133 curveto 558 131 559 132 560 132 curveto 
   558 139 moveto 560 141 560 144 562 146 curveto 563 147 565 146 567 146 curveto 
;
: usb1-conn
   0 54  45 27 boxat
   \ Logo
   13 65 moveto 14 66 14 68 13 69 curveto 12 70 10 70 10 69 curveto 9 68 9 66 10 65 curveto 10 64 12 64 13 65 curveto 
   23 61 moveto 23 60 23 59 23 59 curveto 23 58 22 58 22 59 curveto 21 59 21 60 22 61 curveto 22 61 23 61 23 61 curveto 
   11 67 moveto 29 67 lineto 
   33 67 moveto 29 65 lineto 29 69 lineto 33 67 lineto 
   27 73 moveto 29 73 lineto 29 76 lineto 27 76 lineto 27 73 lineto 
   16 67 moveto 17 65 17 62 18 61 curveto 19 59 21 60 22 60 curveto 
   20 67 moveto 21 69 22 72 23 74 curveto 25 75 27 74 29 74 curveto 
;
: usb2-conn
   0 99  45 45 boxat
   \ Logo
   13 119 moveto 14 120 14 122 13 123 curveto 12 124 10 124 10 123 curveto 9 122 9 120 10 119 curveto 10 118 12 118 13 119 curveto 
   23 115 moveto 23 114 23 113 23 113 curveto 23 112 22 112 22 113 curveto 21 113 21 114 22 115 curveto 22 115 23 115 23 115 curveto 
   11 121 moveto 29 121 lineto 
   33 121 moveto 29 119 lineto 29 123 lineto 33 121 lineto 
   27 127 moveto 29 127 lineto 29 130 lineto 27 130 lineto 27 127 lineto 
   16 121 moveto 17 119 17 116 18 115 curveto 19 113 21 114 22 114 curveto 
   20 121 moveto 21 123 22 126 23 128 curveto 25 129 27 128 29 128 curveto 
;
: battery-conn
   444 306  27 27 boxat
   427 279  18 18 boxat
;   

: led0
   110 344 moveto 115 349 lineto 110 354 lineto 105 349 lineto 110 344 lineto
;
: led1
   136 344 moveto 141 349 lineto 136 354 lineto 131 349 lineto 136 344 lineto
;
: led2
   451 344 moveto 456 349 lineto 451 354 lineto 446 349 lineto 451 344 lineto
;
: led3
   478 344 moveto 483 349 lineto 478 354 lineto 473 349 lineto 478 344 lineto
;
: cmos-battery-conn
   304  85  12 18 boxat
   306  81   8  4 boxat
   306 103   8  4 boxat
;

: cmos-battery
   278 45 moveto
     287  53   287  66   278 74 curveto
     270  83   255  83   247 74 curveto
     238  66   238  53   247 45 curveto
     255  36   270  36   278 45 curveto
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
   erase-screen
   d# 10 d# 20 to dot-offset
   double-size

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
