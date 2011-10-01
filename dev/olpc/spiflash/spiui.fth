\ See license at end of file
purpose: User interface for reflashing SPI FLASH parts

\ This code is concerned with the user interface for getting
\ a new firmware image into memory and using it to program
\ a FLASH device from that image.  The details of how to actually
\ access the FLASH device are defined elsewhere.

h# 4000 constant /chunk   \ Convenient sized piece for progress reports

: write-flash-range  ( adr end-offset start-offset -- )
   ." Writing" cr
   ?do                ( adr )
      \ Save time - don't write if the data is the same
      i .x (cr                              ( adr )
      spi-us d# 20 >=  if                   ( adr )
         \ Just write if reading is slow
         true                               ( adr must-write? )
      else                                  ( adr )
         dup  /flash-block  i  flash-verify ( adr must-write? )
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

[ifndef] flash-buf
/flash buffer: flash-buf
[then]

0 value file-loaded?

: crc  ( adr len -- crc )  0 crctab  2swap ($crc)  ;

: ?crc  ( -- )
   ." Checking integrity ..." cr

   flash-buf crc-offset +            ( crc-adr )
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
   machine-signature count comp  abort" Wrong machine signature"

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
   mfg-data-buf /flash-block                  ( adr len  r: ihandle )
   2dup mfg-data-offset  flash-read           ( adr len r: ihandle )
   " write" r@ $call-method                   ( r: ihandle )
   r> close-dev
;
: restore-mfg-data  ( "filename" -- )
   reading
   ifd @ fsize  dup /flash-block <>  if  ( len )
      drop  ifd @ fclose                ( )
      true abort" File is the wrong size - should be 65536 bytes"
   then                                 ( len )
   mfg-data-buf  swap                   ( adr len )
   2dup ifd @ fgets drop                ( adr len )
   ifd @ fclose

   flash-write-enable
   mfg-data-offset flash-erase-block    ( adr len )
   mfg-data-offset flash-write          ( )
   flash-write-disable                  ( )
;
[then]

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
   flash-vulnerable(
   flash-write-enable

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
   )flash-vulnerable
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

[ifdef] rom-pa
\ This is a slower version of "rom-va flash-buf /flash lmove"
\ It works around the problem that continuous CPU access to the
\ SPI FLASH starves the EC of instruction fetch cycles, often
\ causing it to turn off the system.  This is only a problem
\ for systems where the CPU and EC share the SPI FLASH.
0 value rom-va
: safe-flash-read  ( -- )
   rom-pa /flash root-map-in to rom-va
   /flash  0  do
      rom-va i +  flash-buf i +  h# 1.0000 lmove
      d# 200 ms
   h# 1.0000 +loop
   rom-va /flash root-map-out  0 to rom-va
;
[else]
: safe-flash-read  ( -- )
   flash-buf  /flash  0 flash-read
;
[then]

[ifdef] dev
dev /flash
: selftest  ( -- error? )
   .mfg-data cr

   ." Checking SPI FLASH CRC ..."
   safe-flash-read
   \ Replace the manufacturing data block with all FF
   flash-buf mfg-data-offset +  /flash-block  h# ff fill

   \ Get the CRC and then replace it with -1
   flash-buf crc-offset + dup l@ swap
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

: check-firmware-image  ( adr len -- adr len )
   dup /flash <>  abort" Wrong image length"      ( adr len )
   2dup +  h# 40 -                                ( adr len signature-adr )
   machine-signature count comp  abort" Wrong machine signature"
                                                  ( adr len signature-adr )
   ." Firmware: " h# 10 type                      ( adr len )
   \ XXX add some more sanity checks
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
