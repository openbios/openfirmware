purpose: Basic help for OLPC OFW

warning @ warning off
: help  ( -- )
   blue-letters  ." UPDATES:" cancel  mcr
   \ ================================================================================
   ."   update-nand u:\os.img           Rewrite OS on NAND from USB drive" mcr
   ."   flash u:\q2f07.rom              Rewrite firmware from USB drive" mcr
   blue-letters  ." DIRECTORY LISTING:" cancel  mcr
   ."   dir u:\                         List USB drive root directory" mcr
   ."   dir u:\boot\                    List USB drive /boot directory" mcr
   ."   dir nand:\boot\*.rom            List .rom files in NAND /boot directory" mcr
   blue-letters  ." BOOTING:" cancel  mcr
   ."   boot                            Start the OS" mcr
   ."   boot u:\vmlinuz                 Start the OS from a specific location" mcr
   blue-letters  ." CONFIGURATION VARIABLES FOR BOOTING:" cancel  mcr
   ."   boot-device  Kernel or boot script path.  Example: nand:\boot\olpc.fth" mcr
   ."   boot-file    Default cmdline.    Example: console=ttyS0,115200" mcr
   ."   ramdisk      initrd pathname.    Example: disk:\boot\initrd.imz" mcr
   blue-letters  ." MANAGING CONFIGURATION VARIABLES:" cancel  mcr
   ."   printenv [ <name> ]             Show configuration variables" mcr
   ."   setenv <name> <value>           Set configuration variable" mcr
   ."   editenv <name>                  Edit configuration variable" mcr
   blue-letters  ." DIAGNOSTICS:" cancel  mcr
   ."   test <device-name>              Test device.  Example: test mouse" mcr
   ."   test-all                        Test all devices that have test routines" mcr
   blue-letters  ." More information: "  cancel mcr
   green-letters  ." http://wiki.laptop.org/go/OFW_FAQ" cancel  cr
;
warning !
