\ See license at end of file
purpose: Bad block table handling for NAND FLASH

\ Uses the same layout as the Linux mtd bad block tables

0 value bbt   \ Bad block table address

: round-up  ( n boundary -- n' )
   tuck 1- +    ( boundary n' )
   over / *
;

: /bbt  ( -- bytes )   \ Bytes per bad block table
   total-pages pages/eblock /  3 +  4 /   ( bytes )
   /page round-up
;

\ Return address of byte containing bad-block info and the mask
\ for the relevant bits.
: >bbt  ( page# -- byte-adr mask )
   pages/eblock /        ( eblock# )
   4 /mod                ( remainder byte# )
   bbt +                 ( remainder adr )
   3 rot 2* lshift       ( adr mask )
;

\ Returns true if the block containing page# is bad
: block-bad?  ( page# -- flag )
   >bbt              ( adr mask )
   tuck swap c@ and  ( mask masked-byte )
   <>
;
: block-reserved?  ( page# -- flag )
   >bbt              ( adr mask )
   tuck swap c@ and  ( mask masked-byte )
   swap h# aa and  =
;


\ Marks the block containing page# as used for another purpose
: mark-reserved  ( page# -- )
   >bbt                   ( adr mask )
   dup h# aa and  -rot    ( set-mask adr mask )
   invert over c@ and     ( set-mask adr masked-byte )
   rot or  swap c!        ( )
;

\ Marks the block containing page# as bad
: mark-bad  ( page# -- )
   >bbt                   ( adr mask )
   invert over c@ and     ( adr byte )
   swap c!
;

\ Marks the block containing page# as good
: mark-good  ( page# -- )
   >bbt                   ( adr mask )
   over c@ or             ( adr byte )
   swap c!
;

\ Offset of bbt signature within OOB data for page
\ Depends on the controller.  8 for CS5536, 0xe for CaFe
[ifndef] bb-offset
/ecc value bb-offset
[then]

0 value bbt0   \ Starting page number of primary bad block table
0 value bbt1   \ Starting page number of secondary bad block table

h# 10 constant #bbtsearch   \ Number of erase blocks to search for a bbt

\ Page range to search for a bad block table
: bbtbounds  ( low-page high-page -- )
   0 to bbt0   0 to bbt1
   total-pages  #bbtsearch pages/eblock *  -
   total-pages  pages/eblock -
;

\ Look for existing bad block tables, setting bbt0 and bbt1 if found
: find-existing-bbt  ( -- )
   bbtbounds  do
      i  read-oob   bb-offset +  ( adr )
      dup " Bbt0" comp 0=  if    ( adr )
         drop                    ( )
         i to bbt0  bbt1  if  leave  then
      else                       ( adr )
         " 1tbB" comp 0=  if     ( )
            i to bbt1  bbt0  if  leave  then
         then                    ( )
      then                       ( )
   pages/eblock negate +loop
;

\ Assuming that there is no existing bad block table, find suitable
\ places (i.e. good erase blocks) for a primary one and a secondary one
: find-initial-bbt  ( -- )
   bbtbounds   do
      i block-bad?  0=  if
         bbt0  if
            i to bbt1  leave
         else
            i to bbt0
         then
      then
   pages/eblock negate  +loop
;

: .page-byte  ( page# -- )
    push-hex
    ."  at 0x"  dup /page um*  <# #s #> type
    ."  = page 0x" dup . ." = eblock 0x" pages/eblock / u.
    pop-base
;

\ Determine whether a block is bad based on the factory bad-block info
: initial-block-bad?  ( page# -- flag )  read-oob  c@  h# ff <>  ;

\ Report a bad block
: .bad  ( page# -- )  dup mark-bad  ." Found bad block" .page-byte cr   ;

\ Scan the device and record the factory bad-block info in a table
: initial-badblock-scan  ( -- )
   total-pages 0  do
      i initial-block-bad?  if
         i .bad
      else
         i 1+ initial-block-bad?  if  i .bad  then
      then
   pages/eblock +loop
;

\ Write the bad-block table and sign it
: write-bbt  ( signature$ page# -- )
   dup  if                                  ( signature$ page# )
      dup erase-block                       ( signature$ page# )
      bbt over  /bbt /page /   bounds  ?do  ( signature$ page# adr )
         dup i write-page  if               ( signature$ page# adr )
            ." Error writing Bad Block Table - page# " i .x cr
            3drop unloop exit
         then
         /page +                            ( signature$ page# adr' )
      loop                                  ( signature$ page# adr' )
      drop                                  ( signature$ page# )
      /page bb-offset +  write-bytes        ( )
   else                                     ( signature$ page# )
      3drop                                 ( )
   then
;

: save-bbt  ( -- )
   " Bbt0" bbt0  write-bbt
   " 1tbB" bbt1  write-bbt
;

\ Allocate and free memory for a bad block table
: alloc-bbt  ( -- )  bbt 0=  if  /bbt alloc-mem to bbt  then  ;
: release-bbt  ( -- )
   bbt  if
      bbt /bbt free-mem  0 to bbt
   then
;

\ Create a bad block table on a device that currently doesn't have one
: make-bbt  ( -- )
   alloc-bbt
   bbt /bbt h# ff fill
   initial-badblock-scan
   find-initial-bbt
   bbt0 0=   if  ." No good blocks for saving the bad block table" cr  then
   save-bbt
;

\ Read the bad block table from NAND to memory
: read-bbt-pages  ( page# -- )
   bbt swap /bbt /page /  ( adr page# #pages )
   \ Can't use read-blocks because of block-bad? dependency
   bounds  ?do            ( adr )
      dup i read-page  if ( adr )
         ." BBT has uncorrectable errors" cr
         abort
      then                ( adr )
      /page +             ( adr' )
   loop                   ( adr )
   drop
;

\ Find a bad block table
: get-existing-bbt  ( -- )
   bbt  if  exit  then
   alloc-bbt
   find-existing-bbt

   bbt0  if  bbt0  read-bbt-pages  exit  then
   bbt1  if  bbt1  read-bbt-pages  exit  then

   release-bbt
;

\ Get the existing bad block table, or make a new one if necessary
: get-bbt  ( -- )
   get-existing-bbt
   bbt 0=  if
      ." No bad block table; making one" cr
      make-bbt
   then
;

0 instance value resmap
0 value #reserved-eblocks
: ?free-resmap  ( -- )
   resmap  if
      resmap #reserved-eblocks /n* free-mem
      0 to resmap
   then
;

\ The upper limit of pages below the bad block tables
: usable-page-limit  ( -- page# )
   bbt0  if
      bbt0
      bbt1  if  bbt1 min  then
      exit
   then
   bbt1  if  bbt1 exit  then
   total-pages
;

: map-resblock  ( page# #pages -- page#' #pages )
   swap pages/eblock /mod    ( adr #pages offset eblock# )
   resmap swap na+ @         ( adr #pages offset res-eblock# )
   + pages/eblock *  swap    ( adr page#' #pages )
;

external
\ Assumes that the page range doesn't cross an erase block boundary
: read-blocks  ( adr page# #pages -- #read )
   resmap  if                   ( adr page# #pages )
      map-resblock
   else
      over block-bad?  if  3drop 0 exit  then
   then

   rot >r  2dup r> -rot         ( page# #pages adr page# #pages )
   bounds  ?do                  ( page# #pages adr )
      dup i read-page  if       ( page# #pages adr )
         2drop  i swap -        ( #read )
         unloop  exit
      then                      ( page# #pages adr )
      /page +                   ( page# #pages adr' )
   loop                         ( page# #pages adr )
   drop nip
;

: write-blocks  ( adr page# #pages -- #written )
   resmap  if                   ( adr page# #pages )
      map-resblock
   else
      over block-bad?  if  3drop 0 exit  then
   then

   over >r  dup >r               ( adr page# #pages  r: page# #pages )
   bounds  ?do                   ( adr  r: page# #pages )
      dup i write-page  if       ( adr  r: page# #pages )
         drop r> drop i r> -     ( #written )
         unloop exit
      then                       ( adr  r: page# #pages )
      /page +                    ( adr' r: page# #pages )
   loop                          ( adr  r: page# #pages )
   drop  r>  r> drop             ( #pages )
;

: erase-blocks  ( page# #pages -- #pages )
   tuck  bounds  ?do  i erase-block  pages/eblock +loop
;

: block-size    ( -- n )  /page  ;

: erase-size    ( -- n )  /eblock  ;

: max-transfer  ( -- n )  /eblock  ;

: dma-alloc  ( len -- adr )  " dma-alloc" $call-parent  ;

: dma-free  ( adr len -- )  " dma-free" $call-parent  ;

\ Completely erase the device, ignoring any existing bad-block info
\ This is fairly severe, not recommended except in exceptional situations
: scrub  ( -- )
   release-bbt
   total-pages  0  ?do
      (cr i .
      i erase-block
   pages/eblock +loop
   make-bbt
;

: .bn  ( -- )  (cr .  ;  

: (wipe)  ( 'show-bad 'show-erased 'show-bbt -- )
   get-existing-bbt
   bbt 0=  if
      \ If there is no existing bad block table, make one from factory info
      make-bbt
   then                    ( 'show-bad 'show-erased 'show-bbt )

   bbt0  if  bbt0 pages/eblock / over execute  then
   bbt1  if  bbt1 pages/eblock / over execute  then
   drop                              ( 'show-bad 'show-erased )

   usable-page-limit  0  ?do         ( 'show-bad 'show-erased )
      i block-bad?  if
         i pages/eblock / 2 pick execute
      else
         i pages/eblock / over execute
         i erase-block
      then
   pages/eblock +loop                ( 'show-bad 'show-erased )
   2drop  exit
;

\ Clear the device but honor the existing bad block table
: wipe  ( -- )  ['] drop  ['] .bn  ['] drop  (wipe)  ;

: show-bbt  ( -- )
   get-bbt
   total-pages  0  ?do
      i block-reserved?  if  ." Reserved " i .page-byte cr  else
         i block-bad?    if  ." Bad block" i .page-byte cr  then
      then
   pages/eblock +loop
   bbt1  if  ." BBTable 1" bbt1 .page-byte  cr  then
   bbt0  if  ." BBTable 0" bbt0 .page-byte  cr  then
;

: map-reserved
   0  usable-page-limit  0  ?do
      i block-reserved?  if  1+  then
   pages/eblock +loop
   dup to #reserved-eblocks

   /n* alloc-mem  to resmap   ( adr )

   resmap  usable-page-limit  0  ?do   ( adr )
      i block-reserved?  if            ( adr )
         i over !  na1+                ( adr' )
      then                             ( adr )
   pages/eblock +loop                  ( adr )
   drop
;
      
headers

\ Copy-to-NAND functions

external

0 instance value scan-page#

headers

: (next-page#)  ( -- true | page# false )
   usable-page-limit  scan-page# pages/eblock +  ?do
      i block-bad? 0=  if
         i to scan-page#
         scan-page# false unloop exit
      then
   pages/eblock +loop
   true
;
: next-page#  ( -- page# )
   (next-page#)  if  ." No more good NAND blocks" cr  abort  then
;

0 value test-page

external

\ These methods are used for copying a verbatim file system image
\ onto the NAND FLASH, automatically skipping bad blocks.

: start-scan  ( -- )  pages/eblock negate  to scan-page#  ;

\ Must erase all (wipe) first
: copy-block  ( adr -- page# error? )
   next-page#                             ( adr page# )
   tuck  pages/eblock  bounds  ?do        ( page# adr )
      dup i write-page  if                ( page# adr )
         drop true  unloop exit           ( page# true )
      then                                ( page# adr )
      /page +                             ( page# adr' )
   loop                                   ( page# adr )
   drop false                             ( page# false )
;

: put-cleanmarker  ( page# -- )
   " "(85 19 03 20 08 00 00 00)"   ( page# adr len )
   rot  /page /ecc +  write-bytes              ( )
;
: put-cleanmarkers  ( show-xt -- )
   begin  (next-page#) 0=  while  ( show-xt page# )
      dup put-cleanmarker         ( show-xt page# )
      pages/eblock / over execute ( show-xt )
   repeat                         ( show-xt )
   drop
;

: read-next-block  ( adr -- )
   next-page#  pages/eblock  bounds  ?do   ( adr )
      dup i read-page  if                 ( adr )
         ." Uncorrectable error in page 0x" i .x cr
      then
      /page +                             ( adr' )
   loop                                   ( adr )
   drop                                   ( )
;

\ : start-verify  ( -- )
\    /page dma-alloc to test-page
\    start-scan
\ ;
\ : end-verify  ( -- )
\    test-page /page dma-free
\ ;
\ 
\ : verify-block  ( adr -- false | page# true )
\    find-good-block
\    scan-page#  pages/eblock  bounds  ?do  ( adr )
\       test-page i read-page  drop         ( adr )
\       dup test-page /page comp  if        ( adr )
\          drop                             ( )
\          i  true  exit                    ( -- page# true )
\       then                                ( adr )
\       /page +                             ( adr' )
\    loop                                   ( adr )
\    drop                                   ( )
\    false
\ ;

: erased?  ( adr len -- flag )
   bounds  ?do
      i @ -1 <>  if  false unloop exit  then
   /n +loop
   true
;

: block-erased?  ( page# -- flag )
   pages/eblock  bounds  ?do
      test-page i read-page  drop
      test-page /page erased? 0=  if  false unloop exit  then
   pages/eblock +loop
   true
;
: enough-reserve?  ( len -- flag )
   dup  0=  if  true exit  then                      ( len )
   /eblock 1- +  /eblock /                           ( #eblocks-needed )
   usable-page-limit  0  ?do                         ( #needed )
      i  block-reserved?  if  1-  else               ( #needed' )
         i block-erased?  if  1-  then               ( #needed' )
      then                                           ( #needed )
      dup 0=  if  drop true unloop exit  then        ( #needed )
   pages/eblock +loop                                ( #needed )
   drop  false                                       ( flag )
;

0 value any-marked?

: start-fastcopy  ( len -- error? )
   /page dma-alloc to test-page
   enough-reserve?  0=  if
      test-page /page dma-free
      true exit
   then
   false to any-marked?

   \ Erase existing fastnand area
   usable-page-limit  0  ?do
      i block-reserved?  if
         i erase-block
         i mark-good  true to any-marked?
      then
   pages/eblock +loop

   start-scan
   false
;
: next-fastcopy  ( adr -- )
   usable-page-limit  scan-page#  ?do           ( adr )
      i block-erased?  if                       ( adr )
         i pages/eblock write-blocks  drop      ( )
         i mark-reserved   true to any-marked?  ( )
         i pages/eblock +  to scan-page#
         unloop exit
      then                                      ( adr )
   pages/eblock +loop                           ( adr )
   ." Error: no more NAND fastcopy space" cr
   abort
;
: end-fastcopy  ( -- )
   test-page /page dma-free
   any-marked?  if  save-bbt  then
;

0 instance value deblocker
: $call-deblocker  ( ??? adr len -- ??? )  deblocker $call-method  ;
: init-deblocker  ( -- okay? )
   " "  " deblocker"  $open-package  to deblocker
   deblocker if
      true
   else
      ." Can't open deblocker package"  cr  false
   then
;
: seek  ( d.offset -- status )
   resmap  0=  if  -1 exit  then
   " seek" $call-deblocker
;
: position  ( -- d.offset )
   resmap  0=  if  0. exit  then
   " position" $call-deblocker
;
: read  ( adr len -- actual )
   resmap  0=  if  2drop -1 exit  then
   " read" $call-deblocker
;
: write  ( adr len -- actual )
   resmap  0=  if  2drop -1 exit  then
   " write" $call-deblocker
;
: size  ( -- d.size )
   resmap  0=  if  0. exit  then
   #reserved-eblocks /eblock um*
;
: load  ( adr -- actual )
   resmap  0=  if  drop 0 exit   then
   0 0 seek drop
   size drop  read
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
