icon: cpu.icon      rom:cpu.565
icon: spi.icon      rom:spi.565
icon: ram.icon      rom:ram.565
icon: sdcard.icon   rom:sdcard.565
icon: usb.icon      rom:usb.565
icon: battery.icon  rom:battery.565
icon: camera.icon   rom:camera.565
icon: wifi.icon     rom:wifi.565
icon: audio.icon    rom:audio.565
\- olpc-cl3 icon: touchpad.icon rom:touchpad.565
\+ olpc-cl3 icon: touchscreen.icon rom:touchpad.565
icon: display.icon  rom:display.565
\- olpc-cl3 icon: keyboard.icon rom:keyboard.565
icon: timer.icon    rom:timer.565
icon: clock.icon    rom:clock.565
icon: ebook.icon    rom:ebook.565
icon: leds.icon     rom:leds.565

d# 15 to #mfgtests
d# 5 to #mfgcols
d# 4 to #mfgrows

: cpu-item      ( -- )  " /cpu"       mfg-test-dev  ;
: battery-item  ( -- )  " /battery"   mfg-test-dev  ;
: spiflash-item ( -- )  " /flash"     mfg-test-dev  ;
: memory-item   ( -- )  " /memory"    mfg-test-dev  ;
\+ olpc-cl2  : usb-item   ( -- )  " /usb/hub"   mfg-test-dev  ;
\+ olpc-cl3  : otg-item   ( -- )  " otg"        mfg-test-dev  ;
\+ olpc-cl3  : usb-item   ( -- )  " usba"       mfg-test-dev  ;
: int-sd-item   ( -- )  " int:0"      mfg-test-dev  ;
\- olpc-cl3 : ext-sd-item   ( -- )  " ext:0"      mfg-test-dev  ;
: rtc-item      ( -- )  " /rtc"       mfg-test-dev  ;
: display-item  ( -- )  " /display"   mfg-test-dev  ;
: audio-item    ( -- )  " /audio"     mfg-test-dev  ;
: camera-item   ( -- )  " /camera"    mfg-test-dev  ;
: wlan-item     ( -- )  " /wlan"      mfg-test-dev  ;
: timer-item    ( -- )  " /timer"     mfg-test-dev  ;
\- olpc-cl3 : touchpad-item ( -- )  " /touchpad"  mfg-test-dev  ;
\+ olpc-cl3 : touchscreen-item ( -- )  " /touchscreen"  mfg-test-dev  ;
\- olpc-cl3 : keyboard-item ( -- )  " keyboard"   mfg-test-dev  ;
: switch-item   ( -- )  " /accelerometer" mfg-test-dev  " /switches"  mfg-test-dev  ;
: leds-item     ( -- )  " /leds"      mfg-test-dev   ;

: olpc-test-menu-items  ( -- )
   clear-menu

\   " CPU"
\   ['] cpu-item      cpu.icon      1 0 install-icon

   " SPI Flash: Contains EC code, firmware, manufacturing data."
   ['] spiflash-item    spi.icon      1 0 install-icon

   " RAM chips"
   ['] memory-item   ram.icon      1 1 install-icon

   " Internal mass storage"
   ['] int-sd-item   sdcard.icon   1 2 install-icon

\- olpc-cl3    " Plug-in SD card"
\- olpc-cl3    ['] ext-sd-item   sdcard.icon   1 3 install-icon

   " Wireless LAN"
   ['] wlan-item     wifi.icon     1 4 install-icon

   " Display"
   ['] display-item  display.icon  2 0 install-icon

   " Camera"
   ['] camera-item   camera.icon   2 1 install-icon

   " Audio: Speaker and microphone"
   ['] audio-item    audio.icon    2 2 install-icon

   " Battery"
   ['] battery-item  battery.icon  2 3 install-icon

   " RTC (Real-Time Clock)"
   ['] rtc-item      clock.icon    2 4 install-icon

\+ olpc-cl2  " USB ports"
\+ olpc-cl3  " USB-A port"
   ['] usb-item      usb.icon      3 0 install-icon

\+ olpc-cl3  " USB OTG port"
\+ olpc-cl3   ['] otg-item      usb.icon      3 1 install-icon

   \ These are last because they require user participation.
   \ The earlier tests are all included in automatic batch-mode.

\- olpc-cl3    " Keyboard"
\- olpc-cl3    ['] keyboard-item keyboard.icon 3 1 install-icon

\- olpc-cl3    " Touchpad"
\- olpc-cl3    ['] touchpad-item touchpad.icon 3 2 install-icon

\+ olpc-cl3    " Touchscreen"
\+ olpc-cl3    ['] touchscreen-item touchscreen.icon 3 2 install-icon

   " LEDs"
   ['] leds-item     leds.icon     3 3 install-icon

   " Switches and Accelerometer"
   ['] switch-item   ebook.icon    3 4 install-icon
;
' olpc-test-menu-items to test-menu-items
