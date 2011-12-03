purpose: Get the manufacturing data into memory where it can be manipulated

\ It is tempting to use buffer: for this, but that fails because
\ we need to access manufacturing data very early (for security),
\ in stand-init-io before the call to clear-buffer:s in init.
0 value mfg-data-buf

: get-mfg-data  ( -- )
   mfg-data-buf  if  exit  then
   /flash-block alloc-mem to mfg-data-buf
   flash-open
   mfg-data-buf /flash-block  mfg-data-offset  flash-read
;

: mfg-data-top  ( -- adr )
   get-mfg-data
   mfg-data-buf /flash-block +
;
