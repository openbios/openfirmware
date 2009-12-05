\ See license at end of file
purpose: User interface for reflashing SPI FLASH parts

\ This code is concerned with the user interface for getting
\ a new firmware image into memory and using it to program
\ a FLASH device from that image.  The details of how to actually
\ access the FLASH device are defined elsewhere.

h# 4000 constant /chunk   \ Convenient sized piece for progress reports

[ifdef] use-flash-nvram
h# d.0000 constant nvram-offset
[then]

h# e.0000 constant mfg-data-offset
mfg-data-offset /flash-block +  constant mfg-data-end-offset

: write-flash-range  ( adr end-offset start-offset -- )
   ." Writing" cr
   ?do                ( adr )
      \ Save time - don't write if the data is the same
      i .x (cr                              ( adr )
      spi-us d# 20 >=  if                   ( adr )
         \ Just write if reading is slow
         true                               ( adr must-write? )
      else                                  ( adr )
         dup  /flash-block  i  flash-verify   ( adr must-write? )
      then                                  ( adr must-write? )

      if
         i flash-erase-block
         dup  /flash-block  i  flash-write  ( adr )
      then
      /flash-block +                        ( adr' )
   /flash-block +loop                       ( adr )
   cr  drop           ( )
;

: verify-flash-range  ( adr end-offset start-offset -- )
   ." Verifying" cr
   ?do                ( adr )
      i .x (cr
      dup   /flash-block  i  flash-verify   abort" Verify failed"
      /flash-block +  ( adr' )
   /flash-block +loop ( adr )
   cr  drop           ( )
;


\ Perform a series of sanity checks on the new firmware image.

: check-firmware-image  ( adr len -- adr len )
   dup /flash <>  abort" Wrong image length"      ( adr len )
   2dup +  h# 40 -                                ( adr len signature-adr )
   dup " CL1" comp  abort" No firmware signature" ( adr len signature-adr )
   ." Firmware: " h# 10 type                      ( adr len )
   \ XXX add some more sanity checks
;

[ifdef] load-base
: flash-buf  load-base  ;
: mfg-data-buf     load-base /flash +  ;
[else]
/flash buffer: flash-buf
/flash-block buffer: mfg-data-buf
[then]
0 value file-loaded?

h# 30 constant crc-offset   \ From end (modified in devices.fth for XO 1.5)

: crc  ( adr len -- crc )  0 crctab  2swap ($crc)  ;

: ?crc  ( -- )
   ." Checking integrity ..." cr

   flash-buf /flash + crc-offset -   ( crc-adr )
   dup l@  >r                        ( crc-adr r: crc )
   -1 over l!                        ( crc-adr r: crc )

   flash-buf /flash crc              ( crc-adr calc-crc r: crc )
   r@ rot l!                         ( calc-crc r: crc )
   r> <>  abort" Firmware image has bad internal CRC"
;

: ?image-valid   ( len -- )
   /flash <> abort" Image file is the wrong length"

   ." Got firmware version: "
   flash-buf h# f.ffc0 +  dup  h# 10  type cr  ( adr )
   " CL1" comp  abort" Wrong machine type"

   ?crc

   flash-buf mfg-data-offset +  /flash-block  ['] ?erased  catch
   abort" Firmware image has data in the manufacturing data block"
[ifdef] use-flash-nvram
   flash-buf nvram-offset +  /flash-block  ['] ?erased  catch
   abort" Firmware image has data in the NVRAM block"
[then]
;

: $get-file  ( "filename" -- )
   $read-open
   flash-buf  /flash  ifd @ fgets   ( len )
   ifd @ fclose

   ?image-valid

   true to file-loaded?
;

: ?file  ( -- )
   file-loaded?  0=  if
      ." You must first load a valid FLASH image file with" cr
      ."    get-file filename" cr
      abort
   then
;

: read-flash  ( "filename" -- )
   writing
   /flash  0  do
      i .x (cr
      flash-buf  i +  /chunk i  flash-read
   /chunk +loop
   flash-buf  /flash  ofd @ fputs
   ofd @ fclose
;

: verify  ( -- )  ?file  flash-buf  /flash  0  verify-flash-range  ;

: mfg-data-range  ( -- adr len )  mfg-data-top dup last-mfg-data  tuck -  ;

[ifdef] $call-method
: make-sn-name  ( -- filename$ )
   " SN" find-tag 0=  abort" No serial number in mfg data"  ( sn$ )
   dup  if                   ( sn$ )
      2dup + 1- c@ 0=  if    ( sn$ )
         1-                  ( sn$' )    \ Remove Null
      then                   ( sn$ )
   then                      ( sn$ )
   d# 11 over -  dup 0>  if  ( sn$' #excess )
      /string                ( sn$' )  \ Keep last 11 characters
   else                      ( sn$' #excess )
      drop                   ( sn$ )
   then                      ( sn$ )

   " disk:\" "temp place    ( sn$' )

   dup 8 >  if              ( sn$ )
      over 8 "temp $cat     ( sn$ )
      8 /string             ( sn$' )
      " ."   "temp $cat     ( sn$ )
   then                     ( sn$ )
   "temp $cat               ( )
   "temp count              ( filename$ )
;

: save-mfg-data  ( -- )
   make-sn-name      ( name$ )
   ." Creating " 2dup type cr
   $create-file                               ( ihandle )
   dup 0= abort" Can't create file"   >r      ( r: ihandle )
   mfg-data-range  " write" r@ $call-method   ( r: ihandle )
   r> close-dev
;
: restore-mfg-data  ( "filename" -- )
   reading
   ifd @ fsize  dup /flash-block >  if  ( len )
      drop  ifd @ fclose                ( )
      true abort" File is too big"
   then                                 ( len )
   mfg-data-buf  swap                   ( adr len )
   2dup ifd @ fgets drop                ( adr len )
   ifd @ fclose

   flash-write-enable
   mfg-data-offset flash-erase-block    ( adr len )
   mfg-data-end-offset over -           ( adr len offset )
   flash-write                          ( )
   flash-write-disable                  ( )
;

[then]

: ?move-mfg-data  ( -- )
   ." Merging existing manufacturing data" cr

   tethered?  if
      \ Read the manufacturing data from the other FLASH
      \ First try the new location in the e.0000 block
      flash-buf mfg-data-offset +  /flash-block  mfg-data-offset  flash-read

      \ If there is no mfg data in the e.0000 block, get whatever is in the
      \ last 2K of the 0 block, where the mfg data used to live.
      flash-buf mfg-data-end-offset + invalid-tag?  if
         flash-buf mfg-data-offset +  /flash-block  h# ff  erase

         flash-buf mfg-data-end-offset + h# 800 -  h# 800   ( adr len )
         mfg-data-end-offset h# 800 -                       ( adr len offset )
         flash-read                                         ( )
      then
      exit
   then


   \ If the system has mfg data in the old place, move it to the new place
   mfg-data-top  flash-base h# 1.0000 +  =  if
      \ Copy just the manufacturing data into the memory buffer; don't
      \ copy the EC bits from the beginning of the block
      mfg-data-range                          ( adr len )
      flash-buf mfg-data-end-offset +         ( adr len ram-adr )
      over -   swap                           ( adr ram-adr' len )
      2dup 2>r  move  2r>                     ( ram-adr len )                              

      \ Write from the memory buffer to the FLASH
      mfg-data-offset flash-erase-block       ( ram-adr len )
      mfg-data-end-offset over -              ( ram-adr len offset )
      flash-write                             ( )
   else
      \ Copy the entire block containing the manufacturing data into the
      \ memory buffer.  This make verification easier.

      mfg-data-top /flash-block -             ( src-adr )
      flash-buf mfg-data-offset +             ( src-adr dst-adr )
      /flash-block move                       ( )
   then
;

: verify-firmware  ( -- )
[ifdef] use-flash-nvram
   flash-buf  nvram-offset     0  verify-flash-range     \ Verify first part
[else]
   flash-buf  mfg-data-offset  0  verify-flash-range     \ Verify first part
[then]

   \ Don't verify the block containing the manufacturing data

   flash-buf mfg-data-end-offset +  /flash mfg-data-end-offset  verify-flash-range   \ Verify last part
;
: write-firmware   ( -- )
[ifdef] use-flash-nvram
   flash-buf  nvram-offset     0  write-flash-range      \ Write first part
[else]
   flash-buf  mfg-data-offset  0  write-flash-range      \ Write first part
[then]

   \ Don't write the block containing the manufacturing data

   flash-buf mfg-data-end-offset +   /flash  mfg-data-end-offset  write-flash-range  \ Write last part
;

: .verify-msg  ( -- )
   ." Type verify if you want to verify the data just written."  cr
   ." Verification will take about 17 minutes if the host is running Linux" cr
   ." or about 5 minutes if the host is running OFW." cr
;

: reflash   ( -- )   \ Flash from data already in memory
   ?file
   flash-write-enable

   ?move-mfg-data

   write-firmware

   spi-us d# 20 <  if
      ['] verify-firmware catch  if
         ." Verify failed.  Retrying once"  cr
         spi-identify
         write-firmware
         verify-firmware
      then
      flash-write-disable
   else
      .verify-msg
   then   
;

defer fw-filename$  ' null$ to fw-filename$

: get-file  ( ["filename"] -- )
   parse-word   ( adr len )
   dup 0=  if  2drop fw-filename$  then  ( adr len )
   ." Reading " 2dup type cr                     ( adr len )
   $get-file
;

: flash  ( ["filename"] -- )  get-file ?enough-power reflash  ;
: flash! ( ["filename"] -- )  get-file reflash  ;

\ This is a slower version of "rom-va flash-buf /flash lmove"
\ It works around the problem that continuous CPU access to the
\ SPI FLASH starves the EC of instruction fetch cycles, often
\ causing it to turn off the system.
0 value rom-va
: slow-flash-read  ( -- )
   rom-pa /flash root-map-in to rom-va
   /flash  0  do
      rom-va i +  flash-buf i +  h# 1.0000 lmove
      d# 200 ms
   h# 1.0000 +loop
   rom-va /flash root-map-out  0 to rom-va
;

[ifdef] dev
dev /flash
: selftest  ( -- error? )
   .mfg-data cr

   ." Checking SPI FLASH CRC ..."
   slow-flash-read
   \ Replace the manufacturing data block with all FF
   flash-buf mfg-data-offset +  /flash-block  h# ff fill

   \ Get the CRC and then replace it with -1
   flash-buf /flash + crc-offset - dup l@ swap
   -1 swap l!

   flash-buf /flash crc  <>
   dup  if  ." FAILED"  else  ." passed"  then  cr
;
device-end
[then]

0 [if]
\ Erase the first block containing the EC microcode.  This is dangerous...

: erase-ec  ( -- )  0 flash-erase-block  ;
\ Erase everything after the first sector, thus preserving
\ the EC microcode in the first sector.

: erase-firmware  ( -- )
   h# 100000 /flash-block  do   (cr i .x  i flash-erase-block  /flash-block +loop  cr
;

: reprogram-firmware  ( adr len -- )
   check-firmware-image       ( adr len )
   /flash-block  /string      ( adr+ len- )   \ Remove EC ucode from the beginning
   ." Erasing ..." cr erase-spi-firmware  ( adr len )
   ." Programming..."  2dup /flash-block  flash-write  cr    ( adr len )
   ." Verifying..."  /flash-block flash-verify  abort" Verify failed"  cr  ( )
;

: flash-bios  ( -- )
   ?file

   \ Don't overwrite the EC code
   flash-buf /ec +  /flash  /ec  write-flash-range

   .verify-msg
;
: verify-bios  ( -- )  flash-buf /ec +  /flash  /ec  verify-flash-range  ;

: flash-ec  ( -- )
   ?file

   \ Write only the EC code
   flash-buf  /ec  0  write-flash-range

   ." Type verify-ec if you want to verify the data just written."  cr
   ." Verification will take about 1 minute..." cr
;
: verify-ec  ( -- )  ?file  flash-buf  /ec  0  verify-flash-range  ;

: flash-all  ( -- )
   ?file

   \ Write everything, EC code and BIOS
   flash-buf  /flash  0  write-flash-range

   ." Type verify-all if you want to verify the data just written."  cr
   ." Verification will take about 17 minutes..." cr
;

[then]

\ LICENSE_BEGIN
\ Copyright (c) 2006 FirmWorks
\ 
\ Permission is hereby granted, free of charge, to any person obtaining
\ a copy of this software and associated documentation files (the
\ "Software"), to deal in the Software without restriction, including
\ without limitation the rights to use, copy, modify, merge, publish,
\ distribute, sublicense, and/or sell copies of the Software, and to
\ permit persons to whom the Software is furnished to do so, subject to
\ the following conditions:
\ 
\ The above copyright notice and this permission notice shall be
\ included in all copies or substantial portions of the Software.
\ 
\ THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
\ EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
\ MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
\ NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
\ LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
\ OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
\ WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
\
\ LICENSE_END
