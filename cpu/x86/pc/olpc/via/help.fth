purpose: Basic help for OLPC OFW

warning @ warning off
: help  ( -- )
   blue-letters  ." UPDATES:" black-letters  mcr
   ."   flash u:\q2c18.rom              Rewrite the firmware from USB key" mcr
   ."   flash ext:\q2c18.rom            Rewrite the firmware from external SD file" mcr
   ."   fs-update u:\boot\os51.zd       Rewrite the OS on internal SD from USB key" mcr
   blue-letters  ." DIRECTORY LISTING:" black-letters  mcr
   ."   dir u:\               List USB key root directory" mcr
   ."   dir u:\boot\          List USB key /boot directory" mcr
   ."   dir int:\boot\*.zip   List .zip files in internal SD /boot directory" mcr
   blue-letters  ." BOOTING:" black-letters  mcr
   ."   boot                  Load the OS from list of default locations" mcr
   ."                         'printenv boot-device' shows the list" mcr
   ."   boot <cmdline>        Load the OS, passing <cmdline> to kernel" mcr
   ."   boot u:\boot\vmlinuz  Load the OS from a specific location" mcr
   blue-letters  ." CONFIGURATION VARIABLES FOR BOOTING:" black-letters  mcr
   ."   boot-device  Kernel or boot script path.  Example: ext:\boot\olpc.fth" mcr
   ."   boot-file    Default cmdline.    Example: console=ttyS0,115200" mcr
   ."   ramdisk      initrd pathname.    Example: disk:\boot\initrd.imz" mcr
   blue-letters  ." MANAGING CONFIGURATION VARIABLES:" black-letters  mcr
   ."   printenv [ <name> ]     Show configuration variables" mcr
   ."   setenv <name> <value>   Set configuration variable" mcr
   ."   editenv <name>          Edit configuration variable" mcr
   blue-letters  ." DIAGNOSTICS:" black-letters  mcr
   ."   test <device-name>      Test device.  Example: test mouse" mcr
   ."   test-all                Test all devices that have test routines" mcr
   ."   menu                    Graphical interface to selftests" mcr
   blue-letters  ." More information: "  black-letters mcr
   green-letters  ." http://wiki.laptop.org/go/OFW_FAQ" black-letters  cr
;
warning !
