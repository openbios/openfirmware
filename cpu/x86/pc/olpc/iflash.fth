\ Reflasher that merges Insyde BIOS with manufacturing data

h# 300 constant /mfg-data-merge
mfg-data-end-offset /mfg-data-merge - constant mfg-data-merge-offset

: $get-insyde  ( filename$ -- )
   $read-open
   flash-buf  /flash  ifd @ fgets   ( len )
   ifd @ fclose

   /flash <> abort" Image file is the wrong length"

   flash-buf mfg-data-merge-offset +  /mfg-data-merge  0 bskip  ( residue )
   abort" Firmware image has data in the manufacturing data block"

   true to file-loaded?
;

: merge-mfg-data  ( -- )
   flash-base mfg-data-merge-offset +
   flash-buf  mfg-data-merge-offset +
   /mfg-data-merge move
;

[ifdef] get-mfg-data
\ unpollute-mfg-data clears the Insyde BIOS residue from the beginning
\ of the manufacturing data area, restoring it to erased state
: unpollute-mfg-data  ( -- )
   rom-pa mfg-data-offset + l@ -1 <>  abort" Mfg data area is not polluted"
   get-mfg-data
   mfg-data-buf mfg-data-merge-offset h# ff fill
   put-mfg-data
;
[then]

: get-insyde  ( ["filename"] -- )
   parse-word   ( adr len )
   dup 0=  if  2drop    " u:\insyde.rom"  then  ( adr len )
   ." Reading " 2dup type cr                    ( adr len )
   $get-insyde
;

: write-insyde  ( -- )
   flash-buf  /flash  0  write-flash-range
;

: ireflash   ( -- )   \ Flash from data already in memory
   ?file
   flash-write-enable

   merge-mfg-data

   write-insyde

   spi-us d# 20 <  if
      ['] verify catch  if
         ." Verify failed.  Retrying once"  cr
         spi-identify
         write-insyde
         verify
      then
      flash-write-disable
   else
      .verify-msg
   then   
;

: iflash  ( ["filename"] -- )  get-insyde ?enough-power ireflash  ;

: save-insyde  ( -- )
   " u:\insyde.rom" $write-open

   \ Get the FLASH data into a buffer, slowly to avoid locking out the EC
   slow-flash-read

   \ Zap the manufacturing data
   flash-buf mfg-data-merge-offset +  /mfg-data-merge  0 fill

   flash-buf /flash ofd @ fputs

   ofd @ fclose
;
