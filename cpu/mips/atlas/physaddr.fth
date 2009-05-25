purpose: Physical addresses for the Atlas board
copyright: Copyright 2000 FirmWorks  All Rights Reserved

headerless

h# 0000.0000 constant ram-pa
h# 0800.0000 constant pci-lo0-pa
h# 1800.0000 constant pci-lo1-pa
h# 1c00.0000 constant rom-pa1
h# 1e00.0000 constant rom-pa0
h# 1fc0.0000 constant rom-pa
\ h# 1fd0.0000 constant system-controller-specific
\ h# 1fe0.0000 kseg1 + constant bonito-cfg-pa
\ h# 1fe0.0100 kseg1 + constant bonito-reg-pa
\ h# 1fe8.0000 constant pci-cfg-pa
h# 1f00.0000 constant io0-pa
h# 1f00.0900 constant uart-pa

\ pci-io-pa kseg1 + constant isa-io-base

h# 0200.0000 constant /ram-bank

h# 20.0000 constant rom-base
h# 20.0020 constant rom-entry
h# 10.0000 constant /rom
h# 60 constant /resetjmp
rom-base  kseg0 + constant rom-pa
rom-entry kseg0 + constant rom-entry-pa
rom-pa /resetjmp + constant dropin-base

\ Bonito registers
\ h# 18 bonito-reg-pa + constant pcimap_cfg
\ h# 50 bonito-reg-pa + constant pcicachectrl
\ h# 54 bonito-reg-pa + constant pcicachetag

headers
