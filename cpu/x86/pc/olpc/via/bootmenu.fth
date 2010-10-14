icon: tux.icon          rom:\tux.565
icon: windows.icon      rom:\winlogo.565
icon: maintenance.icon  rom:\settings.565

: boot-linux-item  restore-scroller  ." Booting Linux" cr  " 0 choose-os boot" eval  wait-return  ;
: boot-windows-item  restore-scroller  ." Booting Windows" cr  " 1 choose-os boot" eval  wait-return  ;
: maintenance-item  ['] full-menu  nest-menu  ;

: boot-menu  ( -- )
   d# 1 to rows
   d# 2 to cols
   d# 3 to cols
\   d# 308 to sq-size
\   d# 256 to image-size
\   d# 256 to icon-size

   clear-menu

   " Boot Linux/Sugar"
   ['] boot-linux-item     tux.icon         0 0 selected install-icon

   " Boot Microsoft Windows"
   ['] boot-windows-item   windows.icon     0 1  install-icon

   " Maintenance Functions"
   ['] maintenance-item    maintenance.icon 0 2 install-icon
;

: bootmenu
   ['] boot-menu to root-menu
   menu
;
