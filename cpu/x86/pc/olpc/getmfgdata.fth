\ Mfg data is in a block by itself.
/flash-block buffer: mfg-data-buf

\ Read mfg data from FLASH to RAM
: get-mfg-data  ( -- )
   rom-pa mfg-data-offset +  mfg-data-buf  /flash-block lmove
;

: mfg-data-top  ( -- adr )
   flash-base mfg-data-end-offset +
;
