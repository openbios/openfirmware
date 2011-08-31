fload ${BP}/dev/omap/diaguart.fth	\ OMAP UART

h# 18000 +io to uart-base		\ UART3 base address on MMP2
\ h# 30000 +io to uart-base		\ UART1 base address on MMP2
d# 26000000 to uart-clock-frequency

: init-clocks
   -1    h# 51024 io!   \ PMUM_CGR_PJ - everything on
   h# 07 h# 15064 io!   \ APBC_AIB_CLK_RST - reset, functional and APB clock on
   h# 03 h# 15064 io!   \ APBC_AIB_CLK_RST - release reset, functional and APB clock on
   h# 13 h# 1502c io!   \ APBC_UART1_CLK_RST - VCTCXO, functional and APB clock on (26 mhz)
   h# 13 h# 15034 io!   \ APBC_UART3_CLK_RST - VCTCXO, functional and APB clock on (26 mhz)
   h# c1 h# 1e0c8 io!   \ GPIO29 = af1 for UART1 RXD
   h# c1 h# 1e0cc io!   \ GPIO30 = af1 for UART1 TXD
   h# c4 h# 1e260 io!   \ GPIO115 = af4 for UART3 RXD
   h# c4 h# 1e264 io!   \ GPIO116 = af4 for UART3 TXD
;

: inituarts  ( -- )
   init-clocks

   h# 40 1 uart!          \ Marvell-specific UART Enable bit
   3 3 uart!              \ 8 bits, no parity
   7 2 uart!		  \ Clear and enable FIFOs
   d# 115200 baud
;

fload ${BP}/forth/lib/sysuart.fth	\ Set console I/O vectors to UART

0 value keyboard-ih

fload ${BP}/ofw/core/muxdev.fth          \ I/O collection/distribution device

\ Install the simple UART driver from the standalone I/O init chain
warning off
: stand-init-io  ( -- )
   stand-init-io
   inituarts  install-uart-io
   ." UART installed" cr
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

fload ${BP}/cpu/arm/olpc/1.75/smbus.fth    \ Bit-banged SMBUS (I2C) using GPIOs

fload ${BP}/dev/olpc/spiflash/flashif.fth  \ Generic FLASH interface

fload ${BP}/dev/olpc/spiflash/spiif.fth    \ Generic low-level SPI bus access

fload ${BP}/dev/olpc/spiflash/spiflash.fth \ SPI FLASH programming

: ignore-power-button ;  \ XXX implement me

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
fload ${BP}/cpu/arm/olpc/1.75/getmfgdata.fth \ Get manufacturing data
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
fload ${BP}/cpu/arm/olpc/1.75/boardrev.fth   \ Board revision decoding

false constant tethered?                     \ We only support reprogramming our own FLASH

: hdd-led-off     ( -- )  d# 10 gpio-clr  ;
: hdd-led-on      ( -- )  d# 10 gpio-set  ;
: hdd-led-toggle  ( -- )  d# 10 gpio-pin@  if  hdd-led-off  else  hdd-led-on  then  ;

fload ${BP}/dev/olpc/spiflash/spiui.fth      \ User interface for SPI FLASH programming
\ fload ${BP}/dev/olpc/spiflash/recover.fth    \ XO-to-XO SPI FLASH recovery
: ofw-fw-filename$  " disk:\boot\olpc.rom"  ;
' ofw-fw-filename$ to fw-filename$

fload ${BP}/cpu/arm/olpc/1.75/bbedi.fth
fload ${BP}/cpu/arm/olpc/1.75/edi.fth

fload ${BP}/cpu/arm/olpc/1.75/ecflash.fth

0 0  " d420b000"  " /" begin-package
   " display" name
   fload ${BP}/cpu/arm/olpc/1.75/lcdcfg.fth

   fload ${BP}/cpu/arm/olpc/1.75/lcd.fth
   fload ${BP}/dev/olpc/dcon/mmp2dcon.fth        \ DCON control
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
\      init-xo-display  \ Turns on DCON
      smb-init
      frame-buffer-adr  hdisp vdisp * >bytes  h# ffffffff lfill
      init-lcd
   ;
   : map-frame-buffer  ( -- )
      fb-mem-pa /fb-mem " map-in" $call-parent to frame-buffer-adr
   ;
   " display"                      device-type
   " ISO8859-1" encode-string    " character-set" property
   0 0  encode-bytes  " iso6429-1983-colors"  property

   \ Used as temporary storage for images by $get-image
   : graphmem  ( -- adr )  dimensions * pixel*  fb-mem-pa +  ;

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
   
devalias keyboard /keyboard

create 15x30pc  " ${BP}/ofw/termemu/15x30pc.psf" $file,
' 15x30pc to romfont

fload ${BP}/cpu/arm/olpc/1.75/sdhci.fth
[ifndef] cl2-a1
fload ${BP}/cpu/arm/olpc/1.75/emmc.fth
[then]

devalias int /sd/disk@3
devalias ext /sd/disk@1
devalias net /wlan  \ XXX should report-net in case of USB Ethernet

fload ${BP}/dev/olpc/kb3700/spicmd.fth
fload ${BP}/cpu/arm/olpc/spcmd.fth

devalias keyboard /ec-spi/keyboard

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

fload ${BP}/cpu/arm/olpc/1.75/usb.fth

fload ${BP}/cpu/arm/marvell/utmiphy.fth

: init-usb  ( -- )
   h# 9 h# 28285c io!  \ Enable clock to USB block
   reset-usb-hub
   init-usb-phy
;

stand-init: Init USB Phy
\  usb-power-on   \ The EC now controls the USB power
   init-usb
;

fload ${BP}/dev/olpc/mmp2camera/loadpkg.fth

fload ${BP}/cpu/x86/adpcm.fth            \ ADPCM decoding
d# 32 is playback-volume

fload ${BP}/cpu/arm/olpc/1.75/sound.fth
fload ${BP}/cpu/arm/olpc/1.75/rtc.fth
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
      " olpc,xo-1.75" " compatible" string-property

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

fload ${BP}/cpu/arm/mmp2/dramrecal.fth
fload ${BP}/cpu/arm/mmp2/rtc.fth       \ Internal RTC, used for wakeups

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
