purpose: Physical addresses for AVX
copyright: Copyright 2001 FirmWorks  All Rights Reserved

headerless

\ create for-bcm93730			\ Comment this out for AVX board

h# 0000.0000 constant ram-pa		\ 0000.0000-03ff.ffff
h# 1000.0000 constant bc-reg-pa		\ 1000.0000-1000.4fff

h# 1300.0000 constant pci-io-pa		\ 1300.0000-131f.ffff
h# 13c0.0000 constant bc-pci-reg-pa	\ 13c0.0000-13c0.00ff
h# 13e0.0cf8 constant bc-pci-cf8
h# 13e0.0cfc constant bc-pci-cfc
h# 1400.0000 constant pci-mem-pa	\ 1400.0000-17ff.ffff
h# 1c00.0000 constant 68k-io-pa		\ 1c00.0000-1fff.ffff
h# 1c00.1000 constant atmel-pa		\ 1c00.1000-1c00.13ff
[ifdef] for-bcm93730
h# 1500.07b0 constant uart-pa		\ COM1 on BCM93730
[else]
h# 1c00.2000 constant uart-pa		\ COM1
[then]
h# 1c00.2800 constant uart2-pa		\ COM2
h# 1c00.3000 constant led-pa
h# 1fc0.0000 constant rom-pa

68k-io-pa     kseg1 + constant 68k-io-base
pci-io-pa     kseg1 + constant pci-io-base
pci-mem-pa    kseg1 + constant pci-mem-base
uart-pa       kseg1 + constant uart-base
uart2-pa      kseg1 + constant uart2-base
bc-pci-reg-pa kseg1 + constant pci-reg-base
bc-reg-pa     kseg1 + constant bc-reg-base
bc-pci-cf8    kseg1 + constant pci-cf8
bc-pci-cfc    kseg1 + constant pci-cfc

h# 0400.0000 constant /ram-bank

h# 400 constant /resetjmp

0 constant rom-base
h# 6.0000 constant /rom
rom-pa   kseg1 + constant rom-pa
rom-pa /resetjmp + constant dropin-base

headers
