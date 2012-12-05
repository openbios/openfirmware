purpose: Vendor/product Tables for USB serial devices

headers
hex

create uart-generic-list  here
	525 w, 127a w,		\ Ajays USB 2.0 Debug Cable
here swap - constant /uart-generic-list

create uart-ftdi-list  here
	403 w, 6001 w,          \ FT232
here swap - constant /uart-ftdi-list

create uart-pl2303-list  here
	557 w, 2008 w,		\ ATEN, IOGear
	67b w, 2303 w,		\ PL2303
	67b w, 04bb w,		\ PL2303 RSAQ2
	4bb w, 0a03 w,		\ IODATA
here swap - constant /uart-pl2303-list

create uart-mct-list  here
	711 w, 0210 w,		\ MCT U232-P9
	711 w, 0230 w,		\ Sitecom U232-P25
	711 w, 0200 w,		\ D-LInk DU-H32P
	50d w, 0109 w,		\ Belkin F5U109
here swap - constant /uart-mct-list

create uart-belkin-list  here
	50d w, 0103 w,		\ Belkin F5U103
	50d w, 1203 w,		\ Belkin dockstation
	56c w, 8007 w,		\ "Old" Belkin single port
	565 w, 0001 w,		\ Peracom single port
	921 w, 1000 w,		\ GoHubs single port
here swap - constant /uart-belkin-list

: uart-generic?  ( vid pid -- flag )
   uart-generic-list /uart-generic-list  find-vendor-product?
;

: uart-ftdi?  ( vid pid -- flag )
   uart-ftdi-list /uart-ftdi-list  find-vendor-product?
;

: uart-pl2303?  ( vid pid -- flag )
   uart-pl2303-list /uart-pl2303-list  find-vendor-product?
;

: uart-mct?  ( vid pid -- flag )
   uart-mct-list /uart-mct-list  find-vendor-product?
;

: uart-belkin?  ( vid pid -- flag )
   uart-belkin-list /uart-belkin-list  find-vendor-product?
;

: usb-uart?  ( vid pid -- flag )
   2dup uart-ftdi?     if  2drop true  exit  then
   2dup uart-pl2303?   if  2drop true  exit  then
\ Not debugged yet...
\   2dup uart-mct?     if  2drop true exit  then
   2dup uart-belkin?   if  2drop true  exit  then
   2dup uart-generic?  if  2drop true  exit  then
   2drop false
;
