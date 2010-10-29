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
   d# 38400 baud
;

fload ${BP}/forth/lib/sysuart.fth	\ Set console I/O vectors to UART

0 value keyboard-ih
0 value screen-ih

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

fload ${BP}/cpu/arm/mmp2/timer.fth
fload ${BP}/cpu/arm/mmp2/twsi.fth
fload ${BP}/cpu/arm/mmp2/mfpr.fth
fload ${BP}/cpu/arm/mmp2/gpio.fth

\ fload ${BP}/cpu/arm/olpc/1.75/boardtwsi.fth
fload ${BP}/cpu/arm/olpc/1.75/boardgpio.fth
: init-stuff
\   set-camera-domain-voltage
   acgr-clocks-on
   init-mfprs
   set-gpio-directions
   init-timers
   init-twsi
\   power-on-dsi
\   power-on-sd
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

[ifdef] notyet
fload ${BP}/dev/olpc/confirm.fth             \ Selftest interaction modalities
fload ${BP}/cpu/x86/pc/olpc/mfgdata.fth      \ Manufacturing data
fload ${BP}/cpu/x86/pc/olpc/mfgtree.fth      \ Manufacturing data in device tree
fload ${BP}/cpu/x86/pc/olpc/kbdtype.fth      \ Export keyboard type

fload ${BP}/dev/olpc/kb3700/battery.fth      \ Battery status reports
[else]
: find-tag  ( adr len -- false | value$ true )  2drop false  ;
[then]

fload ${BP}/dev/olpc/spiflash/flashif.fth   \ Generic FLASH interface

fload ${BP}/dev/olpc/spiflash/spiif.fth    \ Generic low-level SPI bus access
fload ${BP}/dev/olpc/spiflash/spiflash.fth \ SPI FLASH programming

: ignore-power-button ;  \ XXX implement me
: ssp-spi-reprogrammed ;
: ?erased  ( adr len -- flag )  2drop true  ;
: ?enough-power  ( -- )  ;

fload ${BP}/cpu/arm/mmp2/sspspi.fth        \ Synchronous Serial Port SPI interface

fload ${BP}/cpu/arm/olpc/1.75/spiui.fth    \ User interface for SPI FLASH programming
\ fload ${BP}/dev/olpc/spiflash/recover.fth    \ XO-to-XO SPI FLASH recovery
: ofw-fw-filename$  " disk:\boot\olpc.rom"  ;
' ofw-fw-filename$ to fw-filename$

0 0  " d420b000"  " /" begin-package
   " display" name
   fload ${BP}/cpu/arm/olpc/1.75/lcdcfg.fth

   fload ${BP}/cpu/arm/olpc/1.75/lcd.fth
   fload ${BP}/cpu/arm/olpc/1.75/dconsmb.fth     \ SMB access to DCON chip - bitbanged
   fload ${BP}/dev/olpc/dcon/mmp2dcon.fth        \ DCON control

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

\ fload ${BP}/ofw/termemu/cp881-16.fth

fload ${BP}/cpu/arm/olpc/1.75/sdhci.fth

devalias int /sd@d4281000/disk
devalias ext /sd@d4280000/disk

fload ${BP}/dev/olpc/kb3700/spicmd.fth

devalias keyboard /ec-spi/keyboard

0 0  " d4208000"  " /" begin-package  \ USB Host Controller
   h# 200 constant /regs
   my-address my-space /regs reg
   : my-map-in  ( len -- adr )
      my-space swap  " map-in" $call-parent  h# 100 +  ( adr )
      3 over h# a8 + rl!   ( adr )  \ Force host mode
   ;
   : my-map-out  ( adr len -- )  swap h# 100 - swap " map-out" $call-parent  ;
   false constant has-dbgp-regs?
   false constant needs-dummy-qh?
   false constant grab-controller
   fload ${BP}/dev/usb2/hcd/ehci/loadpkg.fth
end-package
   
: usb-power-on  ( -- )  1 gpio-set  ;
: unreset-usb-hub  ( -- )  d# 146 gpio-set  ;

fload ${BP}/cpu/arm/marvell/utmiphy.fth

: start-usb  ( -- )
   h# 9 h# d428285c l!  \ Enable clock to USB block
   unreset-usb-hub
   init-usb-phy
;

0 [if]
stand-init: Init USB Phy
\  usb-power-on   \ The EC now controls the USB power
   start-usb
;
[then]

fload ${BP}/dev/olpc/mmp2camera/loadpkg.fth

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
