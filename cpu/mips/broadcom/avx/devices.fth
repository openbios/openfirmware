purpose: Load device drivers for AVX settop box
copyright: Copyright 2001 Firmworks  All Rights Reserved

hex

create use-flash-nvram

fload ${BP}/cpu/mips/broadcom/avx/pcicfg.fth

0 0  " "  " /"  begin-package
   fload ${BP}/cpu/mips/broadcom/avx/mappci.fth		\ Map PCI to root
   fload ${BP}/dev/pcibus.fth				\ Generic PCI bus package
   fload ${BP}/cpu/mips/broadcom/avx/pcinode.fth	\ System-specific words for PCI
end-package
stand-init: PCI host bridge
   " /pci" " init" execute-device-method drop
;

fload ${BP}/dev/pciprobe.fth			\ Generic PCI probing

fload ${BP}/dev/isa/irq.fth

0 0  uart-pa kseg1 + <# u#s u#> " /" begin-package
   4 encode-int " interrupts" property
   fload ${BP}/dev/16550pkg/ns16550p.fth
   d# 14318000 encode-int " clock-frequency" property
   fload ${BP}/dev/16550pkg/isa-int.fth
end-package
: com1  ( -- adr len )  " com1"  ;  ' com1 to fallback-device
: use-com1  ( -- )
   " com1" " input-device" $setenv
   " com1" " output-device" $setenv
;

0 0  uart2-base <# u#s u#> " /" begin-package
   4 encode-int " interrupts" property
   fload ${BP}/dev/16550pkg/ns16550p.fth
   d# 14318000 encode-int " clock-frequency" property
   fload ${BP}/dev/16550pkg/isa-int.fth
end-package
: com2  ( -- adr len )  " com2"  ;

support-package: 16550
fload ${BP}/dev/16550pkg/16550.fth  \ Serial port support package
end-support-package

fload ${BP}/dev/flashpkg.fth
fload ${BP}/dev/am29lv008b.fth			\ Low-level FLASH programming driver
fload ${BP}/cpu/mips/broadcom/loadvpd.fth	\ VPD manager
fload ${BP}/cpu/mips/broadcom/avx/flash.fth	\ Platform-specific FLASH interface

: ll  ( idx -- )  dup f and 0=  if  cr u. ."   "  else  drop  then  ;
: dump-pci  ( cfg-adr len -- )  bounds do i ll i config-l@ 8 u.r space 4  +loop  ;
