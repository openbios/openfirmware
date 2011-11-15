purpose: Platform-specific layout of diagnostic GUI menu items

d# 6 to #mfgcols
d# 4 to #mfgrows

: dummy-test-dev  ( $ -- )
   clear-n-restore-scroller
   ??cr  ." Testing " type ."  - to be implemented" cr
   mfg-color-green sq-border!
   d# 2000 hold-message drop
   cursor-off  gui-alerts  refresh
   flush-keyboard
;

: mfg-test-disk  ( name$ -- )
   clear-n-restore-scroller
   ??cr  ." Testing " 2dup type cr

   ['] $.partitions  catch  if
      2drop false
   else
      0 true
   then

   d# 2000 ms  \ More time to inspect

   mfg-test-result
;

icon: play.icon     rom:play.565
icon: quit.icon     rom:quit.565
icon: cpu.icon      rom:cpu.565
icon: spi.icon      rom:spi.565
icon: ram.icon      rom:ram.565
icon: sdcard.icon   rom:sdcard.565
icon: usb.icon      rom:usb.565
icon: battery.icon  rom:battery.565
icon: camera.icon   rom:camera.565
icon: wifi.icon     rom:wifi.565
icon: audio.icon    rom:audio.565
icon: touchpad.icon rom:touchpad.565
icon: display.icon  rom:display.565
icon: keyboard.icon rom:keyboard.565
icon: timer.icon    rom:timer.565
icon: clock.icon    rom:clock.565
icon: ebook.icon    rom:ebook.565
icon: leds.icon     rom:leds.565

: cpu-item      ( -- )  " /cpu"       mfg-test-dev  ;
: battery-item  ( -- )  " /battery"   dummy-test-dev  ;
: spiflash-item ( -- )  " /flash"     mfg-test-dev  ;
: memory-item   ( -- )  " /memory"    mfg-test-dev  ;
: usb-item      ( -- )  " /usb"       mfg-test-dev  ;
: int-sd-item   ( -- )  " disk"       mfg-test-disk  ;
\ : ext-sd-item   ( -- )  " ext:0"      mfg-test-dev  ;
: rtc-item      ( -- )  " /rtc"       mfg-test-dev  ;
: display-item  ( -- )  " screen"     mfg-test-dev  ;
: audio-item    ( -- )  " /audio"     dummy-test-dev  ;
: camera-item   ( -- )  " /camera"    mfg-test-dev  ;
: wlan-item     ( -- )  " /wlan"      dummy-test-dev  ;
: timer-item    ( -- )  " /timer"     mfg-test-dev  ;
: touchpad-item ( -- )  " /mouse"     mfg-test-dev  ;
: keyboard-item ( -- )  " /keyboard"  mfg-test-dev  ;
: switch-item   ( -- )  " /switches"  mfg-test-dev  ;
: leds-item     ( -- )  " /leds"      mfg-test-dev  ;

: alex-test-menu-items  ( -- )
   silent-probe-usb

   0 to #mfgtests
   0 1 set-col-row

   " CPU"
   ['] cpu-item      cpu.icon      add-icon

   " SPI Flash: Contains EC code, firmware, manufacturing data."
   ['] spiflash-item    spi.icon   add-icon

   " RAM chips"
   ['] memory-item   ram.icon      add-icon

   " Internal mass storage"
   ['] int-sd-item   sdcard.icon   add-icon

\   " Plug-in SD card"
\   ['] ext-sd-item   sdcard.icon   add-icon

   " Timer"
   ['] timer-item    timer.icon    add-icon

   " RTC (Real-Time Clock)"
   ['] rtc-item      clock.icon    add-icon

   " Keyboard"
   ['] keyboard-item keyboard.icon add-icon

   " Touchpad"
   ['] touchpad-item touchpad.icon add-icon

   " Display"
   ['] display-item  display.icon  add-icon

   " Camera"
   ['] camera-item   camera.icon   add-icon

   " Audio: Speaker and microphone"
   ['] audio-item    audio.icon    add-icon

   " Wireless LAN"
   ['] wlan-item     wifi.icon     add-icon

   " USB ports"
   ['] usb-item      usb.icon      add-icon

   " Battery"
   ['] battery-item  battery.icon  add-icon

   \ These are last because they require user participation.
   \ The earlier tests are all included in automatic batch-mode.

\   " LEDs"
\   ['] leds-item     leds.icon     add-icon

\   " Switches"
\   ['] switch-item   ebook.icon    add-icon
;

' alex-test-menu-items to test-menu-items
