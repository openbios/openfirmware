purpose: Common code for build OFW Forth dictionaries for OLPC ARM platforms
\ See license at end of file

hex
: xrn $report-name my-self . cr ;
\ ' xrn is include-hook
\ ' $report-name is include-hook
\ ' noop is include-hook

: init-stuff
   acgr-clocks-on
   init-timers
;
warning @ warning off
: stand-init-io
   stand-init-io
   init-stuff
;
warning !

dev /
   model$  model
   " OLPC" encode-string  " architecture" property
\ The clock frequency of the root bus may be irrelevant, since the bus is internal to the SOC
\    d# 1,000,000,000 " clock-frequency" integer-property
device-end

fload ${BP}/cpu/arm/olpc/fbnums.fth
fload ${BP}/cpu/arm/olpc/fbmsg.fth

fload ${BP}/dev/omap/diaguart.fth	\ OMAP UART

d# 26000000 to uart-clock-frequency

\ CForth has already set up the serial port
: inituarts  ( -- )  ;

fload ${BP}/forth/lib/sysuart.fth	\ Set console I/O vectors to UART

: poll-tty  ( -- )  ubreak?  if  user-abort  then  ;  \ BREAK detection
: install-abort  ( -- )  ['] poll-tty d# 100 alarm  ;

0 value dcon-ih
: $call-dcon  ( ... -- ... )   dcon-ih $call-method  ;

0 value keyboard-ih

fload ${BP}/ofw/core/muxdev.fth          \ I/O collection/distribution device

\ Install the simple UART driver from the standalone I/O init chain
warning off
: stand-init-io  ( -- )
   stand-init-io
   inituarts  install-uart-io  install-abort
;
warning on

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

\ Create a pseudo-device that presents the dropin modules as a filesystem.
fload ${BP}/ofw/fs/dropinfs.fth

\ This devalias lets us say, for example, "dir rom:"
devalias rom     /dropin-fs

fload ${BP}/cpu/x86/pc/cpunode.fth  \ The PC CPU node is actually fairly generic

: cpu-mhz  ( -- n )
   " /cpu@0" find-package drop	( phandle )
   " clock-frequency" rot get-package-property  if  0 exit  then  ( adr )
   decode-int nip nip  d# 1000000 /  
;

fload ${BP}/cpu/arm/mmp2/watchdog.fth	\ reset-all using watchdog timer

fload ${BP}/cpu/arm/olpc/smbus.fth         \ Bit-banged SMBUS (I2C) using GPIOs

fload ${BP}/cpu/arm/olpc/gpio-i2c.fth
fload ${BP}/cpu/arm/olpc/twsi-i2c.fth

0 0  " d4018000"  " /" begin-package  \ UART3
   fload ${BP}/cpu/arm/mmp2/uart.fth
   " /apbc" encode-phandle d# 12 encode-int encode+ " clocks" property
   d# 24 " interrupts" integer-property
end-package

0 0  " d4017000"  " /" begin-package  \ UART2
   fload ${BP}/cpu/arm/mmp2/uart.fth
   " /apbc" encode-phandle d# 11 encode-int encode+ " clocks" property
   d# 28 " interrupts" integer-property
end-package

devalias com1 /uart
: com1  " com1"  ;
' com1 is fallback-device   

0 0  " d4030000"  " /" begin-package  \ UART1
   fload ${BP}/cpu/arm/mmp2/uart.fth
   d# 27 " interrupts" integer-property
   " /apbc" encode-phandle d# 10 encode-int encode+ " clocks" property
end-package

0 0  " d4016000"  " /" begin-package  \ UART4
   fload ${BP}/cpu/arm/mmp2/uart.fth
   " /apbc" encode-phandle d# 32 encode-int encode+ " clocks" property
   d# 46 " interrupts" integer-property
end-package

\needs md5init  fload ${BP}/ofw/ppp/md5.fth                \ MD5 hash

fload ${BP}/dev/olpc/spiflash/flashif.fth  \ Generic FLASH interface

fload ${BP}/dev/olpc/spiflash/spiif.fth    \ Generic low-level SPI bus access

fload ${BP}/dev/olpc/spiflash/spiflash.fth \ SPI FLASH programming

fload ${BP}/cpu/arm/mmp2/sspspi.fth        \ Synchronous Serial Port SPI interface

\ Create the top-level device node to access the entire boot FLASH device
0 0  " d4035000"  " /" begin-package
   " flash" device-name

   " /apbc" encode-phandle d# 19 encode-int encode+ " clocks" property
   d# 0 " interrupts" integer-property
   /rom value /device
   my-address my-space h# 100 reg
   fload ${BP}/dev/nonmmflash.fth
end-package

\ Create a node below the top-level FLASH node to accessing the portion
\ containing the dropin modules
0 0  " 20000"  " /flash" begin-package
   " dropins" device-name

   /rom h# 20000 - constant /device
   fload ${BP}/dev/subrange.fth
end-package

devalias dropins /dropins

fload ${BP}/dev/olpc/confirm.fth             \ Selftest interaction modalities
fload ${BP}/cpu/arm/olpc/getmfgdata.fth      \ Get manufacturing data
fload ${BP}/cpu/x86/pc/olpc/mfgdata.fth      \ Manufacturing data
fload ${BP}/cpu/x86/pc/olpc/mfgtree.fth      \ Manufacturing data in device tree

fload ${BP}/dev/olpc/kb3700/eccmds.fth
: dcon-off  ( -- )  dcon-ih  if  " dcon-off" $call-dcon  then  ;
: stand-power-off  ( -- )  dcon-off ec-power-off  begin wfi again  ;
' stand-power-off to power-off

: olpc-reset-all  ( -- )  dcon-off ec-power-cycle  begin wfi again  ;
' olpc-reset-all to reset-all
stand-init:
   ['] reset-all to bye
;

fload ${BP}/dev/olpc/kb3700/batstat.fth      \ Battery status reports
fload ${BP}/cpu/arm/olpc/boardrev.fth        \ Board revision decoding

false constant tethered?                     \ We only support reprogramming our own FLASH

fload ${BP}/cpu/arm/olpc/bbedi.fth
fload ${BP}/cpu/arm/olpc/edi.fth

load-base constant flash-buf

fload ${BP}/cpu/arm/olpc/ecflash.fth

: ec-spi-reprogrammed   ( -- )
   use-edi-spi  spi-start
   set-ec-reboot
   unreset-8051
   use-ssp-spi
;

: ignore-power-button  ( -- )
   use-edi-spi
   edi-open-active
   ['] reset-8051 catch if
      ['] reset-8051 catch if ." Write Protected EC" cr then
   then
   use-ssp-spi
   ['] ec-spi-reprogrammed to spi-reprogrammed
;
: flash-vulnerable(  ( -- )
   ignore-power-button
   disable-interrupts
;
: )flash-vulnerable  ( -- )
   enable-interrupts
   d# 850 ms  \ allow time for 8051 to finish reset and power us down
;

fload ${BP}/dev/olpc/spiflash/spiui.fth      \ User interface for SPI FLASH programming
\ fload ${BP}/dev/olpc/spiflash/recover.fth    \ XO-to-XO SPI FLASH recovery
: ofw-fw-filename$  " disk:\boot\olpc.rom"  ;
' ofw-fw-filename$ to fw-filename$

0 0  " f0400000"  " /" begin-package
   " vmeta" name
   my-address my-space h# 1000 reg

   " mrvl,mmp2-vmeta" +compatible

   " /pmua" encode-phandle d# 10 encode-int encode+ " clocks" property
   d# 26 " interrupts" integer-property
end-package

fload ${BP}/cpu/arm/olpc/lcd.fth
[ifdef] mmp3
fload ${BP}/cpu/arm/mmp3/galcore.fth
[then]
fload ${BP}/cpu/arm/olpc/sdhci.fth

devalias net /wlan

fload ${BP}/dev/olpc/kb3700/spicmd.fth           \ EC SPI Command Protocol

: wlan-reset  ( -- )  wlan-reset-gpio# gpio-clr  d# 20 ms  wlan-reset-gpio# gpio-set  ;

fload ${BP}/ofw/core/fdt.fth
fload ${BP}/cpu/arm/linux.fth

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
   " disk"  " /usb/disk" ?report-device
;

: report-keyboard  ( -- )
   \ Prefer direct-attached
   " usb-keyboard"  " /usb/keyboard" ?report-device  \ USB 2   (keyboard behind a hub)
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

[ifdef] mmp3
fload ${BP}/cpu/arm/mmp3/usb2phy.fth
[else]
fload ${BP}/cpu/arm/marvell/utmiphy.fth
[then]
fload ${BP}/cpu/arm/olpc/usb.fth

[ifdef] has-sp-kbd
\ Load this after the USB driver so the ambiguous pathname /keyboard will
\ resolve to /ap-sp/keyboard instead of /usb/keyboard after a USB keyboard
\ has been attached.  Manufacturing test scripts need that behavior.
fload ${BP}/cpu/arm/olpc/spcmd.fth   \ Security Processor communication protocol
devalias keyboard /ap-sp/keyboard
devalias mouse    /ap-sp/mouse
[then]

fload ${BP}/dev/olpc/mmp2camera/loadpkg.fth

fload ${BP}/cpu/arm/firfilter.fth

fload ${BP}/cpu/x86/adpcm.fth            \ ADPCM decoding
d# 32 is playback-volume

fload ${BP}/cpu/arm/olpc/sound.fth
fload ${BP}/cpu/arm/olpc/rtc.fth
stand-init: RTC
   " /i2c@d4031000/rtc" open-dev  clock-node !
   \ use RTC 32kHz clock as SoC external slow clock
   h# 38 mpmu@ 1 or h# 38 mpmu!
;

warning @ warning off
: stand-init
   stand-init
   root-device
      model-version$   2dup model     ( name$ )
      " OLPC " encode-bytes  2swap encode-string  encode+  " banner-name" property
      board-revision " board-revision-int" integer-property
      compatible$  " compatible" string-property

      \ The "1-" removes the null byte
      " SN" find-tag  if  1-  else  " Unknown"  then  " serial-number" string-property

      ec-api-ver@ " ec-version" integer-property

      ['] ec-name$  catch  0=  if  " ec-name" string-property  then
      ['] ec-date$  catch  0=  if  " ec-date" string-property  then
      ['] ec-user$  catch  0=  if  " ec-user" string-property  then
      " /interrupt-controller" encode-phandle " interrupt-parent" property
\      " /interrupt-controller"  find-package  if
\         " interrupt-parent" integer-property
\      then
      0 0 " ranges" property
   dend

   " /openprom" find-device
      flash-open  pad d# 16  2dup  signature-offset  flash-read  ( adr len )
      " model" string-property

      " sourceurl" find-drop-in  if  " source-url" string-property  then
   dend
;

warning !

stand-init: More memory
   extra-mem-va /extra-mem add-memory
;

[ifdef] mmp3
fload ${BP}/cpu/arm/mmp3/thermal.fth
[else]
fload ${BP}/cpu/arm/mmp2/thermal.fth
[then]
fload ${BP}/cpu/arm/mmp2/fuse.fth
[ifdef] bsl-uart-base
fload ${BP}/cpu/arm/olpc/bsl.fth
fload ${BP}/cpu/arm/olpc/nnflash.fth
[then]

[ifndef] virtual-mode
warning off
: stand-init-io
   stand-init-io
   go-fast         \ From mmuon.fth
;
warning on
[then]

\ The bottom of extra-mem is the top of DMA memory.
\ We give everything up to that address to Linux.
: olpc-memory-limit  ( -- adr )  extra-mem-va >physical  ;
' olpc-memory-limit to memory-limit
: olpc-mapped-limit  ( -- adr )  dma-mem-va >physical  ;
' olpc-mapped-limit to mapped-limit

machine-type to arm-linux-machine-type

\ Add a tag describing the linear frame buffer
: mmp-fb-tag,  ( -- )
   8 tag-l,
   h# 54410008 tag-l, \ ATAG_VIDEOLFB
   screen-wh over tag-w,            \ Width  ( width height )
   dup tag-w,                       \ Height ( width height )
   " depth" $call-screen dup tag-w, \ Depth  ( width height depth )
   rot * 8 /  dup tag-w,            \ Pitch  ( height pitch )
   fb-mem-va tag-l,                 \ Base address  ( height pitch )
   *  tag-l,                        \ Total size - perhaps could be larger
   \ The following assumes depth is 16 bpp
   5     tag-b,       \ Red size
   d# 11 tag-b,       \ Red position
   6     tag-b,       \ Green size
   d#  5 tag-b,       \ Green position
   5     tag-b,       \ Blue size
   d#  0 tag-b,       \ Blue position
   0     tag-b,       \ Rsvd size
   d# 16 tag-b,       \ Rsvd position
;
' mmp-fb-tag, to fb-tag,

\ Add a tag describing the OFW callback
3 constant MT_DEVICE_WC
9 constant MT_MEMORY
: (ofw-tag,)  ( -- )
   4 2 * 3 +    tag-l,    \ size
   h# 41000502  tag-l,    \ ATAG_MEM
   cif-handler  tag-l,    \ Client interface handler callback address

   \ Each of these groups is a struct map_desc as defined in arch/arm/include/asm/mach/
   extra-mem-va dup                        tag-l,  \ VA of OFW memory
   >physical pageshift rshift              tag-l,  \ Page frame number of OFW memory
   fw-mem-va /fw-mem +  extra-mem-va -     tag-l,  \ Size of OFW memory
   MT_MEMORY                               tag-l,  \ Mapping type of OFW memory

   fb-mem-va dup                           tag-l,  \ VA of OFW Frame Buffer
   >physical pageshift rshift              tag-l,  \ PA of OFW Frame Buffer
   /fb-mem                                 tag-l,  \ Size of OFW memory
   MT_DEVICE_WC                            tag-l,  \ Mapping type of OFW frame buffer
;
' (ofw-tag,) to ofw-tag,

false to stand-init-debug?
\ true to stand-init-debug?

: sec-trg   ( -- )      sec-trg-gpio# gpio-set  ;  \ rising edge latches SPI_WP# low
: sec-trg?  ( -- bit )  sec-trg-gpio# gpio-pin@  ;

alias ec-indexed-io-off sec-trg
alias ec-indexed-io-off? sec-trg?
alias ec-ixio-reboot ec-power-cycle  \ clears latch, brings SPI_WP# high

false value secure?

: protect-fw  ( -- )  secure?  if  flash-protect sec-trg  then  ;

fload ${BP}/cpu/x86/pc/olpc/countdwn.fth	\ Startup countdown

hex
: i-key-wait  ( ms -- pressed? )
   cr ." Type 'i' to interrupt stand-init sequence" cr   ( ms )
   0  do
      ukey?  if
         ukey upc ascii I  =  if  true unloop exit  then
      then
      d# 1000 us  \ 1000 us is more precise than 1 ms, which is often close to 2 ms
   loop
   false
;

defer rotate-button?  ' false to rotate-button?

warning @  warning off 
: init
\ initial-heap add-memory
   init

   standalone?  if
      disable-interrupts
\     d# 1000  i-key-wait  if
      rotate-button? if
         protect-fw
         \ Make the frame buffer visible so CForth won't complain about OFW not starting
         h# 8009.1100 h# 20.b190 io!
         ." Interacting" cr  hex interact
      then
      \ Turn on USB power here to overlap the time with other startup actions
      usb-power-on
   then
;
warning !

: (.firmware)  ( -- )
   ." Open Firmware  "  .built  cr
   ." Copyright 2010 FirmWorks  All Rights Reserved" cr
;
' (.firmware) to .firmware

\ Uninstall the diag menu from the general user interface vector
\ so exiting from emacs doesn't invoke the diag menu.
' quit to user-interface

: screen-#lines  ( -- n )
   screen-ih 0=  if  default-#lines exit  then
   screen-ih  package( #lines )package
;
' screen-#lines to lines/page

true value text-on?
: text-off  ( -- )
   text-on?  if
      screen-ih remove-output
      false to text-on?
   then
;
: text-on   ( -- )
   text-on? 0=  if
      screen-ih add-output
      cursor-on
      true to text-on?
   then
;

\ idt1338 rtc and ram address map
\     00 -> 0f  rtc
\     10 -> 3d  cmos
\     3e -> 3f  driver magic number

: >rtc  ( index -- rtc-address )  h# 3f and  h# 10 +  ;
\ : rtc>  ( rtc-address -- index )  h# 10 - h# 80 or  ;

: cmos@  ( index -- data )
   >rtc " rtc@" clock-node @  ( index adr len ih )
   ['] $call-method catch  if  4drop 0  then
;
: cmos!  ( data index -- )
   >rtc " rtc!" clock-node @  ( data index adr len ih )
   ['] $call-method catch  if  2drop 3drop  then
;

\ cmos address map
\     80 audio volume
\     81 audio volume
\     82 alternate boot
\     83 xid
\     80 -> 8f (erased by driver when magic number wrong)
\     84 -> ad (unallocated)

fload ${BP}/cpu/arm/mmp2/clocks.fth
fload ${BP}/cpu/arm/olpc/banner.fth

: console-start  ( -- )
   " /dcon" open-dev to dcon-ih
   install-mux-io
   cursor-off
   true to text-on?

   " //null" open-dev to null-ih  \ For text-off state
;
: keyboard-off  ( -- )
   keyboard-ih  if
      keyboard-ih remove-input
      keyboard-ih close-dev
      0 to keyboard-ih
   then
;

: teardown-mux-io  ( -- )
   install-uart-io
   text-off
   keyboard-off
   fallback-out-ih remove-output
   fallback-in-ih remove-input
   stdin off
   stdout off
   in-mux-ih close-dev
   out-mux-ih close-dev
;
: quiesce  ( -- )
   usb-quiet
   teardown-mux-io
   timers-off
   unload-crypto
   close-ec
   \ Change the sleep state of EC_SPI_ACK from 1 (OFW value) to 0 (Linux value)
   d# 125 af@  h# 100 invert and  d# 125 af!
;

\ This must precede the loading of gui.fth, which chains from linux-hook's behavior
' quiesce to linux-hook

[ifdef] olpc-cl4
: linux-hook-emmc  ( -- )
   [ ' linux-hook behavior compile, ]  \ Chain to old behavior
   connect-emmc
;
' linux-hook-emmc to linux-hook
[then]

\ This must be defined after spiui.fth, otherwise spiui will choose some wrong code
: rom-pa  ( -- adr )  mfg-data-buf mfg-data-offset -  ;  \ Fake out setwp.fth
fload ${BP}/cpu/x86/pc/olpc/setwp.fth

fload ${BP}/cpu/arm/olpc/help.fth
fload ${BP}/cpu/x86/pc/olpc/gui.fth
fload ${BP}/cpu/x86/pc/olpc/via/mfgtest.fth
fload ${BP}/cpu/x86/pc/olpc/strokes.fth
fload ${BP}/cpu/x86/pc/olpc/plot.fth

fload ${BP}/cpu/arm/mmp2/showirqs.fth
fload ${BP}/cpu/arm/mmp2/wakeups.fth

[ifdef] mmp3
fload ${BP}/cpu/arm/mmp3/dramrecal.fth
[then]
[ifdef] mmp2
fload ${BP}/cpu/arm/mmp2/dramrecal.fth
[then]
fload ${BP}/cpu/arm/olpc/suspend.fth

code halt  ( -- )  wfi   c;

fload ${BP}/cpu/arm/mmp2/rtc.fth       \ Internal RTC, used for wakeups

fload ${BP}/cpu/x86/pc/olpc/via/factory.fth  \ Manufacturing tools

fload ${BP}/cpu/arm/olpc/accelerometer.fth

\ When reprogramming this machine's SPI FLASH, rebooting the EC is unnecessary 
: no-kbc-reboot  ['] noop to spi-reprogrammed  ;
: kbc-on ;

\ Pseudo device that appears in the boot order before net booting
0 0 " " " /" begin-package
   " prober" device-name
   : open
      visible
      false
   ;
   : close ;
end-package

fload ${BP}/cpu/x86/pc/olpc/gamekeynames.fth

defer game-key@  ' 0 to game-key@   \ Implementation will be loaded later

fload ${BP}/cpu/x86/pc/olpc/gamekeys.fth

fload ${BP}/dev/logdev.fth

fload ${BP}/cpu/x86/pc/olpc/disptest.fth

[ifdef] has-sp-kbd
dev /ap-sp/keyboard
fload ${BP}/dev/olpc/keyboard/selftest.fth   \ Keyboard diagnostic
device-end
stand-init: Keyboard
   " /ap-sp/keyboard" " set-keyboard-type" execute-device-method drop
;
dev /ap-sp/mouse
fload ${BP}/dev/olpc/touchpad/syntpad.fth    \ Touchpad diagnostic
device-end
[then]

fload ${BP}/cpu/x86/pc/olpc/gridmap.fth      \ Gridded display tools
fload ${BP}/cpu/x86/pc/olpc/via/copynand.fth

\- use-screen-kbd devalias keyboard /keyboard
\+ use-screen-kbd fload ${BP}/dev/softkeyboard.fth             \ On-screen keyboard

fload ${BP}/cpu/arm/olpc/roller.fth     \ Accelerometer test

\ fload ${BP}/cpu/arm/olpc/pinch.fth  \ Touchscreen gestures
\ : pinch  " pinch" screen-ih $call-method  ;

: emacs  ( -- )
   false to already-go?
   boot-getline to boot-file   " rom:emacs" $boot
;
defer rm-go-hook  \ Not used, but makes security happy
: tsc@  ( -- d.ticks )  timer0@ u>d  ;
d# 6500 constant ms-factor

: dimmer  ( -- )  dcon-ih  if  " dimmer" dcon-ih $call-method  then  ;
: brighter  ( -- )  dcon-ih  if  " brighter" dcon-ih $call-method  then  ;

fload ${BP}/cpu/x86/pc/olpc/sound.fth
fload ${BP}/cpu/x86/pc/olpc/guardrtc.fth
fload ${BP}/cpu/x86/pc/olpc/security.fth

stand-init: xid
   h# 83 cmos@  dup 1+  h# 83 cmos!   ( n )
   d# 24 lshift               ( new-xid )
   " dev /obp-tftp  to rpc-xid  dend" evaluate
;

: pre-setup-for-linux  ( -- )
   [ ' linux-pre-hook behavior compile, ]    \ Chain to old behavior
   sound-end
[ifdef] mmp3
   \ XXX Delete this when Linux is ready to turn on the audio island
   " audio-island-on" " /pmua" execute-device-method drop
[then]
;
' pre-setup-for-linux to linux-pre-hook

: show-temperature  ( -- )  space cpu-temperature .d  ;
fload ${BP}/cpu/arm/bootascall.fth
create use-thinmac
fload ${BP}/cpu/x86/pc/olpc/wifichannel.fth
fload ${BP}/cpu/x86/pc/olpc/via/nbtx.fth
fload ${BP}/cpu/x86/pc/olpc/via/nbrx.fth
fload ${BP}/cpu/x86/pc/olpc/via/blockfifo.fth

alias fast-hash crypto-hash   \ fast-hash uses acceleration when available
fload ${BP}/cpu/x86/pc/olpc/via/fsupdate.fth
fload ${BP}/cpu/x86/pc/olpc/via/fsverify.fth
fload ${BP}/cpu/x86/pc/olpc/via/fssave.fth
fload ${BP}/cpu/x86/pc/olpc/via/fsload.fth
devalias fsdisk int:0

\ create pong-use-touchscreen
\ fload ${BP}/ofw/gui/ofpong.fth

d# 999 ' screen-#rows    set-config-int-default  \ Expand the terminal emulator to fill the screen
d# 999 ' screen-#columns set-config-int-default  \ Expand the terminal emulator to fill the screen

" u:\boot\olpc.fth ext:\boot\olpc.fth int:\boot\olpc.fth ext:\zimage /prober /usb/ethernet /wlan"
   ' boot-device  set-config-string-default

\needs ramdisk  " " d# 128 config-string ramdisk
" "   ' boot-file      set-config-string-default   \ Let the boot script set the cmdline

2 config-int auto-boot-countdown

\ Eliminate 4 second delay in install console for the case where
\ there is no keyboard.  The delay is unnecessary because the screen
\ does not go blank when the device is closed.
patch drop ms install-console

alias reboot bye

alias crcgen drop  ( crc byte -- crc' )

\ Dictionary growth size for the ARM Image Format header
\ 1 section   before origin  section table
h# 10.0000      h# 8000 -      h# 4000 -      dictionary-size !

fload ${BP}/cpu/arm/saverom.fth  \ Save the dictionary for standalone startup

fload ${BP}/dev/hdaudio/noiseburst.fth  \ audio-test support package

\ Because visible doesn't work sometimes when calling back from Linux
dev /client-services  patch noop visible enter  dend

: interpreter-init  ( -- )
   hex
   warning on
   only forth also definitions

   install-alarm

   page-mode
   #line off

\   .built cr
;


: factory-test?  ( -- flag )
   \ TS is the "test station" tag, whose value is set to "SHIP" at the
   \ end of manufacturing test.
   " TS" find-tag  if         ( adr len )
      ?-null  " SHIP" $=  0=  ( in-factory? )
   else                       ( )
      \ Missing TS tag is treated as not in factory test
      false
   then                       ( in-factory? )
;

: ?sound  ( -- )
   \ Suppress the jingle if a game key is pressed, because we don't want
   \ the jingle to interfere with diags and stuff
   -1 game-key?  if  exit  then
   ['] sound catch drop
;

: ?games  ( -- )
   rocker-right game-key?  if
      protect-fw
\      ['] pong guarded
      power-off
   then
;
: ?diags  ( -- )
   rocker-left game-key?  if
      protect-fw
      text-on  ['] gamekey-auto-menu guarded
      ." Tests complete - powering off" cr  d# 5000 ms  power-off
   then
;

: ?fs-update  ( -- )
   button-check button-x or  button-o or  button-square or   ( mask )
   game-key-mask =  if  protect-fw try-fs-update  then
;

[ifdef] use-screen-kbd
0 value screen-kbd-ih
: open-screen-keyboard  ( -- )
   " /touchscreen/keyboard" open-dev to screen-kbd-ih
   screen-kbd-ih  if
      0 background  0 0  d# 1024 d# 400 set-text-region
      screen-kbd-ih add-input
   then
;
: close-screen-keyboard  ( -- )
   screen-kbd-ih  if
      screen-kbd-ih remove-input
      screen-kbd-ih close-dev
      0 to screen-kbd-ih
   then
;
\ ' open-screen-keyboard to scroller-on
\ ' close-screen-keyboard to scroller-off
' close-screen-keyboard to save-scroller
' open-screen-keyboard to restore-scroller

: (go-hook)  ( -- )
   [ ' go-hook behavior compile, ]
   close-screen-keyboard
;
' (go-hook) to go-hook

0 value screen-hot-ih
: open-hotspot  ( -- )
   " /touchscreen/hotspot" open-dev to screen-hot-ih
   screen-hot-ih  if
      d# 412 d# 284  d# 200 d# 200 " "(00)"  " set-hotspot" screen-hot-ih $call-method
      screen-hot-ih add-input
   then
;
: close-hotspot  ( -- )
   screen-hot-ih  if
      screen-hot-ih remove-input
      screen-hot-ih close-dev
      0 to screen-hot-ih
   then
;
: ?text-on  ( -- )  key?  if  text-on visible  then  ;
[then]

: startup  ( -- )
   standalone?  0=  if  exit  then

   block-exceptions
   no-page

   ?factory-mode

   disable-user-aborts
   console-start

   read-game-keys

   factory-test? 0=  if  text-off  then

   " probe-" do-drop-in

   [ifdef] unused-cores-off  unused-cores-off  [then]
   show-child

   update-ec-flash?  if
      ['] ?enough-power catch  ?dup  if  ( error )
         show-no-power
         .error
         ." Skipping EC reflash, not enough power" cr
         d# 1000 ms
      else
         jots-ec  ['] jot to edi-progress
         update-ec-flash
      then
   then
[ifdef] update-nn-flash?
   ['] update-nn-flash?  catch  ?dup if  ( error )
      .error
   else
      if
         ['] ?enough-power catch  ?dup  if  ( error )
            show-no-power
            .error
            ." Skipping NN reflash, not enough power" cr
            d# 1000 ms
         else
            jots-nn  ['] jot to bsl-progress
            update-nn-flash
         then
      then
   then
[then]
\+ use-screen-kbd  open-hotspot

   install-alarm
   ?sound

   ?games

   ['] false to interrupt-auto-boot?
\+ use-screen-kbd  ?text-on
[ifdef] probe-usb
   factory-test?  if  d# 1000 ms  then  \ Extra USB probe delay in the factory
   probe-usb
   report-disk
   report-keyboard
[then]
[ifdef] probe-image-sensor  probe-image-sensor  [then]
   " probe+" do-drop-in

   interpreter-init

\+ use-screen-kbd  ?text-on
   ?diags
   ?fs-update

   factory-test? 0=  if  secure-startup  then
   unblock-exceptions
   ['] (interrupt-auto-boot?) to interrupt-auto-boot?

\+ use-screen-kbd  ?text-on
   ?usb-keyboard

   auto-banner?  if  banner  then

\+ use-screen-kbd  ?text-on
   auto-boot
\+ use-screen-kbd  close-hotspot

\+ use-screen-kbd  open-screen-keyboard  banner

   frozen? text-on? 0=  and  ( no-banner? )
   unfreeze visible cursor-on ( no-banner? )
   if  banner  then  \ Reissue banner if it was suppressed

   blue-letters ." Type 'help' for more information." cancel
   cr cr

   enable-user-aborts
   stop-sound   
   quit
;

: enable-serial ;
fload ${BP}/cpu/x86/pc/olpc/terminal.fth   \ Serial terminal emulator
fload ${BP}/cpu/x86/pc/olpc/apt.fth        \ Common developer utilities

\ LICENSE_BEGIN
\ Copyright (c) 2010 FirmWorks
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
