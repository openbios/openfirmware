purpose: Get the manufacturing data into memory where it can be manipulated

/flash-block buffer: mfg-data-buf

: get-mfg-data  ( -- )
   flash-open
   mfg-data-buf /flash-block  mfg-data-offset  flash-read
;

0 value mfg-data-read?
: mfg-data-top  ( -- adr )
   mfg-data-read? 0=  if
      get-mfg-data
      true to mfg-data-read?
   then
   mfg-data-buf /flash-block +
;
