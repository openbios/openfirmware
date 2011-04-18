purpose: Basic help for OLPC OFW

warning @ warning off
: help  ( -- )
   blue-letters  ." UPDATES:" black-letters  mcr
   \ ================================================================================
   ."   fs-update u:\os1.zd4   Rewrite the OS on internal SD from USB drive" mcr
   ."   flash u:\q3a64.rom     Rewrite the firmware from USB drive" mcr
   ."   flash ext:\q3a64.rom   Rewrite the firmware from external SD file" mcr
   blue-letters  ." DIRECTORY LISTING:" black-letters  mcr
   ."   dir u:\                List USB drive root directory" mcr
   ."   dir u:\boot\           List USB drive /boot directory" mcr
   ."   dir int:\boot\*.zip    List .zip files in internal SD /boot directory" mcr
   blue-letters  ." BOOTING:" black-letters  mcr
   ."   boot                   Start the OS from list of default locations" mcr
   ."   printenv boot-device   Show the list of default locations used by boot" mcr
   ."   boot u:\test.fth       Start the OS from a specific location" mcr
   blue-letters  ." CONFIGURATION VARIABLES FOR BOOTING:" black-letters  mcr
   ."   boot-device  Kernel or boot script paths.  Example: ext:\boot\olpc.fth" mcr
   ."   boot-file    Default kernel command line.  Example: console=ttyS0,115200" mcr
   ."   ramdisk      Initial RAMDISK path.         Example: int:\boot\initrd.img" mcr
   blue-letters  ." MANAGING CONFIGURATION VARIABLES:" black-letters  mcr
   ."   printenv [ <name> ]    Show configuration variables" mcr
   ."   setenv <name> <value>  Set configuration variable" mcr
   ."   editenv <name>         Edit configuration variable" mcr
   blue-letters  ." DIAGNOSTICS:" black-letters  mcr
   ."   test <device-name>     Test device.  Example: test mouse" mcr
   ."   test-all               Test all devices that have test routines" mcr
   ."   menu                   Graphical interface to selftests" mcr
   blue-letters  ." More information: "  black-letters mcr
   green-letters  ."   http://wiki.laptop.org/go/OFW_FAQ" black-letters  cr
;
warning !
