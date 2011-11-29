purpose: Platform-specific layout of diagnostic GUI menu items

d# 5 to #mfgcols
d# 4 to #mfgrows

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
: battery-item  ( -- )  " /battery"   mfg-test-dev  ;
: spiflash-item ( -- )  " /flash"     mfg-test-dev  ;
: memory-item   ( -- )  " /memory"    mfg-test-dev  ;
: usb-item      ( -- )  " /usb"       mfg-test-dev  ;
: int-sd-item   ( -- )  " int:0"      mfg-test-dev  ;
: ext-sd-item   ( -- )  " ext:0"      mfg-test-dev  ;
: rtc-item      ( -- )  " /rtc"       mfg-test-dev  ;
: display-item  ( -- )  " /display"   mfg-test-dev  ;
: audio-item    ( -- )  " /audio"     mfg-test-dev  ;
: camera-item   ( -- )  " /camera"    mfg-test-dev  ;
: wlan-item     ( -- )  " /wlan"      mfg-test-dev  ;
: timer-item    ( -- )  " /timer"     mfg-test-dev  ;
: touchpad-item ( -- )  " /8042/mouse"     mfg-test-dev  ;
: keyboard-item ( -- )  " /8042/keyboard"  mfg-test-dev  ;
: switch-item   ( -- )  " /switches"  mfg-test-dev  ;
: leds-item     ( -- )  " /leds"      mfg-test-dev  ;

: olpc-test-menu-items  ( -- )
   0 to #mfgtests
   1 0 set-row-col

\   " CPU"
\   ['] cpu-item      cpu.icon      add-icon

   " SPI Flash: Contains EC code, firmware, manufacturing data."
   ['] spiflash-item    spi.icon    add-icon

   " RAM chips"
   ['] memory-item   ram.icon       add-icon

   " Internal mass storage"
   ['] int-sd-item   sdcard.icon    add-icon

   " Plug-in SD card"
   ['] ext-sd-item   sdcard.icon    add-icon

   " Wireless LAN"
   ['] wlan-item     wifi.icon      add-icon

   " Display"
   ['] display-item  display.icon   add-icon

   " Camera"
   ['] camera-item   camera.icon    add-icon

   " Audio: Speaker and microphone"
   ['] audio-item    audio.icon     add-icon

   " Battery"
   ['] battery-item  battery.icon   add-icon

   " RTC (Real-Time Clock)"
   ['] rtc-item      clock.icon     add-icon

   " USB ports"
   ['] usb-item      usb.icon       add-icon

   \ These are last because they require user participation.
   \ The earlier tests are all included in automatic batch-mode.

   " Keyboard"
   ['] keyboard-item keyboard.icon  add-icon

   " Touchpad"
   ['] touchpad-item touchpad.icon  add-icon

   " LEDs"
   ['] leds-item     leds.icon      add-icon

   " Switches"
   ['] switch-item   ebook.icon     add-icon
;
' olpc-test-menu-items to test-menu-items
