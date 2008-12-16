purpose: UFS file system support package
\ See license at end of file

0 0  " support" property

decimal

\
\	UFS low-level block routines
\

512 constant ublock
2048 constant /super-block
8 constant ndaddr
16 constant super-block#  ( -- n )
h# 11954 constant fs-magic

0 instance value temp-block
0 instance value dir-block
0 instance value indirect-block
0 instance value inode
0 instance value dir-inode
0 instance value super-block
0 instance value linkpath

defer short@  ( adr -- w )  ' be-w@ to short@
defer int@    ( adr -- l )  ' be-l@ to int@
: le-quad@  ( adr -- l )  int@  ;
: be-quad@  ( adr -- l )  la1+ int@  ;
defer quad@   ( adr -- l )  ' be-quad@ to quad@

\ Unfortunately, 4.4BSD-derived systems use a char field for the
\ name length in the directory entry structure, while most other
\ systems use a short.
: 1+c@  ( adr -- n )  1+ c@  ;
defer namlen@ ( adr -- n )  ' short@ to namlen@

: +sb  ( index -- value )  super-block  swap la+ int@  ;
: iblkno    ( -- n )   4 +sb  ;
: cgoffset  ( -- n )   6 +sb  ;
: cgmask    ( -- n )   7 +sb  ;
: bsize     ( -- n )  12 +sb  ;
: fragshift ( -- n )  24 +sb  ;
: fsbtodbc  ( -- n )  25 +sb  ;
: inopb     ( -- n )  30 +sb  ;
: ipg       ( -- n )  46 +sb  ;
: fpg       ( -- n )  47 +sb  ;
: inodefmt  ( -- n ) 331 +sb  ; \ Reserved (=0) in SunOS, =2 in BSD
: magic     ( -- n ) 343 +sb  ;

: /frag  ( -- fragsize )  bsize fragshift >> ;

: read-ublocks  ( adr len dev-block# -- error? )
   ublock * 0 " seek" $call-parent ?dup  if  exit  then
   ( adr len )  tuck " read" $call-parent <>
;

: get-super-block  ( -- error? )
   super-block /super-block super-block# read-ublocks ?dup  if  exit  then

   ['] le-l@ to int@  ['] le-w@ to short@  ['] le-quad@ to quad@
   magic fs-magic =  if  false exit  then

   ['] be-l@ to int@  ['] be-w@ to short@  ['] be-quad@ to quad@
   magic fs-magic <>
;

: cgstart   ( cg -- block# )
   dup cgmask not and  cgoffset *   swap fpg *  +
;
: cgimin    ( cg -- block# )  cgstart  iblkno +  ;

: blkstofrags  ( #blocks -- #frags )  fragshift <<  ;

: fsbtodb  ( fs-blk# -- dev-blk# )  fsbtodbc <<  ;

: read-fs-blocks  ( adr len fs-blk# -- error? )  fsbtodb read-ublocks  ;
   
\
\	UFS inode routines
\

h# 80 constant /inode

instance variable blkptr
instance variable blklim
instance variable indirptr
0 instance value lblk#

: itoo  ( i# -- offset )  inopb mod  ;
: itog  ( i# -- group )  ipg /  ;
: itod  ( i# -- block# )
   dup itog cgimin  swap ipg mod  inopb /  blkstofrags  +
;

: +i  ( n -- )  inode +  ;
: file-attr  ( -- attributes )  0 +i  short@  ;
: dir?  ( -- flag )  file-attr  h# 4000 and  0<>  ;  \ ****
: file-sec  ( -- seconds )  24 +i int@  ;
: file-size  ( -- n )  8 +i quad@  ;   \ ****
: direct0    ( -- adr )  40 +i  ;
: indirect0  ( -- adr )  88 +i  ;
: #blks-held  ( -- n )  104 +i int@  ;

: symlink? ( -- symlink? )  0 +i  short@  o# 0120000 tuck and =  ;

\ **** Select the indicated file for subsequent accesses
: rewind  ( -- )
   direct0 blkptr !   indirect0 blklim !  indirect0 indirptr !
   0 to lblk#
;

: l@++  ( ptr -- value )  dup @ int@  /l rot +!  ;

\ **** Locate the next block within the current file
: next-block#  ( -- n )
   blkptr @  blklim @ =  if
      indirect-block bsize indirptr l@++ 
      read-fs-blocks drop ( XXX - what about the error? )
      indirect-block  blkptr !   indirect-block bsize +  blklim !
   then
   lblk# 1+ to lblk#
   blkptr l@++  ( blk# )
;

: get-dirblk  ( -- error? )  dir-block bsize  next-block#  read-fs-blocks  ;

\
\	UFS directory routines
\

variable diroff
variable totoff
variable current-dir

\ **** Return the address of the current directory entry
: dirent  ( -- adr )  dir-block diroff @ +  ;

\ **** Select the next directory entry
: next-dirent  ( -- end? )
   dirent  la1+ short@  dup diroff +!  totoff +!
   totoff @  file-size >=  if  true exit  then
   diroff @  bsize =  if
      get-dirblk ?dup  if  exit  then
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
   swap namlen@  h# ff and   ( adr len )
;

\
\	UFS high-level routines
\
\       After this point, the code should be independent of the disk format!

: lookup  ( adr len -- not-found? )
   begin
      2dup file-name  $=  if  2drop false exit  then
      next-dirent
   until
   2drop true
;

: >OFW-path  ( adr len -- )
   \ replace / with \
   bounds do i c@ ascii / =  if  ascii \ i c!  then loop
;
: (select-file)  ( i# -- error? )
   dup temp-block bsize  rot  itod            ( i# adr len fs-block# )
   read-fs-blocks  if  drop true exit  then   ( i# )
   itoo /inode * temp-block +   inode /inode move
   false
;
defer chdir	' noop is chdir
defer (init-dir)  ' noop is (init-dir)
: select-file  ( i# -- error? )
   (select-file)  ?dup  if  exit  then
   symlink?  if
      #blks-held 0=  if		\ short symbolic link path
         direct0 linkpath over cstrlen 1+ move
      else			\ long symbolic link path
	 linkpath bsize direct0 @
	 read-fs-blocks  ?dup  if  exit  then
      then
      linkpath dup cstrlen 2dup >OFW-path ascii \  split-after
      ?dup  if
         chdir  if  2drop true exit  then
      else
         drop current-dir @ (init-dir)  ?dup  if  exit  then
      then
      dup 0=  if  2drop false exit  then
      lookup ?dup  if  exit  then
      file-handle recurse
   else
      rewind  false
   then
;

\ **** Select the directory file
: init-dir  ( i# -- error? )
   dup current-dir ! 
   select-file ?dup  if  exit  then
   get-dirblk ?dup  if  exit  then
   0 diroff !  0 totoff !
   false
;
' init-dir to (init-dir)

\ **** Select the root directory
: froot  ( -- error? )  2 init-dir  ;

: $chdir  ( adr len -- error? )		\ Fail if path is file, not dir
   ?dup 0=  if  drop true exit  then
   froot  if  2drop true exit  then
   begin			( path-$ )
      over c@ ascii \  =  if  1 /string  then
      ascii \ split-before	( \tail-$ head-$ )
   dup while			
      lookup  if  2drop true exit  then
      dir? 0=  if  2drop true exit  then
      file-handle init-dir  if  2drop true exit  then
   repeat   ( tail-$ head-$ )
   2drop 2drop false
;
' $chdir to chdir

\
\	UFS installation routines
\


\ **** Allocate memory for necessary data structures
: allocate-ufs-buffers  ( -- error? )
   /super-block alloc-mem is super-block
   get-super-block dup  if
      super-block /super-block free-mem exit
   then
   inodefmt 2 =  if  ['] 1+c@  else  ['] short@  then  to namlen@
   bsize  alloc-mem is temp-block
   bsize  alloc-mem is dir-block
   bsize  alloc-mem is indirect-block
   bsize  alloc-mem is linkpath
   /inode alloc-mem is inode
   /inode alloc-mem is dir-inode
;

: release  ( -- )
   inode           /inode         free-mem
   dir-inode	   /inode 	  free-mem
   indirect-block  bsize          free-mem
   temp-block      bsize          free-mem
   dir-block	   bsize	  free-mem
   linkpath        bsize          free-mem
   super-block     /super-block   free-mem
;

false instance value file-open?
/fd instance buffer: ufs-fd

\ UFS DIR routines
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
: >dir-inode  ( -- )  inode dir-inode /inode move  ;
: dir-inode>  ( -- )  dir-inode inode /inode move  ;
: file-info  ( id -- false | id' s m h d m y len attributes name$ true )
   file-handle >dir-inode (select-file)  if  ( id )
      drop false                             ( false )
   else                                      ( id )
      1+  file-sec sec>time&date  file-size  file-attr  file-name  ( id' .. )
      true                                   ( id' .. name$ true )
   then
   dir-inode>
;
: next-file-info  ( id -- false | id' s m h d m y len attributes name$ true )
   dup  if  
      next-dirent  if  drop false  else  file-info  then
   else
      file-info
   then
;

\ UFS file interface

: ufsdflen  ( 'fhandle -- d.size )  drop  file-size 0  ;

: ufsdfalign  ( d.byte# 'fh -- d.aligned )
   drop swap bsize 1- invert and  swap
;

: ufsfclose  ( 'fh -- )
   drop  bfbase @  bsize free-mem		\ Registered with initbuf
;

: ufsdfseek  ( d.byte# 'fh -- )
   drop
   bsize um/mod nip ( target-blk# )
   dup lblk# <  if  rewind  then
   begin  dup lblk# <>  while  next-block# drop  repeat
   drop
;

: ufsfread   ( addr count 'fh -- #read )
   drop 
   file-size  lblk# bsize *  -		( addr count rem )
   over min -rot			( actual addr count )
   next-block# read-fs-blocks
   abort" ufsfread failed"
;

: $ufsopen  ( adr len mode -- fid fmode size align close seek write read )
   >r  lookup  ( error? )  if
      false
   else
      file-handle select-file  if
         false
      else
         bsize alloc-mem bsize initbuf
         file-handle r@
	 ['] ufsdflen ['] ufsdfalign ['] ufsfclose ['] ufsdfseek ['] nullwrite
         r@ write =  if  ['] nullread   else  ['] ufsfread  then
         true
      then
   then
   r> drop
;

external

: open  ( -- okay? )
   allocate-ufs-buffers  if  false exit  then

   my-args " <NoFile>"  $=  if  true exit  then

   my-args  ascii \ split-after                 ( file$ path$ )
   $chdir  if  2drop release false  exit  then  ( file$ )

   \ Filename ends in "\"; select the directory and exit with success
   dup  0=  if  2drop  true exit  then          ( file$ )

   file @ >r  ufs-fd file !                     ( file$ )

   2dup r/w $ufsopen  0=  if
      2dup r/o $ufsopen  0=  if
         release 2drop  false    r> file !  exit
      then
   then            ( file$ file-ops ... )

   setupfd
   2drop
   true to file-open?
   true
   r> file !
;

: close  ( -- )
   file-open?  if
      ufs-fd ['] fclose catch  ?dup  if  .error drop  then
   then
   release
;
: read  ( adr len -- actual )
   ufs-fd  ['] fgets catch  if  3drop 0  then
;
: write  ( adr len -- actual )
   tuck  ufs-fd  ['] fputs catch  if  2drop 2drop -1  then
;
: seek   ( offset.low offset.high -- error? )
   ufs-fd  ['] dfseek catch  if  2drop true  else  false  then
;
: size  ( -- d )  file-size  0  ;
: load  ( adr -- size )  file-size  read  ;
: files  ( -- )  begin   file-name type cr  next-dirent until  ;

hex

\ LICENSE_BEGIN
\ Copyright (c) 1994 FirmWorks
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
