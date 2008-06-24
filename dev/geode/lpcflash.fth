\ See license at end of file.
purpose: LPC/FWH FLASH writer.

: geode-lpc-write-enable  ( -- )
   h# 1808 rdmsr  h# ff.ffff and  h# 2100.0000 or  h# 1808 wrmsr
;
: geode-lpc-write-disable  ( -- )
   h# 1808 rdmsr  h# ff.ffff and  h# 2500.0000 or  h# 1808 wrmsr
;

h# 1.0000 constant /lpc-block
h# fff0.0000 constant lpc-flash-base

: lpc-flash-write-enable  ( -- )
   h# ffbc.0000 c@  ( id0 )
   dup 0=  swap h# ff =  or  abort" LPC FLASH not present"
   geode-lpc-write-enable
;

: >lpc-adr  ( offset -- )  lpc-flash-base +  ;
: lpc-jedec!  ( byte -- )  h# 5555 >lpc-adr  c!  ;

\ The write enable for the block at fffx.0000 is at ffbx.0002
: lpc-write-enable-block  ( adr -- )
   >lpc-adr  h# 0040.ffff invert and  2 or  0 swap c!
;

: lpc-write-setup  ( -- )  h# aa lpc-jedec!  h# 55 h# 2aaa >lpc-adr c!  ;

: lpc!  ( byte offset -- )
   over h# ff =  if  2drop exit  then
   >lpc-adr                              ( byte lpc-adr )
   lpc-write-setup   h# a0 lpc-jedec!    ( byte lpc-adr )
   2dup c!                               ( byte lpc-adr )
   begin  2dup c@ =  until  2drop        ( )
;

: lpc-wait-toggle  ( -- )
   lpc-flash-base c@   ( value )
   begin  lpc-flash-base c@ tuck  =  until  ( value )
   drop
;
: lpc-erase-block  ( offset -- )
   dup lpc-write-enable-block
   lpc-write-setup   h# 80 lpc-jedec!
   lpc-write-setup   h# 50 swap >lpc-adr c!
   lpc-wait-toggle
;

: lpc-flash-read  ( adr len offset -- )
   lpc-flash-base +  -rot  move
;
: lpc-flash-verify  ( adr len offset -- )
   lpc-flash-base +  -rot  comp
   abort" LPC FLASH verify failed"
;

: lpc-flash-write  ( adr len offset -- )
   -rot  bounds  ?do           ( offset )
      i c@ over lpc!   1+      ( offset' )
   loop                        ( offset )
   drop
;
: lpc-write-block  ( adr len offset -- )
   dup lpc-erase-block         ( adr len offset )
   lpc-flash-write
;

\ Create defer words for generic FLASH writing routines if necessary
[ifndef] flash-write-enable
defer flash-write-enable   ( -- )
defer flash-write-disable  ( -- )
defer flash-write          ( adr len offset -- )
defer flash-read           ( adr len offset -- )
defer flash-verify         ( adr len offset -- )
defer flash-erase-block    ( offset -- )
h# 10.0000 value /flash-block
h# 10000 value /flash-block
[then]

\ Install the LPC FLASH versions as their implementations.

: use-lpc-flash  ( -- )
   ['] lpc-flash-write-enable  to flash-write-enable
   ['] geode-lpc-write-disable to flash-write-disable
   ['] lpc-flash-write         to flash-write
   ['] lpc-flash-read          to flash-read
   ['] lpc-flash-verify        to flash-verify
   ['] lpc-erase-block         to flash-erase-block
   h# 8.0000  to /flash        \ Should be determined dynamically
   /lpc-block to /flash-block
;
use-lpc-flash

[ifndef] reflash
\ Simple UI for reflashing, assuming that you want to overwrite
\ the entire FLASH contents.  That's not always a good assumption;
\ some systems use certain FLASH blocks for persistent data like
\ configuration variables or manufacturing data ("Vital Product Data").

[ifdef] load-base
: flash-buf  load-base  ;
[else]
/flash buffer: flash-buf
[then]
0 value file-loaded?

: ?image-valid   ( len -- )
   /flash <> abort" Image file is the wrong length"
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

: reflash   ( -- )   \ Flash from data already in memory
   ?file

   flash-write-enable
   ." Writing" cr

   /flash  0  ?do
      (cr i .
      flash-buf i +  /flash-block  i  flash-write  ( )
   /flash-block +loop

   flash-write-disable
;

\ Set this defer word to return a string naming the default
\ filename for firmware updates
defer fw-filename$  ' null$ to fw-filename$

: get-file  ( ["filename"] -- )
   parse-word   ( adr len )
   dup 0=  if  2drop fw-filename$  then  ( adr len )
   ." Reading " 2dup type cr                     ( adr len )
   $get-file
;

: flash  ( ["filename"] -- )  get-file reflash  ;
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
