purpose: Virtual addresses for AVX
copyright: Copyright 2001 FirmWorks  All Rights Reserved

headerless

0 value fw-virt-base     \ Setup later after we know the memory size
h# 10.0000 value fw-virt-size

headers

kseg0 h# 20.0000 + ' load-base set-config-int-default
0 value load-limit	\ Top address of area at load-base (set later)
