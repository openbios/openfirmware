\ See license at end of file
\ User interface for reflashing SPI FLASH parts

\ This code is concerned with the user interface for getting
\ a new firmware image into memory and using it to program
\ a FLASH device from that image.  The details of how to actually
\ access the FLASH device are defined elsewhere.

h# 4000 constant /chunk   \ Convenient sized piece for progress reports
h# 100000 constant /flash
h# 10000 constant /flash-block \ Size of erase block

h# e.0000 constant mfg-data-offset
mfg-data-offset /flash-block +  constant mfg-data-end-offset

: write-flash-range  ( adr end-offset start-offset -- )
   ." Erasing" cr
   2dup  ?do
      i .x (cr  i erase-spi-block
   /spi-eblock +loop  ( adr end start )
   cr                 ( adr end start )
   
   ." Writing" cr
   ?do                ( adr )
      i .x (cr                         ( adr )
      dup  /chunk  i  write-spi-flash  ( adr )
      /chunk +                         ( adr' )
   /chunk +loop       ( adr )
   cr  drop           ( )
;

: verify-flash-range  ( adr end-offset start-offset -- )
   ." Verifying" cr
   ?do                ( adr )
      i .x (cr
      dup  i +  /chunk  i  verify-spi-flash
   /chunk +loop       ( adr )
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

h# 30 constant crc-offset   \ From end

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
      flash-buf  i +  /chunk i  read-spi-flash
   /chunk +loop
   flash-buf  /flash  ofd @ fputs
   ofd @ fclose
;

: verify  ( -- )  ?file  flash-buf  /flash  0  verify-flash-range  ;

: mfg-data-range  ( -- adr len )  mfg-data-top dup last-mfg-data  tuck -  ;

: make-sn-name  ( -- filename$ )
   " SN" find-tag 0=  abort" No serial number in mfg data"  ( sn$ )
   dup  if  1-  then         ( sn$' )  \ Remove Null
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

: ?move-mfg-data  ( -- )
   ." Merging existing manufacturing data" cr

   \ If the system has mfg data in the old place, move it to the new place
   mfg-data-top h# fff1.0000 =  if
      \ Copy just the manufacturing data into the memory buffer; don't
      \ copy the EC bits from the beginning of the block
      mfg-data-range                          ( adr len )
      flash-buf mfg-data-end-offset +         ( adr len ram-adr )
      over -   swap                           ( adr ram-adr' len )
      2dup 2>r  move  2r>                     ( ram-adr len )                              

      \ Write from the memory buffer to the FLASH
      mfg-data-offset erase-spi-block         ( ram-adr len )
      mfg-data-end-offset over -              ( ram-adr len offset )
      write-spi-flash                         ( )
   else
      \ Copy the entire block containing the manufacturing data into the
      \ memory buffer.  This make verification easier.

      mfg-data-top /flash-block -             ( src-adr )
      flash-buf mfg-data-offset +             ( src-adr dst-adr )
      /flash-block move                       ( )
   then
;

: write-firmware  ( -- )
   flash-buf  mfg-data-offset  0  write-flash-range      \ Write first part

   \ Don't write the block containing the manufacturing data

   flash-buf mfg-data-end-offset +          ( adr )
   /flash mfg-data-end-offset  write-flash-range         \ Write last part
;

: reflash   ( -- )   \ Flash from data already in memory
   ?file
   spi-start

   spi-identify .spi-id cr

   ?move-mfg-data

   write-firmware

   spi-us d# 20 <  if
      ['] verify catch  if
         ." Verify failed.  Retrying once"  cr
         spi-identify
         write-firmware
         verify
      then
      spi-reprogrammed
   else
      ." Type verify if you want to verify the data just written."  cr
      ." Verification will take about 17 minutes..." cr
   then   
;

defer fw-filename$  ' null$ to fw-filename$

: get-file  ( ["filename"] -- )
   parse-word   ( adr len )
   dup 0=  if  2drop fw-filename$  then  ( adr len )
   ." Reading " 2dup type cr                     ( adr len )
   $get-file
;

: flash  ( ["filename"] -- )  get-file reflash  power-off  ;

dev /flash
0 value rom-va
: selftest  ( -- error? )
   rom-va 0=  if  rom-pa /flash root-map-in to rom-va  then
   rom-va flash-buf /flash move

   \ Replace the manufacturing data block with all FF
   flash-buf mfg-data-offset +  /flash-block  h# ff fill

   flash-buf /flash crc  <>
   rom-va /flash root-map-out  0 to rom-va
;
device-end

0 [if]
\ Erase the first block containing the EC microcode.  This is dangerous...

: erase-spi-ec  ( -- )  0 erase-spi-block  ;
\ Erase everything after the first sector, thus preserving
\ the EC microcode in the first sector.

: erase-spi-firmware  ( -- )
   h# 100000 /spi-eblock  do   (cr i .x  i erase-spi-block  /spi-eblock +loop  cr
;

: reprogram-firmware  ( adr len -- )
   check-firmware-image       ( adr len )
   /spi-eblock  /string       ( adr+ len- )   \ Remove EC ucode from the beginning
   ." Erasing ..." cr erase-spi-firmware  ( adr len )
   ." Programming..."  2dup /spi-eblock  write-spi-flash  cr    ( adr len )
   ." Verifying..."  /spi-eblock verify-spi-flash  cr  ( )
;

: flash-bios  ( -- )
   ?file

   \ Don't overwrite the EC code
   flash-buf  /flash  /ec  write-flash-range

   ." Type verify-bios if you want to verify the data just written."  cr
   ." Verification will take about 17 minutes..." cr
;
: verify-bios  ( -- )  flash-buf  /flash  /ec  verify-flash-range  ;

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
