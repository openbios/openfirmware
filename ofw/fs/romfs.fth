\ See license at end of file
purpose: romfs reader

0 instance value block-buf    \ Start address of working buffer

0 instance value inode-offset   \ Offset of current inode

0 instance value /page          \ Efficient size for reading
0 instance value pages/chip     \ total number of pages

0 instance value the-page#

\ Access a field within a romfs data structure
: i@  ( adr offset -- value )  la+ be-l@  ;

\ Data structures:
\ Super-block:
\  0: "-rom1fs-"
\  8: total-size
\  c: checksum of first 512 bytes
\ 10: volume name, zero-padded to multiple of 16 
\ 10+n: start of file headers
\
\ file header:
\  0: next_filehdr_offset|4B_file_type 
\  4: spec.info (hard_link:destination hdr, dir:first_file_hdr, block_or_char_dev:maj16/min16)
\  8: size of data
\  c: checksum of metadata
\ 10: filename, zero-padded to multiple of 16
\ 10+n: file data

\ File types:
\ 0*	hard link	link destination [file header]
\ 1*	directory	first file's header
\ 2*	regular file	unused, must be zero [MBZ]
\ 3*	symbolic link	unused, MBZ (file data is the link content)
\ 4	block device	16/16 bits major/minor number
\ 5	char device		    - " -
\ 6	socket		unused, MBZ
\ 7	fifo		unused, MBZ

: get-page  ( page# -- )
   dup  the-page#  =  if       ( page# )
      drop                     ( )
   else                        ( page# )
      block-buf over 1 " read-blocks" $call-parent    ( page# #read )
      1 <>  abort" romfs: Bad read"                   ( page# )
      to the-page#
   then                        ( )
;

: be-checksum  ( adr len -- sum )
   0 -rot  bounds ?do  i be-l@ +  /l +loop
;

0 instance value fs-max

\ Information that we need about the working file/directory
\ The working file changes at each level of a path search

\ 0 instance value wd-inum  \ Inumber of directory
\ 0 instance value wf-inum  \ Inumber of file or directory
0 instance value wf-type  \ File type - see list above

0 instance value root-header    \ Offset of first file header in root directory
0 instance value wd-header      \ Offset of first file header in working directory
0 instance value current-header \ Offset of current file header

: find-root-header  ( -- error? )
   d# 256  d# 31  do
      i block-buf + c@  0=  if
         i 1+ to root-header
         false unloop exit
      then
   d# 16 +loop
   true
;

: bad-super-block?  ( -- bad? )
   0 get-page                                         ( )
   block-buf  " -rom1fs-"  comp  if  true exit  then  ( )
   block-buf d# 512 be-checksum  0<>  if  true exit  then       ( )
   block-buf 4 + be-l@  to fs-max                     ( )
   find-root-header                                   ( bad? )
;

: get-bytes  ( byte# -- adr len )
   /page /mod                  ( offset page# )
   get-page                    ( offset )
   /page over -                ( offset remain )
   swap block-buf + swap       ( adr len )
;

: copy-data  ( dst-adr dst-len byte# -- )
   over bounds  ?do     ( dst-adr dst-len )
      i get-bytes       ( dst-adr dst-len src-adr src-len )
      2 pick min  >r    ( dst-adr dst-len src-adr r: copy-len )
      2 pick  r@ move   ( dst-adr dst-len r: copy-len )
      r@ /string        ( dst-adr' dst-len' r: copy-len )
   r> +loop             ( dst-adr dst-len )
   2drop
;

h# 10 constant /hdr-align
h# 80 constant /name-max
/name-max h# 10 + constant /hdr-max

create root-template  

/hdr-max instance buffer: hdr-buf
: next-header   ( -- byte# )    hdr-buf be-l@ h# f invert and  ;
: file-type     ( -- n )        hdr-buf be-l@ h# f and  ;
: file-info     ( -- n )        hdr-buf 4 + be-l@  ;
: file-size     ( -- n )        hdr-buf 8 + be-l@  ;
: hdr-checksum  ( -- n )        hdr-buf d# 12 + be-l@   ;
: file-name     ( -- adr len )  hdr-buf d# 16 + cscount  ;
base @ octal
\              hardlnk   dir   regular  symlink  blkdev   chardev  socket   fifo
create modes   00444 , 40444 , 100444 , 120444 , 060444 , 020444 , 140444 , 010444 ,
base !
: file-mode  ( -- n )
   modes file-type 7 and na+ @
   file-type 8 and  if  o# 111 or  then
;

0 instance value file-data

: get-file-header  ( byte# -- error? )
   dup d# -16 =  if   \ Synthesize a root header
      to current-header
      1 hdr-buf be-l!
      root-header hdr-buf 4 + be-l!
      false exit
   then

   dup 0=  if  drop true exit  then            ( byte# )
   dup fs-max >=  if  drop true exit  then     ( byte# )

   hdr-buf h# 20  2 pick  copy-data   ( byte# )
   h# 20                              ( byte# len )

   hdr-buf be-l@ h# ffffffff =  if  2drop true exit  then

   begin  dup hdr-buf + 1- c@  while               ( byte# len )
      dup  /hdr-max >=  abort" Bad file header"    ( byte# len )
      2dup + >r  dup hdr-buf +                     ( byte# len hdr-adr+len r: byte#+len)
      /hdr-align  r>  copy-data                    ( byte# len )
      /hdr-align +                                 ( byte# len' )
   repeat                                          ( byte# len )
   hdr-buf  over  be-checksum                      ( byte# len sum )
   0<> abort" Bad header checksum"                 ( byte# len )

   over to current-header
   +  to file-data
   false
;

: dma-alloc  ( len -- adr )  " dma-alloc" $call-parent  ;
: dma-free   ( len -- adr )  " dma-free" $call-parent  ;

: allocate-buffers  ( -- )
   " block-size" $call-parent to /page
   /page  dma-alloc     to block-buf
   -1 to the-page#
;

: release-buffers  ( -- )
   block-buf  /page  dma-free
;

char \ instance value delimiter

: set-root  ( -- )
   d# -16 to wd-header
   wd-header  get-file-header  drop
;

defer $resolve-path

: strip\  ( name$ -- name$' )
   dup  0<>  if                      ( name$ )
      over c@  delimiter  =  if      ( name$ )
         1 /string                   ( name$ )
         set-root                    ( name$ )
      then                           ( name$ )
   then                              ( name$ )
;

: $find-name  ( name$ -- error? )
   wd-header                          ( name# byte# )
   begin  get-file-header 0=  while   ( name$ )
      2dup file-name $=  if           ( name$ )
         2drop false exit
      then                            ( name$ )
      next-header                     ( name$ byte# )
   repeat                             ( name$ byte# )
   3drop   true
;

\ The work file is a symlink.  Resolve it to a new dirent
: dir-link  ( -- error? )
   file-size  /name-max >  if  true exit  then

   delimiter >r  [char] / to delimiter

   \ Allocate temporary space for the symlink value (new name)
   /name-max alloc-mem >r

   r@ file-size  file-data  copy-data  ( )
   r@ file-size  $resolve-path         ( error? )

   r> /name-max free-mem
   r> to delimiter
;
: hard-link  ( -- error? )  file-info get-file-header  ;

: ($resolve-path)  ( path$ -- error? )
   begin  strip\  dup  while                       ( path$  )
      file-type 7 and  case                        ( path$  c: type )
         1  of   \ Directory                       ( path$ )
            delimiter left-parse-string            ( rem$' head$ )
            file-info to wd-header                 ( rem$' head$ )
            $find-name  if  2drop true exit  then  ( rem$ )
         endof                                     ( rem$ )

         0  of   \ Hard link                       ( path$ )
            hard-link  if  2drop true exit  then   ( path$ )
         endof

         3  of   \ symlink                         ( rem$ )
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

decimal

headerless
0 value open-count
0 instance value seek-ptr

: clip-size  ( adr len -- len' adr len' )
   seek-ptr +   file-size min  seek-ptr -     ( adr len' )
   tuck
;
: update-ptr  ( len' -- len' )  dup seek-ptr +  to seek-ptr  ;

headers
external
: seek  ( d.offset -- status )
   0<>  over file-size u>  or  if  drop true  exit  then \ Seek offset too big
   to seek-ptr
   false
;

: ?release  ( flag -- flag )  dup 0=  if  release-buffers  then  ;

\ Starting at the current directory (wd-inum), process all the path components,
\ resolving symlinks until either a directory or an ordinary file is found.
\ If the resulting final component is a directory, leave wd-inum set to it.
\ If the resulting final component is a file, collect its data nodes so that
\ "seek", "read", and "load" will access its data.

: $find-file  ( name$ -- found? )
   $resolve-path  if  false exit  then  ( )

   begin
      \ We now have the dirent for the file at the end of the string
      file-type 7 and  case
         1      of  current-header to wd-header  true exit  endof  \ Directory
         2      of                               true exit  endof  \ Regular file
         3      of  dir-link  if  false exit  then          endof  \ SymLink
         0      of  hard-link if  false exit  then          endof  \ Hard link
         ( default )   \ Anything else (special file) is error
            drop false exit
      endcase
   again
;

: open  ( -- flag )
   \ This lets us open the node during compilation
   standalone?  0=  if  true exit  then

   0 to seek-ptr                                ( )
   allocate-buffers                             ( )

   bad-super-block?  if  release-buffers false exit  then

   my-args " <NoFile>"  $=  if  true exit  then

   set-root
   my-args  $find-file  ( okay? )
   ?release
;

: close  ( -- )  release-buffers  ;

: size  ( -- d.size )  file-size 0  ;

: read  ( adr len -- actual )
   clip-size 			     ( len' adr len' )
   file-data seek-ptr +  copy-data   ( len' )
   update-ptr
;

: load  ( adr -- len )
   file-size  file-data  copy-data
   file-size
;

hex
\ End of common code

: next-file-info  ( id -- false | id' s m h d m y len attributes name$ true )
   if  next-header  else  ( wd-header get-file-header ) file-info  then  ( byte# )
   get-file-header  if  false exit  then    ( )
   current-header
   0 0 0 0 0 0                 ( id' s m h  d m y  )
   file-size                   ( id' s m h  d m y  len  )
   file-mode                   ( id' s m h  d m y  len  mode )
   file-name true
;

: free-bytes  ( -- d.#bytes )  0 0  ;

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
