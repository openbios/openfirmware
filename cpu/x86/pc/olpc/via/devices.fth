\ See license at end of file
purpose: Load device drivers according to configuration definitions

0 0  " "  " /"  begin-package
   fload ${BP}/cpu/x86/pc/mappci.fth	\ Map PCI to root
   fload ${BP}/dev/pcibus.fth		\ Generic PCI bus package
   fload ${BP}/cpu/x86/pc/olpc/via/pcinode.fth	\ System-specific words for PCI
end-package
stand-init: PCI host bridge
   " /pci" " init" execute-device-method drop
;

fload ${BP}/dev/pciprobe.fth		\ Generic PCI probing

fload ${BP}/cpu/x86/tsc.fth             \ Timestamp counter access words

\ Calibrate the Time Stamp Counter using the ACPI timer
fload ${BP}/cpu/x86/acpitimer.fth

fload ${BP}/cpu/x86/pc/olpc/via/smbus.fth	\ SMBUS driver
fload ${BP}/cpu/x86/pc/olpc/via/clkgen.fth	\ SMBus-connected clock generator driver
fload ${BP}/cpu/x86/apic.fth			\ APIC driver

stand-init: APIC
[ifdef] use-apic
   init-apic
[else]
   0. 1b msr!
[then]
;

fload ${BP}/cpu/x86/pc/olpc/via/dumpvia.fth	\ Dump a bunch of registers

stand-init: CPU node
   d# 1,000,000,000  " VIA,C7"

   " /cpu" find-device                                  ( cpu-clock-hz model$ )
      " model" string-property                          ( cpu-clock-hz )
      " clock-frequency" integer-property               ( )
   device-end                                           ( )
;

\ Do this early so the interact timing works right
warning @ warning off
: stand-init-io  ( -- )
   stand-init-io
   acpi-calibrate-tsc
   d# 1000 to us-factor  d# 1000000 to ms-factor
;
warning !

[ifdef] use-ega
0 0 " " " /" begin-package
   fload ${BP}/dev/egatext.fth
end-package
\ devalias screen /ega-text
[then]

[ifdef] addresses-assigned
\ This must precede isamisc.fth in the load file, to execute it first
fload ${BP}/cpu/x86/pc/moveisa.fth
[then]

0 0  " 0"  " /pci" begin-package
   fload ${BP}/dev/pci/isa.fth		\ ISA bus bridge under PCI node
   fload ${BP}/dev/pci/isamisc.fth
end-package

fload ${BP}/cpu/x86/pc/olpc/timertest.fth  \ Selftest for PIT timer

warning @ warning off
: probe-pci  ( -- )
   probe-pci
   " /pci" " make-interrupt-map" execute-device-method drop
;
warning !

fload ${BP}/dev/olpc/spiflash/flashif.fth   \ Generic FLASH interface

\ Create the top-level device node to access the entire boot FLASH device
0 0  " fff00000"  " /" begin-package
   " flash" device-name

   h# 10.0000 value /device
   h# 10.0000 constant /device-phys
   my-address my-space /device-phys reg
   fload ${BP}/dev/flashpkg.fth
   fload ${BP}/dev/flashwrite.fth
end-package

\ Create a node below the top-level FLASH node to accessing the portion
\ containing the dropin modules
0 0  " 10000"  " /flash" begin-package
   " dropins" device-name

   h# d0000 constant /device
   fload ${BP}/dev/subrange.fth
end-package

devalias dropins /dropins

\ Create a pseudo-device that presents the dropin modules as a filesystem.
fload ${BP}/ofw/fs/dropinfs.fth

\ This devalias lets us say, for example, "dir rom:"
devalias rom     /dropin-fs

fload ${BP}/cpu/x86/forthint.fth	\ Low-level interrupt handling code
fload ${BP}/dev/isa/irq.fth		\ ISA interrupt dispatcher
fload ${BP}/cpu/x86/pc/isatick.fth	\ Use ISA timer as the alarm tick timer

dev /interrupt-controller
irq-vector-base to vector-base0
vector-base0 8 + to vector-base1
device-end

[ifdef] resident-packages
support-package: 16550
fload ${BP}/dev/16550pkg/16550.fth  \ Serial port support package
end-support-package
[then]
: serial-enabled?  ( -- flag )  h# 8846 config-b@ h# 40 and 0<>  ;

fload ${BP}/dev/pci/isaall.fth
\ We don't need a serial selftest because the serial port is internal only
\ and the selftest turns off the diag device
dev /serial  warning @ warning off  : selftest false ;  warning !  device-end

[ifndef] demo-board
dev /8042
   patch false ctlr-selftest open
device-end
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

fload ${BP}/cpu/x86/pc/olpc/via/cmos.fth  \ CMOS RAM indices are 1f..ff , above RTC
patch noop init-bios-cmos stand-init

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
0 0  " d0000"  " /flash" begin-package
   " nvram" device-name

   h# 10000 constant /device
   fload ${BP}/dev/subrange.fth
end-package

stand-init: NVRAM
   " /nvram" open-dev  to nvram-node
   ['] init-config-vars catch drop
;
[then]

fload ${BP}/cpu/x86/inoutstr.fth	\ Multiple I/O port read/write
fload ${BP}/dev/isa/diaguart.fth	\ ISA COM port driver
\ : inituarts ascii G uemit  ascii o uemit  ;  \ They are already on

h# 3f8 is uart-base
fload ${BP}/forth/lib/sysuart.fth	\ Use UART for key and emit

0 value keyboard-ih
0 value screen-ih

fload ${BP}/ofw/core/muxdev.fth          \ I/O collection/distribution device

[ifndef] save-flash
: save-flash ;
: restore-flash ;
[then]

\needs md5init  fload ${BP}/ofw/ppp/md5.fth                \ MD5 hash

fload ${BP}/dev/olpc/spiflash/memflash.fth  \ Memory-mapped FLASH read access

warning @ warning off
: stand-init-io  stand-init-io  h# fff0.0000 to flash-base  ;
warning !

: uncache-flash  ( -- )  h# 202 msr@ swap h# ff invert and swap h# 202 msr!  ;

fload ${BP}/dev/olpc/spiflash/spiif.fth     \ Generic low-level SPI bus access
fload ${BP}/dev/olpc/spiflash/spiflash.fth  \ SPI FLASH programming
fload ${BP}/dev/olpc/kb3700/ecspi.fth       \ EC chip SPI FLASH access

\ ignore-power-button is unnecessary on XO-1.5 because the PWR_BUT_OUT# signal
\ is driven by the EC.  If the EC is turned off for SPI FLASH writing, it won't
\ assert PWR_BUT_OUT# .  When the EC is on, it will "pull the plug" on the CPU
\ after the power button has been held down for several seconds, regardless of
\ what the CPU is doing.  So the following implementation of ignore-power-button
\ is mostly pointless in the system context.  It does prevent the CPU from
\ shutting down of its own accord, but the EC override pretty much masks that.

: ignore-power-button  ( -- )  h# 889b config-b@ 2 or  h# 889b config-b!  ;

fload ${BP}/dev/olpc/kb3700/ecio.fth        \ I/O space access to EC chip
fload ${BP}/dev/via/spi/spi.fth             \ Driver for Via SPI controller
fload ${BP}/dev/via/spi/bbspi.fth           \ Tethered SPI FLASH programming

fload ${BP}/cpu/x86/pc/olpc/via/boardrev.fth   \ Board revision decoding
warning @ warning off
: wlan-reset  ( -- )
   h# 4c acpi-l@                         ( old )
   dup h# 800 invert and  h# 4c acpi-l!  ( old )
   d# 10 ms                              ( old )
   h# 800 or h# 4c acpi-l!               ( )
;
warning !

: cpu-mhz  ( -- n )
   " /cpu@0" find-package drop	( phandle )
   " clock-frequency" rot get-package-property  if  0 exit  then  ( adr )
   decode-int nip nip  d# 1000000 /  
;

stand-init: Date to EC
   time&date d# 2000 -  ['] ec-date! catch  if  3drop  then
   3drop
;

stand-init: Wireless reset
   \ Hit the reset on the Marvell wireless.  It sometimes (infrequently)
   \ fails to enumerate after a power-cycle, and reset seems to fix it.
   \ We need > 85 ms between wlan-reset and probe-usb, but console-start
   \ takes about 200 mS, so we are okay.
   atest? 0=  if  wlan-reset  then
;

fload ${BP}/dev/olpc/confirm.fth             \ Selftest interaction modalities
fload ${BP}/cpu/x86/pc/olpc/mfgdata.fth      \ Manufacturing data
fload ${BP}/cpu/x86/pc/olpc/mfgtree.fth      \ Manufacturing data in device tree
fload ${BP}/cpu/x86/pc/olpc/kbdtype.fth      \ Export keyboard type

fload ${BP}/dev/olpc/kb3700/battery.fth      \ Battery status reports
   
fload ${BP}/dev/olpc/spiflash/spiui.fth      \ User interface for SPI FLASH programming
h# 2c to crc-offset
fload ${BP}/cpu/x86/pc/olpc/via/recover.fth  \ XO-to-XO SPI FLASH recovery

: ofw-fw-filename$  " disk:\boot\olpc.rom"  ;
' ofw-fw-filename$ to fw-filename$

: +i encode-int encode+  ;  : 0+i  0 +i  ;

0 0  " 1,0"  " /pci" begin-package
   fload ${BP}/dev/via/unichrome/loadpkg.fth     \ Geode display
   fload ${BP}/dev/via/unichrome/dconsmb.fth     \ SMB access to DCON chip
   fload ${BP}/dev/olpc/dcon/viadcon.fth         \ DCON control

   0 0 encode-bytes
   h# 8200.0810 +i  0+i fb-pci-base   +i  0+i h# d000.0000 +i  \ Frame buffer
   h# 8200.0914 +i  0+i gfx-pci-base  +i  0+i h# f000.0000 +i  \ MMIO
   " assigned-addresses" property
end-package
devalias screen /display
also hidden  d# 34 to display-height  previous  \ For editing

fload ${BP}/dev/olpc/viacamera/loadpkg.fth   \ Camera driver

fload ${BP}/cpu/x86/adpcm.fth            \ ADPCM decoding

warning @ warning off
: stand-init
   stand-init
   root-device
      model-name$   2dup model     ( name$ )
      " OLPC " encode-bytes  2swap encode-string  encode+  " banner-name" property
      board-revision " board-revision-int" integer-property
      \ The "1-" removes the null byte
      " SN" find-tag  if  1-  else  " Unknown"  then  " serial-number" string-property
      8 ec-cmd-b@ dup " ec-version" integer-property

      \ EC code API 56 and greater changes the version numbering
      h# 56 >= if " Ver:" else " PQ2" then

      h# fff0.0000 h# 1.0000 sindex  dup 0>=  if         ( offset )
         h# fff0.0000 +  cscount                         ( name )
      else
         drop  " UNKNOWN"
      then
      " ec-name" string-property

   dend

   " /openprom" find-device
      h# ffff.ffc0 d# 16 " model" string-property

      " sourceurl" find-drop-in  if  " source-url" string-property  then
   dend
;
warning !

devalias com1 /isa/serial@i3f8:115200
devalias mouse /isa/8042/mouse
devalias c int
devalias d disk
devalias n int
devalias ide /ide@0/disk
devalias sd  /sd/disk@2
devalias net /wlan

stand-init: Standard aliases
   atest?  if
      " int" " /ide@0/disk" $devalias
      " ext" " /sd/disk@2"  $devalias
   else
      board-revision h# d28 <  if  \ B2 and earlier
         " int" " /sd/disk@1"  $devalias
         " ext" " /sd/disk@2"  $devalias
      else
         " ext" " /sd/disk@1"  $devalias
         " int" " /sd/disk@3"  $devalias
      then
   then
;

\ The "int" devalias is defined in report-disk at runtime, since it
\ varies between A-test and later boards.

\ Create the alias unless it already exists
: $?devalias  ( alias$ value$ -- )
   2over  not-alias?  if  $devalias exit  then  ( alias$ value$ alias$ )
   2drop 4drop
;

: ?report-device  ( alias$ pathname$ -- )
   2dup  locate-device  0=  if  ( alias$ pathname$ phandle )
      drop                      ( alias$ pathname$ )
      2over 2over $?devalias    ( alias$ pathname$ )
   then                         ( alias$ pathname$ )
   4drop                        ( )
;

: report-disk  ( -- )
   " disk"  " /usb@10,4/disk" ?report-device  \ USB 2
   " disk"  " /usb@10,2/disk" ?report-device  \ USB 1.1
   " disk"  " /usb@10,1/disk" ?report-device  \ USB 1.1
   " disk"  " /usb@10,0/disk" ?report-device  \ USB 1.1
;

: report-keyboard  ( -- )
   \ Prefer direct-attached
   " usb-keyboard"  " /usb@10,2/keyboard" ?report-device  \ USB 1.1
   " usb-keyboard"  " /usb@10,1/keyboard" ?report-device  \ USB 1.1
   " usb-keyboard"  " /usb@10,0/keyboard" ?report-device  \ USB 1.1
   " usb-keyboard"  " /usb@10,4/keyboard" ?report-device  \ USB 2   (keyboard behind a hub)
;

\ If there is a USB ethernet adapter, use it as the default net device.
\ We can't use ?report-device here because we already have net aliased
\ to /wlan, and ?report-device won't override an existing alias.
: report-net  ( -- )
   " /usb/ethernet" 2dup locate-device  0=  if  ( name$ phandle )
      drop                                      ( name$ )

      \ Don't recreate the alias if it is already correct
      " net" aliased?  if                       ( name$ existing-name$ )
         2over $=  if                           ( name$ )
            2drop exit                          ( -- )
         then                                   ( name$ )
      then                                      ( name$ )

      " net" 2swap $devalias                    ( )
   else                                         ( name$ )
      2drop                                     ( )
   then
;

[ifdef] Later
\ Add support for DC-couple microphone input
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
