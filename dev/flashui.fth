purpose: Simple FLASH write user interface, calling flash node methods
\ See license at end of file.

\ Simple UI for reflashing.  That's not always a good assumption;
\ some systems use certain FLASH blocks for persistent data like
\ configuration variables or manufacturing data ("Vital Product Data").

0 value flash-ih
0 value /flash-block

: $call-flash  ( ??? -- ??? )  flash-ih $call-method  ;
: close-flash  ( -- )
   flash-ih  if
      flash-ih close-dev
      0 to flash-ih
   then
;

: open-flash  ( -- )
   flash-ih  if  exit  then

   " flash" open-dev to flash-ih
   flash-ih 0=  if
      close-flash
      true abort" Can't open FLASH device"
   then

   " writable?"  $call-flash  0=  if
      close-flash
      true abort" FLASH device is not writable"
   then

   " block-size" $call-flash  to /flash-block
;

: crc  ( adr len -- crc )  0 crctab  2swap ($crc)  ;

: ?crc  ( adr len -- )
   fw-crc-offset -1 =  if  2drop exit  then   \ -1 means don't check

   ." Checking integrity ..." cr

   \ Negative offsets are from the end
   fw-crc-offset 0<  if  2dup +  else  over  then   ( adr len crc-base )
   fw-crc-offset +                                  ( crc-adr )

   dup l@  >r                        ( adr len crc-adr r: crc )
   -1 over l!                        ( adr len crc-adr r: crc )

   -rot  crc                         ( crc-adr calc-crc r: crc )
   r@ rot l!                         ( calc-crc r: crc )
   r> <>  if
      true abort" Firmware image has bad internal CRC"
   then
;

: ?image-valid   ( adr len -- )
   dup /fw-reflash <>  if
      true abort" Firmware image length is wrong"
   then
   ?crc
;

\ No error checking so you can override the standard parameters
: ($reflash)  ( adr len offset -- )
   open-flash                                 ( adr len offset )

   tuck  u>d  " seek" $call-flash drop        ( adr offset len )

   ." Writing" cr                             ( adr offset len )

   0  ?do                                     ( adr offset )
      (cr dup i + .x                          ( adr offset )
      over i +  /flash-block                  ( adr offset adr' len )
      " write" $call-flash drop               ( adr offset )
   /flash-block +loop                         ( adr offset )
   2drop                                      ( )

   close-flash
;

: $reflash   ( adr len -- )   \ Flash from data already in memory
   2dup ?image-valid
   fw-offset ($reflash)
;

0 value flash-buf

: get-flash-file  ( "filename" -- adr len )
   safe-parse-word                       ( filename$ )
   ." Reading " 2dup type cr             ( filename$ )
   $read-open                            ( )
   ifd @ fsize  /fw-reflash <>  if       ( )
      ifd @ fclose
      true abort" Firmware image file size is wrong"
   then                                  ( )

   /fw-reflash alloc-mem to flash-buf    ( )

   flash-buf  /fw-reflash  ifd @ fgets   ( len )
   ifd @ fclose                          ( )
   /fw-reflash <>  if
      flash-buf /fw-reflash free-mem
      true abort" Firmware image read failure"
   then

   flash-buf /fw-reflash                 ( adr len )
;

: flash  ( "filename" -- )
   get-flash-file                  ( adr len )
   ['] $reflash catch              ( false | x x throw-code )
   flash-buf /fw-reflash free-mem  ( false | x x throw-code )
   throw
;


\ LICENSE_BEGIN
\ Copyright (c) 2008 FirmWorks
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
