\ See license at end of file
purpose: Establish configuration definitions

\ create pc		\ Demo version for generic PC
\ create pc-linux	\ Demo version for generic PC and Linux
\ create pc-serial	\ Demo version for generic PC

\ --- The environment that "boots" OFW ---
\ - Image Format - Example Media - previous stage bootloader

create rom-loaded

\ debug-startup enables early-startup reports on COM1

create debug-startup

\ serial-console makes COM1 the default OFW console device

\ create serial-console

\ resident-packages causes a lot of support packages to be
\ precompiled into the Forth dictionary, instead of being
\ demand-loaded from dropin modules

create resident-packages

\ addresses-assigned suppresses PCI address autoconfiguration.
\ It is useful when OFW is loaded by lower-level firmware that
\ has already assigned PCI addresses.

\ create addresses-assigned

\ use-root-isa puts the ISA bus device node directly under the
\ device tree root (/isa), instead of under the PCI node (/pci/isa).
\ For modern machines, it is usually best not to define use-root-isa .

\ create use-root-isa

\ use-pci-isa puts the ISA bus device node under the PCI node (/pci/isa),
\ which is usually accurate for modern machines.

create use-pci-isa

\ use-timestamp-counter makes low-level timing operations use the
\ timestamp counter (TSC) register.  This is a good thing for modern
\ CPUs that have that register.

create use-timestamp-counter

\ use-isa-ide enables support for a legacy IDE controller accessed
\ directly via I/O ports.  It is usually better to use the PCI IDE
\ controller support via a dynamically-bound FCode driver.

\ create use-isa-ide

\ use-ega enables support for an OFW console that uses EGA text-mode 
\ This typically only works when OFW is loaded on top of a conventional
\ BIOS, because it assumes that the display device is already in the
\ correct mode and OFW can just start writing to the text mode framebuffer.

\ create use-ega

\ use-vga enables support for an OFW console on a legacy VGA device,
\ with OFW initializing the VGA registers to establish the mode.
\ This does not work very well.  It is better to bind the "super driver"
\ (dev/video/build/video.fc) to the PCI display class code.

\ create use-vga

\ use-elf enables support for loading and debugging ELF binaries

create use-elf

\ use-ne2000 enables support for a legacy ISA bus NE2000 network interface

\ create use-ne2000

\ use-watch-all enables the "watch-all" diagnostic command that
\ exercises a variety of common I/O devices.

\ create use-watch-all

\ use-null-nvram installs stub implementations of non-volatile
\ access routines, thus disabling persistent storage of OFW
\ configuration variables.  Generic PCs generally have no good
\ place to store those configuration variables, as the CMOS RAM
\ is too small for typical string-valued variables.

create use-null-nvram

\ pseudo-nvram installs non-volatile access routines that use
\ a fixed-name file on drive A to store the data.  It is a
\ reasonable way to enable configuration variable storage
\ when running OFW under an emulator where such a drive is
\ "always" present, but it is not particularly useful for
\ real hardware platforms.

\ create pseudo-nvram


\ no-floppy-node prevents the creation of a floppy disk device node
\ among the set of legacy ISA devices.  Modern PCs rarely have
\ floppy drives.

\ create no-floppy-node

\ In virtual mode, OFW runs with the MMU on.  The advantages are
\ that OFW can automatically locate itself out of the way, at the
\ top of physical memory, it can dynamically allocate exactly as
\ much physical memory as it needs, and it can remain alive after
\ the OS starts.  The disadvantage is that it is more confusing -
\ you always have to be aware of the distinction between virtual
\ and physical addresses.

\ If you use virtual mode for Linux, you can debug past the point
\ where Linux starts using the MMU.  It is not strictly
\ necessary to use virtual mode if you just want to boot Linux
\ and then have OFW disappear.

create virtual-mode

\ linux-support enables support for ext2 filesystems and bzimage format

create linux-support


\ cpu/x86/pc/<platform>/addrs.fth configures the basic system
\ address assignment.

fload ${BP}/cpu/x86/pc/emu/addrs.fth

\ LICENSE_BEGIN
\ Copyright (c) 2008 FirmWorks
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
