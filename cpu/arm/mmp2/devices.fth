fload ${BP}/dev/omap/diaguart.fth	\ OMAP UART
h# 018000 +io to uart-base		\ UART# base address on MMP2
d# 26000000 to uart-clock-frequency

: init-clocks
   -1    h# 1024 mpmu!   \ PMUM_CGR_PJ - everything on
   h# 07 h#   64 apbc!   \ APBC_AIB_CLK_RST - reset, functional and APB clock on
   h# 03 h#   64 apbc!   \ APBC_AIB_CLK_RST - release reset, functional and APB clock on
   h# 13 h#   34 apbc!   \ APBC_UART3_CLK_RST - VCTCXO, functional and APB clock on (26 mhz)
   h# c1 d#   51   af!   \ GPIO51 = af1 for UART3 RXD
   h# c1 d#   51   af!   \ GPIO52 = af1 for UART3 TXD
   h# 1b h#   54 pmua!   \ SD0 clocks
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

fload ${BP}/cpu/arm/mmp2/boardtwsi.fth
fload ${BP}/cpu/arm/mmp2/boardgpio.fth
: init-stuff
   set-camera-domain-voltage
   acgr-clocks-on
   init-mfprs
   set-gpio-directions
   init-timers
   init-twsi
   power-on-dsi
   power-on-sd
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

0 0  " d420b000"  " /" begin-package
   " display" name
   fload ${BP}/cpu/arm/mmp2/lcdcfg.fth
   fload ${BP}/cpu/arm/mmp2/dsi.fth

   fload ${BP}/cpu/arm/mmp2/lcd.fth
   : display-on
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

fload ${BP}/ofw/termemu/cp881-16.fth

fload ${BP}/cpu/arm/mmp2/sdhcimmp2.fth

devalias ext /sd/disk@1

fload ${BP}/dev/olpc/kb3700/spicmd.fth

0 0  " d4208000"  " /" begin-package
   h# 200 constant /regs
   my-address my-space /regs reg
   : my-map-in  ( len -- adr )
      my-space swap  " map-in" $call-parent  h# 100 +  ( adr )
      3 over h# a8 + rl!   ( adr )  \ Force host mode
   ;
   : my-map-out  ( adr len -- )  swap h# 100 - swap " map-out" $call-parent  ;
   false constant has-dbgp-regs?
   false constant needs-dummy-qh?
   : grab-controller  ( config-adr -- error? )  drop false  ;
   fload ${BP}/dev/usb2/hcd/ehci/loadpkg.fth
end-package
   
: usb-power-on  ( -- )  d# 82 gpio-set  ;  \ 1 instead of 82 for XO

fload ${BP}/cpu/arm/marvell/utmiphy.fth
stand-init: Init USB Phy
   init-usb-phy
;

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
