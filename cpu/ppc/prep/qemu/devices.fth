purpose: Load file for devices of QEMU -M prep
copyright: Copyright 1999 FirmWorks Inc.  All Rights Reserved.

fload ${BP}/cpu/ppc/prep/qemu/pcinode.fth

: unswizzle-move  ( arc dest len -- )  move  ;

0 0  " fff00000"  " /" begin-package
   " flash" device-name
   h# 10.0000 dup constant /device constant /device-phys
   my-address my-space /device reg
   fload ${BP}/dev/flashpkg.fth

end-package

\ Create the /ISA node in the device tree, and load the ISA bridge code.
\ Usually this includes the dma controller, interrupt controller, and timer.
0 0  " b"  " /pci" begin-package
fload ${BP}/dev/via/vt82c586.fth			\ ISA node
end-package

fload ${BP}/dev/isa/irq.fth

support-package: 16550
fload ${BP}/dev/16550pkg/16550.fth  \ Serial port support package
end-support-package

\ Super I/O support.
\ Usually includes serial, parallel, floppy, and keyboard.
\ The 87308 also has gpio and power control functions.
fload ${BP}/dev/isa/pc87307.fth			\ SuperI/O

\ QEMU doesn't have rtc/nvram on port 70
" /rtc"  find-package  if  delete-package  then

0 0 " i74" " /isa" begin-package	 \ RTC node
   fload ${BP}/dev/m48t559.fth
end-package

fload ${BP}/cpu/ppc/prep/qemu/fixednv.fth  \ Offsets of fixed regions of NVRAM 


fload ${BP}/cpu/ppc/prep/qemu/macaddr.fth

0 0  " i74"  " /pci/isa" begin-package	  \ NVRAM node
fload ${BP}/dev/ds1385n.fth

" mk48t18-nvram" encode-string
" ds1385-nvram"  encode-string encode+
" pnpPNP,8"      encode-string encode+
" compatible" property

env-end-offset to /nvram
end-package
stand-init: NVRAM
   " /nvram" open-dev  to nvram-node
    init-config-vars
;

0 0 " b,1" " /pci" begin-package
   fload ${BP}/dev/ide/pcilintf.fth
   fload ${BP}/dev/ide/generic.fth
   fload ${BP}/dev/ide/onelevel.fth
end-package
\ One-level IDE

\ Mark all ISA devices as built-in.
" /isa" find-device  mark-builtin-all  device-end

