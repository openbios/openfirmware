\ See license at end of file
purpose: bitmaps for Linux ext2fs file system

decimal

0 instance value gd-modified?

: gd-update   ( -- )   true to gd-modified?  ;
: block-bitmap  ( group# -- block# )   group-desc     le-l@  ;
: inode-bitmap  ( group# -- block# )   group-desc 4 + le-l@  ;
: inode-table   ( group# -- block# )   group-desc 8 + le-l@  ;
: free-blocks   ( group# -- n )    group-desc h# 0c + le-w@  ;
: free-inodes   ( group# -- n )    group-desc h# 0e + le-w@  ;
: free-blocks+!  ( n group# -- )
   group-desc h# 0c + 
   tuck le-w@ + swap le-w!  gd-update
;
: free-inodes+!  ( n group# -- )
   group-desc h# 0e +
   tuck le-w@ + swap le-w!  gd-update
;

\ find the lowest clear bit in a byte
: find-low   ( byte -- bit )
   1  8 0 do
      2dup and 0= if
	 drop i leave
      then
      2*
   loop
   nip 1+
;
\ find the first clear bit in a bitmap
: first-free   ( map len -- n )
   -1 -rot  0 ?do			( byte map )
      dup i + c@ h# ff <> if
	 nip i swap leave
      then
   loop					( byte map )
   over 0< if  2drop 0 exit  then
   
   over + c@ find-low			( byte bit )
   swap 8* +
;

: (find-free-block)   ( group# -- n )
   block-bitmap  block
   fpg 8 /  bsize min			\ XXX stay in this block
   first-free
;
: find-free-block   ( -- n )
   0
   #groups 0 ?do
      drop
      i (find-free-block) dup ?leave
   loop
   dup 0= abort" no free blocks found"
;

: (find-free-inode)   ( group# -- n )
   inode-bitmap  block
   ipg 8 /  bsize min			\ XXX stay in this block
   first-free
;
: find-free-inode   ( -- n )
   0
   #groups 0 ?do
      drop
      i (find-free-inode) dup ?leave
   loop
   dup 0= abort" no free inodes found"
;

: bitup    ( n adr -- mask adr' )
   over 3 rshift +			( n adr' )
   1 rot 7 and lshift			( adr' mask )
   swap
;
: block-bit     ( block# -- n adr )   1- fpg /mod block-bitmap block bitup  ;
: block-free?   ( block# -- set? )  block-bit c@ and 0=  ;
: set-block-bit   ( block# -- )   block-bit cset   update  ;
: clr-block-bit   ( block# -- )   block-bit creset update  ;
: free-block      ( block# -- )
   dup block-free? if  drop exit  then
   
   dup clr-block-bit			( block# )
   1 swap 1- fpg /			( 1 group# )
   free-blocks+!
;
: alloc-block     ( -- block# )
   find-free-block dup set-block-bit	( block# )
   dup block bsize erase update		( block# )
   dup 1- fpg /				( block# group# )
   -1 swap free-blocks+!
;

: inode-bit     ( inode# -- n adr )   1- ipg /mod inode-bitmap block bitup  ;
: inode-free?   ( inode# -- set? )  inode-bit c@ and 0=  ;
: set-inode-bit   ( inode# -- )   inode-bit cset   update  ;
: clr-inode-bit   ( inode# -- )   inode-bit creset update  ;
: free-inode      ( inode# -- )
   dup inode-free? if  drop exit  then
   
   dup clr-inode-bit
   1 swap 1- ipg /			( 1 group# )
   free-inodes+!
;
: alloc-inode     ( -- inode# )
   find-free-inode dup set-inode-bit	( inode# )
   dup inode /inode erase update	( inode# )
   dup 1- ipg /				( inode# group# )
   -1 swap free-inodes+!
;
: update-sb   ( -- )
   0  #groups 0 ?do  i free-inodes +  loop  total-free-inodes!
   0  #groups 0 ?do  i free-blocks +  loop  total-free-blocks!
   put-super-block abort" failed to update superblock "
   gds /gds gds-block# write-ublocks abort" failed to update group descriptors "
;
: update-gds   ( -- )
   gd-modified? if
      #groups 1 do  0 group-desc  i fpg * 2 + block  bsize move update  loop
      false to gd-modified?
      update-sb
   then
;

: add-block   ( -- block# )
   #blks-held 2+ #blks-held!
   alloc-block
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
