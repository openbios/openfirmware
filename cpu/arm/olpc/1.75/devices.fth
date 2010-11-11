fload ${BP}/dev/omap/diaguart.fth	\ OMAP UART
h# d4018000 to uart-base		\ UART3 base address on MMP2
\ h# d4030000 to uart-base		\ UART1 base address on MMP2
d# 26000000 to uart-clock-frequency

: init-clocks
   -1    h# d4051024 l!   \ PMUM_CGR_PJ - everything on
   h# 07 h# d4015064 l!   \ APBC_AIB_CLK_RST - reset, functional and APB clock on
   h# 03 h# d4015064 l!   \ APBC_AIB_CLK_RST - release reset, functional and APB clock on
   h# 13 h# d401502c l!   \ APBC_UART1_CLK_RST - VCTCXO, functional and APB clock on (26 mhz)
   h# 13 h# d4015034 l!   \ APBC_UART3_CLK_RST - VCTCXO, functional and APB clock on (26 mhz)
   h# c1 h# d401e0c8 l!   \ GPIO29 = af1 for UART1 RXD
   h# c1 h# d401e0cc l!   \ GPIO30 = af1 for UART1 TXD
   h# c4 h# d401e260 l!   \ GPIO115 = af4 for UART3 RXD
   h# c4 h# d401e264 l!   \ GPIO116 = af4 for UART3 TXD
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

\ fload ${BP}/cpu/arm/olpc/1.75/boardtwsi.fth
fload ${BP}/cpu/arm/olpc/1.75/boardgpio.fth
: init-stuff
   acgr-clocks-on
   init-mfprs
   set-gpio-directions
   init-timers
   init-twsi
;
stand-init:
   init-stuff
;

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
: ssp-spi-reprogrammed ;
: ?enough-power  ( -- )  ;

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

[ifdef] notyet
fload ${BP}/dev/olpc/kb3700/battery.fth      \ Battery status reports
[then]

false constant tethered?                     \ We only support reprogramming our own FLASH

fload ${BP}/dev/olpc/spiflash/spiui.fth      \ User interface for SPI FLASH programming
\ fload ${BP}/dev/olpc/spiflash/recover.fth    \ XO-to-XO SPI FLASH recovery
: ofw-fw-filename$  " disk:\boot\olpc.rom"  ;
' ofw-fw-filename$ to fw-filename$

0 0  " d420b000"  " /" begin-package
   " display" name
   fload ${BP}/cpu/arm/olpc/1.75/lcdcfg.fth

   fload ${BP}/cpu/arm/olpc/1.75/lcd.fth
   fload ${BP}/dev/olpc/dcon/mmp2dcon.fth        \ DCON control
   defer pixel*
   defer pixel+
   defer pixel!
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
   [else]
      ' /w* to pixel*
      ' wa+ to pixel+
      ' w!  to pixel!
   [then]

   : display-on
      init-xo-display  \ Turns on DCON
      init-lcd
      fb-pa  hdisp vdisp * >bytes  h# ff fill
   ;
   : map-frame-buffer  ( -- )
      fb-pa to frame-buffer-adr
   ;
   " display"                      device-type
   " ISO8859-1" encode-string    " character-set" property
   0 0  encode-bytes  " iso6429-1983-colors"  property

   : display-install  ( -- )
      display-on
      default-font set-font
      map-frame-buffer
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

devalias int /sd@d4281000/disk
devalias ext /sd@d4280000/disk
devalias net /wlan  \ XXX should report-net in case of USB Ethernet

fload ${BP}/dev/olpc/kb3700/spicmd.fth

devalias keyboard /ec-spi/keyboard

fload ${BP}/cpu/arm/olpc/1.75/ecflash.fth

0 0  " d4208000"  " /" begin-package  \ USB Host Controller
   h# 200 constant /regs
   my-address my-space /regs reg
   : my-map-in  ( len -- adr )
      my-space swap  " map-in" $call-parent  h# 100 +  ( adr )
   ;
   : my-map-out  ( adr len -- )  swap h# 100 - swap " map-out" $call-parent  ;
   false constant has-dbgp-regs?
   false constant needs-dummy-qh?
   : grab-controller  ( config-adr -- error? )  drop false  ;
   fload ${BP}/dev/usb2/hcd/ehci/loadpkg.fth
   : otg-set-host-mode  3 h# a8 ehci-reg!  ;  \ Force host mode
   ' otg-set-host-mode to set-host-mode

end-package
   
\ : usb-power-on  ( -- )  1 gpio-set  ; 
: usb-power-on  ( -- )  ;  \ The EC controls the USB power
: reset-usb-hub  ( -- )  d# 146 gpio-set  d# 10 ms  d# 146 gpio-set  ;

fload ${BP}/cpu/arm/marvell/utmiphy.fth

: init-usb  ( -- )
   h# 9 h# d428285c l!  \ Enable clock to USB block
   reset-usb-hub
   init-usb-phy
;

stand-init: Init USB Phy
\  usb-power-on   \ The EC now controls the USB power
   init-usb
;

fload ${BP}/dev/olpc/mmp2camera/loadpkg.fth

fload ${BP}/cpu/arm/olpc/1.75/sound.fth
fload ${BP}/cpu/arm/olpc/1.75/rtc.fth
fload ${BP}/cpu/arm/olpc/1.75/accelerometer.fth
fload ${BP}/cpu/arm/olpc/1.75/compass.fth

warning @ warning off
: stand-init
   stand-init
   root-device
[ifdef] notyet
      model-name$   2dup model     ( name$ )
      " OLPC " encode-bytes  2swap encode-string  encode+  " banner-name" property
      board-revision " board-revision-int" integer-property
[then]
      \ The "1-" removes the null byte
      " SN" find-tag  if  1-  else  " Unknown"  then  " serial-number" string-property
[ifdef] notyet
      8 ec-cmd-b@ dup " ec-version" integer-property

      XXX Get EC name with an EC command
      " ec-name" string-property
[then]
   dend

   " /openprom" find-device
      flash-open  pad d# 16  2dup  h# fffc0  flash-read  ( adr len )
      " model" string-property

      " sourceurl" find-drop-in  if  " source-url" string-property  then
   dend
;
warning !

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
