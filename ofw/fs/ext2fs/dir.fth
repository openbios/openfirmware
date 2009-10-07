\ See license at end of file
purpose: Linux ext2fs file system directories

decimal

2 constant root-dir#
0 instance value dir-block#
0 instance value lblk#

variable diroff
variable totoff

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

: dirent-vars  ( -- diroff totoff lblk# inode# )
   diroff @  totoff @  lblk#  inode#
;
: restore-dirent  ( diroff totoff lblk# inode# -- )
   to inode#  to lblk#  totoff !  diroff !
   get-dirblk drop
;

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
   inode >r			( mode r: inode-adr )
   r@ /inode erase		( mode r: inode-adr )
   r@ short!			( r: inode-adr )
   time&date >unix-seconds	( time r: inode-adr )
   dup r@ 2 la+ int!		( time r: inode-adr ) \ set access time
   dup r@ 3 la+ int!		( time r: inode-adr ) \ set creation time
       r@ 4 la+ int!		( r: inode-adr )      \ set modification time
   1 r@ d# 13 wa+ short!	( r: inode-adr )      \ set links_count to 1
   update			( r: inode-adr )
   r> drop			( )
;

\ On entry:
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
: set-dirent   ( name$ type rec-len file-type inode# -- )
   dirent int!						( name$ rec-len )
   \ XXX this should be contingent upon EXT2_FEATURE_INCOMPAT_FILETYPE
   dirent-type!						( name$ )
   dirent-len!						( name$ )
   dup dirent-namelen!					( name$ )
   dirent-nameadr swap move				( )
   update
;

: to-previous-dirent  ( -- )
   diroff @  					( this )
   diroff off					( this )
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

1 constant regular-type
2 constant dir-type
7 constant symlink-type

: ($create)   ( name$ mode -- error? )
   >r							( name$ r: mode )
   \ check for room in the directory, and expand it if necessary
   dup >reclen  no-dir-space?   if			( name$ new-reclen r: mode )
      \ doesn't fit, allocate more room
      bsize						( name$ bsize r: mode )
      append-block
      lblk#++ get-dirblk drop
   then							( name$ rec-len r: mode )

   \ At this point dirent points to the place for the new dirent
   \ XXX handle symlinks!
   r@ h# f000 and h# 4000 =  if  dir-type  else  regular-type  then  ( name$ rec-len type r: mode )
   alloc-inode set-dirent false		( error? r: mode )
   r> dirent-inode@ init-inode
;

: linkpath   ( -- a )
   file-acl  if  bsize 9 rshift  else  0  then     ( #acl-blocks )
   #blks-held  <>  if	\ long symbolic link path
      direct0 int@ block
   else			\ short symbolic link path
      direct0
   then
;

\ --

\ Information that we need about the working file/directory
\ The working file changes at each level of a path search

0 instance value wd-inum  \ Inumber of directory to search
0 instance value wf-inum  \ Inumber of file or directory found
0 instance value wf-type  \ Type - 4 for directory, d# 10 for symlink, etc

char \ instance value delimiter

defer $resolve-path
d# 1024 constant /symlink   \ Max length of a symbolic link

: set-root  ( -- )
   root-dir# to wd-inum  root-dir# to wf-inum  dir-type to wf-type
;

: strip\  ( name$ -- name$' )
   dup  0<>  if                      ( name$ )
      over c@  delimiter  =  if      ( name$ )
         1 /string                   ( name$ )
         set-root                    ( name$ )
      then                           ( name$ )
   then                              ( name$ )
;

: set-inode  ( inode# -- )
   to inode#
   0 to lblk#
;

: first-dirent  ( dir-inode# -- end? )  \ Adapted from (init-dir)
   set-inode
   get-dirblk  if  true exit  then
   diroff off  totoff off               ( )
   false                                ( )
;   

\ On entry:
\   inode# is the inode of the directory file
\   dir-block# is the physical block number of the first directory block
\   diroff @ and totoff @ are 0
\ On successful exit:
\   dir-block# is the physical block number of the current directory block
\   diroff @ is the within-block offset of the directory entry that matches name$
\   totoff @ is the overall offset of the directory entry that matches name$

: $find-name  ( name$ dir-inum -- error? )
   first-dirent                            ( end? )
   begin  0=  while                        ( name$ )
      \ dirent-inode@ = 0 means a deleted dirent at the beginning
      \ of a block; skip those
      dirent-inode@  if                    ( name$ )
         2dup  file-name                   ( name$ name$ this-name$ )
         $=  if
            dirent-inode@ to wf-inum       ( name$ )
            dirent-type@  to wf-type       ( name$ )
            2drop false exit
         then                              ( name$ )
      then
      next-dirent                          ( name$ end? )
   repeat                                  ( name$ )

   2drop                                   ( )
   true
;

: symlink-resolution$  ( inum -- data$ )
   to inode#
   linkpath dup cstrlen
;

\ The work file is a symlink.  Resolve it to a new dirent
: dir-link  ( -- error? )
   delimiter >r  [char] / to delimiter     ( r: delim )

   \ Allocate temporary space for the symlink value (new name)
   /symlink alloc-mem >r                   ( r: delim dst )

   \ Copy the symlink resolution to the temporary buffer
   wf-inum symlink-resolution$    ( src len  r: delim dst )
   tuck  r@ swap move             ( len      r: delim dst )

   r@ swap $resolve-path          ( error?   r: delim dst )

   r> /symlink free-mem           ( error?   r: delim )
   r> to delimiter                ( error? )
;

\ On successful exit, wf-inum is the inode# of the last path component,
\ wf-type is its type, and wd-inum is inode# of the last directory encountered

: ($resolve-path)  ( path$ -- error? )
   dir-type to wf-type
   \ strip\ sets wd-inum if the path begins with the delimiter
   begin  strip\  dup  while                       ( path$  )
      wf-type  case                                ( path$  c: type )
         dir-type  of                              ( path$ )
            delimiter left-parse-string            ( rem$' head$ )
            \ $find-name sets wf-inum and wf-type to the pathname component
            wd-inum  $find-name  if  2drop true exit  then  ( rem$ )
            wf-type dir-type =  if                 ( rem$ )
               wf-inum to wd-inum                  ( rem$ )
            then                                   ( rem$ )
         endof                                     ( rem$ )

         symlink-type  of                          ( rem$ )
            \ dir-link recursively calls $resolve-path, setting
            \ wf-inum and wf-type to the symlink's last component
            dir-link  if  2drop true exit  then    ( rem$ )
         endof                                     ( rem$ )
         ( default )                               ( rem$  c: type )

         \ The parent is an ordinary file or something else that
         \ can't be treated as a directory
         3drop true exit
      endcase                           ( rem$ )
   repeat                               ( rem$ )
   2drop false                          ( false )
;

' ($resolve-path) to $resolve-path

: $find-file  ( name$ -- error? )
   $resolve-path  if  true exit  then  ( )

   begin
      \ We now have the dirent for the file at the end of the string
      wf-type  case
         dir-type      of  wf-inum to wd-inum   false exit  endof  \ Directory
         regular-type  of                       false exit  endof  \ Regular file
         symlink-type  of  dir-link  if  true exit  then  endof    \ Link
         ( default )   \ Anything else (special file) is error
            drop true exit
      endcase
   again
;
\ --

: $chdir  ( path$ -- error? )
   $find-file  if  true exit  then
   wf-type dir-type <>  if  true exit  then
   wd-inum first-dirent
;

\ Returns true if inode# refers to a directory that is empty
\ Side effect - changes dirent context
: empty-dir?  ( -- empty-dir? )
   dir? 0= if  false exit  then

   file-handle first-dirent  if  false exit  then   \ Should be pointing to "." entry
   next-dirent  if  false exit  then   \ Should be point to ".." entry
   next-dirent  ( end? )               \ The rest should be empty
;

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
   file-handle set-inode
   file? 0= if  r> drop true exit  then	\ XXX handle symlinks
   
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
   dirent-vars 2>r 2>r
   $resolve-path  if  2r> 2r> restore-dirent  true exit  then
   wf-type symlink-type <>  if  2r> 2r> restore-dirent  true exit  then
 
   wf-inum symlink-resolution$ false
   2r> 2r> restore-dirent
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
