\ See license at end of file
purpose: bitmaps for Linux ext2fs file system

decimal

\ Group descriptor access

0 instance value gd-modified?

: gd-update   ( -- )   true to gd-modified?  ;
: block-bitmap  ( group# -- block# )   group-desc     le-l@  ;
: inode-bitmap  ( group# -- block# )   group-desc 4 + le-l@  ;
: inode-table   ( group# -- block# )   group-desc 8 + le-l@  ;
: free-blocks   ( group# -- n )    group-desc h# 0c + le-w@  ;
: free-blocks+!  ( n group# -- )
   group-desc h# 0c +
   tuck le-w@ +  0 max  swap le-w!  gd-update
;
: free-inodes   ( group# -- n )    group-desc h# 0e + le-w@  ;
: free-inodes+!  ( n inode# -- )
   group-desc h# 0e +
   tuck le-w@ + swap le-w!  gd-update
;

[ifdef] 386-assembler
code find-low-zero  ( n -- bit# )
   ax pop
   cx cx xor
   clc
   begin
      cx inc
      1 # ax rcr
   no-carry? until
   cx dec
   cx push
c;
[else]
create lowbits
   8 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  3 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  \ 0-f
   4 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  3 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  \ 10-1f

   5 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  3 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  \ 20-2f
   4 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  3 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  \ 30-3f

   6 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  3 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  \ 40-4f
   4 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  3 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  \ 50-5f

   5 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  3 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  \ 20-2f
   4 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  3 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  \ 30-3f

   7 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  3 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  \ 80-8f
   4 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  3 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  \ 90-9f

   5 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  3 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  \ a0-af
   4 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  3 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  \ b0-bf

   6 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  3 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  \ c0-cf
   4 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  3 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  \ d0-df

   5 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  3 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  \ e0-ef
   4 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  3 c,  0 c,  1 c,  0 c,  2 c,  0 c,  1 c,  0 c,  \ f0-ff

: find-low-zero  ( byte -- bit# )  invert h# ff and  lowbits + c@  ;
[then]

\ Find the first clear bit in a bitmap, set it if found
: first-free   ( len block# -- false | block#-in-group true )
   block swap				( map len )

   2dup  h# ff bskip  dup  0=  if	( map len 0 )
      3drop false exit
   then					( map len residue )
   - 					( map byte# )
   tuck +  dup  c@  dup  find-low-zero	( byte# adr byte bit# )

   \ Set the bit we just found
   >r  1 r@ lshift  or			( byte# adr byte' r: bit# )
   swap c!  \ Write back to map		( byte# r: bit# )

   8* r> +				( block#-in-group )
   update				( block#-in-group )
   true
;

: bitup    ( n adr -- mask adr' )
   over 3 rshift +			( n adr' )
   1 rot 7 and lshift			( adr' mask )
   swap
;

: clear-bit?  ( bit# block# -- cleared? )
   block  bitup				( mask adr' )
   tuck c@				( adr mask byte )
   2dup and  0=  if	\ Already free	( adr mask byte )
      3drop  false  exit
   then					( adr mask byte )
   swap invert and			( adr byte' )
   swap c!				( )
   update				( )
   true
;

: free-block      ( block# -- )
   datablock0 - bpg /mod  		( bit# group# )
   tuck block-bitmap 			( group# bit# block# )
   clear-bit?  if			( group# )
      1  swap  free-blocks+!
   else					( group# )
      drop
   then
;

: alloc-block   ( -- block# )
   #groups 0  ?do			( )
      i free-blocks  if			( )
         bpg 3 rshift  bsize min	( len )	\ XXX stay in this block
         i  block-bitmap  		( len block# )
         first-free  if			( block#-in-group )
            -1 i free-blocks+!		( block#-in-group )
            i bpg *  +  datablock0 +	( block# )
            dup buffer bsize erase update	( block# )
            unloop exit
         else
            \ The allocation bitmap disagrees with the free block count,
            \ so fix the free block count to prevent thrashing.
            i free-blocks  negate  i free-blocks+!
         then
      then
   loop
   true abort" no free blocks found"
;

: free-inode      ( inode# -- )
   1- ipg /mod 				( bit# group# )
   tuck inode-bitmap			( group# bit# block# )
   clear-bit?  if			( group# )
      1  swap  free-inodes+!
   else					( group# )
      drop
   then
;

: alloc-inode   ( -- inode# )
   #groups 0 ?do
      ipg 3 rshift  bsize min		( len )		\ XXX stay in this block
      i  inode-bitmap 			( len block# )
      first-free  if			( inode#-in-group )
         -1 i free-inodes+!		( inode#-in-group )
         i ipg * +  1+			( inode# )
         dup inode /inode erase update	( inode# )
         unloop exit
      then
   loop
   true abort" no free inodes found"
;

: update-sb   ( -- )
   0  #groups 0 ?do  i free-inodes +  loop  total-free-inodes!
   0  #groups 0 ?do  i free-blocks +  loop  total-free-blocks!
   put-super-block abort" failed to update superblock "
   gds /gds gds-block# write-ublocks abort" failed to update group descriptors "
;

: update-gds   ( -- )
   gd-modified? if
      \ Copy group descriptors to backup locations
      #groups 1  do
         0 group-desc		( gd0-adr )
         i bpg *  2+ block	( gd0-adr gdn-adr )
         bsize move update	( )
      loop
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
