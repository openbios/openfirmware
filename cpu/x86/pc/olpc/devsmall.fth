\ See license at end of file
purpose: Load device drivers according to configuration definitions

: gx?  ( -- flag )  h# 4c000017 msr@ drop  4 rshift  2 =  ;
: lx?  ( -- flag )  h# 4c000017 msr@ drop  4 rshift  3 =  ;

fload ${BP}/cpu/x86/pc/isaio.fth

fload ${BP}/cpu/x86/pc/olpc/vsapci.fth	\ PCI configuration access with some hacks

0 0  " "  " /"  begin-package
   fload ${BP}/cpu/x86/pc/mappci.fth	\ Map PCI to root
   fload ${BP}/dev/pcibus.fth		\ Generic PCI bus package
   fload ${BP}/cpu/x86/pc/olpc/pcinode.fth	\ System-specific words for PCI
end-package
stand-init: PCI host bridge
   " /pci" " init" execute-device-method drop
;

fload ${BP}/dev/pciprobe.fth		\ Generic PCI probing

\ Use the CPU chip's Time Stamp Counter for timing; it does just what we want
fload ${BP}/cpu/x86/tsc.fth

stand-init:
   d# 1000 rounded-/ dup  to ms-factor                  ( cpu-clock-khz )
   d# 1000 rounded-/      to us-factor                  ( )
;

[ifdef] use-root-isa
0 0  " "  " /" begin-package
   fload ${BP}/cpu/x86/pc/isabus.fth	\ ISA Bus Bridge under root node
end-package
[then]

[ifdef] use-pci-isa

[ifdef] addresses-assigned
[ifdef] use-pci-isa
\ This must precede isamisc.fth in the load file, to execute it first
fload ${BP}/cpu/x86/pc/moveisa.fth
[then]
[then]

0 0  " 0"  " /pci" begin-package
   fload ${BP}/dev/pci/isa.fth		\ ISA bus bridge under PCI node
   fload ${BP}/dev/pci/isamisc.fth
end-package

[then]

1 [if]
dev /interrupt-controller
h# 20 to vector-base0
h# 28 to vector-base1
device-end

warning @ warning off
: probe-pci  ( -- )
   probe-pci
   " /pci" " make-interrupt-map" execute-device-method drop
;
warning !

0 0  dropin-base <# u#s u#>  " /" begin-package
   " flash" device-name

   h# 10.0000
   dup value /device
   constant /device-phys
   my-address my-space /device-phys reg
   fload ${BP}/cpu/x86/pc/flashpkg.fth

   : init  ( comp$ /device -- )
      to /device  2>r
      0 0 encode-bytes
      2r> encode-string encode+
      " rom" encode-string encode+
      " compatible" property
[ifdef] enable-flash-select      
      /device /device-phys <>  if  enable-flash-select  then
[then]
   ;

end-package
" rom"  dropin-base <# u#s " /flash@" hold$ u#>  $devalias

: foo-save-state  here 5 +  ;  ' foo-save-state to save-state

fload ${BP}/cpu/x86/forthint.fth	\ Low-level interrupt handling code
fload ${BP}/dev/isa/irq.fth		\ ISA interrupt dispatcher
fload ${BP}/cpu/x86/pc/isatick.fth	        \ Use ISA timer as the alarm tick timer

[ifdef] resident-packages
support-package: 16550
fload ${BP}/dev/16550pkg/16550.fth  \ Serial port support package
end-support-package
[then]

fload ${BP}/dev/pci/isaall.fth
devalias com1 /isa/serial@i3f8:115200
devalias sd /sd/disk


dev /8042
   patch false ctlr-selftest open
device-end

0 [if]
0 0  " i70"  " /isa" begin-package   	\ Real-time clock node
   fload ${BP}/dev/ds1385r.fth
   8 encode-int  0 encode-int encode+    " interrupts" property
   2 encode-int " device#" property
end-package
[then]

fload ${BP}/cpu/x86/pc/cpunode.fth

fload ${BP}/cpu/x86/pc/olpc/cmos.fth     \ CMOS RAM indices are 1f..ff , above RTC

[if] 0
[ifdef] use-null-nvram
fload ${BP}/cpu/x86/pc/nullnv.fth
stand-init: Null-NVRAM
   " /null-nvram" open-dev  to nvram-node
   ['] init-config-vars catch drop
;
[then]
[then]

fload ${BP}/cpu/x86/inoutstr.fth	\ Multiple I/O port read/write
fload ${BP}/dev/isa/diaguart.fth	\ ISA COM port driver
\ : inituarts ascii G uemit  ascii o uemit  ;  \ They are already on

h# 3f8 is uart-base
fload ${BP}/forth/lib/sysuart.fth	\ Use UART for key and emit

[ifndef] save-flash
: save-flash ;
: restore-flash ;
[then]

\needs md5init  fload ${BP}/ofw/ppp/md5.fth                \ MD5 hash

fload ${BP}/dev/olpc/kb3700/ecspi.fth      \ EC chip SPI FLASH access

warning @ warning off
: stand-init  stand-init  h# fff0.0000 to flash-base  ;
warning !

fload ${BP}/dev/olpc/kb3700/ecserial.fth   \ Serial access to EC chip

fload ${BP}/dev/olpc/kb3700/ecio.fth       \ I/O space access to EC chip

fload ${BP}/cpu/x86/pc/olpc/boardrev.fth   \ Board revision decoding

fload ${BP}/cpu/x86/pc/olpc/mfgdata.fth      \ Manufacturing data

fload ${BP}/dev/olpc/spiflash/spiflash.fth   \ SPI FLASH programming
fload ${BP}/dev/olpc/spiflash/spiui.fth      \ User interface for SPI FLASH programming
fload ${BP}/dev/olpc/spiflash/recover.fth    \ XO-to-XO SPI FLASH recovery
: ofw-fw-filename$  " disk:\boot\olpc.rom"  ;
' ofw-fw-filename$ to fw-filename$

: +i encode-int encode+  ;  : 0+i  0 +i  ;

fload ${BP}/cpu/x86/fb16-ops.fth
fload ${BP}/ofw/termemu/fb16.fth
0 0  " 1,1"  " /pci" begin-package
   fload ${BP}/dev/olpc/dcon/dconsmb.fth         \ SMB access to DCON chip
   fload ${BP}/dev/olpc/dcon/dcon.fth            \ DCON control
   fload ${BP}/dev/geode/display/loadpkg.fth     \ Geode display

   0 0 encode-bytes
   h# 8200.0910 +i  0+i h# fd00.0000 +i  0+i h# 0080.0000 +i  \ Frame buffer
   h# 8200.0914 +i  0+i h# fe00.0000 +i  0+i h# 0000.4000 +i  \ GP
   h# 8200.0918 +i  0+i h# fe00.4000 +i  0+i h# 0000.4000 +i  \ DC
   h# 8200.091c +i  0+i h# fe00.8000 +i  0+i h# 0000.4000 +i  \ VP
   h# 8200.0920 +i  0+i h# fe00.c000 +i  0+i h# 0000.4000 +i  \ VIP (LX only)
   " assigned-addresses" property

end-package
devalias screen /display

0 0  " c,1"  " /pci" begin-package
   fload ${BP}/dev/mmc/sdhci/sdhci.fth    \ SD host controller
.( Gots to do init in sdhci.fth) cr
   new-device
      fload ${BP}/dev/mmc/sdhci/sdmmc.fth
   finish-device
end-package


\ fload ${BP}/dev/geode/acpi.fth           \ Power management

[ifdef] rom-loaded
fload ${BP}/cpu/x86/pc/olpc/gpioinit.fth
fload ${BP}/cpu/x86/pc/olpc/chipinit.fth
[then]

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
