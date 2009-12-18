\ See license at end of file
purpose: inodes for Linux ext2fs file system

decimal

0 instance value inode#
: set-inode  ( inode# -- )  to inode#  ;

: ipb	( -- n )  bsize /inode /  ;
: itob  ( i# -- offset block# )
   1- ipg /mod		( rel-i# group )
   gpimin  swap		( block# rel-i# )
   ipb /mod		( gp-block# offset rel-blk# )
   blkstofrags
   rot +		( offset block# )
;

: inode  ( i# -- adr )   itob block swap /inode * +  ;
: ind   ( n -- )  inode  /inode dump  ;
: +i  ( n -- )  inode# inode +  ;
: file-attr   ( -- attributes )  0 +i short@  ;
: file-attr!  ( attributes -- )  0 +i short!  update  ;
: uid         ( -- uid )         2 +i short@  ;
: uid!        ( uid -- )         2 +i short!  update  ;
: filetype    ( -- type )  file-attr  h# f000 and  ;
: file-size   ( -- n )           4 +i int@  ;
: file-size!  ( n -- )           4 +i int!  update  ;
: atime       ( -- seconds )     8 +i int@  ;
: atime!      ( seconds -- )     8 +i int!  update  ;
: ctime       ( -- seconds )    12 +i int@  ;
: ctime!      ( seconds -- )    12 +i int!  update  ;
: mtime       ( -- seconds )    16 +i int@  ;
: mtime!      ( seconds -- )    16 +i int!  update  ;
: dtime       ( -- seconds )    20 +i int@  ;
: dtime!      ( seconds -- )    20 +i int!  update  ;
: gid         ( -- gid )        24 +i short@  ;
: gid!        ( gid -- )        24 +i short!  update  ;
: link-count  ( -- n )          26 +i short@  ;
: link-count! ( n -- )          26 +i short!  update  ;
: #blks-held  ( -- n )          28 +i int@  ;
: #blks-held! ( n -- )          28 +i int!  update  ;
: file-acl    ( -- n )         104 +i int@  ;

d# 12 constant #direct-blocks
: direct0     ( -- adr )   40 +i  ;
: indirect1   ( -- adr )   88 +i  ;
: indirect2   ( -- adr )   92 +i  ;
: indirect3   ( -- adr )   96 +i  ;

: dir?     ( -- flag )      filetype  h# 4000 =  ;
: file?    ( -- flag )      filetype  h# 8000 =  ;
: symlink? ( -- symlink? )  filetype  h# a000 =  ;

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
