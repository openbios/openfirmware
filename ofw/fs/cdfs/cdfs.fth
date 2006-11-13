\ See license at end of file
purpose: ISO 9660 (AKA High Sierra) (CD-ROM) file sytem reader

decimal

0 0 " support" property

headerless

\ defer open-disk  ( -- )
\ defer read-dev-bytes  ( adr len byte# -- error? )
\ defer close-disk  ( -- )

\ : le-w@  ( adr -- w )  dup c@     swap ca1+  c@    bwjoin  ;
\ : le-l@  ( adr -- w )  dup le-w@  swap wa1+ le-w@  wljoin  ;

0 instance value offset-low
0 instance value offset-high
0 instance value position
0 instance value dir-buf
0 instance value vol-desc

d# 12 constant max-name
max-name instance buffer: sought-name

2048 constant /sector

16 constant vol-desc-sector#  ( -- n )

: /block  ( -- n )   vol-desc 128 +  le-w@  ;
: root-dirent  ( -- adr )  vol-desc 156 +  ;

: release  ( -- )
   dir-buf   /block  free-mem
   vol-desc  /sector free-mem
;

: read-piece  ( adr len piece# /piece -- )
   um*   " seek" $call-parent     abort" Seek failed"       ( adr len )
   tuck  " read" $call-parent  <> abort" Disk read failed"
;

: get-vol-desc  ( -- )
   vol-desc /sector vol-desc-sector# /sector read-piece
;

\ **** Allocate memory for necessary data structures
: allocate-hsfs-buffers  ( -- )
   /sector alloc-mem is vol-desc
   get-vol-desc
   /block  alloc-mem is dir-buf
;

\ File handles

\ Remove any version number ( ;nnn ) from the name.
: -version  ( adr len -- adr len' )
   2dup
   bounds  ?do                        ( adr len )
      \ If a ; is located, set len to the length before the ;
      i c@  ascii ;  =
      if  drop i over - leave  then   ( adr len' )
   loop
;
\ Remove any trailing period from the name
: -period  ( adr len -- adr len' )
   dup  if
     2dup + 1- c@  ascii .  =  if  1-  then
   then
;

0 instance value file-desc
: select-file  ( adr -- )  is file-desc  ;
: +fd  ( n -- adr )  file-desc +  ;
\ The size and extent are stored in little-endian format at the given
\ address, and also in big-endian format at the address plus 4.
: file-extent  ( -- n )  2 +fd le-l@  ;
: file-size  ( -- n )  10 +fd le-l@  ;
: file-name  ( -- adr len )  33 +fd  32 +fd c@  -version  -period  ;
: dir?  ( -- flag )  25 +fd  c@  h# 02 and  0<>  ;

\ Directories

instance variable dir-block0	\ First block number in the directory file
instance variable dir-size	\ Number of bytes in the directory file

instance variable dir-block#	\ Next block number in the directory file
instance variable diroff	\ Offset into the current directory block
instance variable totoff	\ Total offset into the directory

\ Read the next directory block
: get-dirblk  ( -- )
   dir-buf  /block  dir-block# @ /block  read-piece
   0 diroff !
   1 dir-block# +!
;

\ **** Select the next directory entry
: another-file?  ( -- flag )
   totoff @  dir-size @  >=  if  false  else  file-desc c@ 0<>  then
;
: next-file  ( -- )
   file-desc c@  dup diroff +!  totoff +!
   totoff @  dir-size @  >=  if  exit  then
\   diroff @  /block >=  if  get-dirblk  then
   diroff @  /block >=  if
      get-dirblk
   else
      dir-buf  diroff @ +  c@  0=  if
         \ Unused bytes in the sector are included in the total,
         \ per ISO 9660 : 1988 clause 6.8.1.3
         /block diroff @ -  totoff +!
         get-dirblk
      then
   then
   dir-buf  diroff @  +  select-file
;

\ **** Select the first file in the current directory
: reset-dir  ( -- )
   dir-block0 @  dir-block# !
   get-dirblk
   0 totoff !
   dir-buf  diroff @  +  select-file
   next-file   next-file   \ Skip the "parent" and "self" entries
;

\ **** "cd" to the current file
: set-dir  ( -- )
   file-extent dir-block0 !
   file-size   dir-size   !
   reset-dir
;

\ **** Select the root directory
: canonical-name  ( adr len -- adr' len' )
   max-name min                 ( adr len' )
   tuck sought-name swap move   ( len' )
   sought-name  swap	        ( adr' len' )
   2dup upper       	        ( adr' len' )
   -period                      ( adr' len'' )
;
: froot  ( -- )  root-dirent select-file set-dir  ;

: lookup  ( adr len -- not-found? )
   canonical-name
   begin
      another-file?
   while
      2dup file-name $=  if  2drop false exit  then
      next-file
   repeat
   2drop true
;

\ Splits a string around a delimiter.  If the delimiter is found,
\ two strings are returned under true, otherwise one string under false.
: $split  ( adr len char -- remaining-adr,len  [ initial-adr,len ]  found?  )
   2 pick  2 pick  bounds  ?do
      dup i c@  =  if  i nip -1  then 
   loop                                    ( adr len   adr' -1  |  char )
   -1 =  if   ( adr len  adr' )
      swap >r            ( adr adr' )  ( r: len )
      2dup swap - swap   ( adr [adr'-adr] adr' )  ( r: len )
      1+  r>             ( adr [adr'-adr] adr'+1 len )
      2 pick - 1-        ( adr [adr'-adr]  adr'+1  len-[adr'-adr-1] )
      2swap true         ( rem-adr,len initial-adr,len true )
   else
      false
   then
;

: find-dir  ( adr len -- true | rem-adr,len false )
   dup 0=  if  2drop true exit  then
   over c@ ascii \  =  if  1 /string  then
   froot
   begin
      ascii \ $split  ( rem-adr,len  [ adr,len ] delim-found? )
   while
      lookup   if  2drop true exit  then
      dir? 0=  if  2drop true exit  then
      set-dir
   repeat   ( rem-adr,len )
   false
;
headers

: $chdir  ( adr len -- not-found? )
   find-dir  if
      true		\ File or directory not found
   else
      dup  if
         lookup		\ Path didn't end with backslash
         dir?  if  set-dir  then
      else
         2drop false	\ Path ended with backslash - open directory
      then
   then
;

external

: size  ( -- d )  file-size 0  ;

: seek  ( d -- error? )
   over size drop u>  if  2drop true exit  then
   over to position
   offset-low offset-high d+  " seek" $call-parent
;

: open  ( -- flag )
   allocate-hsfs-buffers
   my-args
   ['] $chdir catch  if  2drop  release false exit  then  ( err? )
   if  release false exit  then
\  dir?  if  ." Requested file is a directory" cr  release false exit  then
   file-extent /block um*  to offset-high  to offset-low
   0 0 seek  if  false exit  then
   true
;

: close  ( -- )  release  ;

: read  ( adr len -- actual-len )
   \ Don't read past end of file
   dup  position +  size drop -  0 max  -  ( adr len' )
   dup  position +  to position
   " read" $call-parent
;

: load  ( load-adr -- size )  size drop  read  ;
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
