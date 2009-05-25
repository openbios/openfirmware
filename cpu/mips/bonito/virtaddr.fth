purpose: Virtual addresses for Bonito
copyright: Copyright 2001 FirmWorks  All Rights Reserved

headerless

[ifdef] ram-image
rom-base kseg0 +   value fw-virt-base		\ 1 meg of mapping space
[else]
0 value fw-virt-base     \ Setup later after we know the memory size
[then]
h# 10.0000 value fw-virt-size

headers

[ifdef] ram-image
fw-virt-base fw-virt-size + ' load-base set-config-int-default
[else]
kseg0 h# 20.0000 + ' load-base set-config-int-default
[then]
0 value load-limit	\ Top address of area at load-base (set later)
