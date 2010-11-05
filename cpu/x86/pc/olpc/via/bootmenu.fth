icon: tux.icon          rom:tux.565
icon: windows.icon      rom:winlogo.565

: choose-linux-item
   restore-scroller  ." Choosing Linux" cr
   0 " choose-os" eval
   menu-done
;

: choose-windows-item
   restore-scroller  ." Choosing Windows" cr
   1 " choose-os" eval
   menu-done
;

: boot-menu  ( -- )
   d# 1 to rows
   d# 3 to cols

   clear-menu

   " Linux/Sugar"
   ['] choose-linux-item     tux.icon         0 0 selected install-icon

   " Microsoft Windows"
   ['] choose-windows-item   windows.icon     0 1 install-icon

   " Continue"
   ['] quit-item             play.icon        0 2 install-icon
;

: no-boot-menu  ( -- )
   d# 1 to rows
   d# 1 to cols

   clear-menu

   " No operating system choice installed"
   ['] quit-item             quit.icon        0 0 selected install-icon
;

: bootmenu
   " choice-present?" eval if
       ['] boot-menu to root-menu
   else
       ['] no-boot-menu to root-menu
   then
   (menu)
;
