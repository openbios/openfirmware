purpose: Common code for build OFW Forth dictionaries for OLPC ARM platforms
\ See license at end of file

hex
: xrn $report-name my-self . cr ;
\ ' xrn is include-hook
\ ' $report-name is include-hook
\ ' noop is include-hook

fload ${BP}/cpu/arm/olpc/fbnums.fth
fload ${BP}/cpu/arm/olpc/fbmsg.fth

fload ${BP}/dev/omap/diaguart.fth	\ OMAP UART

h# 18000 +io to uart-base		\ UART3 base address on MMP2
\ h# 30000 +io to uart-base		\ UART1 base address on MMP2
d# 26000000 to uart-clock-frequency

\ CForth has already set up the serial port
: inituarts  ( -- )  ;

fload ${BP}/forth/lib/sysuart.fth	\ Set console I/O vectors to UART

0 value keyboard-ih

fload ${BP}/ofw/core/muxdev.fth          \ I/O collection/distribution device

\ Install the simple UART driver from the standalone I/O init chain
warning off
: stand-init-io  ( -- )
   stand-init-io
   inituarts  install-uart-io
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


fload ${BP}/cpu/arm/mmp2/timer.fth
fload ${BP}/cpu/arm/mmp2/twsi.fth
fload ${BP}/cpu/arm/mmp2/mfpr.fth
fload ${BP}/cpu/arm/mmp2/gpio.fth

: init-stuff
   acgr-clocks-on
   init-timers
   init-twsi
;
warning @ warning off
: stand-init-io
   stand-init-io
   init-stuff
;
warning !

fload ${BP}/cpu/arm/mmp2/irq.fth

fload ${BP}/cpu/arm/mmp2/watchdog.fth	\ reset-all using watchdog timer

0 0  " d4018000"  " /" begin-package  \ UART3
   fload ${BP}/cpu/arm/mmp2/uart.fth
end-package
devalias com1 /uart
: com1  " com1"  ;
' com1 is fallback-device   

0 0  " d4030000"  " /" begin-package  \ UART1
   fload ${BP}/cpu/arm/mmp2/uart.fth
end-package
devalias com2 /uart
: com2  " com2"  ;

\needs md5init  fload ${BP}/ofw/ppp/md5.fth                \ MD5 hash

fload ${BP}/cpu/arm/olpc/smbus.fth         \ Bit-banged SMBUS (I2C) using GPIOs

fload ${BP}/dev/olpc/spiflash/flashif.fth  \ Generic FLASH interface

fload ${BP}/dev/olpc/spiflash/spiif.fth    \ Generic low-level SPI bus access

fload ${BP}/dev/olpc/spiflash/spiflash.fth \ SPI FLASH programming

fload ${BP}/cpu/arm/mmp2/sspspi.fth        \ Synchronous Serial Port SPI interface

\ Create the top-level device node to access the entire boot FLASH device
0 0  " d4035000"  " /" begin-package
   " flash" device-name

   h# 10.0000 value /device
   my-address my-space h# 100 reg
   fload ${BP}/dev/nonmmflash.fth
end-package

\ Create a node below the top-level FLASH node to accessing the portion
\ containing the dropin modules
0 0  " 20000"  " /flash" begin-package
   " dropins" device-name

   h# e0000 constant /device
   fload ${BP}/dev/subrange.fth
end-package

devalias dropins /dropins

fload ${BP}/dev/olpc/confirm.fth             \ Selftest interaction modalities
fload ${BP}/cpu/arm/olpc/getmfgdata.fth      \ Get manufacturing data
fload ${BP}/cpu/x86/pc/olpc/mfgdata.fth      \ Manufacturing data
fload ${BP}/cpu/x86/pc/olpc/mfgtree.fth      \ Manufacturing data in device tree

fload ${BP}/dev/olpc/kb3700/eccmds.fth
: stand-power-off  ( -- )  ec-power-off  begin wfi again  ;
' stand-power-off to power-off

: olpc-reset-all  ( -- )
   " screen" " dcon-off" ['] execute-device-method catch if
      2drop 2drop
   then
   ec-power-cycle
   begin  wfi  again
;
' olpc-reset-all to reset-all
stand-init:
   ['] reset-all to bye
;

fload ${BP}/dev/olpc/kb3700/batstat.fth      \ Battery status reports
fload ${BP}/cpu/arm/olpc/boardrev.fth        \ Board revision decoding

false constant tethered?                     \ We only support reprogramming our own FLASH

[ifdef] olpc-cl3
: hdd-led-off     ( -- )  ;
: hdd-led-on      ( -- )  ;
: hdd-led-toggle  ( -- )  ;
[then]
[ifdef] olpc-cl2
: hdd-led-off     ( -- )  d# 10 gpio-clr  ;
: hdd-led-on      ( -- )  d# 10 gpio-set  ;
: hdd-led-toggle  ( -- )  d# 10 gpio-pin@  if  hdd-led-off  else  hdd-led-on  then  ;
[then]

fload ${BP}/cpu/arm/olpc/bbedi.fth
fload ${BP}/cpu/arm/olpc/edi.fth

load-base constant flash-buf

fload ${BP}/cpu/arm/olpc/ecflash.fth

: ec-spi-reprogrammed   ( -- )
   edi-spi-start
   set-ec-reboot
   unreset-8051
;

: ignore-power-button  ( -- )
   edi-spi-start
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

0 0  " d420b000"  " /" begin-package
   " display" name
\+ olpc-cl2   fload ${BP}/cpu/arm/olpc/1.75/lcdcfg.fth
\+ olpc-cl3   fload ${BP}/cpu/arm/olpc/3.0/lcdcfg.fth

   fload ${BP}/cpu/arm/olpc/lcd.fth
\+ olpc-cl2   fload ${BP}/dev/olpc/dcon/mmp2dcon.fth        \ DCON control
   defer convert-color ' noop to convert-color
   defer pixel*
   defer pixel+
   defer pixel!

   : color!  ( r g b index -- )  4drop  ;
   : color@  ( index -- r g b )  drop 0 0 0  ;

   fload ${BP}/dev/video/common/rectangle16.fth     \ Rectangular graphics

   depth d# 24 =  [if]
      code 3a+  ( adr n -- n' )
         pop  r0,sp
         inc  tos,#3
         add  tos,tos,r0
      c;
      code rgb888!  ( n adr -- )
         pop   r0,sp
         strb  r0,[tos]
         mov   r0,r0,lsr #8
         strb  r0,[tos,#1]
         mov   r0,r0,lsr #8
         strb  r0,[tos,#2]
         pop   tos,sp
      c;
      ' 3* to pixel*
      ' 3a+ to pixel+
      ' rgb888! to pixel!
      ' noop to convert-color
   [else]
      ' /w* to pixel*
      ' wa+ to pixel+
      ' w!  to pixel!
      ' argb>565-pixel to convert-color
   [then]

   : display-on
      init-xo-display  \ Turns on DCON etc
      frame-buffer-adr  hdisp vdisp * >bytes  h# ffffffff lfill
      init-lcd
   ;
   : map-frame-buffer  ( -- )
      \ We use fb-mem-va directly instead of calling map-in on the physical address
      \ because the physical address changes with the total memory size.  The early
      \ assembly language startup code establishes the mapping.
      fb-mem-va to frame-buffer-adr
   ;
   " display"                      device-type
   " ISO8859-1" encode-string    " character-set" property
   0 0  encode-bytes  " iso6429-1983-colors"  property

   \ Used as temporary storage for images by $get-image
   : graphmem  ( -- adr )  dimensions * pixel*  fb-mem-va +  ;

   : display-install  ( -- )
      map-frame-buffer
      display-on
      default-font set-font
      width  height                           ( width height )
      over char-width / over char-height /    ( width height rows cols )
      /scanline depth fb-install              ( )
   ;

   : display-remove  ( -- )  ;
   : display-selftest  ( -- failed? )  false  ;

   ' display-install  is-install
   ' display-remove   is-remove
   ' display-selftest is-selftest
end-package

devalias screen /display
   
\- olpc-cl3 devalias keyboard /keyboard

\+ olpc-cl2 create 15x30pc  " ${BP}/ofw/termemu/15x30pc.psf" $file,
\+ olpc-cl2 ' 15x30pc to romfont
\+ olpc-cl3 create cp881-16  " ${BP}/ofw/termemu/cp881-16.obf" $file,
\+ olpc-cl3 ' cp881-16 to romfont

fload ${BP}/cpu/arm/olpc/sdhci.fth
\- cl2-a1 fload ${BP}/cpu/arm/olpc/emmc.fth

devalias int /sd/disk@3
devalias ext /sd/disk@1
devalias net /wlan  \ XXX should report-net in case of USB Ethernet

fload ${BP}/dev/olpc/kb3700/spicmd.fth           \ EC SPI Command Protocol

\- olpc-cl3  fload ${BP}/cpu/arm/olpc/spcmd.fth   \ Security Processor communication protocol

: wlan-reset  ( -- )  d# 58 gpio-clr  d# 20 ms  d# 58 gpio-set  ;

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

fload ${BP}/cpu/arm/marvell/utmiphy.fth

fload ${BP}/ofw/core/fdt.fth
fload ${BP}/cpu/arm/linux.fth

\+ olpc-cl2 fload ${BP}/cpu/arm/olpc/1.75/usb.fth
\+ olpc-cl3 fload ${BP}/cpu/arm/mmp2/ulpiphy.fth
\+ olpc-cl3 fload ${BP}/cpu/arm/olpc/3.0/usb.fth

fload ${BP}/dev/olpc/mmp2camera/loadpkg.fth

fload ${BP}/cpu/arm/firfilter.fth

fload ${BP}/cpu/x86/adpcm.fth            \ ADPCM decoding
d# 32 is playback-volume

fload ${BP}/cpu/arm/olpc/sound.fth
fload ${BP}/cpu/arm/olpc/rtc.fth
stand-init: RTC
   " /rtc" open-dev  clock-node !
;

warning @ warning off
: stand-init
   stand-init
   root-device
      model-name$   2dup model     ( name$ )
      " OLPC " encode-bytes  2swap encode-string  encode+  " banner-name" property
      board-revision " board-revision-int" integer-property
\+ olpc-cl2  " olpc,xo-1.75" " compatible" string-property
\+ olpc-cl3  " olpc,xo-3.0"  " compatible" string-property

      \ The "1-" removes the null byte
      " SN" find-tag  if  1-  else  " Unknown"  then  " serial-number" string-property

      ec-api-ver@ " ec-version" integer-property

      ['] ec-name$  catch  0=  if  " ec-name" string-property  then
      ['] ec-date$  catch  0=  if  " ec-date" string-property  then
      ['] ec-user$  catch  0=  if  " ec-user" string-property  then
   dend

   " /openprom" find-device
      flash-open  pad d# 16  2dup  h# fffc0  flash-read  ( adr len )
      " model" string-property

      " sourceurl" find-drop-in  if  " source-url" string-property  then
   dend
;

warning !

stand-init: More memory
   extra-mem-va /extra-mem add-memory
;

fload ${BP}/cpu/arm/mmp2/thermal.fth
fload ${BP}/cpu/arm/mmp2/fuse.fth

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

\+ olpc-cl2 d#  9999 to arm-linux-machine-type  \ XO-1.75
\+ olpc-cl3 d# 10000 to arm-linux-machine-type  \ XO-3

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

: sec-trg   ( -- )      d# 73 gpio-set  ;  \ rising edge latches SPI_WP# low
: sec-trg?  ( -- bit )  d# 73 gpio-pin@  ;

alias ec-indexed-io-off sec-trg
alias ec-indexed-io-off? sec-trg?
alias ec-ixio-reboot ec-power-cycle  \ clears latch, brings SPI_WP# high

false value secure?

: protect-fw  ( -- )  secure?  if  flash-protect sec-trg  then  ;

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

\+ olpc-cl2 : rotate-button?  ( -- flag )  d# 15 gpio-pin@ 0=  ;
\+ olpc-cl3 false value rotate-button?
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
fload ${BP}/cpu/x86/pc/olpc/via/mfgtest.fth

[ifdef] notyet
fload ${BP}/cpu/x86/pc/olpc/via/bootmenu.fth
[then]

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

fload ${BP}/cpu/x86/pc/olpc/via/banner.fth

\- olpc-cl3  devalias keyboard /ap-sp/keyboard
\- olpc-cl3  devalias mouse    /ap-sp/mouse

: console-start  ( -- )
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

\ This must be defined after spiui.fth, otherwise spiui will choose some wrong code
: rom-pa  ( -- adr )  mfg-data-buf mfg-data-offset -  ;  \ Fake out setwp.fth
fload ${BP}/cpu/x86/pc/olpc/setwp.fth

fload ${BP}/cpu/arm/olpc/help.fth
fload ${BP}/cpu/x86/pc/olpc/gui.fth
fload ${BP}/cpu/x86/pc/olpc/strokes.fth
fload ${BP}/cpu/x86/pc/olpc/plot.fth

fload ${BP}/cpu/arm/mmp2/dramrecal.fth

code halt  ( -- )  wfi   c;

\+ olpc-cl3 fload ${BP}/cpu/arm/olpc/3.0/switches.fth  \ Switches
\+ olpc-cl2 fload ${BP}/cpu/arm/olpc/1.75/switches.fth \ Lid and ebook switches
fload ${BP}/cpu/arm/mmp2/rtc.fth       \ Internal RTC, used for wakeups
\+ olpc-cl3 fload ${BP}/cpu/arm/olpc/3.0/leds.fth     \ LEDs
\+ olpc-cl2 fload ${BP}/cpu/arm/olpc/1.75/leds.fth     \ LEDs
fload ${BP}/cpu/x86/pc/olpc/via/factory.fth  \ Manufacturing tools

fload ${BP}/cpu/arm/olpc/accelerometer.fth
\+ olpc-cl2 fload ${BP}/cpu/arm/olpc/1.75/compass.fth

\ Suppress long memory test at final test stage
dev /memory
0 value old-diag-switch?
: not-final-test?  ( -- flag )
   final-test?   if  false exit  then
   smt-test?  if  false exit  then
   old-diag-switch?
;
warning @ warning off
: selftest  ( -- error? )
   diag-switch? to old-diag-switch?
   not-final-test?  to diag-switch?
   selftest
   old-diag-switch? to diag-switch?
;
warning !
device-end

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

\ it seems to be difficult to get SoC wakeups from the keypad controller,
\ so we set them up as gpio, instead.
[ifdef] use_mmp2_keypad_control
fload ${BP}/cpu/arm/mmp2/keypad.fth
[ifdef] notdef  \ CForth turns on the keypad; resetting it makes it not work
stand-init: keypad
   keypad-on
   8 keypad-direct-mode
;
[then]
: keypad-bit  ( n keypad out-mask key-mask -- n' keypad )
   third invert  and  if    ( n keypad out-mask )
      rot or swap           ( n' keypad )
   else                     ( n keypad out-mask )
      drop                  ( n keypad )
   then                     ( n' keypad )
;
[then]

fload ${BP}/cpu/x86/pc/olpc/gamekeynames.fth

: game-key@  ( -- n )
   0                                        ( n )
[ifdef] cl2-a1
   d# 16 gpio-pin@ 0=  if  h#  80 or  then  \ O
   d# 17 gpio-pin@ 0=  if  h#  02 or  then  \ Check
   d# 18 gpio-pin@ 0=  if  h# 100 or  then  \ X
   d# 19 gpio-pin@ 0=  if  h#  01 or  then  \ Square
   d# 20 gpio-pin@ 0=  if  h#  40 or  then  \ Rotate
[then]
[ifdef] olpc-cl2
[ifdef] use_mmp2_keypad_control
   d# 15 gpio-pin@ 0=  if  button-rotate or  then   ( n )
   scan-keypad                              ( n keypad )
   button-o       h# 01  keypad-bit         ( n' keypad )
   button-check   h# 02  keypad-bit         ( n' keypad )
   button-x       h# 04  keypad-bit         ( n' keypad )
   button-square  h# 08  keypad-bit         ( n' keypad )
   rocker-up      h# 10  keypad-bit         ( n' keypad )
   rocker-right   h# 20  keypad-bit         ( n' keypad )
   rocker-down    h# 40  keypad-bit         ( n' keypad )
   rocker-left    h# 80  keypad-bit         ( n' keypad )
   drop                                     ( n )
[else]
   d# 15 gpio-pin@ 0=  if  button-rotate  or  then
   d# 16 gpio-pin@ 0=  if  button-o       or  then
   d# 17 gpio-pin@ 0=  if  button-check   or  then
   d# 18 gpio-pin@ 0=  if  button-x       or  then
   d# 19 gpio-pin@ 0=  if  button-square  or  then
   d# 20 gpio-pin@ 0=  if  rocker-up      or  then
   d# 21 gpio-pin@ 0=  if  rocker-right   or  then
   d# 22 gpio-pin@ 0=  if  rocker-down    or  then
   d# 23 gpio-pin@ 0=  if  rocker-left    or  then
[then]
[then]
;

fload ${BP}/cpu/x86/pc/olpc/gamekeys.fth

fload ${BP}/dev/logdev.fth

fload ${BP}/cpu/x86/pc/olpc/disptest.fth

[ifndef] olpc-cl3
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
\+ olpc-cl3 fload ${BP}/cpu/arm/olpc/exc7200-touchscreen.fth    \ Touchscreen driver and diagnostic
\+ olpc-cl3 fload ${BP}/dev/softkeyboard.fth                    \ On-screen keyboard
\+ olpc-cl3 devalias mouse /touchscreen
\+ olpc-cl2 fload ${BP}/cpu/arm/olpc/rm3150-touchscreen.fth    \ Touchscreen driver and diagnostic
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

\ idt1338 rtc and ram address map
\     00 -> 0f  rtc
\     10 -> 3f  cmos

: >rtc  ( index -- rtc-address )  h# 3f and  h# 10 +  ;

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

: dimmer  ( -- )  screen-ih  if  " dimmer" screen-ih $call-method  then  ;
: brighter  ( -- )  screen-ih  if  " brighter" screen-ih $call-method  then  ;

fload ${BP}/cpu/x86/pc/olpc/sound.fth
fload ${BP}/cpu/x86/pc/olpc/guardrtc.fth
fload ${BP}/cpu/x86/pc/olpc/security.fth
2 to bundle-suffix

stand-init: xid
   h# 83 cmos@  dup 1+  h# 83 cmos!   ( n )
   d# 24 lshift               ( new-xid )
   " dev /obp-tftp  to rpc-xid  dend" evaluate
;

: pre-setup-for-linux  ( -- )
   [ ' linux-pre-hook behavior compile, ]    \ Chain to old behavior
   sound-end
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
devalias fsdisk int:0

\ create pong-use-touchscreen
fload ${BP}/ofw/gui/ofpong.fth
fload ${BP}/cpu/x86/pc/olpc/life.fth

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

fload ${BP}/ofw/core/countdwn.fth	\ Startup countdown

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
      time&date 5drop 1 and  if
         ['] pong guarded
      else
         ['] life-demo guarded
      then
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

[ifdef] olpc-cl3
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

fload ${BP}/cpu/arm/olpc/testitems.fth
\+ olpc-cl3 fload ${BP}/cpu/arm/olpc/3.0/testinstructions.fth
\+ olpc-cl2 fload ${BP}/cpu/arm/olpc/1.75/testinstructions.fth

fload ${BP}/cpu/arm/mmp2/clocks.fth

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

   show-child

   update-ec-flash?  if
      ['] ?enough-power catch  ?dup  if  ( error )
	 show-no-power
	 .error
	 ." Skipping EC reflash, not enough power" cr
	 d# 1000 ms
      else
	 show-reflash
	 ['] show-reflash-dot to edi-progress
	 update-ec-flash
      then
   then
\+ olpc-cl3  open-hotspot

   install-alarm
   ?sound

   ?games

   ['] false to interrupt-auto-boot?
\+ olpc-cl3  ?text-on
[ifdef] probe-usb
   factory-test?  if  d# 1000 ms  then  \ Extra USB probe delay in the factory
   probe-usb
   report-disk
   report-keyboard
[then]
   " probe+" do-drop-in

   interpreter-init

\+ olpc-cl3  ?text-on
   ?diags
   ?fs-update

   factory-test? 0=  if  secure-startup  then
   unblock-exceptions
   ['] (interrupt-auto-boot?) to interrupt-auto-boot?

\+ olpc-cl3  ?text-on
   ?usb-keyboard

   auto-banner?  if  banner  then

\+ olpc-cl3  ?text-on
   auto-boot
\+ olpc-cl3  close-hotspot

\+ olpc-cl3  open-screen-keyboard  banner

   frozen? text-on? 0=  and  ( no-banner? )
   unfreeze visible cursor-on ( no-banner? )
   if  banner  then  \ Reissue banner if it was suppressed

   blue-letters ." Type 'help' for more information." black-letters cancel
   cr cr

   enable-user-aborts
   stop-sound   
   quit
;

: newrom
   " flash! http:\\192.168.200.200\new.rom" eval
;
: newec
   " flash-ec http:\\192.168.200.200\ecimage.bin" eval
;
: qz
   " qz" $essid  " http:\\qz\" included  \ qa test bed scripting, james cameron
;
: urom  " flash! u:\new.rom" eval  ;
: uec   " flash-ec! u:\ecimage.bin" eval  ;
: erom  " flash! ext:\new.rom" eval  ;
: no-usb-delay  " dev /usb  false to delay?  dend"  evaluate  ;
: null-fsdisk
   " dev /null : write-blocks-start 3drop ; : write-blocks-finish ; dend" evaluate
   " devalias fsdisk //null" evaluate
;

tag-file @ fclose  tag-file off
my-self [if]
   ." WARNING: my-self is not 0" cr
   bye
[then]

.( --- Saving fw.dic ...)
" fw.dic" $save-forth cr

fload ${BP}/cpu/arm/mmp2/rawboot.fth

.( --- Saving fw.img --- )  cr " fw.img" $save-rom

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
