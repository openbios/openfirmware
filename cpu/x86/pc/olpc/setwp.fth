\ Set the write protect tag.  This is used to convert unlocked prototype
\ machined to locked machines for testing the firmware security.  This
\ should not be necessary once mass production systems start coming from
\ the factor with the "wp" tag set.

: set-wp  ( -- )
   h# fffefffe 2  " wp"  $=  if  ." wp is already set" cr  exit  then
   h# fffefffe 2  " ww"  $=  0=  abort" No ww tag"
   spi-start  spi-identify
   " wp"  h# efffe  write-spi-flash
   h# fffefffe 2  " wp"  $=  if  ." Succeeded" cr  then
   spi-reprogrammed
;
set-wp
