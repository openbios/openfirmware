\ See license at end of file
purpose: Support package for "ZIP file system"

headerless
0 instance value base-adr
0 instance value image-size
0 instance value seek-ptr
0 instance value offset

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

headers
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


d# 42 constant /central		\ Size of central header

4 buffer: zip-magic

/central instance buffer: zip-buffer
d# 512 instance buffer: zip-name

0 value name-len

: zfield  \ name  ( offset -- offset' )
   create  over ,  +  does> @ zip-buffer +
;

struct
   /w zfield zip-version
   /w zfield zip-flag
   /w zfield zip-how
   /w zfield zip-time
   /w zfield zip-date
   /l zfield zip-crc
   /l zfield zip-size	\ Compressed size
   /l zfield zip-len	\ Uncompressed size
   /w zfield zip-namelen
   /w zfield zip-extlen
constant /local-header
   
: ?crc  ( adr len -- )
   $crc                 ( crc )
   zip-crc le-l@ <>  if  ." Zip file CRC mismatch" cr  abort  then
;

\ ID of the header that's currently in the buffer
-1 instance value header-id

: load  ( adr -- len )
   0 0 seek drop
   dup image-size read    ( adr len )
   tuck  ?crc             ( len )
;

: read-magic  ( id -- adr )
   -1 to header-id                     ( id )
   4 -  0 seek drop                    ( id )
   zip-magic  4 read drop              ( )
   zip-magic                           ( adr )
;
: get-header?  ( id -- false | id true )
   dup  header-id =  if  false exit  then  ( id )
   dup read-magic  " PK"(0304)" comp  if   ( id )
      drop false exit                      ( false )
   then                                    ( id )
   zip-buffer  /local-header  read drop      ( id )
   dup to header-id                        ( id )
   zip-namelen le-w@ to name-len           ( id )
   zip-name name-len read drop             ( id )
   true                                    ( id true )
;

: first-header  ( -- false | id true )
   d# 2000  4  do
      i get-header?  if  true unloop exit  then  ( )
   loop
   0
;

: +extras  ( id -- id' )  
   zip-namelen le-w@ +    ( id+ )   \ Skip the old name
   zip-extlen  le-w@ +    ( id' )   \ Skip the old extra field
;
: +local  ( id -- id' )  /local-header +  +extras  ;
: +file  ( id -- id' )  +local  zip-size le-l@ +  4 +  ;
: +central+end  ( id -- id' )
   dup read-magic
   zip-buffer  " PK"(01 02)" comp  if  exit  then  ( id )
   begin                               ( id )
      zip-buffer /central read drop    ( id )
      zip-buffer  " PK"(0506)" comp    ( id flag )
   while                               ( id )
      /central +                       ( id' )  \ Skip fixed-length stuff
      zip-buffer d# 24 + le-w@ +       ( id' )  \ Skip file name
      zip-buffer d# 26 + le-w@ +       ( id' )  \ Skip extras
   repeat                              ( id )
   \ Now ID is the offset of the END header signature, which is in the
   \ buffer along with that header
   4 +  d# 18 +                        ( id' )  \ Skip signature and end hdr
   zip-buffer d# 18 + le-w@ +          ( id' )  \ Skip comment
;
   

: another-file?  ( id -- false  | id' true )
   ?dup  if                  ( id )    \ Not the first call
      get-header? drop       ( id )    \ Get the old header into the buffer
      +file                  ( id )    \ Skip the old header
      get-header?            ( false | id' true )   \ Get the new header
   else                      ( )
      first-header           ( false | id' true )
   then                      ( false | id' true )
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

: next-header-ok?  ( id -- flag )
   +file 4 -  0 seek drop  zip-magic  2 read        ( len )
   zip-magic swap  " PK" $=
;
: find-file  ( name$ -- false  | file-id file-len true )
   0                                      ( name$ id )
   begin  another-file?  while            ( name$ id )
      2 pick  2 pick                      ( name$ id name$ )
      zip-name name-len $=  if            ( name$ id )
         nip nip                          ( id )
         dup next-header-ok?  if          ( id )
            zip-size le-l@  true          ( id len true )
         else                             ( id )
            ." Missing signature in Zip archive" cr     ( id )
            drop false                    ( false )
         then                             ( false  | file-id file-len true )
         exit
      then                                ( name$ id )
   repeat                                 ( name$ )
   2drop false
;

headers
: open  ( -- flag )
   -1 to image-size  0 to offset
   my-args  fix-delims  2dup  " /"  $=  if       ( adr len )
      2drop                                      ( )
      true exit                                  ( true )
   else                                          ( adr len )
      over c@  [char] /  =  if  1 /string  then  ( adr' len' )
      find-file  dup  if                         ( file-id file-len true )
         -rot  to image-size  +local to offset   ( true )
         0. seek drop                            ( true )
      then                                       ( flag )
      exit                                       ( flag )
   then                                          ( adr len )
   2drop false                                   ( false )
;
: close  ( -- )  ;

: next-file-info  ( id -- false | id' s m h d m y len attributes name$ true )
   another-file?  if                    ( id )
      zip-time le-w@ >hms               ( id s m h )
      zip-date le-w@ >dmy               ( id s m h d m y )
      zip-len le-l@                     ( id s m h d m y size )
\     di-expansion be-l@                ( id s m h d m y size )
\     ?dup 0=  if  di-size be-l@  then  ( id s m h d m y size )
      o# 100444                         ( id s m h d m y size attributes )
      zip-name name-len                 ( id s m h d m y size attr name$ )
      true                              ( id s m h d m y size attr name$ true )
   else                                 ( )
      false                             ( false )
   then
;

: free-bytes  ( -- d.#bytes )
   0                                   ( "first"-id )
   begin  dup another-file?  while     ( prev-id new-id )
      nip                              ( id )
   repeat                              ( prev-id )
   +file                               ( central-id )
   +central+end                        ( end-offset )
   " size" $call-parent  rot 0  d-     ( d.#bytes )
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
