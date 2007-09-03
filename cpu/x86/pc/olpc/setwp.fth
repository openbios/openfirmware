\ Set the write protect tag.  This is used to convert unlocked prototype
\ machined to locked machines for testing the firmware security.  This
\ should not be necessary once mass production systems start coming from
\ the factor with the "wp" tag set.

\ You can turn "ww" into "wp" just by clearing bits, which doesn't
\ require a full erase.  That is faster and safer than copying out the
\ data, erasing the block and rewriting it.

: set-wp  ( -- )
   h# fffefffe 2  " wp"  $=  if  ." wp is already set" cr  exit  then
   h# fffefffe 2  " ww"  $=  0=  abort" No ww tag"
   spi-start  spi-identify
   " wp"  h# efffe  write-spi-flash
   h# fffefffe 2  " wp"  $=  if  ." Succeeded" cr  then
   spi-reprogrammed
;

\ Set and clear the write-protect tag by copying, erasing, rewriting

\ Read mfg data from FLASH to RAM
: get-mfg-data  ( -- )
   rom-pa mfg-data-offset +  mfg-data-buf  /flash-block lmove
;

\ Write mfg data from RAM to FLASH
: put-mfg-data  ( -- )
   spi-start spi-identify
   mfg-data-buf  mfg-data-end-offset mfg-data-offset  write-flash-range
   spi-reprogrammed
;

\ Find RAM address of tag, given FLASH address
: tag>ram-adr  ( adr len -- ram-adr )
   drop 2+                      ( adr' )   \ Address of  "ww" tag
   rom-pa mfg-data-offset +  -  ( offset )

   dup /flash-block u>= abort" Bad ww offset"        \ Sanity check

   mfg-data-buf +               ( ram-adr )
;

\ Get ready to modify the tag whose name is tag$
: mfg-data-setup  ( tag$ -- ram-adr )
   get-mfg-data
   2dup  find-tag  0=  if  ." No " type ."  tag" cr  abort  then  ( tag$ adr len )
   tag>ram-adr  >r                            ( tag$ r: ram-adr )
   r@ 2 $=  0= abort" Tag mismatch in RAM"    ( r: ram-adr )
   r>
;

\ Change the "ww" tag to "wp"
: hard-set-wp  ( -- )
   " ww" mfg-data-setup  ( ram-adr )
   [char] p  swap 1+ c!  ( )
   put-mfg-data
;

\ Change the "wp" tag to "ww"
: clear-wp  ( -- )
   " wp" mfg-data-setup  ( ram-adr )
   [char] w  swap 1+ c!  ( )
   put-mfg-data
;
