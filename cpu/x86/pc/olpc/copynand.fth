\ See license at end of file
purpose: Copy a file onto the NAND FLASH

0 value fileih
0 value nandih
0 value /nand-block
0 value /nand-page
0 value nand-pages/block
0 value #nand-pages

: open-nand  ( -- )
   " /nandflash" open-dev to nandih
   nandih 0= abort" Can't open NAND FLASH device"
   " erase-size" nandih $call-method to /nand-block
   " block-size" nandih $call-method to /nand-page
   " size" nandih $call-method  /nand-page  um/mod nip to #nand-pages
   /nand-block /nand-page /  to nand-pages/block
   " start-scan" nandih $call-method
;

: open-img  ( "devspec" -- )
   safe-parse-word  open-dev  to fileih
   fileih 0=  abort" Can't open NAND image file"
;

: #records  ( ih /record -- n )
   swap " size" rot $call-method  rot um/mod nip
;

: copy-nand  ( "devspec" -- )
   open-nand
   open-img

   ['] noop to show-progress

   ." Erasing..." cr
   " wipe" nandih $call-method

   cr ." Writing " fileih /nand-block #records .  ." blocks" cr
   0
   begin
      load-base /nand-block  " read" fileih $call-method
   0> while
      (cr dup .  1+
      load-base " copy-block" nandih $call-method
   repeat
   drop
   fileih close-dev
   nandih close-dev
;

: verify-nand  ( "devspec" -- )
   open-nand
   open-img
   ['] noop to show-progress

   ." Verifing " fileih /nand-block #records . ." blocks" cr

   0
   begin                                                   ( block# )
      load-base /nand-block  " read" fileih $call-method   ( block# #read )
   0> while                                                ( block# )
      (cr dup .  1+                                        ( block#' )
      load-base /nand-block +  " read-next-block" nandih $call-method  ( block# )
      load-base  load-base /nand-block +  /nand-block  comp  if        ( block# )
         cr  ." Miscompare in block starting at page# "                ( block# )
         " scan-page#" nandih $call-method  .x cr                      ( block# )
         key? abort" Aborted by keystroke"                             ( block# )
      then                                                 ( block# )
   repeat                                                  ( block# )
   drop                                                    ( )
   fileih close-dev
   nandih close-dev
;

0 value crc-ih
h# 20 buffer: line-buf
: next-crc  ( -- false | crc true )
   line-buf 9  " read" crc-ih $call-method   ( len )
   dup  0=  if  exit  then                   ( len )
   9 <> abort" Bad CRC line length"          ( )
   line-buf 8 $number  abort" Bad number in CRC file"   ( crc )
   true
;

: open-crcs  ( -- )
   safe-parse-word  open-dev  to crc-ih
   crc-ih 0=  abort" Can't open CRC file"
;

: crc-img  ( "img-devspec" "crc-devspec" -- )
   hex
   open-nand  nandih close-dev  \ To set sizes
   open-img
   open-crcs

   ['] noop to show-progress

   ." Verifying " crc-ih 9 #records . ." blocks" cr

   0
   begin  next-crc  while                                  ( block# crc )
      swap  (cr dup .  1+   swap                           ( block#' crc )

      load-base /nand-block  " read" fileih $call-method   ( block# crc len )
      /nand-block <>  abort" Short img file"               ( block# crc )

      load-base /nand-block  $crc                          ( block# crc actual-crc )
      2dup <>  if
         cr ." CRC miscompare - expected " swap . ." got " . cr
         key? abort" Aborted by keystroke"
      else
         2drop
      then                                                 ( block# )
   repeat                                                  ( block# )
   drop                                                    ( )
   fileih close-dev
   crc-ih close-dev
;

: crc-nand  ( "crc-devspec" -- )
   hex
   open-nand
   open-crcs
   ['] noop to show-progress

   ." Verifying " crc-ih 9 #records . ." blocks" cr

   0
   begin  next-crc  while                                  ( block# crc )
      swap  (cr dup .  1+  swap                            ( block#' crc )

      load-base " read-next-block" nandih $call-method     ( block# crc )

      load-base /nand-block  $crc                          ( block# crc actual-crc )
      2dup <>  if
         cr ." CRC miscompare - expected " swap . ." got " .
         ." in NAND block starting at page "
         " scan-page#" nandih $call-method . cr
         key? abort" Aborted by keystroke"
      else
         2drop
      then                                                 ( block# )
   repeat                                                  ( block# )
   drop                                                    ( )
   nandih close-dev
   crc-ih close-dev
;


: written?  ( adr len -- flag )
   false -rot   bounds  ?do            ( flag )
      i @ -1 <>  if  0= leave  then    ( flag )
   /n +loop                            ( flag )
;

true value dump-oob?
: (dump-nand)  ( "devspec" -- )
   open-nand
   safe-parse-word   ( name$ )

   cr ." Dumping to " 2dup type  cr

   2dup ['] $delete  catch  if  2drop  then  ( name$ )
   $create-file to fileih

   fileih 0=  if  nandih close-dev  true abort" Can't open file"  then

   \ The stack is empty at the end of each line unless otherwise noted
   #nand-pages  0  do
      (cr i .
      load-base  i  nand-pages/block  " read-blocks" nandih $call-method
      nand-pages/block =  if
         load-base /nand-block  written?  if
            load-base /nand-block  " write" fileih $call-method drop
            dump-oob?  if
               i  nand-pages/block  bounds  ?do
                  i " read-oob" nandih $call-method  h# 40  ( adr len )
                  " write" fileih $call-method drop
                  i pad !  pad 4 " write" fileih $call-method drop
               loop
            then
         then
      then
   nand-pages/block +loop
   cr  ." Done" cr

   fileih close-dev
   nandih close-dev
;
: dump-nand  ( "devspec" -- )  true  to dump-oob?  (dump-nand)  ;
: save-nand  ( "devspec" -- )  false to dump-oob?  (dump-nand)  ;


: fastcopy-nand  ( "devspec" -- )
   open-nand

   safe-parse-word  open-dev  to fileih
   fileih 0=  abort" Can't open NAND fastboot image file"

   " size" fileih $call-method  drop              ( len )
   " start-fastcopy" nandih $call-method  if      ( )
      nandih close-dev  fileih close-dev
      true abort" Not enough spare NAND space for fast copy"
   then                                                   ( )

   begin                                                  ( )
      load-base /nand-block  " read" fileih $call-method  ( len )
   dup 0> while                                           ( len )
      \ If the read didn't fill a complete block, zero the rest
      load-base /nand-block  rot /string  erase

      load-base " next-fastcopy" nandih $call-method      ( )
   repeat                                                 ( len )
   drop                                                   ( )
   " end-fastcopy" nandih $call-method                    ( )

   fileih close-dev
   nandih close-dev
;

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
