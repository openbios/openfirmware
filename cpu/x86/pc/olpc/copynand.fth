\ See license at end of file
purpose: Copy a file onto the NAND FLASH

0 value fileih
0 value nandih
0 value crc-ih

0 value /nand-block
0 value /nand-page
0 value nand-pages/block
0 value #nand-pages

: close-nand-ihs  ( -- )
   fileih  ?dup  if  0 to fileih  close-dev  then
   nandih  ?dup  if  0 to nandih  close-dev  then
   crc-ih  ?dup  if  0 to crc-ih  close-dev  then
;

: ?nand-abort  ( flag msg$ -- )
   rot  if
      close-nand-ihs  $abort
   else
      2drop
   then
;

: ?key-stop  ( -- )
    key?  dup  if  key drop  then           ( stop? )
    " Stopped by keystroke"   ?nand-abort
;

: open-nand  ( -- )
   " /nandflash" open-dev to nandih
   nandih 0=  " Can't open NAND FLASH device"  ?nand-abort
   " erase-size" nandih $call-method to /nand-block
   " block-size" nandih $call-method to /nand-page
   " size" nandih $call-method  /nand-page  um/mod nip to #nand-pages
   /nand-block /nand-page /  to nand-pages/block
   " start-scan" nandih $call-method
;

h# 20 buffer: line-buf
: next-crc  ( -- false | crc true )
   line-buf 9  " read" crc-ih $call-method   ( len )
   dup  0=  if  exit  then                   ( len )
   9 <> " Bad CRC line length" ?nand-abort   ( )
   line-buf 8 $number " Bad number in CRC file"  ?nand-abort  ( crc )
   true
;


: open-crcs  ( name$ -- )
   open-dev  to crc-ih
   crc-ih 0= " Can't open CRC file"  ?nand-abort
;

h# 100 buffer: image-name-buf
: image-name$  ( -- adr len )  image-name-buf count  ;


: ?open-crcs  ( -- )
   image-name$ + 4 -  " .img" caps-comp 0=  if
      " crc"  image-name$ + 3 -  swap move
      image-name$ open-crcs
   else
      0 to crc-ih
   then
   crc-ih  if  ." Check file is " image-name$ type cr  then
;

: open-img  ( "devspec" -- )
   safe-parse-word  2dup image-name-buf place   ( devspec$ )
   open-dev  to fileih
   fileih 0= " Can't open NAND image file"  ?nand-abort
;

: #records  ( ih /record -- n )
   swap " size" rot $call-method  rot um/mod nip
;

: check-mem-crc  ( crc -- )
   load-base /nand-block  $crc                          ( crc actual-crc )
   2dup <>  if
      cr ." CRC miscompare - expected " swap . ." got " . cr
      true " Stopping" ?nand-abort
      ?key-stop
   else
      2drop
   then                                                 ( )
;

: ?check-crc  ( -- )
   crc-ih  if
      next-crc  0=  " Premature end of .crc file" ?nand-abort
      check-mem-crc
   then
;
: copy-nand  ( "devspec" -- )
   open-nand
   open-img
   ?open-crcs

   ['] noop to show-progress

   ." Erasing..." cr
   " wipe" nandih $call-method

   cr ." Writing " fileih /nand-block #records .  ." blocks" cr
   0
   begin
      load-base /nand-block  " read" fileih $call-method
   0> while
      (cr dup .  1+
      ?check-crc
      load-base " copy-block" nandih $call-method
   repeat
   drop
   close-nand-ihs
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
         ?key-stop
      then                                                 ( block# )
   repeat                                                  ( block# )
   drop                                                    ( )
   close-nand-ihs
;

: crc-img  ( "img-devspec" -- )
   hex
   open-nand  close-nand-ihs   \ To set sizes
   open-img
   ?open-crcs
   crc-ih 0= " No CRC file"  ?nand-abort

   ['] noop to show-progress

   ." Verifying " crc-ih 9 #records . ." blocks" cr

   0
   begin  next-crc  while                                  ( block# crc )
      swap  (cr dup .  1+   swap                           ( block#' crc )

      load-base /nand-block  " read" fileih $call-method   ( block# crc len )
      /nand-block <> " Short img file"  ?nand-abort        ( block# crc )

      check-mem-crc                                        ( block# )
   repeat                                                  ( block# )
   drop                                                    ( )
   close-nand-ihs
;

: crc-nand  ( "crc-devspec" -- )
   hex
   open-nand
   safe-parse-word  open-crcs
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
         ?key-stop
      else
         2drop
      then                                                 ( block# )
   repeat                                                  ( block# )
   drop                                                    ( )
   close-nand-ihs
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
   2dup ['] $create-file  catch  if
      2drop
      " Can't open a file.  Try using the raw disk?" confirm  if
         open-file
      else
         2drop 0
      then
   then
   to fileih

   fileih 0=  " Can't open output"  ?nand-abort

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

   close-nand-ihs
;
: dump-nand  ( "devspec" -- )  true  to dump-oob?  (dump-nand)  ;
: save-nand  ( "devspec" -- )  false to dump-oob?  (dump-nand)  ;


: fastcopy-nand  ( "devspec" -- )
   open-nand

   safe-parse-word  open-dev  to fileih
   fileih 0= " Can't open NAND fastboot image file"  ?nand-abort

   " size" fileih $call-method  drop                      ( len )
   " start-fastcopy" nandih $call-method                  ( error? )
   " Not enough spare NAND space for fast copy" ?nand-abort

   begin                                                  ( )
      load-base /nand-block  " read" fileih $call-method  ( len )
   dup 0> while                                           ( len )
      \ If the read didn't fill a complete block, zero the rest
      load-base /nand-block  rot /string  erase

      load-base " next-fastcopy" nandih $call-method      ( )
   repeat                                                 ( len )
   drop                                                   ( )
   " end-fastcopy" nandih $call-method                    ( )

   close-nand-ihs
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
