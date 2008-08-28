\ See license at end of file
purpose: Establish configuration definitions

create neptune

\ create debug-reset
\ create debug-startup

\ --- The environment that "boots" us ---
\ - Image Format - Example Media - previous stage bootloader

\ - OBMD format - ROM - direct boot from ROM
create rom-loaded

\ - ELF format (no pheader) - ROM - LinuxBIOS direct
\ create linuxbios-loaded

\ - Linux kernel format - USB Key w/ FAT FS - LinuxBIOS w/ stripped Linux payload
\ create bzimage-loaded

\ - ELF format w/ Multiboot signature - various - GRUB
\ create grub-loaded

\ - (Syslinux) COM32 format - USB Key w/ FAT FS - Syslinux
\ create syslinux-loaded


create virtual-mode
create addresses-assigned  \ Define if base addresses are already assigned
create serial-console      \ Define to default to serial port for console
create pc
create linux-support
create jffs2-support
create use-elf

create lx-pll-autoconfig   \ enable pll autoconfiguration from bootstrap pin
create use-memtest86

\ create use-timestamp-counter \ Use CPU's timestamp counter for timing ...
			\ ... this is worthwhile if your CPU has one.

create resident-packages
\ create use-watch-all
create use-root-isa   \ If defined, isa node is in the devtree root, not under /pci
create no-floppy-node
\ create no-com2-node
create no-lpt-node
create use-pci-isa
create basic-isa
create isa-dma-only
\ create use-ega
\ create save-msrs

\ create use-null-nvram  \ Don't store configuration variables
create use-flash-nvram  \ Store configuration variables in firmware FLASH

fload ${BP}/cpu/x86/pc/neptune/addrs.fth

\ LICENSE_BEGIN
\ Copyright (c) 2006 FirmWorks
\ Copyright (c) 2008 Dave Srl
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
