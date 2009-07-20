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

0 value nanddump-mode?

0 value crc-buf

h# 40 constant /nand-oob

: >crc  ( index -- 'crc )  crc-buf swap la+  ;

: $call-nand  ( ?? method$ -- ?? )  nandih $call-method  ;

: close-image-file  ( -- )
   fileih  ?dup  if  0 to fileih  close-dev  then
;
: close-nand  ( -- )
   nandih  ?dup  if  0 to nandih  close-dev  then
;
: close-nand-ihs  ( -- )
   0 to nanddump-mode?
   close-image-file
   close-nand
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

: set-nand-vars  ( -- )
   " erase-size" $call-nand to /nand-block
   " page-size" $call-nand to /nand-page
   " size" $call-nand  /nand-page  um/mod nip to #nand-pages
   /nand-block /nand-page /  to nand-pages/block
;
: open-nand  ( -- )
   " /nandflash" open-dev to nandih
   nandih 0=  " Can't open NAND FLASH device"  ?nand-abort
   set-nand-vars
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
   nanddump-mode?  if  exit  then
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

   nanddump-mode?  if
      2dup  h# 20000 um/mod  swap  if  1+  then   ( d.size #eblocks )
      false to img-has-oob?
      nip nip                                     ( #eblocks )
   else
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
   then

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
   nanddump-mode?  if
      load-base /nand-block " read" fileih $call-method   ( len )
      dup /nand-block <>  if                               ( len )
         load-base over +   /nand-page rot -  h# ff fill
      else
         drop
      then
   else
      load-base /nand-block  " read" fileih $call-method   ( len )
      /nand-block <> " Bad read of .img file"  ?nand-abort ( )
   then
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

: written?  ( adr len -- flag )  h# ffffffff lskip 0<>  ;

h# 80 h# 80 h# 80  rgb>565 constant bbt-color      \ gray
    0     0     0  rgb>565 constant erased-color   \ black
h# ff     0     0  rgb>565 constant bad-color      \ red
    0     0 h# ff  rgb>565 constant clean-color    \ blue
h# ff     0 h# ff  rgb>565 constant partial-color  \ magenta
h# ff h# ff     0  rgb>565 constant pending-color  \ yellow
    0 h# ff     0  rgb>565 constant written-color  \ green
    0 h# ff h# ff  rgb>565 constant strange-color  \ cyan
h# ff h# ff h# ff  rgb>565 constant starting-color \ white

d# 22 constant status-line

: gshow-init  ( #eblocks -- )
   cursor-off  " erase-screen" $call-screen

   " bbt0" $call-nand nand-pages/block /  bbt-color show-state
   " bbt1" $call-nand nand-pages/block /  bbt-color show-state

   starting-color   ( #eblocks color )
   swap 0  ?do  i over show-state  loop
   drop
   0 status-line at-xy  
;

: gshow-erasing ( #eblocks -- )   drop  ." Erasing  "  ;

: gshow-erased    ( eblock# -- )  erased-color  show-state  ;
: gshow-bad       ( eblock# -- )  bad-color     show-state  ;
: gshow-bbt-block ( eblock# -- )  bbt-color     show-state  ;
: gshow-clean     ( eblock# -- )  clean-color   show-state  ;
: gshow-strange   ( eblock# -- )  strange-color show-state  ;

: gshow-cleaning ( -- )  d# 26 status-line at-xy  ." Cleanmarkers"  cr  ;
: gshow-done  ( -- )  cursor-on  ;

: gshow-pending  ( eblock# -- )  pending-color  show-state  ;

: gshow-writing  ( #eblocks -- )
   ." Writing  "
   0  swap 0  ?do              ( eblock# )
      dup nand-pages/block * " block-bad?" $call-nand  0=  if  ( eblock# )
         dup show-pending      ( eblock# )
         1                     ( eblock# increment )
      else                     ( eblock# )
         0                     ( eblock# increment )
      then                     ( eblock# increment )
      swap 1+ swap             ( eblock#' increment )
   +loop                       ( eblock#' )
   drop
;

: show-eblock#  ( eblock# -- )  d# 20 status-line at-xy .x  ;
: gshow-written  ( eblock# -- )
   dup  written-color  show-state
   show-eblock#
;

: gshow
   ['] gshow-init      to show-init
   ['] gshow-erasing   to show-erasing
   ['] gshow-erased    to show-erased
   ['] gshow-bad       to show-bad
   ['] gshow-bbt-block to show-bbt-block
   ['] gshow-clean     to show-clean
   ['] gshow-cleaning  to show-cleaning
   ['] gshow-pending   to show-pending
   ['] gshow-writing   to show-writing
   ['] gshow-written   to show-written
   ['] gshow-strange   to show-strange
   ['] gshow-done      to show-done
;

gshow

\ 0 - marked bad block : show-bad
\ 1 - unreadable block : show-bad
\ 2 - jffs2 w/  summary: show-written
\ 3 - jffs2 w/o summary: show-pending
\ 4 - clean            : show-clean
\ 5 - non-jffs2 data   : show-strange
\ 6 - erased           : show-erased
\ 7 - primary   bad-block-table  : show-bbt-block
\ 8 - secondary bad-block-table  : show-bbt-block
: show-status  ( status eblock# -- )
   swap case
      0  of  show-bad        endof
      1  of  show-bad        endof
      2  of  show-written    endof
      3  of  show-pending    endof
      4  of  show-clean      endof
      5  of  show-strange    endof
      6  of  show-erased     endof
      7  of  show-bbt-block  endof
      8  of  show-bbt-block  endof
   endcase
;

0 value nand-map
0 value working-page
: classify-block  ( page# -- status )
   to working-page

   \ Check for block marked bad in bad-block table
   working-page  " block-bad?" $call-nand  if  0 exit  then

   \ Try to read the first few bytes
   load-base 4  working-page  0  " pio-read" $call-nand

   \ Check for a JFFS2 node at the beginning
   load-base w@ h# 1985 =  if
      \ Look for a summary node
      load-base 4  working-page h# 3f +  h# 7fc  " pio-read" $call-nand
      load-base " "(85 18 85 02)" comp  if  3  else  2  then
      exit
   then

   \ Check for non-erased, non-JFFS2 data
   load-base l@ h# ffff.ffff <>  if  5 exit  then

   \ Check for various signatures in the OOB area
   working-page " read-oob" $call-nand  d# 14 +  ( adr )

   \ .. Cleanmarker
   dup  " "(85 19 03 20 08 00 00 00)" comp  0=  if  drop 4 exit  then  ( adr )

   \ .. Bad block tables
\ These can't happen because the BBT table blocks are marked "bad"
\ so they get filtered out at the top of this routine.
\   dup  " Bbt0" comp  0=  if  drop 7 exit  then
\   dup  " 1tbB" comp  0=  if  drop 8 exit  then

[ifdef] notdef
   drop

   \ See if the whole thing is really completely erased
   load-base  working-page  nand-pages/block  ( adr block# #blocks )
   " read-pages" $call-nand  nand-pages/block  <>  if  1 exit  then

   \ Not completely erased
   load-base  /nand-block  written?  if  5 exit  then
[else]
   ( adr )  h# 40 written?  if  5 exit  then
[then]

   \ Erased
   6
;

0 value current-block
0 value examine-done?

string-array status-descriptions
   ," Marked bad in Bad Block Table"  \ 0
   ," Read error"                     \ 1
   ," JFFS2 data with summary"        \ 2
   ," JFFS2 data, no summary"         \ 3
   ," Clean (erased with JFFS2 cleanmarker)"  \ 4
   ," Dirty, with non-JFFS2 data"     \ 5 
   ," Erased, no cleanmarker"         \ 6
   ," Primary Bad Block Table"        \ 7
   ," Secondary Bad Block Table"      \ 8
end-string-array

: show-block-status  ( block# -- )
   dup show-eblock#
   nand-map + c@  status-descriptions count type  kill-line
;

: cell-border  ( block# color -- )
   swap >loc      ( color x y )
   -1 -1 xy+
   3dup  grid-w 1   do-fill                    ( color x y )
   3dup  grid-w 0 xy+  1 grid-h  do-fill  ( color x y )
   3dup  0 1 xy+  1 grid-h do-fill            ( color x y )
   1 grid-h xy+  grid-w 1  do-fill
;
: lowlight  ( block# -- )  background-rgb rgb>565 cell-border  ;
: highlight  ( block# -- )  0 cell-border  ;
: point-block  ( block# -- )
   current-block lowlight
   to current-block
   current-block highlight
;

0 value nand-block-limit
: +block  ( offset -- )
   current-block +   nand-block-limit mod  ( new-block )
   point-block
   current-block  show-block-status
;

: process-key  ( char -- )
   case
      h# 9b     of  endof
      [char] A  of  #cols negate +block  endof  \ up
      [char] B  of  #cols        +block  endof  \ down
      [char] C  of  1            +block  endof  \ right
      [char] D  of  -1           +block  endof  \ left
      [char] ?  of  #cols 8 * negate +block  endof  \ page up
      [char] /  of  #cols 8 *        +block  endof  \ page down
      [char] K  of  8                +block  endof  \ page right
      [char] H  of  -8               +block  endof  \ page left
      h# 1b     of  d# 20 ms key?  0=  if  true to examine-done?  then  endof
   endcase
;

: examine-nand  ( -- )
   0 status-line 1- at-xy  red-letters ." Arrows, fn Arrows to move, Esc to exit" black-letters cr
   #nand-pages nand-pages/block /  to nand-block-limit
   0 to current-block
   current-block highlight
   false to examine-done?
   begin key  process-key  examine-done? until
   current-block lowlight
;

: (scan-nand)  ( -- )
   nand-map 0=  if
      #nand-pages nand-pages/block /  alloc-mem  to nand-map
   then

   " usable-page-limit" $call-nand   
   dup  nand-pages/block /  show-init  ( page-limit )

   7 " bbt0" $call-nand  nand-pages/block /  nand-map + c!
   8 " bbt1" $call-nand  nand-pages/block /  nand-map + c!

   0  ?do
      i classify-block       ( status )
      i nand-pages/block /   ( status eblock# )
      2dup nand-map + c!     ( status eblock# )
      show-status
   nand-pages/block +loop  ( )

   show-done
;

: scan-nand  ( -- )
   open-nand (scan-nand) close-nand-ihs
   examine-nand
;


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
: nd-copy-nand  ( "devspec" -- )
   true to nanddump-mode?
   copy-nand
   false to nanddump-mode?
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
      load-base /nand-block +  " read-next-block" $call-nand           ( end? )
      " More image file blocks than NAND blocks" ?nand-abort           ( )
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

      load-base " read-next-block" $call-nand              ( end? )
      " More CRC records than NAND blocks" ?nand-abort     ( )
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

: dump-eblock?  ( block# -- flag )
   \ Dump JFFS2 w/summary (2), JFFS2 w/o summary (3), non JFFS2 data (5)
   nand-map + c@  dup 2 =  over 3 = or  swap 5 = or
;

: eblock>file  ( -- )
   load-base /nand-block  " write" fileih $call-method
   /nand-block  <>  " Write to dump file failed" ?nand-abort
   load-base /nand-block $crc #image-eblocks >crc l!
   #image-eblocks 1+ to #image-eblocks
;

: fastdump-nand  ( -- )
   \ The stack is empty at the end of each line unless otherwise noted
   (scan-nand)

   cursor-off
   d# 20 status-line at-xy   ."          "

   " usable-page-limit" $call-nand  >eblock#  0  do
      i dump-eblock?  if
         i point-block
         i show-eblock#
         load-base  i nand-pages/block *  nand-pages/block  " read-pages" $call-nand  ( #read )
         nand-pages/block <>  " Read failed" ?nand-abort
         eblock>file
      then
   loop
   show-done
;

: slowdump-nand  ( -- )
   \ The stack is empty at the end of each line unless otherwise noted
   #nand-pages  0  ?do
      (cr i >eblock# .
      load-base  i  nand-pages/block  " read-pages" $call-nand  ( #read )
      nand-pages/block =  if
         load-base /nand-block  written?  if
            ." w"
            eblock>file
            i  nand-pages/block  bounds  ?do
               i " read-oob" $call-nand  h# 40  ( adr len )
               " write" fileih $call-method
               h# 40 <>  " Write of OOB data failed" ?nand-abort
               i pad !  pad 4 " write" fileih $call-method
               4 <>  " Write of eblock number failed" ?nand-abort
            loop
         else
            ." s"
         then
      then
   nand-pages/block +loop
;

: (dump-nand)  ( "devspec" -- )
   open-nand
   get-img-filename

   alloc-crc-buf
   image-name$ open-dump-file

   0 to #image-eblocks

   dump-oob?  if  slowdump-nand  else  fastdump-nand  then
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
