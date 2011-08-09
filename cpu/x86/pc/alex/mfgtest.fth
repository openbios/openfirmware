\ See license at end of file
purpose: Menu for manufacturing tests

h# f800 constant mfg-color-red
h# 07e0 constant mfg-color-green

: blank-screen  ( -- )
   h# ffff              ( color )
   0 0                  ( color x y )
   screen-wh            ( color x y w y )
   fill-rectangle-noff  ( )
;

: clear-n-restore-scroller  ( -- )
   blank-screen
   restore-scroller
;

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

: dummy-test-dev  ( $ -- )
   clear-n-restore-scroller
   ??cr  ." Testing " type ."  in the future" cr
   mfg-color-green sq-border!
   d# 2000 hold-message
   cursor-off  gui-alerts  refresh
   flush-keyboard
;

: mfg-test-dev  ( $ -- )
   clear-n-restore-scroller
   ??cr  ." Testing " 2dup type cr
   locate-device  if
      ." Can't find device node" cr
      flush-keyboard
      mfg-wait-return
      exit
   then                                              ( phandle )
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
         ??cr ." Okay" cr
         black-letters
         mfg-color-green sq-border!
         true to pass?
         d# 2000 hold-message
      then
   else
      ??cr ." Selftest failed due to abort"  cr
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
   clear-n-restore-scroller
\   clear-screen
   ." All automatic tests passed successfully." cr cr cr
   green-screen
   wait-return
   cursor-off  gui-alerts  refresh
   flush-keyboard
;

0 value #mfgtests
6 value #mfgcols
: #mfgtests++  ( -- )  #mfgtests 1+ to #mfgtests  ;
: #mfgrows     ( -- rows )  #mfgtests #mfgcols /mod  swap  if  1+  then  1+  ;

0 value cur-col
0 value cur-row
: cur-col++  ( -- )  cur-col 1+ to cur-col  ;
: cur-row++  ( -- )  cur-row 1+ to cur-row  ;
: set-col-row ( row col -- )  to cur-col  to cur-row  ;
: add-icon   ( -- )
   cur-col #mfgcols =  if
      cur-row++  cur-row #mfgcols >=  if  abort" Too many icons"  then
      0 to cur-col
   then
   cur-row  cur-col  install-icon
   cur-col++
;

: mfg-test-autorunner  ( -- )  \ Unattended autorun of all tests
   #mfgcols #mfgtests +  #mfgcols  ?do
      i set-current-sq
      refresh
      d# 1000 ms
      run-menu-item
      pass? 0= ?leave
   loop
;

: play-item     ( -- )   \ Interactive autorun of all tests
   #mfgcols #mfgtests +  #mfgcols  ?do
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
: battery-item  ( -- )  " /battery"   dummy-test-dev  ;
: spiflash-item ( -- )  " /flash"     dummy-test-dev  ;
: memory-item   ( -- )  " /memory"    mfg-test-dev  ;
: usb-item      ( -- )  " /usb"       mfg-test-dev  ;
: int-sd-item   ( -- )  " disk:0"     dummy-test-dev  ;
: ext-sd-item   ( -- )  " ext:0"      mfg-test-dev  ;
: rtc-item      ( -- )  " /rtc"       mfg-test-dev  ;
: display-item  ( -- )  " screen"     mfg-test-dev  ;
: audio-item    ( -- )  " /audio"     dummy-test-dev  ;
: camera-item   ( -- )  " /camera"    mfg-test-dev  ;
: wlan-item     ( -- )  " /wlan"      dummy-test-dev  ;
: timer-item    ( -- )  " /timer"     mfg-test-dev  ;
: touchpad-item ( -- )  " /8042/mouse"     mfg-test-dev  ;
: keyboard-item ( -- )  " /8042/keyboard"  mfg-test-dev  ;
: switch-item   ( -- )  " /switches"  mfg-test-dev  ;
: leds-item     ( -- )  " /leds"      mfg-test-dev  ;

: olpc-menu-items  ( -- )
   clear-menu

   1 0 set-col-row
   " CPU"
   ['] cpu-item      cpu.icon      add-icon   [ #mfgtests++  ]

   " SPI Flash: Contains EC code, firmware, manufacturing data."
   ['] spiflash-item    spi.icon   add-icon   [ #mfgtests++  ]

   " RAM chips"
   ['] memory-item   ram.icon      add-icon   [ #mfgtests++  ]

   " Internal mass storage"
   ['] int-sd-item   sdcard.icon   add-icon   [ #mfgtests++  ]

\   " Plug-in SD card"
\   ['] ext-sd-item   sdcard.icon   add-icon   [ #mfgtests++  ]

   " Timer"
   ['] timer-item    timer.icon    add-icon   [ #mfgtests++  ]

   " RTC (Real-Time Clock)"
   ['] rtc-item      clock.icon    add-icon   [ #mfgtests++  ]

   " Keyboard"
   ['] keyboard-item keyboard.icon add-icon   [ #mfgtests++  ]

   " Touchpad"
   ['] touchpad-item touchpad.icon add-icon   [ #mfgtests++  ]

   " Display"
   ['] display-item  display.icon  add-icon   [ #mfgtests++  ]

   " Camera"
   ['] camera-item   camera.icon   add-icon   [ #mfgtests++  ]

   " Audio: Speaker and microphone"
   ['] audio-item    audio.icon    add-icon   [ #mfgtests++  ]

   " Wireless LAN"
   ['] wlan-item     wifi.icon     add-icon   [ #mfgtests++  ]

   " USB ports"
   ['] usb-item      usb.icon      add-icon   [ #mfgtests++  ]

   " Battery"
   ['] battery-item  battery.icon  add-icon   [ #mfgtests++  ]

   \ These are last because they require user participation.
   \ The earlier tests are all included in automatic batch-mode.

\   " LEDs"
\   ['] leds-item     leds.icon     add-icon   [ #mfgtests++  ]

\   " Switches"
\   ['] switch-item   ebook.icon    add-icon   [ #mfgtests++  ]
;

: init-menu  ( -- )
   ?open-screen  ?open-mouse
   #mfgrows to rows
   #mfgcols to cols
   d# 180 to sq-size
   d# 128 to image-size
   d# 128 to icon-size
   cursor-off
;

: full-menu  ( -- )
   init-menu
   olpc-menu-items

   " Run all non-interactive tests. (Press a key between tests to stop.)"
   ['] play-item     play.icon     0 0 selected install-icon

   " Exit selftest mode."
   ['] quit-item     quit.icon     0 1 install-icon
;

' full-menu to root-menu
' noop to do-title

: autorun-mfg-tests  ( -- )
   init-menu
   ['] run-menu behavior >r
   ['] mfg-test-autorunner to run-menu   \ Run menu automatically
   true to diag-switch?
   ['] olpc-menu-items  ['] nest-menu catch  drop
   r> to run-menu
   false to diag-switch?
   clear-n-restore-scroller
;

: run-mfg-tests  ( -- )
   ['] full-menu ['] nest-menu catch  drop
   clear-n-restore-scroller
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
