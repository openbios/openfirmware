\ See license at end of file
purpose: Load device drivers according to configuration definitions

: lx? true  ;
: gx? false ;

fload ${BP}/dev/geode/msr.fth
fload ${BP}/cpu/x86/pc/isaio.fth

[ifdef] rom-loaded
fload ${BP}/cpu/x86/pc/neptune/vsapci.fth	\ PCI configuration access with some hacks
[else]
fload ${BP}/dev/pci/configm1.fth	\ Generic PCI configuration access
[then]

0 0  " "  " /"  begin-package
   fload ${BP}/cpu/x86/pc/mappci.fth	\ Map PCI to root
   fload ${BP}/dev/pcibus.fth		\ Generic PCI bus package
   fload ${BP}/cpu/x86/pc/neptune/pcinode.fth	\ System-specific words for PCI
end-package
stand-init: PCI host bridge
   " /pci" " init" execute-device-method drop
;

fload ${BP}/dev/pciprobe.fth		\ Generic PCI probing

\ Use the CPU chip's Time Stamp Counter for timing; it does just what we want
fload ${BP}/cpu/x86/tsc.fth
\ d# 366,666 to ms-factor  \ XXX is this right????
\ d# 367 to us-factor

stand-init:
   d# 366,666,667  " AMD,Geode LX"

   " /cpu" find-device                                  ( cpu-clock-hz model$ )
      " model" string-property                          ( cpu-clock-hz )
      dup " clock-frequency" integer-property           ( cpu-clock-hz )
   device-end                                           ( cpu-clock-hz )

   d# 1000 rounded-/ dup  to ms-factor                  ( cpu-clock-khz )
   d# 1000 rounded-/      to us-factor                  ( )
;

[ifdef] use-ega
0 0 " " " /" begin-package
   fload ${BP}/dev/egatext.fth
end-package
\ devalias screen /ega-text
[then]

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

fload ${BP}/cpu/x86/pc/olpc/timertest.fth  \ Selftest for PIT timer

1 [if]
warning @ warning off
: probe-pci  ( -- )
   probe-pci
   " /pci" " make-interrupt-map" execute-device-method drop
;
warning !

\ Create the secondary FLASH node.  This device exists only when an external
\ card is attached to the board.  It is used for initial programming of
\ the primary FLASH, by swapping the ID selects for the internal and external
\ FLASH chips.  The external FLASH appears as the primary boot FLASH (fff00000)
\ and the internal one as the secondary (ffe00000).  In normal operation,
\ the internal FLASH is primary (fff00000) and the secondary doesn't exist.

\ We define the secondary node first so that "/flash" will refer to the primary
\ (pathname matching finds the most recent match first).

0 0  " ffe00000"  " /" begin-package
   " flash" device-name

   h# 10.0000 constant /device
   h#  1.0000 constant /block
   h#    1000 constant /sector
   my-address my-space /device reg

   h# 40.0000 negate  constant regs-offset

   : write-enable  ( -- )
      h# 1808 rdmsr  h# ff.ffff and  h# 2100.0000 or  h# 1808 wrmsr
   ;
   : write-disable  ( -- )
      h# 1808 rdmsr  h# ff.ffff and  h# 2500.0000 or  h# 1808 wrmsr
   ;

   fload ${BP}/dev/flashpkg.fth
   fload ${BP}/dev/lpcflash.fth
   fload ${BP}/dev/flashwritepkg.fth
end-package

\ Create the top-level device node to access the entire boot FLASH device
0 0  " fff00000"  " /" begin-package
   " flash" device-name

   h# 10.0000 value /device
   my-address my-space /device reg

   h# 10.0000 constant /device-phys
   h#  1.0000 constant /block
   h#    1000 constant /sector

   h# 40.0000 negate constant regs-offset

   : write-enable  ( -- )
      h# 1808 rdmsr  h# ff.ffff and  h# 2100.0000 or  h# 1808 wrmsr
   ;
   : write-disable  ( -- )
      h# 1808 rdmsr  h# ff.ffff and  h# 2500.0000 or  h# 1808 wrmsr
   ;

   fload ${BP}/dev/flashpkg.fth
   fload ${BP}/dev/lpcflash.fth
   fload ${BP}/dev/flashwritepkg.fth
end-package

devalias flash /flash@fff00000

\ Create a node below the top-level FLASH node to accessing the portion
\ containing the dropin modules
0 0   dropin-offset <# u#s u#>   " flash" begin-package
   " dropins" device-name

   dropin-size constant /device
   fload ${BP}/dev/subrange.fth
end-package

devalias dropins /dropins

\ Create a pseudo-device that presents the dropin modules as a filesystem.
fload ${BP}/ofw/fs/dropinfs.fth

\ This devalias lets us say, for example, "dir rom:"
devalias rom     /dropin-fs

fload ${BP}/cpu/x86/forthint.fth	\ Low-level interrupt handling code
fload ${BP}/dev/isa/irq.fth		\ ISA interrupt dispatcher
fload ${BP}/cpu/x86/pc/isatick.fth	        \ Use ISA timer as the alarm tick timer

dev /interrupt-controller
irq-vector-base to vector-base0
vector-base0 8 + to vector-base1
device-end

[ifdef] resident-packages
support-package: 16550
fload ${BP}/dev/16550pkg/16550.fth  \ Serial port support package
end-support-package
[then]

fload ${BP}/dev/pci/isaall.fth
devalias com1 /isa/serial@i3f8:115200
\ devalias mouse /isa/8042/mouse
devalias d disk
devalias n nand
devalias u /usb/disk
devalias sd /sd/disk

\ If we don't do the ctlr-selftest, the keyboard won't start on the LX devel board
\ dev /8042      patch false ctlr-selftest open   device-end

0 0  " i70"  " /isa" begin-package   	\ Real-time clock node
   fload ${BP}/dev/ds1385r.fth
   8 encode-int  0 encode-int encode+    " interrupts" property
   2 encode-int " device#" property
end-package
0 [if]  \ XXX check me
stand-init: RTC
   " /rtc" open-dev  clock-node !
;
[then]

fload ${BP}/cpu/x86/pc/cpunode.fth
fload ${BP}/cpu/x86/k6cputest.fth	\ Burnin test for K6 CPU

0 [if]
fload ${BP}/ofw/console/bailout.fth
stand-init:  Keyboard overrides
   ?bailout
;
[then]

fload ${BP}/forth/lib/pattern.fth	\ Text string pattern matching
fload ${BP}/forth/lib/tofile.fth	\ to-file and append-to-file
\ XXX remove the OS file commands from tools.dic
fload ${BP}/ofw/core/filecmds.fth	\ File commands: dir, del, ren, etc.

fload ${BP}/cpu/x86/pc/olpc/cmos.fth     \ CMOS RAM indices are 1f..ff , above RTC

devalias nand /nandflash
devalias mtd  /nandflash

[ifdef] use-null-nvram
\ For not storing configuration variable changes across reboots ...
\ This is useful for "turnkey" systems where configurability would
\ increase support costs.

fload ${BP}/cpu/x86/pc/nullnv.fth
stand-init: Null-NVRAM
   " /null-nvram" open-dev  to nvram-node
   ['] init-config-vars catch drop
;
[then]

[ifdef] use-flash-nvram
\ For configuration variables stored in a sector of the boot FLASH ...

\ Create a node below the top-level FLASH node to access the portion
\ containing the configuration variables.
0 0  config-vars-offset <# u#s u#>  " flash" begin-package
   " nvram" device-name

   h# 1000 constant /device      \ 4K - SST49LF080A sector size
   fload ${BP}/dev/subrange.fth
end-package

stand-init: NVRAM
   " /nvram" open-dev  to nvram-node
   ['] init-config-vars catch drop
;
[then]

\ Create the alias unless it already exists
: $?devalias  ( alias$ value$ -- )
   2over  not-alias?  if  $devalias exit  then  ( alias$ value$ alias$ )
   2drop 4drop
;

: report-disk  ( -- )
   " /usb/disk" locate-device  0=  if
      drop
      " disk"  " /usb/disk"   $devalias
      exit
   then
   " /usb@f,4/disk" locate-device  0=  if
      ." Found USB 1.1 disk!" cr
      drop
      " disk"  " /usb@f,4/disk" $devalias
      exit
   then
;

: report-keyboard  ( -- )
   " /usb@f,4/keyboard" locate-device  0=  if
      drop
      " keyboard"  " /usb@f,4/keyboard"  $devalias
      exit
   then

   \ In case the keyboard is behind a USB 2 hub
   " /usb@f,5/keyboard" locate-device  0=  if
      drop
      " keyboard"  " /usb@f,5/keyboard"  $devalias
   then
;

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

fload ${BP}/dev/geode/acpi.fth           \ Power management
\ warning @ warning off
\ : stand-init-io  stand-init-io  h# fff0.0000 to flash-base  ;
\ warning !
: cpu-mhz  ( -- n )
   " /cpu@0" find-package drop	( phandle )
   " clock-frequency" rot get-package-property  if  0 exit  then  ( adr )
   decode-int nip nip  d# 1000000 /  
;

stand-init: PCI properties
   " /pci" find-device
   d# 66,666,667  " clock-frequency" integer-property
   dend
;

: +i encode-int encode+  ;  : 0+i  0 +i  ;

[ifdef] rom-loaded
fload ${BP}/cpu/x86/pc/neptune/gpioinit.fth
fload ${BP}/cpu/x86/pc/neptune/chipinit.fth
[then]

false config-int tft-mode?

fload ${BP}/cpu/x86/fb16-ops.fth
fload ${BP}/ofw/termemu/fb16.fth
0 0  " 1,1"  " /pci" begin-package
   fload ${BP}/dev/geode/display/loadpkg.fth     \ Geode display

   0 0 encode-bytes
   h# 8200.0910 +i  0+i fb-pci-base  +i  0+i h# 0080.0000 +i  \ Frame buffer
   h# 8200.0914 +i  0+i gp-pci-base  +i  0+i h# 0000.4000 +i  \ GP
   h# 8200.0918 +i  0+i dc-pci-base  +i  0+i h# 0000.4000 +i  \ DC
   h# 8200.091c +i  0+i vp-pci-base  +i  0+i h# 0000.4000 +i  \ VP
   h# 8200.0920 +i  0+i vip-pci-base +i  0+i h# 0000.4000 +i  \ VIP (LX only)
   " assigned-addresses" property

end-package
devalias screen /display
also hidden  d# 34 to display-height  previous  \ For editing

fload ${BP}/cpu/x86/adpcm.fth            \ ADPCM decoding

warning @ warning off
: stand-init
   stand-init
   root-device
\ XXX perhaps report subordinate version info?
      " Neptune"  model
      " Neptune" " banner-name" string-property
   dend

   " /openprom" find-device
      h# ffff.ffc0 d# 16 " model" string-property

      " sourceurl" find-drop-in  if  " source-url" string-property  then
   dend
;
warning !

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
