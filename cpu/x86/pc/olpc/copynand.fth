\ See license at end of file
purpose: Copy a file onto the NAND FLASH

0 value fileih
0 value nandih
0 value crc-ih

0 value /nand-block
0 value /nand-page
0 value nand-pages/block
0 value #nand-pages

0 value #image-eblocks
0 value #crc-records

0 value crc-buf

: >crc  ( index -- crc )  crc-buf swap la+ l@  ;

: $call-nand  ( ?? method$ -- ?? )  nandih $call-method  ;

: close-nand-ihs  ( -- )
   fileih  ?dup  if  0 to fileih  close-dev  0 to #image-eblocks  then
   nandih  ?dup  if  0 to nandih  close-dev  0 to #nand-pages     then
   crc-ih  ?dup  if  0 to crc-ih  close-dev  then
   #crc-records  if
      crc-buf #crc-records /l* free-mem
      0 to crc-buf
      0 to #crc-records
   then
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
   " erase-size" $call-nand to /nand-block
   " block-size" $call-nand to /nand-page
   " size" $call-nand  /nand-page  um/mod nip to #nand-pages
   /nand-block /nand-page /  to nand-pages/block
   " start-scan" $call-nand
;

h# 20 buffer: line-buf
: next-crc  ( -- false | crc true )
   line-buf 9  " read" crc-ih $call-method   ( len )
   dup  0=  if  exit  then                   ( len )
   9 <> " Bad CRC line length" ?nand-abort   ( )
   line-buf 8 $number " Bad number in CRC file"  ?nand-abort  ( crc )
   true
;

\ Open the CRC file and parse all the CRC values into an integer array
: open-crcs  ( name$ -- )
   open-dev  to crc-ih
   crc-ih 0= " Can't open CRC file"  ?nand-abort

   " size" crc-ih $call-method 9 um/mod   ( residue #lines )
   swap  0<> " CRC file length is not a multiple of the CRC record length" ?nand-abort

   to #crc-records                        ( )
   #crc-records /l* alloc-mem  to crc-buf

   #crc-records 0  ?do
      next-crc  0=  " CRC record read failure" ?nand-abort  ( crc )
      crc-buf i la+ l! 
   loop

   crc-ih close-dev   0 to crc-ih
;

h# 100 buffer: image-name-buf
: image-name$  ( -- adr len )  image-name-buf count  ;
h# 100 buffer: crc-name-buf
: crc-name$  ( -- adr len )  crc-name-buf count  ;

: ?open-crcs  ( -- )
   image-name$ + 4 -  " .img" caps-comp 0=  if
      image-name$ crc-name-buf place
      " crc"  crc-name$ + 3 -  swap move
      crc-name$ open-crcs
   then
   #crc-records  if
      ." Check file is " crc-name$ type cr
   then
;

: get-img-filename  ( -- )  safe-parse-word  image-name-buf place  ;

: open-img  ( "devspec" -- )
   image-name$  open-dev  to fileih
   fileih 0= " Can't open NAND image file"  ?nand-abort
   " size" fileih $call-method  /nand-block  um/mod  ( residue #eblocks )
   to #image-eblocks                                 ( residue )
   0<>  " Image file size is not a multiple of the NAND erase block size" ?nand-abort
   #image-eblocks 0= " Image file is empty" ?nand-abort

   #crc-records  if
      #image-eblocks #crc-records <>  " CRC file length is wrong" ?nand-abort
   then
;

: read-image-block  ( -- )
   load-base /nand-block  " read" fileih $call-method   ( len )
   /nand-block <> " Bad read of .img file"  ?nand-abort ( )
;

: check-mem-crc  ( record# -- )
   >crc                                                 ( crc )
   load-base /nand-block  $crc                          ( crc actual-crc )
   2dup <>  if
      cr ." CRC miscompare - expected " swap . ." got " . cr
      true " Stopping" ?nand-abort
      ?key-stop
   else
      2drop
   then                                                 ( )
;

: ?check-crc  ( record# -- )
   #crc-records  if  check-mem-crc  else  drop  then
;

defer show-erasing  ( #blocks -- )
: (show-erasing)  ( #blocks -- )  ." Erasing " . ." blocks" cr  ;
' (show-erasing) is show-erasing

defer show-erased
: (show-erased)  ( block# -- )  (cr .  ;
' (show-erased) is show-erased

defer show-bad
: (show-bad)  ( block# -- )  drop  ;
' (show-bad) is show-bad

defer show-clean
: (show-clean)  ( block# -- )  drop  ;
' (show-clean) is show-clean

defer show-cleaning
: (show-cleaning)  ( -- )  cr ." Cleanmarkers" cr  ;
' (show-cleaning) is show-cleaning

defer show-writing  ( #blocks -- )
: (show-writing)  ." Writing " . ." blocks" cr  ;
' (show-writing) is show-writing

defer show-written
: (show-written)  ( block# -- )  (cr .  ;
' (show-written) is show-written

: copy-nand  ( "devspec" -- )
   open-nand
   get-img-filename
   ?open-crcs
   open-img

   ['] noop to show-progress

   #nand-pages nand-pages/block / show-erasing
   ['] show-bad  ['] show-erased  " (wipe)" $call-nand

   #image-eblocks show-writing

   #image-eblocks  0  ?do
      read-image-block
      i ?check-crc
      load-base " copy-block" $call-nand          ( page# error? )
      " Error writing to NAND FLASH" ?nand-abort  ( page# )
      nand-pages/block / show-written             ( )
   loop

   show-cleaning
   ['] show-clean " put-cleanmarkers" $call-nand

   close-nand-ihs
;

: verify-nand  ( "devspec" -- )
   open-nand
   get-img-filename
   open-img
   ['] noop to show-progress

   ." Verifing " #image-eblocks . ." blocks" cr

   #image-eblocks  0  ?do
      (cr i .
      read-image-block
      load-base /nand-block +  " read-next-block" $call-nand           ( )
      load-base  load-base /nand-block +  /nand-block  comp  if        ( )
         cr  ." Miscompare in block starting at page# "                ( )
         " scan-page#" $call-nand  .x cr                               ( )
         ?key-stop
      then                                                             ( )
   repeat                                                              ( )
   close-nand-ihs
;

: crc-img  ( "img-devspec" -- )
   hex
   open-nand  close-nand-ihs   \ To set sizes
   get-img-filename
   ?open-crcs
   open-img
   #crc-records 0= " No CRC file"  ?nand-abort

   ['] noop to show-progress

   ." Verifying " #crc-records . ." blocks" cr

   #crc-records  0  ?do
      (cr i .  
      read-image-block
      i check-mem-crc
   loop
   close-nand-ihs
;

: crc-nand  ( "crc-devspec" -- )
   hex
   open-nand
   safe-parse-word  open-crcs
   ['] noop to show-progress

   ." Verifying " #crc-records . ." blocks" cr

   #crc-records  0  ?do
      (cr i .

      load-base " read-next-block" $call-nand              ( )

      load-base /nand-block  $crc  i >crc                  ( actual-crc expected-crc )
      2dup <>  if                                          ( actual-crc expected-crc )
         cr ." CRC miscompare - expected " . ." got " .    ( )
         ." in NAND block starting at page "
         " scan-page#" $call-nand . cr
         ?key-stop
      else                                                 ( actual-crc expected-crc )
         2drop                                             ( )
      then                                                 ( )
   repeat                                                  ( )
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
      load-base  i  nand-pages/block  " read-blocks" $call-nand
      nand-pages/block =  if
         load-base /nand-block  written?  if
            load-base /nand-block  " write" fileih $call-method drop
            dump-oob?  if
               i  nand-pages/block  bounds  ?do
                  i " read-oob" $call-nand  h# 40  ( adr len )
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
   " start-fastcopy" $call-nand                           ( error? )
   " Not enough spare NAND space for fast copy" ?nand-abort

   begin                                                  ( )
      load-base /nand-block  " read" fileih $call-method  ( len )
   dup 0> while                                           ( len )
      \ If the read didn't fill a complete block, zero the rest
      load-base /nand-block  rot /string  erase

      load-base " next-fastcopy" $call-nand               ( )
   repeat                                                 ( len )
   drop                                                   ( )
   " end-fastcopy" $call-nand                             ( )

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
