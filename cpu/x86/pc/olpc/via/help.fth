purpose: Basic help for OLPC OFW

warning @ warning off
: help  ( -- )
   blue-letters  ." INSTALLATION:" cancel  mcr
   \ ================================================================================
   ."   fs-update u:\os1.zd4   Install OS from USB drive to internal storage" mcr
   ."   flash u:\q3c03.rom     Install firmware from USB drive" mcr
   blue-letters  ." DIRECTORY LISTING:" cancel  mcr
   ."   dir u:\                List USB drive root directory" mcr
   ."   dir u:\boot\           List USB drive /boot directory" mcr
   ."   dir int:\boot\*.zip    List .zip files in internal /boot directory" mcr
   blue-letters  ." BOOTING:" cancel  mcr
   ."   boot                   Start the OS from list of default locations" mcr
   ."   boot u:\test.fth       Start the OS from a specific location" mcr
   blue-letters  ." CONFIGURATION VARIABLES FOR BOOTING:" cancel  mcr
   ."   boot-device  Kernel or boot script paths.  Example: ext:\boot\olpc.fth" mcr
   ."   boot-file    Default kernel command line.  Example: debug" mcr
   ."   ramdisk      Initial RAMDISK path.         Example: int:\boot\initrd.img" mcr
   blue-letters  ." MANAGING CONFIGURATION VARIABLES:" cancel  mcr
   ."   printenv [ <name> ]    Show configuration variables" mcr
   ."   setenv <name> <value>  Set configuration variable" mcr
   ."   editenv <name>         Edit configuration variable" mcr
   blue-letters  ." DIAGNOSTICS:" cancel  mcr
   ."   test <device-name>     Test a device.  Example: test mouse" mcr
   ."   test-all               Test all devices that have test routines" mcr
   ."   menu                   Graphical interface to selftests" mcr
   blue-letters  ." More information: "  cancel mcr
   green-letters  ."   http://wiki.laptop.org/go/OFW_FAQ" cancel  cr
;
warning !
