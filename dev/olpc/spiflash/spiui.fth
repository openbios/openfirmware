\ See license at end of file
\ User interface for reflashing SPI FLASH parts

\ This code is concerned with the user interface for getting
\ a new firmware image into memory and using it to program
\ a FLASH device from that image.  The details of how to actually
\ access the FLASH device are defined elsewhere.

h# 1000 constant /chunk  \ Convenient sized piece for progress reports
h# 10000 constant /ec    \ Size of EC code area
h# 100000 constant /flash

: write-flash-range  ( adr end-offset start-offset -- )
   ." Erasing" cr
   2dup  ?do
      i .x (cr  i erase-spi-block
   /spi-eblock +loop  ( adr end start )
   cr                 ( adr end start )
   
   ." Writing" cr
   ?do                ( adr )
      i .x (cr
      dup  i +  /chunk  i  write-spi-flash
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
[else]
/flash buffer: flash-buf
[then]
0 value file-loaded?


h# 30 constant crc-offset  \ From end

: crc  ( adr len -- crc )  0 crctab  2swap ($crc)  ;

: ?crc  ( -- )
   ." Checking integrity ..." cr

   flash-buf /flash + crc-offset -   ( crc-adr )
   dup l@  >r                        ( crc-adr r: crc )
   -1 over l!                        ( crc-adr r: crc )

   flash-buf /flash crc              ( crc-adr calc-crc r: crc )
   r@ rot l!                         ( calc-crc r: crc )
   r> <>  abort" Corrupt firmware image - bad internal CRC"
;

: ?image-valid   ( len -- )
   /flash <> abort" Image file is the wrong length"

   ." Got firmware version: "
   flash-buf h# f.ffc0 +  dup  h# 10  type cr  ( adr )
   " CL1" comp  abort" Wrong machine type"

   ?crc
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

: reflash   ( -- )   \ Flash from data already in memory
   ?file
   spi-start

   spi-identify .spi-id cr

   flash-buf  /flash  0  write-flash-range   \ Write everything, EC code and BIOS

   spi-us d# 20 <  if
      verify
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

: flash  ( ["filename"] -- )  get-file reflash  ;


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
