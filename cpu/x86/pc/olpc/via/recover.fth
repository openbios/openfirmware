purpose: Reprogram SPI FLASH from another XO-1.5

\ Use a working OLPC XO-1.5 board to recover one whose firmware is bad,
\ using a 6-pin ribbon cable connected from J3 on the good machine to J2
\ on the bad one.
\
\ The commands are:
\    ok clone                   \ Copies this machine's FLASH to the dead one
\    ok recover disk:\file.rom  \ Copies a ROM file to the dead one

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
