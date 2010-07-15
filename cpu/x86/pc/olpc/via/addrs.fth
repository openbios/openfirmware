\ See license at end of file
purpose: Establish address and I/O configuration definitions

[ifdef] rom-loaded
[ifdef] demo-board
h# fff8.0000   constant rom-pa		\ Physical address of boot ROM
h#    8.0000   constant /rom		\ Size of boot ROM
\ h# fffe.0000   constant rom-pa	\ Physical address of boot ROM
\ h#    2.0000   constant /rom		\ Size of boot ROM
rom-pa         constant dropin-base
[then]
[ifdef] xo-board
h# fff0.0000   constant rom-pa		\ Physical address of boot ROM
h#   10.0000   constant /rom		\ Size of boot ROM
rom-pa  h# 1.0000 +  constant dropin-base
[then]

h#    8.0000   constant dropin-size

dropin-base h# 20 +  constant ResetBase	\ Location of "reset" dropin in ROM

0 value  fw-pa     \ Set in probemem.fth
\ h# 3b00.0000 value    fw-pa     \ Changed in probemem.fth
\ h# 3bc0.0000 value    fw-pa     \ Changed in probemem.fth
\ h# 1bc0.0000 value    fw-pa     \ Changed in probemem.fth
\ h#  bc0.0000 value    fw-pa     \ Changed in probemem.fth
h#   20.0000 constant /fw-ram
[then]

h# 100.0000 constant def-load-base      \ Convenient for initrd

\ The heap starts at RAMtop, which on this system is "fw-pa /fw-ram +"

\ We leave some memory in the /memory available list above the heap
\ for DMA allocation by the sound and USB driver.  OFW's normal memory
\ usage thus fits in one 4M page-directory mapping region.

h#  18.0000 constant heap-size

\ h# 40.0000 constant /dma-extra          \ In case the firmware region isn't enough
h# 1000.0000 constant /dma-extra          \ In case the firmware region isn't enough
/fw-ram /dma-extra + constant dma-size  \ We let the DMA area overlap the FW area
\ fw-pa /dma-extra - constant dma-base
0 value dma-base                        \ Set in probemem.fth

h# f.0000 constant suspend-base      \ In the DOS hole
h# f.1000 constant resume-data

\ If you change these, also change {g/l}xmsrs.fth and {g/l}xearly.fth
h# fd00.0000 constant fw-map-base
h# ffc0.0000 constant fw-map-limit

h# 8fff.0000 constant hdac-pci-base  \ Temporary for use during early startup

h# d000.0000 constant fb-pci-base
h# f000.0000 constant gfx-pci-base
\ h# fe01.a000 constant ohci-pci-base
\ h# fe01.b000 constant ehci-pci-base
\ h# fe02.4000 constant sd-pci-base
\ h# fe02.8000 constant camera-pci-base
h# fed0.0000 constant hpet-mmio-base
h# fed3.0000 constant spi-mmio-base
h# fed4.0000 constant spi0-mmio-base
h# fed5.0000 constant wdt-mmio-base
h# fec0.0000 constant io-apic-mmio-base
h# fee0.0000 constant apic-mmio-base

h#   400 constant acpi-io-base
h#   500 constant smbus-io-base
h#  4080 constant uart-dma-io-base

h# e0000 constant rsdp-adr
h# e0040 constant rsdt-adr
h# e0080 constant fadt-adr
h# e0180 constant facs-adr
h# e01c0 constant dbgp-adr
h# e0200 constant madt-adr  \ MADT is 5a bytes long
h# e0280 constant hpet-adr

h# e1000 constant smm-sp0
h# e1400 constant smm-rp0
h# e1800 constant smm-gdt

h# fc000 constant dsdt-adr   \ Don't change this address; Windows OEM Activation depends on it
h# fd000 constant ssdt-adr

h# ffc00 constant smbios-adr
h# fff00 constant wake-adr   \ Needs to be at least h# 32 bytes - used in acpi.fth
h# fff40 constant rm-buf     \ 8-byte buffer used by BIOS INT 15 AH=C0 for returning config info
h# fff48 constant video-mode-adr    \ Saves display mode for resume code
h# fff4c constant windows-mode-adr  \ Flag to control Windows-specific resume fixups
\ h# fff50 Next address available for resume variables

h# fff80 constant 'int10-dispatch

h#  4fff constant native-mode#

h#  3e.0000 constant inflate-base
h#  30.0000 constant workspace

h# 7d constant cmos-alarm-day	\ Offset of day alarm in CMOS
h# 7e constant cmos-alarm-month	\ Offset of month alarm in CMOS
h# 7f constant cmos-century	\ Offset of century byte in CMOS

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
