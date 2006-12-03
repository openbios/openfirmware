0 value bbt   \ Bad block table address

: round-up  ( n boundary -- n' )  over 1- +  over / *  ;

: /bbt  ( -- bytes )   \ Bytes per bad block table
   pages/chip pages/eblock /  3 +  4 /   ( bytes )
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

\ Marks the block containing page# as bad
: mark-bad  ( page# -- )
   >bbt                   ( adr mask )
   invert over c@ and     ( adr byte )
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
   pages/chip  #bbtsearch pages/eblock *  -
   pages/chip  pages/eblock -
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
   pages/chip 0  do
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
         dup i write-page                   ( signature$ page# adr )
         /page +                            ( signature$ page# adr' )
      loop                                  ( signature$ page# adr' )
      drop                                  ( signature$ page# )
      /page bb-offset +  write-bytes        ( )
   else                                     ( signature$ page# )
      3drop                                 ( )
   then
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
   " Bbt0" bbt0  write-bbt
   " 1tbB" bbt1  write-bbt
;

\ Read the bad block table from NAND to memory
: read-bbt-pages  ( page# -- )
   bbt swap /bbt /page /  ( adr page# #pages )
   \ Can't use read-blocks because of block-bad? dependency
   bounds  ?do            ( adr )
      dup i read-page     ( adr )
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

\ The upper limit of pages below the bad block tables
: usable-page-limit  ( -- page# )
   bbt0  if
      bbt0
      bbt1  if  bbt1 min  then
      exit
   then
   bbt1  if  bbt1 exit  then
   pages/chip
;

external
\ Assumes that the page range doesn't cross an erase block boundary
: read-blocks  ( adr page# #pages -- #read )
   over block-bad?  if  3drop 0 exit  then
   dup >r          ( adr page# #pages r: #pages )
   bounds  ?do                  ( adr )
      \ XXX need some error handling
      dup i read-page           ( adr )
      /page +                   ( adr' )
   loop                         ( adr )
   drop  r>
;

: write-blocks  ( adr page# #pages -- #written )
   over block-bad?  if  3drop 0 exit  then
   dup >r          ( adr page# #pages r: #pages )
   bounds  ?do                          ( adr )
      \ XXX need some error handling
      dup i write-page                  ( adr )
      /page +                           ( adr' )
   loop                                 ( adr )
   drop  r>
;

: erase-blocks  ( page# #pages -- #pages )
   tuck  bounds  ?do  i erase-block  pages/eblock +loop
;

: block-size    ( -- n )  /page  ;

: erase-size    ( -- n )  /eblock  ;

: max-transfer  ( -- n )  /eblock  ;

\ Completely erase the device, ignoring any existing bad-block info
\ This is fairly severe, not recommended except in exceptional situations
: scrub  ( -- )
   release-bbt
   pages/chip  0  ?do
      (cr i .
      i erase-block
   pages/eblock +loop
   make-bbt
;

\ Clear the device but honor the existing bad block table
: wipe  ( -- )
   get-existing-bbt
   bbt  if
      usable-page-limit  0  ?do
         i block-bad?  if
            cr ." Skipping bad block" i .page-byte cr
         else
            (cr i .
            i erase-block
         then
      pages/eblock +loop
      exit
   then
   \ If there is no existing bad block table, make one from factory info
   make-bbt
;
: show-bbt  ( -- )
   get-bbt
   pages/chip  0  ?do
      i block-bad?  if  ." Bad block" i .page-byte cr  then
   pages/eblock +loop
   bbt1  if  ." BBTable 1" bbt1 .page-byte  cr  then
   bbt0  if  ." BBTable 0" bbt0 .page-byte  cr  then
;

headers

\ Copy-to-NAND functions

0 instance value copy-page#
: +copy-page  ( -- )  copy-page# pages/eblock +  to copy-page#  ;

: find-good-block  ( -- )
   begin  copy-page# block-bad?  while  +copy-page  repeat
;

external

\ These methods are used for copying a verbatim file system image
\ onto the NAND FLASH, automatically skipping bad blocks.

: start-copy  ( -- )  0 to copy-page#  ;

\ Must erase all (wipe) first
: copy-block  ( adr -- )
   find-good-block
   copy-page#  pages/eblock  bounds  ?do  ( adr )
      dup i write-page                    ( adr )
      /page +                             ( adr' )
   loop                                   ( adr )
   drop                                   ( )
   +copy-page
;
