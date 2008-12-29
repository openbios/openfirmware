\ See license at end of file
purpose: Establish configuration definitions

create use-lx
create lx-devel

\ --- The environment that "boots" us ---
\ - Image Format - Example Media - previous stage bootloader

\ - OBMD format - ROM - direct boot from ROM
create rom-loaded

create virtual-mode
create addresses-assigned  \ Define if base addresses are already assigned
\ create serial-console      \ Define to default to serial port for console
create pc
create linux-support
create jffs2-support
create use-elf

\ create use-timestamp-counter \ Use CPU's timestamp counter for timing ...
			\ ... this is worthwhile if your CPU has one.

create resident-packages
\ create use-watch-all
\ create use-root-isa
create no-floppy-node
create use-pci-isa

\ create use-null-nvram  \ Don't store configuration variables
create use-flash-nvram  \ Store configuration variables in SPI FLASH

fload ${BP}/cpu/x86/pc/lxdevel/addrs.fth

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
