purpose: Load device drivers for Bonito 
copyright: Copyright 2001 Firmworks  All Rights Reserved

hex

fload ${BP}/cpu/mips/bonito/pcicfg.fth

0 0  " "  " /"  begin-package
   fload ${BP}/cpu/mips/bonito/mappci.fth	\ Map PCI to root
   fload ${BP}/dev/pcibus.fth			\ Generic PCI bus package
   fload ${BP}/cpu/mips/bonito/pcinode.fth	\ System-specific words for PCI
end-package
stand-init: PCI host bridge
   " /pci" " init" execute-device-method drop
;

fload ${BP}/dev/pciprobe.fth			\ Generic PCI probing

\ Create the /ISA node in the device tree, and load the ISA bridge code.
\ Usually this includes the dma controller, interrupt controller, and timer.
0 0  " 1c"  " /pci" begin-package
fload ${BP}/dev/fw82371.fth			\ ISA node
end-package

fload ${BP}/dev/isa/irq.fth

support-package: 16550
fload ${BP}/dev/16550pkg/16550.fth  \ Serial port support package
end-support-package

\ Super I/O support.
\ Usually includes serial, parallel, floppy, and keyboard.
\ The 87308 also has gpio and power control functions.
fload ${BP}/dev/pc87307.fth			\ SuperI/O

0 0 dropin-base <# u#s u#> " /" begin-package
   " flash" device-name

   /rom value /device
   my-address my-space /device reg
   fload ${BP}/dev/flashpkg.fth
end-package

" rom"  dropin-base <# u#s " /flash@" hold$ u#>  $devalias

fload ${BP}/dev/flashpkg.fth
fload ${BP}/dev/amd29fxx.fth		\ Low-level FLASH programming driver
fload ${BP}/dev/at29c020.fth		\ Low-level FLASH programming driver
fload ${BP}/cpu/mips/bonito/flash.fth	\ Platform-specific FLASH interface

dev /rtc
   fload ${BP}/cpu/mips/bonito/nvram.fth
device-end

stand-init: NVRAM
   " /rtc" open-dev  to nvram-node
   nvram-node 0=  if
      ." The configuration EEPROM is not working" cr
   then
   ['] init-config-vars catch drop
;

0 0 ide0-pa <# u#s u#>  " /" begin-package
   fload ${BP}/dev/ide/bonito.fth
   fload ${BP}/dev/ide/onelevel.fth
end-package

h# f800 constant ide-dma-bar

0 0 " i1f0" " /isa" begin-package	\ Master IDE
   create include-secondary-ide
   fload ${BP}/dev/ide/isaintf.fth
   fload ${BP}/dev/ide/generic.fth
   2 to max#drives
   fload ${BP}/dev/ide/onelevel.fth
end-package

: init-ide  ( -- )
   ide-dma-bar h# e120 config-l!	\ Set I/O port
   h# 8022 h# e140 config-w!		\ Enable master IDE decoding
   h# 8022 h# e142 config-w!		\ Enable secondary IDE decoding
   h#    5 h# e104 config-w!		\ Enable I/O and bus mastering
;
stand-init: Enable IDE on Algorithmics
   init-ide
;
