purpose: Simple FLASH write user interface, calling flash node methods
\ See license at end of file.

[ifndef] reflash
0 value flash-buf
0 value /flash
0 value /flash-block

\ Simple UI for reflashing, assuming that you want to overwrite
\ the entire FLASH contents.  That's not always a good assumption;
\ some systems use certain FLASH blocks for persistent data like
\ configuration variables or manufacturing data ("Vital Product Data").

0 value file-loaded?

: ?image-valid   ( len -- )
   /flash <> abort" Image file is the wrong length"
;

0 value flash-ih

: $call-flash  ( ??? -- ??? )  flash-ih $call-method  ;
: close-flash  ( -- )
   flash-ih  if
      flash-ih close-dev
      0 to flash-ih
      flash-buf /flash free-mem
   then
;

: ?open-flash  ( -- )
   flash-ih  if  exit  then

   " flash" open-dev to flash-ih
   flash-ih 0=  abort" Can't open FLASH device"

   " writable?"  $call-flash  0=  if
      close-flash
      true abort" FLASH device is not writable"
   then

   " block-size" $call-flash  to /flash-block
   " size"       $call-flash  drop  to /flash
   /flash alloc-mem to flash-buf
;

: $get-flash-file  ( "filename" -- )
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

: reflash   ( -- )   \ Flash from data already in memory
   ?open-flash
   ?file

   ." Writing" cr

   /flash  0  ?do
      (cr i .
      flash-buf i +  /flash-block  i  " flash-write" $call-flash  ( )
   /flash-block +loop

   close-flash
;

\ Set this defer word to return a string naming the default
\ filename for firmware updates
defer fw-filename$  ' null$ to fw-filename$

: get-flash-file  ( ["filename"] -- )
   ?open-flash
   parse-word   ( adr len )
   dup 0=  if  2drop fw-filename$  then  ( adr len )
   ." Reading " 2dup type cr                     ( adr len )
   $get-flash-file
;

: flash  ( ["filename"] -- )  get-flash-file reflash  ;
[then]


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
