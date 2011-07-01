\ See license at end of file
purpose: Menu for manufacturing tests

h# f800 constant mfg-color-red
h# 07e0 constant mfg-color-green

: flush-keyboard  ( -- )  begin  key?  while  key drop  repeat  ;

: sq-border!  ( bg -- )  current-sq sq >border !  ;

warning off
\ Intentional redefinitions.  It would be better to change the name, but
\ Quanta could be using these words directly in manufacturing test scripts.
: red-screen    ( -- )  h# ffff mfg-color-red   " replace-color" $call-screen  ;
: green-screen  ( -- )  h# ffff mfg-color-green " replace-color" $call-screen  ;
warning on

0 value pass?

: mfg-wait-return  ( -- )
   ." ... Press any key to proceed ... "
   cursor-off
   gui-alerts
   begin
      key?  if  key drop  refresh exit  then
      mouse-ih  if
         10 get-event  if
            \ Ignore movement, act only on a button down event
            nip nip  if  wait-buttons-up  refresh exit  then
         then
      then
   again
;

: mfg-test-dev  ( $ -- )
   restore-scroller
   ??cr  ." Testing " 2dup type cr
   locate-device  if  ." Can't find device node" cr  exit  then  ( phandle )
   " selftest" rot execute-phandle-method            ( return abort? )
   if
      ?dup  if
         ??cr ." Selftest failed. Return code = " .d cr
         mfg-color-red sq-border!
         false to pass?
         red-screen
         flush-keyboard
         mfg-wait-return
      else
         green-letters
         ." Okay" cr
         black-letters
         mfg-color-green sq-border!
         true to pass?
         d# 2000 hold-message
      then
   else
      ." Selftest failed due to abort"  cr
      mfg-color-red sq-border!
      false to pass?
      red-screen
      flush-keyboard
      mfg-wait-return
   then
   cursor-off  gui-alerts  refresh
   flush-keyboard
;

: draw-error-border  ( -- )
   mfg-color-red d# 20 d# 20 d# 1160 d# 820 d# 20 box
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

: all-tests-passed  ( -- )
   restore-scroller
   clear-screen
   ." All automatic tests passed successfully." cr cr cr
   green-screen
   wait-return
   cursor-off  gui-alerts  refresh
   flush-keyboard
;

d# 15 value #mfgtests

: mfg-test-autorunner  ( -- )  \ Unattended autorun of all tests
   5 #mfgtests +  5  ?do
      i set-current-sq
      refresh
      d# 1000 ms
      run-menu-item
      pass? 0= ?leave
   loop
;

: play-item     ( -- )   \ Interactive autorun of all tests
   5 #mfgtests +  5  ?do
      i set-current-sq
      refresh
      d# 200 0 do
         d# 10 ms  key? if  unloop unloop exit  then
      loop
      run-menu-item
      pass? 0= if  unloop exit  then
   loop
   all-tests-passed
;         
: quit-item     ( -- )  menu-done  ;
: cpu-item      ( -- )  " /cpu"       mfg-test-dev  ;
: battery-item  ( -- )  " /battery"   mfg-test-dev  ;
: spiflash-item ( -- )  " /flash"     mfg-test-dev  ;
: memory-item   ( -- )  " /memory"    mfg-test-dev  ;
: usb-item      ( -- )  " /usb/hub"   mfg-test-dev  ;
: int-sd-item   ( -- )  " int:0"      mfg-test-dev  ;
: ext-sd-item   ( -- )  " ext:0"      mfg-test-dev  ;
: rtc-item      ( -- )  " /rtc"       mfg-test-dev  ;
: display-item  ( -- )  " /display"   mfg-test-dev  ;
: audio-item    ( -- )  " /audio"     mfg-test-dev  ;
: camera-item   ( -- )  " /camera"    mfg-test-dev  ;
: wlan-item     ( -- )  " /wlan"      mfg-test-dev  ;
: timer-item    ( -- )  " /timer"     mfg-test-dev  ;
: touchpad-item ( -- )  " mouse"      mfg-test-dev  ;
: keyboard-item ( -- )  " keyboard"   mfg-test-dev  ;
: switch-item   ( -- )  " /switches"  mfg-test-dev  " /accelerometer" mfg-test-dev  ;
: leds-item     ( -- )  " /leds"      mfg-test-dev   ;
\ XXX need to test sensors like accelerometer and compass

: olpc-menu-items  ( -- )
   clear-menu

\   " CPU"
\   ['] cpu-item      cpu.icon      1 0 install-icon

   " SPI Flash: Contains EC code, firmware, manufacturing data."
   ['] spiflash-item    spi.icon      1 0 install-icon

   " RAM chips"
   ['] memory-item   ram.icon      1 1 install-icon

   " Internal mass storage"
   ['] int-sd-item   sdcard.icon   1 2 install-icon

   " Plug-in SD card"
   ['] ext-sd-item   sdcard.icon   1 3 install-icon

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

   " USB ports"
   ['] usb-item      usb.icon      3 0 install-icon

   \ These are last because they require user participation.
   \ The earlier tests are all included in automatic batch-mode.

   " Keyboard"
   ['] keyboard-item keyboard.icon 3 1 install-icon

   " Touchpad"
   ['] touchpad-item touchpad.icon 3 2 install-icon

   " LEDs"
   ['] leds-item     leds.icon     3 3 install-icon

   " Switches and Accelerometer"
   ['] switch-item   ebook.icon    3 4 install-icon
;

: full-menu  ( -- )
   d# 4 to rows
   d# 5 to cols
   d# 180 to sq-size
   d# 128 to image-size
   d# 128 to icon-size

   olpc-menu-items

   " Run all non-interactive tests. (Press a key between tests to stop.)"
   ['] play-item     play.icon     0 1 selected install-icon

   " Exit selftest mode."
   ['] quit-item     quit.icon     0 3 install-icon
;

' full-menu to root-menu
' noop to do-title

: autorun-mfg-tests  ( -- )
   ['] mfg-test-autorunner to run-menu   \ Run menu automatically
   true to diag-switch?
   ['] olpc-menu-items  ['] nest-menu catch  drop
   false to diag-switch?
   restore-scroller
;


\ LICENSE_BEGIN
\ Copyright (c) 2009 Luke Gorrie
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
