purpose: Vendor/product Tables for USB ethernet devices

headers
hex

create net-ax8817x-list  here
        2001 w, 3c05 w,		\ D-Link DUBE100 Rev B1 ax88772
        07d1 w, 3c05 w,		\ D-Link DUBE100 Rev B1 ax88772
        2001 w, 1a00 w,		\ D-Link DUBE100 Rev A  ax88772
	0b95 w,	7720 w,		\ ST Lab
	0b95 w,	772a w,		\ Chip on VIA demo board
        13b1 w, 0018 w,		\ Linksys USB200M  ax88772
	077b w,	2226 w,		\ Linksys USB200M
	0846 w,	1040 w,		\ Netgear FA120
	2001 w,	1a00 w,		\ DLink DUB-E100
	0b95 w,	1720 w,		\ ST Lab
	07b8 w,	420a w,		\ Hawking UF200
	08dd w,	90ff w,		\ Billionton Systems, USB2AR
        05ac w, 1402 w,		\ Apple
here swap - constant /net-ax8817x-list

create net-pegasus-list  here
        050d w, 0121 w,         \ Belkin F5D5050
        07a6 w, 8515 w,         \ ADMtek 8515
        0846 w, 1020 w,		\ Netgear FA101
here swap - constant /net-pegasus-list

: net-ax8817x?  ( vid pid -- flag )
   net-ax8817x-list /net-ax8817x-list  find-vendor-product?
;

: pegasus? ( vid pid -- flag )
   net-pegasus-list /net-pegasus-list  find-vendor-product?
;

: usb-net?  ( vid pid -- flag )
   2dup net-ax8817x?  ( vid pid flag )
   -rot pegasus?  or  ( flag )
;
