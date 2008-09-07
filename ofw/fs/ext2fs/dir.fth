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
\ Dirent fields:
\ 00.l inode
\ 04.w offset to next dirent
\ 06.b name length
\ 07.b flags?
\ 08.s name string

: >reclen   ( name-length -- record-length )   8 + 4 round-up  ;

: dirent-inode@  ( -- n )  dirent int@  ;
: dirent-inode!  ( n -- )  dirent int!  ;
: dirent-len@  ( -- n )  dirent la1+ short@  ;
: dirent-len!  ( n -- )  dirent la1+ short!  ;
: dirent-nameadr   ( -- adr )  dirent la1+ 2 wa+  ;
: dirent-namelen@  ( -- b )  dirent la1+ wa1+ c@  ;
: dirent-namelen!  ( b -- )  dirent la1+ wa1+ c!  ;
: dirent-type@     ( -- b )  dirent la1+ wa1+ ca1+  c@  ;
: dirent-type!     ( b -- )  dirent la1+ wa1+ ca1+  c!  ;
: dirent-reclen    ( -- n )  dirent-namelen@ >reclen  ;

: lblk#++  ( -- )   lblk# 1+ to lblk#  ;

\ **** Select the next directory entry
: next-dirent  ( -- end? )
   dirent-len@  dup diroff +!  totoff +!
   totoff @  file-size >=  if  true exit  then
   diroff @  bsize =  if
      lblk#++  get-dirblk  if  true exit  then
      diroff off
   then
   false
;

\ **** From directory, get handle of the file or subdir that it references
\ For Unix, file handle is the inode #
: file-handle  ( -- i# )  dirent-inode@  ;

\ **** From directory, get name of file
: file-name  ( -- adr len )
   dirent la1+ wa1+  dup wa1+    ( len-adr name-adr )
   swap c@                       ( adr len )
;

\
\	high-level routines
\
\       After this point, the code should be independent of the disk format!

: init-inode    ( mode inode# -- )
   inode >r			( mode )
   r@ /inode erase		( mode )
   r@ short!			( )
   time&date >unix-seconds	( time )
   dup r@ 2 la+ int!		( time )	\ set access time
   dup r@ 3 la+ int!		( time )	\ set creation time
       r@ 4 la+ int!		( )		\ set modification time
   1 r@ d# 13 wa+ short!			\ set links_count to 1
   update
   r> drop
;

\ On entry:
\   current-dir @  is the inode of the directory file
\   dir-block# is the physical block number of the first directory block
\   diroff @ is 0
\ On successful exit:
\   dir-block# is the physical block number of the current directory block
\   diroff @ is the within-block offset of the new dirent
: no-dir-space?  ( #needed -- true | offset-to-next false )
   begin						( #needed )
      dirent-inode@  if					( #needed )
         dup  dirent-len@ dirent-reclen -  <=  if	( #needed )
            \ Carve space out of active dirent
            drop					( )
            dirent-len@ dirent-reclen -			( offset-to-next )
            dirent-reclen  dup dirent-len!  diroff +!	( offset-to-next )
            false exit
         then
      else						( #needed )
         dup  dirent-len@  <=  if			( #needed )
            \ Reuse deleted-but-present dirent
            drop					( )
            dirent-len@					( offset-to-next )
            false exit
         then						( #needed )
      then						( #needed )
      next-dirent					( #needed )
   until						( #needed )
   drop true
;

\ a directory entry needs 8+n 4-aligned bytes, where n is the name length
\ the last entry has a larger size; it points to the end of the block
: (last-dirent)   ( -- penultimate-offset )
   diroff off   0
   begin						( last )
      dirent-len@				        ( last rec-len )
      dup diroff @ + bsize <				( last rec-len not-end? )
\     over dirent-reclen =  and				( last rec-len not-end? )
   while						( last rec-len )
      nip diroff @ swap					( last' rec-len )
      diroff +!						( last )
   repeat						( last )
   drop							( last )
;
: last-dirent   ( -- free-bytes )
   file-size bsize /mod swap 0= if  1-  then to lblk#	( )
   lblk# >pblk# to dir-block#
   (last-dirent) drop
   dirent-len@  dirent-reclen  -
;
: set-dirent   ( name$ rec-len inode# -- )
   dirent int!						( name$ rec-len )
   dirent-len!						( name$ )
   dup dirent-namelen!					( name$ )
   \ XXX set actual file type here if EXT2_FEATURE_INCOMPAT_FILETYPE
   0 dirent-type!					( name$ )
   dirent-nameadr swap move				( )
   update
;

: to-previous-dirent  ( -- )
   diroff @  					( this )
   0 diroff !					( this )
   begin					( this )
      dup  diroff @ dirent-len@ +  <>		( this not-found? )
   while					( this )
      dirent-len@ diroff +!			( this )
   repeat					( this )
   diroff @ swap -  totoff +!			( )
;

\ delete directory entry at diroff
: del-dirent   ( -- error? )
   diroff @  if
      \ Not first dirent in block; coalesce with previous
      dirent-len@				( deleted-len )
      to-previous-dirent			( deleted-len )
      dirent-len@ + dirent-len!			( )
      dirent dirent-reclen +			( adr )
      dirent-len@ dirent-reclen -  erase	( )
   else
      \ First dirent in block; zap its inode
      0 dirent-inode!
      
   then      
   update
   false
;

: ($create)   ( name$ mode -- error? )
   >r							( name$ )
   \ check for room in the directory, and expand it if necessary
   dup >reclen  no-dir-space?   if			( name$ new-reclen )
      \ doesn't fit, allocate more room
      bsize						( name$ bsize )
      append-block
      lblk#++ get-dirblk drop
   then							( name$ rec-len )

   \ At this point dirent points to the place for the new dirent
   alloc-inode set-dirent false				( error? )
   r> dirent-inode@ init-inode
;

\ On entry:
\   current-dir @  is the inode of the directory file
\   dir-block# is the physical block number of the first directory block
\   diroff @ and totoff @ are 0
\ On successful exit:
\   dir-block# is the physical block number of the current directory block
\   diroff @ is the within-block offset of the directory entry that matches name$
\   totoff @ is the overall offset of the directory entry that matches name$
: lookup  ( name$ -- not-found? )
   begin
      dirent-inode@  if   \ inode=0 for a deleted dirent at the beginning of a block
         2dup file-name  $=  if  2drop false exit  then
      then
      next-dirent
   until
   2drop true
;

defer init-dir

: $chdir  ( path$ -- error? )
   begin  dup  while		( path$ )
      [char] \ left-parse-string  ( tail$ head$ )
      dup  0=  if               ( tail$ head$ )  \ Begins with \
         2drop			( tail$ )
         root-dir# init-dir  if  2drop  true exit  then
      else		        ( tail$ head$ )
         lookup  if  2drop true exit  then
         dir? 0=  if  2drop true exit  then
         file-handle init-dir  if  2drop true exit  then
      then			( tail$ )
   repeat			( path$ )
   2drop false
;

\ replace / with \ in a string
: >OFW-path  ( adr len -- )
   bounds do i c@ ascii / =  if  ascii \ i c!  then loop
;

: linkpath   ( -- a )
   file-acl  if  bsize 9 rshift  else  0  then     ( #acl-blocks )
   #blks-held  <>  if	\ long symbolic link path
      direct0 int@ block
   else			\ short symbolic link path
      direct0
   then
;

variable parent-dir

: select-file  ( i# -- error? )
   to inode#
   symlink?  if                                                 ( )
      linkpath dup cstrlen 2dup >OFW-path ascii \  split-after  ( file$ path\$ )
      dup  if                                                   ( file$ path\$ )
         parent-dir @ init-dir  if  4drop true exit  then       ( file$ path\$ )
         $chdir  if  2drop true exit  then                      ( file$ )
      else                                                      ( file$ path\$ )
         2drop current-dir @ init-dir  if  2drop true exit  then ( file$ )
      then                                                       ( file$ )
      dup 0=  if  2drop false exit  then                         ( file$ )
      lookup  if  true exit  then                                ( )
      
      file-handle recurse
   else                                                         ( )
      0 to lblk#  false                                         ( )
   then                                                         ( )
;

\ **** Select the directory file
: (init-dir)  ( i# -- error? )
   \ Save the current directory because we will need to return to it
   \ in case we encounter a relative symlink.
   current-dir @ parent-dir !           ( i# )
   dup current-dir !                    ( i# )
   select-file  if  true exit  then     ( )
   get-dirblk   if  true exit  then     ( )
   0 diroff !  0 totoff !               ( )
   false                                ( )
;
' (init-dir) to init-dir

\ Delete a file, given its inode. Does not affect the directory entry, if any.
: idelete   ( inode# -- )
   to inode#
   delete-blocks
   \ clear #blks-held, link-count, etc.
   inode# inode  /inode  6 /l* /string erase
   
   \ delete inode, and set its deletion time.
   time&date >unix-seconds		( time )
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
   1+  file-sec unix-seconds>  file-size  file-attr  file-name true
   r> to inode#
;

\ Deleted files at the beginning of a directory block have inode=0
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
