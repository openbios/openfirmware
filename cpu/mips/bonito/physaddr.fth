purpose: Physical addresses for the Bonito
copyright: Copyright 2000 FirmWorks  All Rights Reserved

headerless

h# 0000.0000 constant ram-pa
h# 1000.0000 constant pci-lo0-pa
h# 1400.0000 constant pci-lo1-pa
h# 1800.0000 constant pci-lo2-pa
h# 1c00.0000 constant rom-pa1
h# 1f80.0000 constant rom-pa0
h# 1fc0.0000 constant rom-pa
h# 1fd0.0000 constant pci-io-pa
h# 1fe0.0000 kseg1 + constant bonito-cfg-pa
h# 1fe0.0100 kseg1 + constant bonito-reg-pa
h# 1fe8.0000 kseg1 + constant pci-cfg-pa
h# 1ff0.0000 constant io0-pa
h# 1ff4.0000 constant io1-pa
h# 1ff8.0000 constant io2-pa
h# 1ffc.0000 constant io3-pa

pci-io-pa kseg1 + constant isa-io-base

h# 0200.0000 constant /ram-bank

h# 400 constant /resetjmp
[ifdef] ram-image
h# 20.0000 constant rom-base
h# 10.0000 constant /rom
rom-base kseg0 + constant rom-pa
[else]
0 constant rom-base
h# 8.0000 constant /rom
rom-pa   kseg1 + constant rom-pa
[then]
rom-pa /resetjmp + constant dropin-base

h# f000 constant smbus-base		\ offset into isa-io-base

io2-pa kseg1 + constant ide0-pa
io3-pa kseg1 + constant ide1-pa

\ Bonito registers
h# 00 bonito-reg-pa + constant bonponcfg
h# 04 bonito-reg-pa + constant bongencfg
h# 08 bonito-reg-pa + constant iodevcfg
h# 0c bonito-reg-pa + constant sdcfg
h# 10 bonito-reg-pa + constant pcimap
h# 14 bonito-reg-pa + constant pcimembasecfg
h# 18 bonito-reg-pa + constant pcimap_cfg
h# 1c bonito-reg-pa + constant gpiodata
h# 20 bonito-reg-pa + constant gpioie
h# 24 bonito-reg-pa + constant intedge
h# 28 bonito-reg-pa + constant intsteer
h# 2c bonito-reg-pa + constant intpol
h# 30 bonito-reg-pa + constant intenset
h# 34 bonito-reg-pa + constant intenclr
h# 38 bonito-reg-pa + constant inten
h# 3c bonito-reg-pa + constant intisr
h# 40 bonito-reg-pa + constant pcimail0
h# 44 bonito-reg-pa + constant pcimail1
h# 48 bonito-reg-pa + constant pcimail2
h# 4c bonito-reg-pa + constant pcimail3
h# 50 bonito-reg-pa + constant pcicachectrl
h# 54 bonito-reg-pa + constant pcicachetag
h# 58 bonito-reg-pa + constant pcibadaddr
h# 5c bonito-reg-pa + constant pcimstat
h# 100 bonito-reg-pa + constant ldmactrl
h# 100 bonito-reg-pa + constant ldmastat
h# 104 bonito-reg-pa + constant ldmaaddr
h# 108 bonito-reg-pa + constant ldmago
h# 200 bonito-reg-pa + constant copctrl
h# 200 bonito-reg-pa + constant copstat
h# 204 bonito-reg-pa + constant coppaddr
h# 208 bonito-reg-pa + constant copdaddr
h# 20c bonito-reg-pa + constant copgo

headers
