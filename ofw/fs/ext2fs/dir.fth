\ See license at end of file
purpose: Linux ext2fs file system directories

decimal

2       constant root-dir#
0 instance value dir-block#

variable diroff
variable totoff
variable current-dir

: get-dirblk  ( -- end? )
   lblk# bsize * file-size >=  if  true exit  then
   lblk# >pblk# to dir-block#
   false
;

\ **** Return the address of the current directory entry
: dirent  ( -- adr )  dir-block# block diroff @ +  ;

: lblk#++  ( -- )   lblk# 1+ to lblk#  ;

\ **** Select the next directory entry
: next-dirent  ( -- end? )
   dirent  la1+ short@  dup diroff +!  totoff +!
   totoff @  file-size >=  if  true exit  then
   diroff @  bsize =  if
      lblk#++  get-dirblk ?dup  if  exit  then
      diroff off
   then
   false
;

\ **** From directory, get handle of the file or subdir that it references
\ For Unix, file handle is the inode #
: file-handle  ( -- i# )  dirent int@  ;

\ **** From directory, get name of file
: file-name  ( -- adr len )
   dirent la1+ wa1+  dup wa1+    ( len-adr name-adr )
   swap short@  h# ff and   ( adr len )
;

\
\	high-level routines
\
\       After this point, the code should be independent of the disk format!

\ time stamps

\ date&time is number of seconds since 1970
create days/month
\ Jan   Feb   Mar   Apr   May   Jun   Jul   Aug   Sep   Oct   Nov   Dec
  31 c, 28 c, 31 c, 30 c, 31 c, 30 c, 31 c, 31 c, 30 c, 31 c, 30 c, 31 c,

: >d/m  ( day-in-year -- day month )
   12 0  do
      days/month i ca+ c@  2dup <  if
         drop 1+  i 1+  leave
      then
      -
   loop
;
: sec>time&date  ( seconds -- s m h d m y )
   60 u/mod  60 u/mod  24 u/mod		( s m h days )
   [ 365 4 * 1+ ] literal /mod >r	( s m h day-in-cycle )  ( r: cycles )
   dup [ 365 365 + 31 + 29 + ] literal
   2dup =  if		\ exactly leap year Feb 29
      3drop 2 29 2			( s m h year-in-cycle d m )
   else
      >  if  1-  then	\ after leap year
      365 u/mod				( s m h day-in-year year-in-cycle )
      swap >d/m				( s m h year-in-cycle d m )
   then
   rot r> 4 * + 1970 +			( s m h d m y )
;
: timestamp   ( s m h d m y -- seconds )	\ since 1970
   d# 1970 - 4 /mod [ d# 365 4 * 1+ ] literal *		( s m h d m yrs days )
   swap d# 365 * +					( s m h d m days )
   swap 1- 0 ?do  i days/month + c@ + loop		( s m h d days )
   + 1-							( s m h days )
   d# 24 * +   d# 60 * +   d# 60 * +
;

\ e.g.  time&date timestamp
\ timestamp sec>time&date	should have no net effect

: init-inode    ( mode inode# -- )
   inode >r			( mode )
   r@ /inode erase		( mode )
   r@ short!			( )
   time&date timestamp		( time )
   dup r@ 2 la+ int!		( time )	\ set access time
   dup r@ 3 la+ int!		( time )	\ set creation time
       r@ 4 la+ int!		( )		\ set modification time
   1 r@ d# 13 wa+ short!			\ set links_count to 1
   update
   r> drop
;
: >reclen   ( name-length -- record-length )   8 + 4 round-up  ;
\ a directory entry needs 8+n 4-aligned bytes, where n is the name length
\ the last entry has a larger size; it points to the end of the block
: (last-dirent)   ( -- penultimate-offset last-offset )
   diroff off   0 0
   begin						( previous' last' )
      nip diroff @					( previous last )
      dirent la1+ short@				( previous last rec-len )
      dup diroff @ + bsize <				( previous last rec-len not-end? )
      over dirent la1+ wa1+ short@ >reclen = and	( previous last rec-len not-end? )
   while						( previous last rec-len )
      diroff +!						( previous last )
   repeat						( previous last rec-len )
   drop
;
: last-dirent   ( -- free-bytes )
   file-size bsize /mod swap 0= if  1-  then to lblk#	( )
   lblk# >pblk# to dir-block#
   (last-dirent) 2drop
   dirent la1+ dup short@  swap wa1+ short@ >reclen -
;
: set-dirent   ( name$ rec-len inode# -- )
   dirent int!						( name$ rec-len )
   dirent la1+ short!					( name$ )
   dup dirent la1+ wa1+ short!
   dirent la1+ 2 wa+ swap move
   update
;

\ delete directory entry at diroff
: del-dirent   ( -- error? )
   diroff @ >r
   (last-dirent) dup r@ = if				( prev last )
      \ current entry is the last
      r> 2drop						( prev )
      diroff @ 0= abort" delete this block in directory" \ XXX last is also first
      dirent  bsize diroff @ - erase			( prev )
   else							( prev last )
      nip						( last )
      r> diroff !					( last )
      dirent  dup la1+ wa1+ short@ >reclen		( last dirent oldlen )
      rot over - -rot					( last' dirent oldlen )
      2dup + -rot					( last' nextent dirent reclen )
      diroff @ + bsize swap - move			( last' )
   then							( last )
   dup diroff !
   bsize swap -  dirent la1+ short!
   update
   false
;

: ($create)   ( name$ mode -- error? )
   >r							( name$ )
   \ check for room in the directory, and expand it if necessary
   dup >reclen  last-dirent  tuck <  if			( name$ free )
      
      \ there is room. update previous entry, and point to new entry
      dirent la1+ wa1+ short@ >reclen			( name$ free old-len )
      dup dirent la1+ short!  diroff +!			( name$ free )
   else							( name$ free )
      \ doesn't fit, allocate more room
      drop bsize					( name$ bsize )
      append-block
      lblk#++ get-dirblk drop
   then							( name$ rec-len )
   alloc-inode set-dirent false				( error? )
   r> file-handle init-inode
;

: lookup  ( name$ -- not-found? )
   begin
      2dup file-name  $=  if  2drop false exit  then
      
      next-dirent
   until
   2drop true
;

defer init-dir

: $chdir  ( adr len -- error? )		\ Fail if path is file, not dir
   dup 0=  if  2drop true exit  then
   root-dir# init-dir  if  2drop true exit  then
   
   begin			( path-$ )
      over c@ ascii \  =  if  1 /string  then
      ascii \ split-before	( \tail-$ head-$ )
   dup while			
      lookup  if  2drop true exit  then
      dir? 0=  if  2drop true exit  then
      
      file-handle init-dir  if  2drop true exit  then
   
   repeat   ( tail-$ head-$ )
   4drop false
;

\ replace / with \ in a string
: >OFW-path  ( adr len -- )
   bounds do i c@ ascii / =  if  ascii \ i c!  then loop
;

\ XXX try:
: linkpath   ( -- a )
   #blks-held  if	\ long symbolic link path
      direct0 int@ block
   else			\ short symbolic link path
      direct0
   then
;

: select-file  ( i# -- error? )
   to inode#
   symlink?  if
      linkpath dup cstrlen 2dup >OFW-path ascii \  split-after
      ?dup  if
         $chdir  if  2drop true exit  then
      
      else
         drop current-dir @ init-dir  ?dup  if  exit  then
      
      then
      dup 0=  if  2drop false exit  then
      lookup ?dup  if  exit  then
      
      file-handle recurse
   else
      0 to lblk#  false
   then
;

\ **** Select the directory file
: (init-dir)  ( i# -- error? )
   dup current-dir ! 
   select-file ?dup  if  exit  then
   get-dirblk ?dup  if  exit  then
   0 diroff !  0 totoff !
   false
;
' (init-dir) to init-dir

\ Delete a file, given its inode. Does not affect the directory entry, if any.
: idelete   ( inode# -- )
   to inode#
   delete-blocks
   \ clear #blks-held, link-count, etc.
   inode# inode  /inode  6 /l* /string erase
   
   \ delete inode, and set its deletion time.
   time&date timestamp		( time )
   inode# inode 5 la+ int! update
   inode# free-inode
;

\ Delete the file at dirent
: (delete-file)   ( -- error? )
   file-handle 0= if  true exit  then
   
   inode# >r
   file-handle select-file if  r> drop true exit  then
   file? 0= if  r> drop true exit  then		\ XXX handle symlinks
   
   \ is this the only link?
   link-count  dup 2 u< if
      drop
      inode# idelete
   else
      1- link-count!
   then
   
   
   r> to inode#
   \ delete directory entry
   del-dirent			( error? )
;
: (delete-files)   ( -- )		\ from current directory. used by rmdir
   begin  (delete-file) until
;

external

\ directory information

: file-info  ( id -- false | id' s m h d m y len attributes name$ true )
   inode# >r   file-handle to inode#			( id )
   1+  file-sec sec>time&date  file-size  file-attr  file-name true
   r> to inode#
;

\ Linux sometimes leaves a deleted file in the directory with an inode of 0
: next-file-info  ( id -- false | id' s m h d m y len attributes name$ true )
   dup  if  
      begin
	 next-dirent  0= while
	 file-handle if   file-info exit   then
      
      repeat
      drop false
   else
      file-info
   then
;

: $readlink   ( name$ -- true | link$ false )
   lookup if  true exit  then
   
   inode# >r   file-handle to inode#
   linkpath dup cstrlen false
   r> to inode#
;

headers
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
