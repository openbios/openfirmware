purpose: Coreboot filesystem ("CBFS") package
\ See license at end of file

h# ffc0.0000 value flash-base
: .cbfs-type  ( type -- )
   case
      h#  10 of  ."        stage"  endof
      h#  20 of  ."      payload"  endof
      h#  30 of  ."    optionrom"  endof
      h#  40 of  ."   bootsplash"  endof
      h#  50 of  ."          raw"  endof
      h#  51 of  ."          vsa"  endof
      h#  52 of  ."          mbi"  endof
      h#  53 of  ."    microcode"  endof
      h#  aa of  ." cmos_default"  endof
      h# 1aa of  ."  cmos_layout"  endof
      -1     of  ."       unused"  endof
      ( default )  dup push-hex d# 12 u.r pop-base
   endcase
;
\ 0,1 magic  2 length  3 type  4 checksum  5 offset  6+ name\0
: .cbfs  ( -- )
   ." Address    Length         Type Name" cr
   flash-base
   begin  dup be-l@  h# 4c415243 =  while   ( adr )
      push-hex                              ( adr )
      dup dup 5 la+ be-l@ +  8 u.r space    ( adr )
      dup 2 la+ be-l@ 8 u.r space           ( adr ) 
      pop-base                              ( adr )
      dup 3 la+ be-l@ .cbfs-type space      ( adr )
      dup 6 la+ cscount type  cr            ( adr )
      dup 2 la+ be-l@                       ( adr len ) 
      over 5 la+ be-l@                      ( adr len offset )
      + + h# 40 round-up                    ( adr' )
   repeat                                   ( adr )
   drop
;

support-package: cbfs-file-system

headerless
0 instance value image-size
0 value open-count
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
: size  ( -- d.size )  image-size u>d  ;
: read  ( adr len -- actual )
   clip-size                     ( adr len' )
   " read" $call-parent          ( len' )
   update-ptr                    ( len' )
;

headers
d# 24 d# 64 +  instance buffer: cbfs-hdr  \ should be large enough

d# 64 instance buffer: saved-name

: cbfield  \ name  ( offset -- adr )
   create  over ,  +  does> @ cbfs-hdr +
;

struct
   8  cbfield cb-magic	\ 4c415243 48495645
   /l cbfield cb-length	\ Data length in bytes
   /l cbfield cb-type	\ Image type
   /l cbfield cb-sum	\ Checksum
   /l cbfield cb-offset	\ Offset to data
   0  cbfield cb-name	\ Name
constant /cb-hdr	\ Size of header excluding name

: cbfs-name$  ( -- adr len )  cb-name cscount  ;

\ ID of the header that's currently in the buffer
-1 instance value header-id

external
: load  ( adr -- len )
   0. seek drop           ( adr )
   image-size read        ( len )
   \ XXX should verify the checksum
;

headers
: file-header?  ( id -- id flag )
   -1 to header-id                          ( id )
   dup u>d seek drop                        ( id )
   cb-magic  8 read drop                    ( id )
   cb-magic " "(4c41524348495645)" comp 0=  ( id adr )
;
: read-file-header  ( -- )
   cb-length  h# 10 read drop                    ( id )
   cb-name  cb-offset be-l@ h# 18 -  read drop   ( id )
;
: get-file-header?  ( id' -- id flag )
   dup  header-id =  if  true exit  then   ( id )
   file-header?  if			   ( id )
      dup to header-id                     ( id )
      read-file-header                     ( id )
      true                                 ( id true )
   else                                    ( id )
      false                                ( false )
   then                                    ( id )
;

: +file  ( id -- id' )
   cb-length be-l@ +   ( id' )
   cb-offset be-l@ +   ( id' )
   h# 40 round-up      ( id' )
;

: first-file-header  ( -- false | id true )
   d# 2000  0  do
      i get-file-header?  if  +file true unloop exit  else  drop  then  ( )
   loop
   0
;

: another-file?  ( id -- false  | id' true )
   ?dup  if                     ( id )    \ Not the first call
      get-file-header?  0=  if  ( )
         false exit
      then                      ( id )    \ Get the old header into the buffer
      +file                     ( id' )   \ Skip the old header
      get-file-header?          ( false | id true )  \ Get the new header
   else                         ( )
      first-file-header         ( false | id' true )
   then                         ( false | id' true )
;

\ When found, cbfs-hdr contains the file header
: find-file  ( name$ -- found? )
   0                                      ( name$ id )
   begin  another-file?  while            ( name$ id )
      2 pick  2 pick                      ( name$ id name$ )
      cbfs-name$ $=  if                   ( name$ id )
         3drop  true                      ( true )
         exit
      then                                ( name$ id )
   repeat                                 ( name$ )
   2drop false                            ( false )
;

\ Called after find-file has located the file header.
\ Adjusts offset and image-size so subsequent seeks and reads
\ apply only to that file's data.
: select-file-data  ( -- okay? )
   header-id cb-offset be-l@ +  to offset  ( )
   cb-length be-l@  to image-size          ( )
   0. seek drop                            ( )
   true                                    ( true )
;

: resolve-path
   find-file  if                           ( )
      select-file-data                     ( flag )
   else                                    ( )
      false                                ( false )
   then                                    ( flag )
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
      cb-type be-l@ h# ffffffff <>  if     ( id )
         " built-time-int" $find  if       ( id s m h xt )
            execute                        ( id s m h packed-date )
            d# 100 /mod  d# 100 /mod       ( id s m h d m y )
         else                              ( id s m h adr len )
            2drop  0 0 0                   ( id s m h d m y )
         then                              ( id s m h d m y )
         " built-date-int" $find  if       ( id s m h xt )
            execute                        ( id s m h packed-date )
            d# 100 /mod  d# 100 /mod       ( id s m h d m y )
         else                              ( id s m h adr len )
            2drop  0 0 0                   ( id s m h d m y )
         then                              ( id s m h d m y )
         cb-length be-l@                   ( id s m h d m y size )
         o# 555 h# 8000 or  \ Ordinary,r-x ( id s m h d m y size attributes )
         cbfs-name$ saved-name $save       ( id s m h d m y size attr name$ )
         true                              ( id s m h d m y size attr name$ true )
         exit
      then                                 ( id )
   repeat                                  ( id )
   drop                                    ( )
   false                                   ( false )
;

: free-bytes  ( -- d.#bytes )  0.  ;

end-support-package

\ LICENSE_BEGIN
\ Copyright (c) 2011 FirmWorks
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
