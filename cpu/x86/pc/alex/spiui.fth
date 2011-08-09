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

[ifdef] load-base
: flash-buf  load-base  ;
[else]
/flash buffer: flash-buf
[then]

0 value file-loaded?

: -cbid  ( offset -- )  flash-buf /flash +  swap -  ;

: check-id-string  ( offset expect$ -- )
   rot -cbid @  -cbid cscount  ( expect$ got$ )
   2over 2over $=  0=  if      ( expect$ got$ )
      ." Expecting " 2swap type ." , got " type  cr
      abort
   then                        ( expect$ got$ )
   4drop                       ( )
;
: ?coreboot-id  ( -- )
   h# 14 -cbid @  /flash <>  abort" Coreboot flash size mismatch"
   h# 1c " Samsung" check-id-string
   h# 18 " Alex" check-id-string
;
: ?cbfs  ( -- )
   flash-buf " LARCHIVE" comp  abort" Image file is not in CBFS format"
   \ We could also check the integrity of the CBFS headers
;

: ?image-valid   ( len -- )
   /flash <> abort" Image file is the wrong length"

   ?cbfs
   ?coreboot-id
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

: verify-firmware  ( -- )
   flash-buf  /flash  0  verify-flash-range     \ Verify first part
;

: write-firmware   ( -- )
   flash-buf  /flash 0  write-flash-range      \ Write first part
;

: reflash   ( -- )   \ Flash from data already in memory
   ?file
   flash-write-enable

   write-firmware

   ['] verify-firmware catch  if
      ." Verify failed.  Retrying once"  cr
      spi-identify
      write-firmware
      verify-firmware
   then
   flash-write-disable
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

: safe-flash-read  ( -- )
   flash-buf  /flash  0 flash-read
;

dev /flash
: selftest  ( -- error? )
   .cbfs
   d# 2000 ms  \ More time to inspect
   false
;
device-end

\ LICENSE_BEGIN
\ Copyright (c) 2011 FirmWorks
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
