\ See license at end of file
purpose: Establish address and I/O configuration definitions

[ifdef] rom-loaded
[ifdef] demo-board
h# fff8.0000   constant rom-pa		\ Physical address of boot ROM
h#    8.0000   constant /rom		\ Size of boot ROM
\ h# fffe.0000   constant rom-pa	\ Physical address of boot ROM
\ h#    2.0000   constant /rom		\ Size of boot ROM
rom-pa         constant dropin-base
[else]
h# fff0.0000   constant rom-pa		\ Physical address of boot ROM
h#   10.0000   constant /rom		\ Size of boot ROM
rom-pa  h# 1.0000 +  constant dropin-base
[then]

h#    8.0000   constant dropin-size

dropin-base h# 20 +  constant ResetBase	\ Location of "reset" dropin in ROM

h# 1bc0.0000 value    fw-pa     \ Changed in probemem.fth
h#   20.0000 constant /fw-ram
h#   40.0000 constant /fw-area
[then]

h#  80.0000 constant def-load-base      \ Convenient for initrd

\ The heap starts at RAMtop, which on this system is "fw-pa /fw-ram +"

\ We leave some memory in the /memory available list above the heap
\ for DMA allocation by the sound and USB driver.  OFW's normal memory
\ usage thus fits in one 4M page-directory mapping region.

h#  18.0000 constant heap-size

h# 900.0000 constant dma-size
fw-pa dma-size - constant dma-base

h# f.0000 constant suspend-base      \ In the DOS hole
h# f.0008 constant resume-entry
h# f.1000 constant resume-data

\ If you change these, also change {g/l}xmsrs.fth and {g/l}xearly.fth
h# fd00.0000 constant fw-map-base
h# ffc0.0000 constant fw-map-limit

h# d000.0000 constant fb-pci-base
h# f000.0000 constant gfx-pci-base
h# fe01.a000 constant ohci-pci-base
h# fe01.b000 constant ehci-pci-base
h# fe02.4000 constant sd-pci-base
h# fe02.8000 constant camera-pci-base
h# fec0.0000 constant ioapic-mmio-base
h# fed0.0000 constant hpet-mmio-base
h# fed3.0000 constant spi-mmio-base
h# fed4.0000 constant wdt-mmio-bast

h#      4000 constant acpi-io-base
h#      4100 constant smbus-io-base

h# 9.fc00 constant 'ebda  \ Extended BIOS Data Area, which we co-opt for our real-mode workspace

h# e0000 constant rsdp-adr
h# e0040 constant rsdt-adr
h# e0080 constant fadt-adr
h# e0180 constant facs-adr
h# e01c0 constant dbgp-adr
h# fc000 constant dsdt-adr
h# fd000 constant ssdt-adr

h#  3e.0000 constant inflate-base
h#  30.0000 constant workspace

fload ${BP}/cpu/x86/pc/virtaddr.fth


\ LICENSE_BEGIN
\ Copyright (c) 2009 FirmWorks
\ 
\ Permission is hereby granted, free of charge, to any person obtaining
\ a copy of this software and associated documentation files (the
\ "Software"), to deal in the Software without restriction, including
\ without limitation the rights to use, copy, modify, merge, publish,
\ distribute, sublicense, and/or sell copies of the Software, and to
\ permit persons to whom the Software is furnished to do so, subject to
\ the following conditions:
\ 
\ The above copyright notice and this permission notice shall be
\ included in all copies or substantial portions of the Software.
\ 
\ THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
\ EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
\ MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
\ NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
\ LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
\ OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
\ WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
\
\ LICENSE_END
