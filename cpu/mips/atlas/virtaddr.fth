purpose: Virtual addresses for the Atlas board
copyright: Copyright 2001 FirmWorks  All Rights Reserved

headerless

rom-base kseg0 +   value fw-virt-base		\ 1 meg of mapping space
h# 10.0000 value fw-virt-size

headers

\ fw-virt-base fw-virt-size + ' load-base set-config-int-default
0 value load-limit	\ Top address of area at load-base (set later)
