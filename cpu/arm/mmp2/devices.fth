fload ${BP}/dev/omap/diaguart.fth	\ OMAP UART
h# d4018000 to uart-base		\ UART# base address on MMP2
d# 26000000 to uart-clock-frequency
defer init-clocks  ' noop to init-clocks
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

fload ${BP}/cpu/arm/mmp2/twsi.fth
fload ${BP}/cpu/arm/mmp2/timer.fth
fload ${BP}/cpu/arm/mmp2/mfpr.fth
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

fload ${BP}/cpu/arm/mmp2/gpio.fth

fload ${BP}/cpu/arm/mmp2/watchdog.fth	\ reset-all using watchdog timer

0 0  " d4018000"  " /" begin-package
   " uart" name
   h# d4018000  h# 20  reg

   : write  ( adr len -- actual )
      0 max  tuck                    ( actual adr actual )
      bounds  ?do  i c@ uemit  loop  ( actual )
   ;
   : read   ( adr len -- actual )
      0=  if  drop 0  exit  then
      ukey?  if           ( adr )
         ukey swap c!  1  ( actual )
      else                ( adr )
         drop  -2         ( -2 )
      then
   ;
   : open  ( -- okay? )  true  ;
   : close  ( -- )   ;
   : install-abort  ;
   : remove-abort  ;
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

d# 3000 to ms-factor

fload ${BP}/cpu/arm/mmp2/sdhcimmp2.fth

devalias ext /sd/disk@1

fload ${BP}/dev/olpc/kb3700/spicmd.fth
   
