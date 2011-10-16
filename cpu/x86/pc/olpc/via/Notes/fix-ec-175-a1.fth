\ This runs on an XO-1.5 and lets you repair the EC code on an XO-1.75 A1
\ The XO-1.75 A1 EC code is stored in an SPI FLASH that can be tethered
\ to the XO-1.5's auxiliary SPI header.

: fix-ec
   use-bb-spi
   spi-start
   ab-id h# 10 <> abort" Wrong ID"
   ['] common-write to flash-write
   " ext:\ecimage.bin" $read-open
   flash-buf h# 10000 ifd @ fgets
   ifd @ fclose
   h# 10000 <> abort" Wrong image length"
   flash-buf h# 10000 0  write-flash-range  
;
