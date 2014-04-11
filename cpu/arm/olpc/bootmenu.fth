\ TODO: enable touchscreen

\ ubuntu:/usr/share/app-install/icons/sugar-xo.svg
icon: xos.icon     rom:xos.565

\ The Android robot is reproduced or modified from work created and
\ shared by Google and used according to terms described in the
\ Creative Commons 3.0 Attribution License.
\ http://developer.android.com/distribute/googleplay/promote/brand.html
icon: android.icon     rom:android.565

: choose-linux
   restore-scroller  ." Choosing Linux" cr
   0 " choose-os" eval
   menu-done
;

: choose-android
   restore-scroller  ." Choosing Android" cr
   1 " choose-os" eval
   menu-done
;

: boot-menu  ( -- )
   d# 1 to rows
   d# 5 to cols

   0 0 set-row-col
   " Linux/Sugar"
   ['] choose-linux          xos.icon         0 0 install-icon

   0 4 set-row-col
   " Android"
   ['] choose-android        android.icon     0 4 install-icon

   0 2 selected 2drop
;

: no-boot-menu  ( -- )
   d# 1 to rows
   d# 1 to cols

   " No operating system choice installed"
   ['] quit-item             quit.icon        0 0 selected install-icon
;

: bootmenu
   init-menu clear-menu
   " choice-present?" eval if
       ['] boot-menu to root-menu
   else
       ['] no-boot-menu to root-menu
   then
   (menu)
;
