purpose: Reprogram SPI FLASH from another XO-1.5

\ Use a working OLPC XO-1.5 board to recover one whose firmware is bad,
\ using a 6-pin ribbon cable connected from J3 on the good machine to J2
\ on the bad one.
\
\ The commands are:
\    ok clone                   \ Copies this machine's FLASH to the dead one
\    ok recover disk:\file.rom  \ Copies a ROM file to the dead one
\    ok excavate disk:\the.rom  \ Reads the dead ROM and writes to a file

: (tethered-flash)  ( -- )
   use-bb-spi
   reflash
   use-local-ec
;

: clone  ( -- )
   ." Getting a copy of this machine's FLASH" cr
   safe-flash-read
   true to file-loaded?

   (tethered-flash)
;

: recover  ( "filename" -- )  get-file (tethered-flash)  ;

: excavate  ( "filename" -- )
   use-bb-spi
   flash-write-enable
   read-flash
   flash-write-disable
   use-local-ec
;

: use-layout-xo-4
   h# 20.0000 to /flash
   /flash h# 1.0000 - to mfg-data-offset
   /flash to mfg-data-end-offset
   mfg-data-offset h# 30 - to crc-offset
   mfg-data-offset h# 40 - to signature-offset
   " "(03)"CL4" machine-signature swap cmove
   \ ." WARNING: do not use local SPI FLASH access without reboot" cr
;

\ write only the CForth image to SPI FLASH, leaving Open Firmware alone
: recover-cforth  ( "filename" -- )
   use-bb-spi
   $read-open flash-buf h# 2.0000 ifd @ fgets ifd @ fclose
   flash-write-enable
   flash-buf h# 2.0000 0 write-flash-range
   flash-write-disable
   use-local-ec
;
