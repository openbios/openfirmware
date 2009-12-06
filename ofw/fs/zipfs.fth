\ See license at end of file
purpose: Support package for "ZIP file system"

headerless
0 instance value base-adr
0 instance value image-size
0 instance value seek-ptr
external
\ Expose for the OLPC security scheme
0 instance value offset
headerless

: clip-size  ( adr len -- adr len' )
   seek-ptr +   image-size umin  seek-ptr -
;
: update-ptr  ( len' -- len' )  dup seek-ptr +  to seek-ptr  ;

d# 255 instance buffer: pathbuf
: fix-delims  ( adr len -- adr' len' )
   pathbuf pack count 2dup
   bounds  ?do  ( adr len )
      i c@  dup [char] | =  swap [char] \ =  or  if  [char] / i c!  then
   loop
;

external
: seek  ( d.offset -- status )
   0<>  over image-size u>  or  if  drop true  exit  then \ Seek offset too big
   to seek-ptr
   seek-ptr offset +  0  " seek" $call-parent
;
: size  ( -- d.size )  image-size 0  ;
: read  ( adr len -- actual )
   clip-size                     ( adr len' )
   " read" $call-parent          ( len' )
   update-ptr                    ( len' )
;

headers
4 buffer: zip-magic

d# 64 instance buffer: zip-buffer  \ the largest zip header is 52 bytes

d# 512 instance buffer: zip-name
0 instance value name-len
: zip-name$  ( -- adr len )  zip-name name-len  ;

d# 512 instance buffer: saved-name

d# 512 instance buffer: path-prefix
0 instance value prefix-len
: prefix$  ( -- adr len )  path-prefix prefix-len  ;

: zfield  \ name  ( offset -- offset' )
   create  over ,  +  does> @ zip-buffer +
;

struct
   /w zfield ch-madeby	\ Creator ID (UNIX, DOS, etc)
   /w zfield ch-extract	\ Version needed for extraction
   /w zfield ch-bits	\ General purpose flags
   /w zfield ch-compr	\ Compression type
   /w zfield ch-time	\ Modification time
   /w zfield ch-date	\ Modification date
   /l zfield ch-crc	\ CRC-32
   /l zfield ch-size	\ Compressed size
   /l zfield ch-len	\ Uncompressed size
   /w zfield ch-namelen	\ Name length
   /w zfield ch-extlen	\ Extra length
   /w zfield ch-comlen	\ Comment length
   /w zfield ch-diskno	\ Disk number
   /w zfield ch-iattrs	\ Internal attributes (e.g. text vs. binary)
   /l zfield ch-eattrs	\ External attributes (OS-specific permissions)
   /l zfield ch-hdroff	\ Offset to corresponding header in files section
constant /central	\ Size of central header

struct
   /w zfield eh-diskno	\ This disk number
   /w zfield eh-chdisk	\ Disk number of central header
   /w zfield eh-cdnum	\ Number of central directory entries on this disk
   /w zfield eh-cdtot	\ Total number of central directory entries
   /l zfield eh-cdsize	\ Central directory size
   /l zfield eh-cdoff	\ Offset to central directory
   /w zfield eh-comlen	\ Comment length
constant /end-header	\ Size of central header

struct
   /w zfield fh-version
   /w zfield fh-flag
   /w zfield fh-how
   /w zfield fh-time
   /w zfield fh-date
   /l zfield fh-crc
   /l zfield fh-size	\ Compressed size
   /l zfield fh-len	\ Uncompressed size
   /w zfield fh-namelen
   /w zfield fh-extlen
constant /local-header
   
: ?crc  ( adr len -- )
   $crc                 ( crc )
   fh-crc le-l@ <>  if  ." Zip file CRC mismatch" cr  abort  then
;

\ ID of the header that's currently in the buffer
-1 instance value header-id

external
: load  ( adr -- len )
   0. seek drop
   dup image-size read    ( adr len )
   tuck  ?crc             ( len )
;

headers
: read-magic  ( id -- adr )
   -1 to header-id                     ( id )
   u>d seek drop                       ( id )
   zip-magic  4 read drop              ( )
   zip-magic                           ( adr )
;
: file-header?  ( id -- id flag )  dup read-magic  " PK"(0304)" comp 0=  ;
: read-file-header  ( -- )
   zip-buffer  /local-header  read drop    ( id )
   fh-namelen le-w@ to name-len            ( id )
   zip-name$ read drop                     ( id )
;
: get-file-header?  ( id -- id flag )
   dup  header-id =  if  true exit  then   ( id )
   file-header?  if			   ( id )
      dup to header-id                     ( id )
      read-file-header                     ( id )
      true                                 ( id true )
   else                                    ( id )
      false                                ( false )
   then                                    ( id )
;

: dir-header?   ( id -- id flag )  dup read-magic  " PK"(0102)" comp 0=  ;
: read-dir-header  ( -- )
   zip-buffer  /central  read drop   ( id )
   ch-namelen le-w@ to name-len      ( id )
   zip-name$ read drop               ( id )
;

: get-dir-header?  ( id -- false | id true )
   dup  header-id =  if  true exit  then   ( id )
   dir-header?  if			   ( id )
      dup to header-id                     ( id )
      read-dir-header                      ( id )
      true                                 ( id true )
   else                                    ( id )
      drop  false                          ( false )
   then                                    ( false | id true )
;
: end-header?   ( id -- flag )  read-magic  " PK"(0506)" comp 0=  ;
: read-end-header  ( -- )   zip-buffer  /end-header  read drop  ;

: first-file-header  ( -- false | id true )
   d# 2000  0  do
      i get-file-header?  if  true unloop exit  else  drop  then  ( )
   loop
   0
;

: +local  ( id -- id' )
   4 + /local-header +   ( id+ )   \ Skip fixed length stuff
   fh-namelen le-w@ +    ( id+ )   \ Skip the old name
   fh-extlen  le-w@ +    ( id' )   \ Skip the old extra field
;
: +file  ( id -- id' )  +local  fh-size le-l@ +  ;

: +dirent  ( id -- id' )
   4 +  /central +                  ( id' )  \ Skip fixed-length stuff
   ch-namelen le-w@ +               ( id' )  \ Skip file name
   ch-extlen  le-w@ +               ( id' )  \ Skip extras
;
: +end-header
   \ Now ID is the offset of the END header signature, which is in the
   \ buffer along with that header
   4 +  /end-header +               ( id' )
   eh-comlen le-w@ +                ( id' )  \ Skip comment
;

: first-dir-header  ( -- false | id true )
   first-file-header  0=  if  false exit  then

   begin  file-header?  while    ( id )
      read-file-header +file     ( id' )
   repeat                        ( id )

   get-dir-header?               ( false | id true )
;

: +central+end  ( id -- id' )
   begin  dir-header?  while           ( id )
      read-dir-header  +dirent         ( id' )
   repeat                              ( id )

   end-header?  if                     ( id )
      read-end-header  +end-header     ( id' )
   then
;

: another-file?  ( id -- false  | id' true )
   ?dup  if                    ( id )    \ Not the first call
      get-dir-header?  0=  if  ( )
         false exit
      then                     ( id )    \ Get the old header into the buffer
      +dirent                  ( id' )   \ Skip the old header
      get-dir-header?          ( false | id true )  \ Get the new header
   else                        ( )
      first-dir-header         ( false | id' true )
   then                        ( false | id' true )
;

headerless

\ Extracted from pkg/fatfs/dosdate.fth
: >hms  ( dos-packed-time -- secs mins hours )
   dup h#   1f and     2*   swap  ( secs packed )
   dup h# 07e0 and d#  5 >> swap  ( secs mins packed )
       h# f800 and d# 11 >>       ( secs mins hours )
;  
: >dmy  ( dos-packed-date -- day month year )
   dup h#   1f and       swap   ( day packed )
   dup h# 01e0 and  5 >> swap   ( day month packed )
       h# fe00 and  9 >> d# 1980 + ( day month year )
;  

: set-prefix  ( adr len -- )
   to prefix-len
   path-prefix prefix-len move
;

\ When found, zip-buffer contains the central directory header
: find-file  ( name$ -- found? )
   0                                      ( name$ id )
   begin  another-file?  while            ( name$ id )
      2 pick  2 pick                      ( name$ id name$ )
      zip-name$ $=  if                    ( name$ id )
         3drop  true                      ( true )
         exit
      then                                ( name$ id )
   repeat                                 ( name$ )
   2drop false                            ( false )
;

\ Called after find-file has located the directory information for a file.
\ Adjusts offset and image-size so subsequent seeks and reads
\ apply only to that file's data.
: select-file-data  ( -- okay? )
   ch-hdroff le-l@  get-file-header?  if   ( file-header-id )
      +local to offset                     ( )
      fh-size le-l@  to image-size         ( )
      0. seek drop                         ( )
      true                                 ( true )
   else                                    ( )
      false                                ( false )
   then                                    ( flag )
;

\ Convert DOS file attributes to the firmware encoding
\ see showdir.fth for a description of the firmware encoding
: >canonical-attrs  ( dos-attrs -- canon-attrs )
   >r
   \ Access permissions
   r@     1 and  if  o# 666  else  o# 777  then \ rwxrwxrwx

   \ Bits that are independent of one another
   r@     2 and  if  h# 10000 or  then		\ hidden
   r@     4 and  if  h# 20000 or  then		\ system
   r@ h# 20 and  if  h# 40000 or  then		\ archive

   \ Mutually-exclusive file types
   r@     8 and  if  h#  3000 or  then		\ Volume label
   r> h# 10 and  if  h#  4000 or  then		\ Subdirectory
   dup h# f000 and  0=  if  h# 8000 or  then	\ Ordinary file	
;

: zip-attrs  ( -- attributes )
   ch-madeby le-w@  h# ff00 and  case        ( )
      h# 0300  of  ch-eattrs le-l@ d# 16 rshift       endof   ( attributes )  \ Unix permissions
      h# 0000  of  ch-eattrs le-w@  >canonical-attrs  endof   ( attributes' ) \ DOS
      ( default )  o# 100444  swap                            ( attributes' selector )
   endcase
;
: dir?  ( -- flag )  zip-attrs h# f000 and h# 4000 =  ;
: symlink?  ( -- flag )  zip-attrs h# f000 and  h# a000 =  ;

: link-target  ( -- true | link$ false )
   ch-hdroff le-l@  get-file-header?  if     ( file-header-id )
      +local u>d seek drop                   ( )
      fh-size le-l@ to name-len              ( )
      zip-name$ read                         ( actual-len )
      zip-name swap  false                   ( link$ false)
   else                                      ( )
      true                                   ( true )
   then                                      ( true | link$ false )
;
: $readlink  ( name$ -- true | link$ false )
   find-file  0=  if  true exit  then
   link-target
;

\ Find the link target for the current directory entry and
\ if it is relative, prefix it with the current entry's path
: chase-link  ( -- true | name$ false )
   zip-name$  [char] / right-split-string  set-prefix
   link-target  if  true exit  then   ( link$ )
   dup  if                            ( link$ )
      over c@ [char] / <>  if         ( link$ )
         \ If the path is relative, append it to the prefix
         \ XXX should handle ..
         tuck  prefix$ +  swap move   ( link-len )
         prefix-len +  to prefix-len  ( )
         prefix$                      ( link$ )
      then
      false
   else
      true
   then
;

: find-file-follow-links  ( name$ -- found? )
   begin  find-file  while                ( )
      symlink?  0=  if  true exit  then   ( )
      chase-link  if  false exit  then    ( name$ )
   repeat                                 ( )
   false                                  ( false )
;
: final-component  ( -- flag )
   dir?  if                                ( )
      zip-name$ set-prefix  true           ( true )
   else                                    ( )
      select-file-data                     ( flag )
   then                                    ( flag )
;
: resolve-path
   find-file-follow-links  if              ( )
      final-component                      ( flag )
   else                                    ( )
      false                                ( false )
   then                                    ( flag )
;
\ Determine if the current path name matches the path prefix
: in-directory?  ( -- flag )
   prefix-len 0=  if  true exit  then  \ No prefix - return true

   \ If the path name is shorter than the prefix, it doesn't match
   \ The = in <= filters out the name of the directory itself
   name-len prefix-len <=  if  false exit  then

   zip-name prefix$ comp 0=
;

external
: open  ( -- flag )
   -1 to image-size  0 to offset
   my-args  fix-delims  2dup  " /"  $=  if       ( adr len )
      2drop                                      ( )
      true exit                                  ( true )
   else                                          ( adr len )
      over c@  [char] /  =  if  1 /string  then  ( adr' len' )
      resolve-path                               ( flag )
      exit                                       ( flag )
   then                                          ( adr len )
   2drop false                                   ( false )
;
: close  ( -- )  ;

: next-file-info  ( id -- false | id' s m h d m y len attributes name$ true )
   begin  another-file?  while             ( id' )
      in-directory?  if                    ( id )
         ch-time le-w@ >hms                ( id s m h )
         ch-date le-w@ >dmy                ( id s m h d m y )
         ch-len le-l@                      ( id s m h d m y size )
   \     di-expansion be-l@                ( id s m h d m y size )
   \     ?dup 0=  if  di-size be-l@  then  ( id s m h d m y size )
         zip-attrs                         ( id s m h d m y size attributes )
         zip-name$ saved-name $save        ( id s m h d m y size attr name$ )
         prefix-len /string                ( id s m h d m y size attr name$' )
         true                              ( id s m h d m y size attr name$ true )
         exit
      then                                 ( id )
   repeat                                  ( )
   false                                   ( false )
;

: free-bytes  ( -- d.#bytes )
   first-dir-header  0=  if  0. exit  then  ( id )
   +central+end                        ( end-offset )
   " size" $call-parent  rot u>d  d-   ( d.#bytes )
;

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
