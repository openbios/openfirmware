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


: >crc  ( index -- 'crc )  crc-buf swap la+  ;

: $call-nand  ( ?? method$ -- ?? )  nandih $call-method  ;

: close-image-file  ( -- )
   fileih  ?dup  if  0 to fileih  close-dev  then
;
: close-nand-ihs  ( -- )
   close-image-file
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

0 value img-has-oob?

: ?open-crcs  ( -- )
   img-has-oob?  if  exit  then
   image-name$ + 4 -  " .img" caps-comp 0=  if
      image-name$ crc-name-buf place
      " crc"  crc-name$ + 3 -  swap move
      crc-name$ open-crcs
   then
   #crc-records  if
      ." Check file is " crc-name$ type cr

      #image-eblocks  if
         #image-eblocks #crc-records <>  " CRC file length is wrong" ?nand-abort
      then
   then
;

: get-img-filename  ( -- )  safe-parse-word  image-name-buf place  ;

: open-img  ( "devspec" -- )
   image-name$  open-dev  to fileih
   fileih 0= " Can't open NAND image file"  ?nand-abort
   " size" fileih $call-method               ( d.size )
   2dup  /nand-block  um/mod  swap  if       ( d.size #eblocks )
      \ Wrong size for the no-oob data format; try the dump-nand format
      drop                                   ( d.size #eblocks )
      h# 21100 um/mod  swap                  ( #eblocks residue )
      0<>  " Image file size is not a multiple of the NAND erase block size" ?nand-abort
      true to img-has-oob?
   else                                      ( d.size #eblocks )
      false to img-has-oob?
      nip nip                                ( #eblocks )
   then                                      ( #eblocks )
   to #image-eblocks

   #image-eblocks 0= " Image file is empty" ?nand-abort
;

: ?skip-oob  ( -- )
   img-has-oob?  if
      load-base h# 1100  " read" fileih $call-method   ( len )
      h# 1100 <> " Bad read of OOB data in .img file"  ?nand-abort ( )
   then
;

: read-image-block  ( -- )
   load-base /nand-block  " read" fileih $call-method   ( len )
   /nand-block <> " Bad read of .img file"  ?nand-abort ( )
;

: check-mem-crc  ( record# -- )
   >crc l@                                              ( crc )
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

defer show-init  ( #eblocks -- )
' drop to show-init

defer show-erasing  ( #blocks -- )
: (show-erasing)  ( #blocks -- )  ." Erasing " . ." blocks" cr  ;
' (show-erasing) to show-erasing

defer show-erased  ( block# -- )
: (show-erased)  ( block# -- )  (cr .  ;
' (show-erased) to show-erased

defer show-bad  ( block# -- )
' drop to show-bad

defer show-bbt-block  ( block# -- )
' drop to show-bbt-block

defer show-clean  ( block# -- )
' drop to show-clean

defer show-cleaning  ( -- )
: (show-cleaning)  ( -- )  cr ." Cleanmarkers"  ;
' (show-cleaning) to show-cleaning

defer show-writing  ( #blocks -- )
: (show-writing)  ." Writing " . ." blocks" cr  ;
' (show-writing) to show-writing

defer show-pending  ( block# -- )
' drop to show-pending

defer show-written
: (show-written)  ( block# -- )  (cr .  ;
' (show-written) to show-written

defer show-strange
' drop to show-strange

defer show-done
' cr to show-done

: >eblock#  ( page# -- eblock# )  nand-pages/block /  ;

: copy-nand  ( "devspec" -- )
   open-nand
   get-img-filename
   open-img
   ?open-crcs

   ['] noop to show-progress

   #nand-pages >eblock#  dup  show-init  ( #eblocks )

   show-erasing                                    ( )
   ['] show-bad  ['] show-erased  ['] show-bbt-block " (wipe)" $call-nand

   #image-eblocks show-writing

   #image-eblocks  0  ?do
      read-image-block
      i ?check-crc
      load-base " copy-block" $call-nand          ( page# error? )
      " Error writing to NAND FLASH" ?nand-abort  ( page# )
      ?skip-oob
      >eblock# show-written             ( )
   loop

   show-cleaning
   ['] show-clean " put-cleanmarkers" $call-nand
   show-done

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
   loop                                                                ( )
   close-nand-ihs
;

: crc-img  ( "img-devspec" -- )
   hex
   open-nand  close-nand-ihs   \ To set sizes
   get-img-filename
   open-img
   ?open-crcs
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

      load-base /nand-block  $crc  i >crc l@               ( actual-crc expected-crc )
      2dup <>  if                                          ( actual-crc expected-crc )
         cr ." CRC miscompare - expected " . ." got " .    ( )
         ." in NAND block starting at page "
         " scan-page#" $call-nand . cr
         ?key-stop
      else                                                 ( actual-crc expected-crc )
         2drop                                             ( )
      then                                                 ( )
   loop                                                    ( )
   close-nand-ihs
;


: written?  ( adr len -- flag )
   false -rot   bounds  ?do            ( flag )
      i @ -1 <>  if  0= leave  then    ( flag )
   /n +loop                            ( flag )
;

true value dump-oob?
: make-new-file  ( devspec$ -- fileih )
   2dup ['] $delete  catch  if  2drop  then  ( name$ )
   2dup ['] $create-file  catch  if          ( name$ x x )
      2drop                                  ( name$ )
      " Can't open a file.  Try using the raw disk?" confirm  if  ( name$ )
         open-dev                            ( ih )
      else                                   ( name$ )
         2drop 0                             ( ih=0 )
      then                                   ( ih )
   else                                      ( name$ ih )
      nip nip                                ( ih )
   then                                      ( ih )
;

: alloc-crc-buf  ( -- )
   #nand-pages >eblock# to #crc-records
   #crc-records /l* alloc-mem to crc-buf
;

: save-crcs  ( -- )
   image-name$ crc-name-buf place
   true
   crc-name$ nip 4 >=  if
      crc-name$ + 4 - c@  [char] .  =  if
         " crc"  crc-name$ + 3 -  swap move
         drop false
      then
   then                ( error? )
   " Filename needs a 3-character extension"  ?nand-abort
   crc-name$           ( name$ )

   ." CRC file is " 2dup type  ( name$ )

   make-new-file to crc-ih

   crc-ih 0=  " Can't open CRC output file"  ?nand-abort

   #image-eblocks 0  ?do
      i >crc l@
      push-hex  
      <# newline hold u# u# u# u# u# u# u# u# u#>    ( adr len )
      pop-base
      " write" crc-ih $call-method 9 <>  " CRC write failed" ?nand-abort
   loop

;
: open-dump-file  ( devspec$ -- )
   cr ." Dumping to " 2dup type  cr

   make-new-file  to fileih

   fileih 0=  " Can't open output"  ?nand-abort
;

: (dump-nand)  ( "devspec" -- )
   open-nand
   get-img-filename

   dump-oob?  0=  if  alloc-crc-buf  then
   image-name$ open-dump-file

   0 to #image-eblocks

   \ The stack is empty at the end of each line unless otherwise noted
   dump-oob?  if  #nand-pages  else  " usable-page-limit" $call-nand  then
   0  do
      (cr i >eblock# .
      load-base  i  nand-pages/block  " read-blocks" $call-nand
      nand-pages/block =  if
         load-base /nand-block  written?  if
            ." w"
            load-base /nand-block  " write" fileih $call-method
            /nand-block  <>  " Write to dump file failed" ?nand-abort
            dump-oob?  if
               i  nand-pages/block  bounds  ?do
                  i " read-oob" $call-nand  h# 40  ( adr len )
                  " write" fileih $call-method drop
                  h# 40 <>  " Write of OOB data failed" ?nand-abort
                  i pad !  pad 4 " write" fileih $call-method
                  4 <>  " Write of eblock number failed" ?nand-abort
               loop
            else
               load-base /nand-block $crc #image-eblocks >crc l!
            then
            #image-eblocks 1+ to #image-eblocks
         else
            ." s"
         then
      then
   nand-pages/block +loop
   cr  ." Done" cr

   close-image-file
   save-crcs

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
