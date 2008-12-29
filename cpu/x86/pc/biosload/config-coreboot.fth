purpose: Configuration setting for OFW as a Coreboot payload under QEMU
\ See license at end of file

\ pc-linux sets the default values for the configuration variables
\ that control the boot device to boot vmlinuz from drive A.
create pc-linux

\ - ELF format (no pheader) - ROM - Coreboot direct
create coreboot-loaded
create coreboot-qemu       \ Coreboot QEMU variant

\ Coreboot+OFW under QEMU currently does not do VGA right
create serial-console

\ In virtual mode, OFW runs with the MMU on.  The advantages are
\ that OFW can automatically locate itself out of the way, at the
\ top of physical memory, it can dynamically allocate exactly as
\ much physical memory as it needs, and it can remain alive after
\ the OS starts.  The disadvantage is that it is more confusing -
\ you always have to be aware of the distinction between virtual
\ and physical addresses.

\ If you use virtual mode for Linux, you can debug past
\ the point where Linux starts using the MMU.  It is not strictly
\ necessary to use virtual mode if you just want to boot Linux
\ and then have OFW disappear.

\ create virtual-mode

\ linux-support includes a bzImage file-format handler
\ and ext2 filesystem support

create linux-support

\ create pseudo-nvram
create resident-packages
create addresses-assigned  \ Don't reassign PCI addresses
create use-root-isa
create use-isa-ide
create use-ega
create use-elf
create use-ne2000
create use-watch-all
create use-null-nvram
create no-floppy-node

fload ${BP}/cpu/x86/pc/biosload/addrs.fth

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
