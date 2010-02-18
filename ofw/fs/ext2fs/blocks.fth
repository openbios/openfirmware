\ See license at end of file
purpose: BLOCK primitive for Linux ext2fs file system

decimal

\ the return of BLOCK, complete with an LRU buffer manager

0 instance value block-bufs
8 constant #bufs

false value bbug?
\ true to bbug?

struct	\ buffer
   /n field >dirty
   /n field >blk#
   \ /n field >device
   0 field >data
constant /buf-hdr
0 instance value /buffer

: >bufadr   ( n -- a )   /buffer * block-bufs +  ;
: >buffer   ( n -- adr )      >bufadr >data  ;
: dirty?    ( n -- dirty? )   >bufadr >dirty @  ;
: dirty!    ( dirty? n -- )   >bufadr >dirty !  ;
: blk#      ( n -- blk# )     >bufadr >blk# @  ;
: blk#!     ( blk# n -- )     >bufadr >blk# !  ;

create buf-table  #bufs allot

: read-fs-block  ( adr fs-blk# -- error? )
   bsize  swap logbsize lshift  read-ublocks
;
: write-fs-block  ( adr fs-blk# -- error? )
   bsize  swap logbsize lshift  write-ublocks
;

: empty-buffers   ( -- )
   block-bufs /buffer #bufs * erase
   #bufs 0 do  -1 i blk#!  loop
   buf-table  #bufs 0 ?do  i 2dup + c!  loop  drop
;

: mru   ( -- buf# )   buf-table c@  ;
: update   ( -- )   true mru dirty!  ;
: mru!   ( buf# -- )			\ mark this buffer as most-recently-used
   dup mru = if  drop exit  then	\ already mru
   
   -1 swap   #bufs 1 do	( offset buf# )
      dup i buf-table + c@ = if				( offset buf# )
	 nip i swap leave
      then
   loop						( offset buf# )
   over #bufs >= abort" mru problem "
   
   swap  buf-table dup 1+ rot move
   buf-table c!
;
: lru   ( -- buf# )
   buf-table #bufs + 1- c@	( n )
   buf-table dup 1+ #bufs 1- move
   dup buf-table c!
;

: flush-buffer   ( buffer# -- )
   dup dirty? if			( buffer# )
      false over dirty!
      dup >buffer  swap blk#		( buffer-adr block# )
      dup gds-fs-block# <=  if
         dup . ." attempt to corrupt superblock or group descriptor" abort
      then
      bbug? if ." W " dup . cr then
      write-fs-block abort" write error "
   else
      drop
   then
;
: flush   ( -- )   #bufs 0 ?do   i flush-buffer   loop  ;

: (buffer)   ( block# -- buffer-adr in-buf? )
   \ is the block already in a buffer?
   0
   begin					( block# buf# )
      2dup blk# = if			\ found it
	 nip  dup mru!  >buffer true exit
      then
      
      1+ dup #bufs =
   until  drop				\ not found	( block# )
   
   \ free up the least-recently-used buffer
   lru dup flush-buffer				( block# buf# )
   
   tuck blk#!   >buffer false			( buffer-adr )
;

: buffer   ( block# -- a )	\ like block, but does no reads
   (buffer) drop
;
: block   ( block# -- a )
   dup (buffer) if  nip exit  then		( block# buffer-adr )
   
   bbug? if ." r " over . cr then
   dup rot read-fs-block abort" read error "	( buffer-adr )
;

: bd   ( n -- )   block bsize dump  ;

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
