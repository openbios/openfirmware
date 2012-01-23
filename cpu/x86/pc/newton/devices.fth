\ See license at end of file
purpose: Load device drivers according to configuration definitions

0 0  " "  " /"  begin-package
   fload ${BP}/cpu/x86/pc/mappci.fth	\ Map PCI to root
   fload ${BP}/dev/pcibus.fth		\ Generic PCI bus package

   0 0  " addresses-preassigned" property
[then]

   fload ${BP}/cpu/x86/pc/newton/pcinode.fth	\ System-specific words for PCI
end-package
stand-init: PCI host bridge
   " /pci" " init" execute-device-method drop
;

fload ${BP}/dev/pciprobe.fth		\ Generic PCI probing

\ Use the CPU chip's Time Stamp Counter for timing
fload ${BP}/cpu/x86/tsc.fth

0 0  " "  " /" begin-package
   fload ${BP}/cpu/x86/pc/isabus.fth	\ ISA Bus Bridge under root node
end-package

dev /interrupt-controller
h# 20 to vector-base0
h# 28 to vector-base1
device-end

fload ${BP}/dev/olpc/spiflash/flashif.fth   \ Generic FLASH interface

fload ${BP}/dev/olpc/spiflash/memflash.fth  \ Memory-mapped FLASH read access

warning @ warning off
: stand-init-io  stand-init-io  h# fff8.0000 to flash-base  ;
warning !

fload ${BP}/ofw/fs/cbfs.fth     \ Coreboot ROM filesystem

h# 80.0000 to /flash   \ Entire device
\ Create the top-level device node to access the entire boot FLASH device
0 0  " ff800000"  " /" begin-package
   " flash" device-name

   h# 80.0000 value /device
   h# 80.0000 constant /device-phys
   my-address my-space /device-phys reg
   fload ${BP}/dev/flashpkg.fth
   fload ${BP}/dev/flashwrite.fth
end-package

\ XXX later
\ devalias cbfs /flash//cbfs-file-system

\ Create a node below the top-level FLASH node to accessing the portion
\ containing the dropin modules
0 0  " 200000"  " /flash" begin-package
   " dropins" device-name

   h# 100000 constant /device
   fload ${BP}/dev/subrange.fth
end-package

devalias dropins /dropins

\ Create a node below the top-level FLASH node to accessing the portion
\ containing the dropin modules
0 0  " 780000"  " /flash" begin-package
   " coreboot" device-name

   h# 080000 constant /device
   fload ${BP}/dev/subrange.fth
end-package

devalias coreboot /coreboot

0 [if]
\ This really should be a subrange of /flash
0 0  dropin-base <# u#s u#>  " /" begin-package
   " dropinram" device-name

   dropin-size
   dup value /device
   constant /device-phys
   my-address my-space /device-phys reg
   fload ${BP}/dev/flashpkg.fth
end-package

devalias dropins /dropinram
[then]

\ [else]
\ patch /l /di-header first-header
\ patch /l /di-header first-header
\ \ devalias dropins cbfs:fallback\payload
\ devalias dropins /flash
\ [then]

\ Create a pseudo-device that presents the dropin modules as a filesystem.
fload ${BP}/ofw/fs/dropinfs.fth

\ This devalias lets us say, for example, "dir rom:"
devalias rom     /dropin-fs

fload ${BP}/cpu/x86/forthint.fth	\ Low-level interrupt handling code
fload ${BP}/dev/isa/irq.fth		\ ISA interrupt dispatcher
fload ${BP}/cpu/x86/pc/isatick.fth		\ Use ISA timer as the alarm tick timer
fload ${BP}/cpu/x86/pc/olpc/timertest.fth  \ Selftest for PIT timer

fload ${BP}/dev/pci/isaall.fth
devalias mouse /usb/mouse

fload ${BP}/cpu/x86/pc/tsccal1.fth

fload ${BP}/dev/null2.fth

[ifdef] serial-console
[ifdef] resident-packages
support-package: 16550
fload ${BP}/dev/16550pkg/16550.fth  \ Serial port support package
end-support-package
[then]

0 0  hex mem-uart-base (u.)  " /" begin-package
   4 encode-int  0 encode-int encode+    " interrupts" property
   fload ${BP}/dev/16550pkg/ns16550p.fth
   d# 64,000,000  " clock-frequency"  integer-property
   fload ${BP}/dev/16550pkg/isa-int.fth
end-package
devalias com1 /serial:115200
: com1  ( -- adr len )  " com1"  ;
' com1 to fallback-device
[else]
: devnull  ( -- adr len )  " /null"  ;
' devnull to fallback-device
[then]

0 0  " i70"  " /isa" begin-package   	\ Real-time clock node
   fload ${BP}/dev/ds1385r.fth
   8 encode-int  0 encode-int encode+    " interrupts" property
   2 encode-int " device#" property
end-package
stand-init: RTC
   " /rtc" open-dev  clock-node !
;

fload ${BP}/cpu/x86/pc/cpunode.fth
fload ${BP}/cpu/x86/k6cputest.fth       \ Burnin test for K6 CPU
dev /cpu  1 to default#passes  dend

[ifdef] use-ega
0 0 " " " /" begin-package
   fload ${BP}/dev/egatext.fth
end-package
devalias screen /ega-text
[then]

[ifdef] use-vesa
fload ${BP}/dev/video/controlr/vesa.fth
devalias screen /display	\ Explicit, because it's not probed
[then]

[ifdef] use-pineview
0 0  " 2,0"  " /pci" begin-package
   " display" name
   fload ${BP}/dev/intel/graphics/pineview.fth
   alias  /scanline  bytes/line
   fload ${BP}/dev/video/common/rectangle16.fth
   alias color! 4drop
end-package
devalias screen /pci/display@2,0	\ Explicit, because it's not probed
[then]

\ Create the alias unless it already exists
: $?devalias  ( alias$ value$ -- )
   2over  not-alias?  if  $devalias exit  then  ( alias$ value$ alias$ )
   2drop 4drop
;

: report-disk  ( -- )
   " /pci-ide" locate-device  0=  if
      drop
      " disk" " /pci-ide/ide@0/disk@0" $devalias
      " c"    " /pci-ide/ide@0/disk@0" $devalias
      " d"    " /pci-ide/ide@0/disk@1" $devalias
      " e"    " /pci-ide/ide@1/disk@0" $devalias
      " f"    " /pci-ide/ide@1/disk@1" $devalias
      exit
   then
   " /ide" locate-device  0=  if
      drop
      " disk" " /ide@1f0/disk@0" $devalias
      " c"    " /ide@1f0/disk@0" $devalias
      " d"    " /ide@170/disk@1" $devalias
      " e"    " /ide@1f0/disk@0" $devalias
      " f"    " /ide@170/disk@2" $devalias
      exit
   then
;

fload ${BP}/cpu/x86/inoutstr.fth	\ Multiple I/O port read/write

[ifdef] serial-console
fload ${BP}/dev/isa/diaguart.fth	\ ISA COM port driver
fload ${BP}/forth/lib/sysuart.fth	\ Use UART for key and emit
[else]
fload ${BP}/dev/nulluart.fth		\ Null UART driver
[then]
[ifdef] use-ega
fload ${BP}/cpu/x86/pc/egauart.fth	\ Output also to EGA
[then]

0 value keyboard-ih
0 value screen-ih

fload ${BP}/ofw/core/muxdev.fth		\ I/O collection/distribution device

fload ${BP}/dev/olpc/spiflash/spiif.fth     \ Generic low-level SPI bus access
fload ${BP}/dev/intel/spi.fth               \ SPI FLASH programming

\ XXX we probably need to use the port CF9 method
fload ${BP}/cpu/x86/pc/reset.fth	\ reset-all

\ fload ${BP}/dev/acpiec.fth              \ Access to ACPI EC internal variables
\ fload ${BP}/cpu/x86/pc/newton/ec.fth      \ Battery, AC, CPU temperature, Fan controls

: ?enough-power  ;                      \ Implement based on AC presence and battery status

fload ${BP}/cpu/x86/pc/newton/spiui.fth   \ User interface for SPI FLASH programming
: urom  ( -- )  " flash! u:\stumpy.rom" evaluate  ;
: netrom  ( -- )  " flash! http:\\192.168.200.200\stumpy.rom" evaluate  ;

\ LICENSE_BEGIN
\ Copyright (c) 2011 FirmWorks
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
