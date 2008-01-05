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
   partition-start +
   pages/eblock /        ( eblock# )
   4 /mod                ( remainder byte# )
   bbt +                 ( remainder adr )
   3 rot 2* lshift       ( adr mask )
;

\ Returns true if the block containing page# is bad
: block-bad?  ( page# -- flag )
   bbt 0=  if  drop false exit  then
   >bbt              ( adr mask )
   tuck swap c@ and  ( mask masked-byte )
   <>
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
    partition-start +
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
      /page bb-offset +  write-bytes  if    ( )
         ." Failed to write bad block table" cr
      then
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
: read-bbt-pages  ( page# -- error? )
   bbt swap /bbt /page /  ( adr page# #pages )
   \ Can't use read-blocks because of block-bad? dependency
   bounds  ?do            ( adr )
      dup i read-page  if ( adr )
         ." BBT has uncorrectable errors" cr
         drop true unloop exit
      then                ( adr )
      /page +             ( adr' )
   loop                   ( adr )
   drop false
;

\ Find a bad block table
: get-existing-bbt  ( -- )
   bbt  if  exit  then
   alloc-bbt
   find-existing-bbt

   bbt0  if  bbt0  read-bbt-pages 0=  if  exit  then  then
   bbt1  if  bbt1  read-bbt-pages 0=  if  exit  then  then

   bbt0 bbt1 or  if
      ." Both bad block tables are unreadable" cr
   then
   release-bbt
;

0 instance value #bad-blocks
0 instance value bb-list
: make-bb-list  ( -- )
   0  usable-page-limit  0  ?do   ( bb# )
      i block-bad?  if  1+  then
   pages/eblock +loop
   to #bad-blocks

   #bad-blocks 1+  /n* alloc-mem to bb-list

   bb-list  usable-page-limit  0  ?do   ( adr )
      i block-bad?  if                  ( adr )
         i over !  na+                  ( adr' )
      then                              ( adr )
   pages/eblock +loop                   ( adr )
   h# 7fffffff swap !                   ( )   \ "Stopper" entry
;

: map-page#  ( page# -- page#' )
   pages/eblock /mod         ( offset eblock# )
   bb-list                   ( offset eblock# list-adr )
   begin  2dup @  >=  while  ( offset eblock# list-adr )
      swap 1+  swap na1+     ( offset eblock#' list-adr' )
   repeat                    ( offset eblock#' list-adr' )
   pages/eblock *  +         ( page#' )
;
: ?free-bb-list  ( -- )
   bb-list  if
      bb-list #bad-blocks 1+  /n*  free-mem
      0 to bb-list
   then
;

\ The upper limit of pages below the bad block tables
: (usable-page-limit)  ( -- page# )
   bbt0  if
      bbt0
      bbt1  if  bbt1 min  then
      exit
   then
   bbt1  if  bbt1 exit  then
   total-pages
;

\ Get the existing bad block table, or make a new one if necessary
: get-bbt  ( -- )
   get-existing-bbt
   bbt0 bbt1 or  0=  if
      ." No bad block table; making one" cr
      make-bbt
   then
   (usable-page-limit) to usable-page-limit  
;

external
\ Assumes that the page range doesn't cross an erase block boundary
: read-blocks  ( adr page# #pages -- #read )
   over block-bad?  if  3drop 0 exit  then

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
   over block-bad?  if  3drop 0 exit  then

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
: scrub!  ( -- )
   release-bbt
   total-pages  0  ?do
      (cr i .
      i erase-block
   pages/eblock +loop
   make-bbt
;
: scrub  ( -- )
   ." scrub is dangerous because it discards factory bad block information."  cr
   ." That can cause bad problems with later use of the NAND FLASH device."  cr
   ." Type  scrub!  if you really want to do it." cr
;

: .bn  ( -- )  (cr .  ;  

: (wipe)  ( 'show-bad 'show-erased 'show-bbt -- )
   partition# 0=  if
      get-existing-bbt
      bbt0 bbt1 or  0=  if
         \ If there is no existing bad block table, make one from factory info
         make-bbt
      then                    ( 'show-bad 'show-erased 'show-bbt )

      bbt0  if  bbt0 pages/eblock / over execute  then
      bbt1  if  bbt1 pages/eblock / over execute  then
   then
   drop                              ( 'show-bad 'show-erased )

   partition-size  0  ?do            ( 'show-bad 'show-erased )
      i block-bad?  if
         i partition-start + pages/eblock / 2 pick execute
      else
         i partition-start + pages/eblock / over execute
         i erase-block
      then
   pages/eblock +loop                ( 'show-bad 'show-erased )
   2drop  exit
;

\ Clear the device but honor the existing bad block table
: wipe  ( -- )  ['] drop  ['] .bn  ['] drop  (wipe)  ;

: show-bbt  ( -- )
   total-pages  0  ?do
      i block-bad?    if  ." Bad block" i .page-byte cr  then
   pages/eblock +loop
   bbt1  if  ." BBTable 1" bbt1 .page-byte  cr  then
   bbt0  if  ." BBTable 0" bbt0 .page-byte  cr  then
;

headers

\ Copy-to-NAND functions

external

0 instance value scan-page#

headers

: next-page#  ( -- true | page# false )
   partition-size  scan-page# pages/eblock +  ?do
      i block-bad? 0=  if
         i to scan-page#
         scan-page# false unloop exit
      then
   pages/eblock +loop
   true
;

0 value test-page

external

\ These methods are used for copying a verbatim file system image
\ onto the NAND FLASH, automatically skipping bad blocks.

: start-scan  ( -- )  pages/eblock negate  to scan-page#  ;

: try-copy-block  ( adr page# -- okay? )
   pages/eblock  bounds  ?do        ( adr )
      dup i write-page  if          ( adr )
         drop false  unloop exit    ( false )
      then                          ( adr )
      /page +                       ( adr' )
   loop                             ( adr )
   drop true                        ( true )
;
: block-okay?  ( adr page# -- okay? )
   pages/eblock  bounds  ?do        ( adr )
      i get-page  if                ( adr )
         drop false  unloop exit    ( false )
      then                          ( adr buf-adr )
      over /page comp  if           ( adr )
         drop false unloop exit
      then
      /page +                       ( adr' )
   loop                             ( adr )
   drop true                        ( true )
;
: copy&check  ( adr page# -- okay? )
   2dup try-copy-block  0=  if  2drop false exit  then  ( adr page# )
   block-okay?
;

: copy-block  ( adr -- page# error? )
   begin  next-page#  0=  while                      ( adr page# )
      2dup copy&check  if  nip partition-start + false exit  then      ( adr page# )
      \ Error; retry once
      dup erase-block                                ( adr page# )
      2dup copy&check  if  nip partition-start + false exit  then     ( adr page# )
      mark-bad  save-bbt                             ( adr )
   repeat                                            ( adr )
   drop                                              ( )
   partition-size pages/eblock - partition-start + true            ( page# error? )
;

: put-cleanmarker  ( page# -- )
   >r
   " "(85 19 03 20 08 00 00 00)"     ( adr len r: page# )
   r@ /page /ecc +  write-bytes  if  ( r: page# )
      r@ mark-bad save-bbt           ( r: page# )
   then                              ( r: page# )
   r> drop
;
: put-cleanmarkers  ( show-xt -- )
   begin  next-page# 0=  while    ( show-xt page# )
      dup put-cleanmarker         ( show-xt page# )
      partition-start + pages/eblock / over execute ( show-xt )
   repeat                         ( show-xt )
   drop
;

: read-next-block  ( adr -- no-more? )
   next-page#  if  drop true exit  then   ( adr page# )
   pages/eblock  bounds  ?do              ( adr )
      dup i read-page  if                 ( adr )
         ." Uncorrectable error in page 0x" i .x cr
      then
      /page +                             ( adr' )
   loop                                   ( adr )
   drop false                             ( flag )
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
