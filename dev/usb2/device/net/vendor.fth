purpose: Vendor/product Tables for USB ethernet devices

headers
hex

create net-ax8817x-list  here
	077b w,	2226 w,		\ Linksys USB200M
	0846 w,	1040 w,		\ Netgear FA120
	2001 w,	1a00 w,		\ DLink DUB-E100
	0b95 w,	1720 w,		\ ST Lab
	07b8 w,	420a w,		\ Hawking UF200
here swap - constant /net-ax8817x-list

: net-ax8817x?  ( vid pid -- flag )
   net-ax8817x-list /net-ax8817x-list  find-vendor-product?
;

: usb-net?  ( vid pid -- flag )
   net-ax8817x?
;
