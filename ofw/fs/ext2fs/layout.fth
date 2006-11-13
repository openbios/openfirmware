\ See license at end of file
\ file layout

\ in inode: block0..block11, ind1, ind2, ind3
\ if block# is 0, read returns all 0s

0 instance value #ind-blocks1
0 instance value #ind-blocks2
0 instance value #ind-blocks3
0 instance value lblk#

\ first	number
\ 0	12		direct
\ 12	256		indirect1
\ 268	65536		indirect2
\ 65806	16777216	indirect3
\ maximum 16843020

: >direct     ( index -- adr )     direct0 swap la+  ;
: get-direct  ( index -- block# )  >direct int@  ;
: put-direct  ( block# index -- )  >direct int! update  ;

\ reads: if any indir block is 0, bail and return 0

: >ind1  ( index block# -- adr )
   dup 0=  if  nip exit  then
   
   block swap la+
;
: >ind2  ( index block# -- adr )
   dup 0=  if  nip exit  then
   
   block
   >r  #ind-blocks1 /mod  r>		( index-low index-high adr )
   swap la+ int@			( index-low block# )
   >ind1				( adr )
;
: >ind3  ( index block# -- adr )
   dup 0=  if  nip exit  then
   
   block
   >r  #ind-blocks2 /mod  r>		( index-low index-high adr )
   swap la+ int@			( index-low block# )
   >ind2				( adr )
;
: >pblk  ( logical-block# -- 0 | physical-block-adr )
   dup #direct-blocks <  if     ( lblk# )
      >direct exit
   then                         ( lblk# )
   #direct-blocks -             ( lblk#' )

   dup #ind-blocks1 <  if       ( lblk# )
      #direct-blocks    get-direct >ind1  exit
   then
   #ind-blocks1 -               ( lblk#' )

   dup #ind-blocks2  <  if
      #direct-blocks 1+ get-direct >ind2 exit
   then
   #ind-blocks2  -              ( lblk#' )

   dup #ind-blocks3  <  if
      #direct-blocks 2+ get-direct >ind3 exit
   then

   drop 0
;
: >pblk#  ( logical-block# -- physical-block# )
   >pblk dup 0=  if  exit  then   int@
;


\ writes: if any indir block is 0, allocate and return it.

: get-ind1  ( index block# -- adr )
   >r					( index ) ( r: ind3-block# )
   r@ block over la+ int@		( index block# )
   dup if				( index block# )
      nip
   else
      drop add-block			( index new-block# )
      dup rot r@ block swap la+ int! update	( new-block# )
   then					( block# )
   r> drop
;
: get-ind2  ( index ind2-block# -- block# )
   >r					( index ) ( r: ind3-block# )
   #ind-blocks1 /mod			( index-low index-high )
   r@ block over la+ int@		( index-low index-high block# )
   dup if				( index-low index-high block# )
      nip
   else
      drop add-block			( index-low index-high new-block# )
      dup rot r@ block swap la+ int! update	( index-low new-block# )
   then					( index-low block# )
   get-ind1				( adr )
   r> drop
;
: get-ind3  ( index ind3-block# -- block# )
   >r					( index ) ( r: ind3-block# )
   #ind-blocks2 /mod			( index-low index-high )
   r@ block over la+ int@		( index-low index-high block# )
   dup if				( index-low index-high block# )
      nip
   else
      drop add-block			( index-low index-high new-block# )
      dup rot r@ block swap la+ int! update	( index-low new-block# )
   then					( index-low block# )
   get-ind2				( adr )
   r> drop
;

\ get-pblk# will allocate the block if necessary, used for writes
: get-pblk#  ( logical-block# -- 0 | physical-block# )
   dup #direct-blocks <  if			( lblk# )
      dup get-direct ?dup  if  nip exit  then	( lblk# )
      
      add-block dup rot >direct int! update  exit
   then						( lblk# )
   #direct-blocks -				( lblk#' )

   dup #ind-blocks1 <  if			( lblk# )
      #direct-blocks    get-direct ?dup 0=  if	( lblk# )
	 add-block  dup #direct-blocks put-direct
      then					( lblk# block )
      get-ind1  exit
   then
   #ind-blocks1 -				( lblk#' )

   dup #ind-blocks2  <  if
      #direct-blocks 1+ get-direct ?dup 0=  if
	 add-block  dup #direct-blocks 1+ put-direct
      then					( lblk# block )
      get-ind2 exit
   then
   #ind-blocks2  -              ( lblk#' )

   dup #ind-blocks3  <  if
      #direct-blocks 2+ get-direct ?dup 0=  if
	 add-block  dup #direct-blocks 2+ put-direct
      then					( lblk# block )
      get-ind3 exit
   then

   drop 0
;

\ deletes

\ this code is a bit tricky, in that after deleting a block,
\ you must update the block which pointed to it.

: del-blk0   ( a -- deleted? )
   int@ dup 0= if  exit  then   free-block  true
;
: del-blk1   ( a -- deleted? )
   int@ dup 0= if  exit  then			( blk# )
   
   bsize 0 do					( blk# )
      dup block i + del-blk0 if  0 over block i + int! update  then
   4 +loop					( blk# )
   free-block  true
;
: del-blk2   ( a -- deleted? )
   int@ dup 0= if  exit  then			( blk# )
   
   bsize 0 do					( blk# )
      dup block i + del-blk1 if  0 over block i + int! update  then
   4 +loop					( blk# )
   free-block  true
;
: del-blk3   ( a -- deleted? )
   int@ dup 0= if  exit  then			( blk# )
   
   bsize 0 do					( blk# )
      dup block i + del-blk2 if  0 over block i + int! update  then
   4 +loop					( blk# )
   free-block  true
;
: delete-directs   ( -- )
   #direct-blocks 0 do
      direct0 i la+ del-blk0  if  0 direct0 i la+ int! update  then
   loop
;
: delete-blocks   ( -- )
   delete-directs
   indirect1 del-blk1  if  0 indirect1 int! update  then
   indirect2 del-blk2  if  0 indirect2 int! update  then
   indirect3 del-blk3  if  0 indirect3 int! update  then
;

: append-block   ( -- )
   add-block					( block )
   file-size bsize / dup bsize * file-size!	( block #blocks )
   1+ >pblk int! update
;

: read-file-block  ( adr lblk# -- )
   >pblk#  ?dup  if      ( adr pblk# )
      block swap bsize move
   else                  ( adr )
      bsize erase        ( )
   then
;

: zeroed?   ( a -- empty? )
   0 swap  bsize bounds do  i l@ or  4 +loop  0=
;
: write-file-block  ( adr lblk# -- )
   over zeroed? if	\ see if it is already allocated (XXX later: deallocate it)
      >pblk#   dup 0= if   2drop  exit  then
   else			\ find or allocate physical block
      get-pblk#			( adr pblk# )
   then
   dup h# f8 < if  dup . ." attempt to destroy file system" cr abort  then
   block bsize move update
;


\ installation routines

\ **** Allocate memory for necessary data structures
: allocate-buffers  ( -- error? )
   /super-block alloc-mem is super-block
   get-super-block ?dup  if
      super-block /super-block free-mem exit
   then

   /gds alloc-mem is gds
   gds /gds gds-block# read-ublocks dup  if
      gds         /gds          free-mem
      super-block /super-block  free-mem exit
   then

   bsize /buf-hdr + dup to /buffer
   #bufs *  alloc-mem is block-bufs
   empty-buffers

   bsize /l /  dup to #ind-blocks1  ( #ind-blocks1 )
   dup dup *   dup to #ind-blocks2  ( #ind-blocks1 #ind-blocks2 )
   *               to #ind-blocks3  ( )
;

: release-buffers  ( -- )
   gds             /gds             free-mem
   block-bufs      /buffer #bufs *  free-mem
   super-block     /super-block     free-mem
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
