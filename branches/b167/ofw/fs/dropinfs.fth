\ See license at end of file
purpose: Support package for "dropin file system"

headerless
0 instance value base-adr
0 instance value image-size
0 instance value seek-ptr
0 instance value offset

: clip-size  ( adr len -- adr len' )
   seek-ptr +   image-size umin  seek-ptr -
;
: update-ptr  ( len' -- len' )  dup seek-ptr +  to seek-ptr  ;

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

d# 32 buffer: di-buffer

\ ID of the header that's currently in the buffer
-1 instance value header-id

: difield  \ name  ( offset -- offset' )
   create  over ,  +  does> @ di-buffer +
;

d# 16 constant max-di-name
struct
   /l difield di-magic
   /l difield di-size
   /l difield di-sum
   /l difield di-expansion
max-di-name difield di-name
constant /di-header

: load  ( adr -- len )  0 0 seek drop  image-size read  ;

: ?get-header  ( id -- id )
   dup  header-id  <>  if                ( id )
      dup /di-header -  0  seek drop     ( id )
      di-buffer  /di-header  read drop   ( id )
      dup to header-id                   ( id )
   then                                  ( id )
;

: di-magic?  ( -- flag )  di-magic 4  " OBMD" $=  ;
: first-header  ( -- id )
   d# 2000  /di-header  do
      i ?get-header drop
      di-magic?  if  i unloop exit  then
   /di-header +loop
   0
;

: another-dropin?  ( id -- false  | id' true )
   ?dup  if                  ( id )    \ Not the first call
      ?get-header            ( id )    \ Get the old header into the buffer
      di-size be-l@ +        ( id+ )   \ Skip the old dropin
      4 round-up             ( id' )   \ Finish skipping
      /di-header +           ( id' )   \ Set ID to image offset
      ?get-header            ( id' )   \ Get the new header
   else                      ( )
      first-header           ( id' )
   then                      ( id' )

   di-magic?  dup  0=  if  nip  then
;

headerless
: find-drop-in  ( name-adr,len -- false  | drop-in-adr,len true )
   0                                      ( name-adr,len id )
   begin  another-dropin?  while          ( name-adr,len id )
      2 pick 2 pick                       ( name-adr,len id name-adr,len )
      di-name cscount  $=  if             ( name-adr,len id )
         nip nip                          ( id )
         di-size be-l@  true              ( adr len true )
         exit
      then                                ( name-adr,len id )
   repeat                                 ( name-adr,len )
   2drop false
;

: open  ( -- flag )
   -1 to image-size  0 to offset
   my-args  2dup  " \"  $=  if                   ( adr len )
      2drop                                      ( )
      true exit                                  ( true )
   else                                          ( adr len )
      over c@  [char] \  =  if  1 /string  then  ( adr' len' )
      find-drop-in  dup  if                      ( di-adr di-len true )
         -rot  to image-size  to offset          ( true )
         0. seek drop                            ( true )
      then                                       ( flag )
      exit                                       ( flag )
   then                                          ( adr len )
   2drop false                                   ( false )
;
: close  ( -- )  ;

: next-file-info  ( id -- false | id' s m h d m y len attributes name$ true )
   another-dropin?  if                  ( id )
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
\     di-expansion be-l@                ( id s m h d m y size )
\     ?dup 0=  if  di-size be-l@  then  ( id s m h d m y size )
      di-size be-l@                     ( id s m h d m y size )
      o# 100444                         ( id s m h d m y size attributes )
      di-name cscount  max-di-name min  ( id s m h d m y size attr name$ )
      true                              ( id s m h d m y size attr name$ true )
   else                                 ( )
      false                             ( false )
   then
;

: free-bytes  ( -- d.#bytes )
   0                                  ( high-water )
   0  begin  another-dropin?  while   ( high-water id )
      nip  di-size be-l@ 4 round-up   ( id size )
      over +  swap                    ( high-water' id )
   repeat                             ( high-water )
   " size" $call-parent  rot 0  d-    ( d.#bytes )
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
