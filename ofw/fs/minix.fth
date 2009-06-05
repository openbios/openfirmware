purpose: Minix file system support package
\ See license at end of file

\ ??? rawfs.c potential problems:
\  a) rawfs.c doesn't appear to handle holes that appear in the direct
\     block list, but it does handle holes in indirect blocks.
\  b) Indirect blocks waste space because they are "addressed" by zone
\     number, but only contain a block of data
\  c) The interior partion map start blocks are absolute, not relative
\     to the container partition.

0 0  " support" property

decimal

h# 40 constant /inode  \ Support only the new Minix FS
h# 40 constant /dirent \ Support only the new Minix FS
\ h# 3c constant /name   \ Support only the new Minix FS

/inode instance buffer: dir-inode

0 instance value dir-block
0 instance value indirect-block
0 instance value linkpath

h# 20 constant /super-block
/super-block instance buffer: super-block

0 instance value inode-blk0    \ Block offset for inodes
0 instance value /block        \ Bytes/block for the inodes and maps
\ 0 instance value datazone0     \ Block offset for data zones (clusters)
0 instance value /zone         \ Zone (cluster) size
0 instance value inodes/block  \ Number of inodes stored in a block
0 instance value zone#s/indir  \ Number of zone numbers in an indirect block

\ rawfs.c from the Minix3 code assumes that the size of an indirect block
\ is /block instead of /zone, despite addressing them with zone numbers.
alias /indirect /block         \ Size of an indirect block

 0 instance value iblk-buf        \ Inode block buffer
-1 instance value have-iblk#      \ Inode block "cache tag"

 0 instance value indirect-buf    \ Indirect block buffer
-1 instance value have-indirect#  \ Indirect block "cache tag"

h# 40 constant /partition-map
/partition-map instance buffer: partition-map
0 instance value part-offset-hi
0 instance value part-offset-lo

: pseek  ( d.offset -- )
   part-offset-lo part-offset-hi d+  " seek" $call-parent  abort" Bad seek"
;
: pread  ( adr len -- error? )  tuck " read" $call-parent <>  ;

\ Handling nested partition maps fully is too much trouble for now,
\ so we just look for the bootable partition inside the inner map.
: set-partition-offset  ( -- error? )
   \ 0 to partition-offset  \ Unnecessary; it's initialized to 0
   h# 1be.  pseek
   partition-map  /partition-map pread  if  true exit  then
   partition-map  /partition-map  bounds  ?do
      i c@ h# 80 and  if                 \ Bootable?
         \ The "1-" below is somewhat dubious.  The problem is that
         \ the interior partition map uses absolute sector numbers,
         \ instead of being relative to the start sector of the
         \ container partition.
         i 8 + l@ 1- d# 512 um* to part-offset-hi  to part-offset-lo
         false unloop exit
      then
   h# 10 +loop
   true
;

: get-inode  ( i# -- adr )
   inodes/block /mod                      ( index iblk# )
   dup  have-iblk# =  if                  ( index iblk# )
      drop                                ( index )
   else                                   ( index iblk# )
      inode-blk0 +                        ( index block# )
      /block um* pseek                    ( index )
      iblk-buf  /block pread drop         ( index )
   then                                   ( index )
   iblk-buf  swap /inode * +              ( adr )
;

: sbw@  ( offset -- w )  super-block + w@  ;
: max-size  ( -- d )  h# 14 super-block + l@ /zone um*  ;

: get-super-block  ( -- error? )
   set-partition-offset  if  true exit  then
   h# 400. pseek     \ The offset is relative to the interior partition start
   super-block /super-block pread  if  true exit  then
   h# 18 sbw@  h# 4d5a <>  if  true exit  then

   6 sbw@  8 sbw@ +  2+  to inode-blk0
\   h#  a sbw@ to datazone0
   h# 1c sbw@ to /block        ( )      \ 1c
   /block /inode / to inodes/block
   /block  h# c sbw@  lshift  to /zone  \ c.w is log_zone_size

   /indirect /l / to zone#s/indir
   false
;

: read-zone  ( adr zone# -- error? )  /zone um* pseek  /zone pread  ;
   
/inode instance buffer: inode
: +i  ( n -- )  inode +  ;
: file-attr  ( -- attributes )  0 +i  w@  ;
: dir?  ( -- flag )  file-attr  h# 4000 and  0<>  ;
: symlink? ( -- symlink? )  file-attr  o# 0120000 tuck and =  ;
: file-sec  ( -- seconds )  d# 16 +i l@  ;
: file-size  ( -- n )  8 +i l@  ;

: zone-list@  ( index -- zone# )  /l*  h# 18 +  +i  l@  ;

: @zone  ( index adr -- zone# )  swap la+ l@  ;

: indirect  ( index zone# -- zone#' )
   indirect-buf swap read-zone abort" Indirect zone read error"  ( index )
   indirect-buf @zone  ( zone# )
;

: lblk>zone  ( lblk# -- blk# )
   dup 7 <  if  zone-list@ exit  then   \ Direct - zone# in inode
   7 -                                          ( lblk#' )

   zone#s/indir /mod                            ( index indirect# )

   dup have-indirect# =  if                     ( index indirect# )
      drop  indirect-buf @zone  exit
   then                                         ( index indirect# )

   dup to have-indirect#                        ( index indirect# )

   zone#s/indir /mod                            ( index lo hi )

   ?dup  if                                     ( index lo hi )
      9 zone-list@  indirect indirect indirect  ( index blk )
      exit
   then                                         ( index lo )

   ?dup  if                                     ( index lo )
      8 zone-list@  indirect indirect           ( blk# )
      exit
   then                                         ( index )

   7 zone-list@  indirect                       ( blk )
;

0 instance value lblk#

\ Locate the next block within the current file
: next-zone#  ( -- n )
   lblk# lblk>zone
   lblk# 1+ to lblk#
;

: get-dirblk  ( -- error? )  dir-block next-zone#  read-zone  ;

\ Directory routines

variable diroff
variable totoff
variable current-dir

\ Return the address of the current directory entry
: dirent  ( -- adr )  dir-block diroff @ +  ;

\ Select the next directory entry
: next-dirent  ( -- end? )
   /dirent  dup diroff +!  totoff +!
   totoff @  file-size >=  if  true exit  then
   diroff @  /zone =  if
      get-dirblk ?dup  if  exit  then
      diroff off
   then
   false
;

\ From directory, get handle of the file or subdir that it references
: file-handle  ( -- i# )  dirent l@ 1-  ;

\ From directory, get name of file
: file-name  ( -- adr len )
   \ XXX could fail if the name is not null-terminated
   dirent la1+  cscount   ( adr len )
;

\ High-level routines

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
   get-inode                            ( adr )
   inode /inode move                    ( )
   false
;

defer chdir	' noop to chdir
defer (init-dir)  ' noop to (init-dir)
: select-file  ( i# -- error? )
   (select-file)  ?dup  if  exit  then
   symlink?  if
      linkpath 0 lblk>zone read-zone  ?dup  if  exit  then
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
      0 to lblk#  false
   then
;

\ Select the directory file
: init-dir  ( i# -- error? )
   dup current-dir ! 
   select-file ?dup  if  exit  then
   get-dirblk ?dup  if  exit  then
   0 diroff !  0 totoff !
   false
;
' init-dir to (init-dir)

: $chdir  ( adr len -- error? )		\ Fail if path is file, not dir
   ?dup 0=  if  drop true exit  then
   0 init-dir  if  2drop true exit  then  \ Root directory
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

\ Allocate memory for necessary data structures
: allocate-buffers  ( -- error? )
   /block     alloc-mem  to iblk-buf
   /zone      alloc-mem  to dir-block
   /zone      alloc-mem  to linkpath
   /indirect  alloc-mem  to indirect-block
;

: release  ( -- )
   iblk-buf        /block     free-mem
   dir-block	   /zone      free-mem
   linkpath        /zone      free-mem
   indirect-block  /indirect  free-mem
;

false instance value file-open?
/fd instance buffer: the-fd

\ DIR routines
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
   inode dir-inode /inode move               ( id )  \ Save directory inode
   file-handle (select-file)  if             ( id )
      drop false                             ( false )
   else                                      ( id )
      1+  file-sec sec>time&date  file-size  file-attr  file-name  ( id' .. )
      true                                   ( id' .. name$ true )
   then
   dir-inode inode /inode move               \ restore directory inode
;
: next-file-info  ( id -- false | id' s m h d m y len attributes name$ true )
   dup  if  
      next-dirent  if  drop false  else  file-info  then
   else
      file-info
   then
;

\ File interface

: fsdflen  ( 'fhandle -- d.size )  drop  file-size 0  ;

: fsdfalign  ( d.byte# 'fh -- d.aligned )
   drop swap /zone 1- invert and  swap
;

: fsfclose  ( 'fh -- )
   drop  bfbase @  /zone free-mem   \ $fsopen allocated this block
;

: fsdfseek  ( d.byte# 'fh -- )
   drop                ( d.byte# )
   /zone um/mod        ( offset target-blk# )
   to lblk#            ( offset )
   drop                ( )
;

: fsfread   ( adr len 'fh -- #read )
   \ fh is implicit (it is in our instance context) and len will be /zone
   2drop                                                ( adr )
   file-size  lblk# /zone *  u<  if  drop 0 exit  then	( adr )
   next-zone# read-zone abort" fsfread failed"          ( )
   file-size  lblk# /zone *  -  dup  0<  if             ( shortfall )
      /zone +                                           ( #read )
   else                                                 ( shortfall )
      drop /zone                                        ( #read )
   then                                                 ( #read )
;

: $fsopen  ( adr len mode -- fid fmode size align close seek write read )
   >r  lookup  ( error? )  if
      false
   else
      file-handle select-file  if
         false
      else
         /zone alloc-mem /zone initbuf
         file-handle r@
	 ['] fsdflen ['] fsdfalign ['] fsfclose ['] fsdfseek ['] nullwrite
         r@ write =  if  ['] nullread   else  ['] fsfread  then
         true
      then
   then
   r> drop
;

external

: open  ( -- okay? )
   get-super-block  if  false exit  then
   allocate-buffers

   my-args " <NoFile>"  $=  if  true exit  then

   my-args  ascii \ split-after                 ( file$ path$ )
   $chdir  if  2drop release false  exit  then  ( file$ )

   \ Filename ends in "\"; select the directory and exit with success
   dup  0=  if  2drop  true exit  then          ( file$ )

   file @ >r  the-fd file !                     ( file$ )

   2dup r/w $fsopen  0=  if
      2dup r/o $fsopen  0=  if
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
      the-fd ['] fclose catch  ?dup  if  .error drop  then
   then
   release
;
: read  ( adr len -- actual )
   the-fd  ['] fgets catch  if  3drop 0  then
;
: write  ( adr len -- actual )
   tuck  the-fd  ['] fputs catch  if  2drop 2drop -1  then
;
: seek   ( offset.low offset.high -- error? )
   the-fd  ['] dfseek catch  if  2drop true  else  false  then
;
: size  ( -- d )  file-size  0  ;
: load  ( adr -- size )  file-size  read  ;
: files  ( -- )  begin   file-name type cr  next-dirent until  ;

hex

\ LICENSE_BEGIN
\ Copyright (c) 2007 FirmWorks
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
