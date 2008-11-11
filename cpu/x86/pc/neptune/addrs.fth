\ See license at end of file
purpose: Establish address and I/O configuration definitions

h# fff0.0000   constant rom-pa		\ Physical address of boot ROM
h#   10.0000   constant /rom		\ Size of boot ROM

h#    0.0000   constant config-vars-offset
h#    0.1000   constant mfg-data-offset
h#    8.0000   constant dropin-offset
rom-pa dropin-offset +  constant dropin-base
h#    8.0000   constant dropin-size

dropin-base h# 20 +  constant ResetBase	\ Location of "reset" dropin in ROM

h# ffe0.0000   constant rom1-pa		\ Secondary ROM (FLASH) on dongle

h# ff80.0000   constant lpc-pa		\ Extra stuff decoded by LPC FLASH chips
h#   60.0000   constant /lpc		\ Space to reserve for LPC stuff

h# ffbc.0100   constant lpc-gpi0-pa	\ GPI port for LPC FLASH 0
h# ffac.0100   constant lpc-gpi1-pa	\ GPI port for LPC FLASH 1

\ Firmware reflash parameters
h# 8.0000 constant fw-offset       \ Where to start reflashing
h# 8.0000 constant /fw-reflash     \ Expected size of a reflash image
h#    -30 constant fw-crc-offset   \ Location of firmware CRC (- is from end)

h#  1c0.0000 constant fw-pa
h#   20.0000 constant /fw-ram

h#  80.0000 constant def-load-base      \ Convenient for initrd

\ The heap starts at RAMtop, which on this system is "fw-pa /fw-ram +"

\ We leave some memory in the /memory available list above the heap
\ for DMA allocation by the sound and USB driver.  OFW's normal memory
\ usage thus fits in one 4M page-directory mapping region.

h#  18.0000 constant heap-size

h#  800.0000 constant dma-base
h# 7800.0000 constant dma-size

h# f.0000 constant suspend-base      \ In the DOS hole
h# f.0008 constant resume-entry
h# f.0800 constant resume-data

h#   80.0000 constant fb-size

h# fd00.0000 constant fb-pci-base
h# fe00.0000 constant gp-pci-base
h# fe00.4000 constant dc-pci-base
h# fe00.8000 constant vp-pci-base
h# fe00.c000 constant vip-pci-base
h# fe01.0000 constant aes-pci-base
h# fe01.a000 constant ohci-pci-base
h# fe01.b000 constant ehci-pci-base
h# fe02.0000 constant nand-pci-base
h# fe02.4000 constant sd-pci-base
h# fe02.8000 constant camera-pci-base
h# fe02.c000 constant uoc-pci-base

\ These two are used when running in physical mode, to delimit
\ a set of v=p mappings that we create just before invoking Linux.
h# fd00.0000 constant fw-map-base
h# ffc0.0000 constant fw-map-limit

fload ${BP}/cpu/x86/pc/virtaddr.fth

\ Override the usual fw-virt-base setting.
\ There's some LPC stuff in the way of the normal OFW virtual address ff80.0000
\ And if we are running in physical mode, we use an MSR to double-map some memory up high

h# ff40.0000 to fw-virt-base
h#   40.0000 to fw-virt-size

\ LICENSE_BEGIN
\ Copyright (c) 2006 FirmWorks
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
