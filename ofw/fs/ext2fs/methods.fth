\ See license at end of file
purpose: Linux ext2fs file system package methods

decimal

0 instance value modified?

external

: free-bytes  ( -- d )  total-free-blocks bsize um*  ;

: $create   ( name$ -- error? )
   o# 100666 ($create)
;
\ XXX note: increment link count in parent
: $mkdir   ( name$ -- error? )
   o# 40777 ($create) if  true exit  then
   
   file-handle to inode#
   add-block				( block# )
   file-size h# 400 + file-size!
   dup direct0 int! update		( block# )
   block bsize erase update	\  flush
   wd-inum >r
   inode# first-dirent  if  r> drop  true exit  then
   " ."   d# 12		 inode#	set-dirent
   d# 12 diroff !
   " .."  bsize d# 12 -	 r> set-dirent
   false				( error? )
   diroff off
;

: $delete   ( name$ -- error? )
   $find-file  if  true exit  then		( )
   
   (delete-file)
;
: $delete!  $delete ;			\ XXX should these be different?

\ XXX note: decrement link count in parent
: $rmdir   ( name$ -- error? )	\ XXX UNTESTED
   $find-file  if  true exit  then		( )
   wf-type dir-type <>  if  true exit  then     ( )
   
   inode# >r					\ save parent directory
   file-handle set-inode  if  r> drop true exit  then
   dir? 0= if  r> drop true exit  then
   
   (delete-files)   file-handle if  r> drop true exit  then	\ still some left
   
   \ now empty, remove it.
   delete-blocks

   \ delete inode. clear or mark it?
   file-handle free-inode
   
   r> to inode#					\ restore parent directory
   
   \ delete directory entry
   del-dirent			( error? )
;

headers

\ EXT2FS file interface

: ext2fsdflen  ( 'fhandle -- d.size )  drop  file-size 0  ;

: ext2fsdfalign  ( d.byte# 'fh -- d.aligned )
   drop swap bsize 1- invert and  swap
;

: ext2fsfclose  ( 'fh -- )
   drop  bfbase @  bsize free-mem		\ Registered with initbuf
   modified? if
      false to modified?
      time&date >unix-seconds file-handle inode 4 la+ int! update
   then
;

: ext2fsdfseek  ( d.byte# 'fh -- )
   drop
   bsize um/mod nip	( target-blk# )
   to lblk#
;

: ext2fsfread   ( addr count 'fh -- #read )
   drop 
   dup bsize > abort" Bad size for ext2fsfread"
   file-size  lblk# bsize *  -	( addr count rem )
   umin swap			( actual addr )
   lblk# read-file-block	( actual )
   dup  0>  if  lblk#++  then	( actual )
;

: ext2fsfwrite   ( addr count 'fh -- #written )
   drop 
   dup bsize > abort" Bad size for ext2fsfwrite"	( addr count )
   tuck  lblk# bsize * + dup file-size u>  if		( actual addr new )
      file-size!				\ changing byte count, NOT #blks
   else
      drop
   then							( actual addr )
   lblk# write-file-block				( actual )
   
   \ XXX I am skeptical about this line.
   dup  0>  if  lblk#++  then				( actual )
   true to modified?
\   flush					\ XXX kludge for tests
;

: $ext2fsopen  ( adr len mode -- false | fid fmode size align close seek write read true )
   -rot $find-file  if  drop false exit  then	        ( mode )
   wf-type regular-type <>  if  drop false exit  then   ( mode )

   file-handle set-inode                                ( mode )
   false to modified?
   
   >r
   bsize alloc-mem bsize initbuf
   file-handle  r@  ['] ext2fsdflen ['] ext2fsdfalign ['] ext2fsfclose ['] ext2fsdfseek 
   r@ read =  unknown-extensions? or if  ['] nullwrite  else  ['] ext2fsfwrite  then
   r> write =  if  ['] nullread   else  ['] ext2fsfread   then
   true
;


false instance value file-open?
/fd instance buffer: ext2fs-fd

external

: open  ( -- okay? )
   allocate-buffers  if  false exit  then

   my-args " <NoFile>"  $=  if  true exit  then

   \ Start out in the root directory
   set-root

   my-args  ascii \ split-after                 ( file$ path$ )
   $chdir  if  2drop release-buffers false  exit  then  ( file$ )

   \ Filename ends in "\"; select the directory and exit with success
   dup  0=  if  2drop  true exit  then          ( file$ )

   file @ >r  ext2fs-fd file !                     ( file$ )
   2dup r/w $ext2fsopen  0=  if
      2dup r/o $ext2fsopen  0=  if
         release-buffers 2drop  false    r> file !  exit
      then
   then            ( file$ file-ops ... )

   setupfd
   2drop
   false to gd-modified?
   true to file-open?
   true
   r> file !
;

: close  ( -- )
   file-open?  if
      ext2fs-fd ['] fclose catch  ?dup  if  .error drop  then
      false to file-open?
   then
   update-gds
   flush
   release-buffers
;
: read  ( adr len -- actual )
   ext2fs-fd  ['] fgets catch  if  3drop 0  then
;
: write  ( adr len -- actual )
   tuck  ext2fs-fd  ['] fputs catch  if  4drop -1  then
;
: seek   ( offset.low offset.high -- error? )
   ext2fs-fd  ['] dfseek catch  if  2drop true  else  false  then
;
: size  ( -- d )  file-size  0  ;
: load  ( adr -- size )  file-size  read  ;
\ : files  ( -- )  begin   file-name type cr  next-dirent until  ;

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
