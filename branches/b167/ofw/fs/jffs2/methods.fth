\ See license at end of file
purpose: JFFS2 file system package methods

decimal

headerless
0 value open-count
0 instance value seek-ptr

: clip-size  ( adr len -- len' adr len' )
   seek-ptr +   file-size min  seek-ptr -     ( adr len' )
   tuck
;
: update-ptr  ( len' -- len' )  dup seek-ptr +  to seek-ptr  ;
: 'base-adr  ( -- adr )  seek-ptr  file-buf +  ;

headers
external
: seek  ( d.offset -- status )
   0<>  over file-size u>  or  if  drop true  exit  then \ Seek offset too big
   to seek-ptr
   false
;

: ?release  ( flag -- flag )  dup 0=  if  release-buffers  then  ;

: open  ( -- flag )
   \ This lets us open the node during compilation
   standalone?  0=  if  true exit  then

   0 to seek-ptr                                 ( )

   set-sizes  allocate-buffers  scan-occupied    ( )

   my-args " <NoFile>"  $=  if  true exit  then

[ifdef] notdef
   my-args  ascii \ split-after                 ( file$ path$ )
   root-dirent  $find-dirent  if                ( file$ )
      2drop false ?release exit
   then                                         ( file$ inode )

   \ Filename ends in "\"; select the directory and exit with success
   over  0=  if  3drop  true exit  then          ( file$ dirent )

   dirino@ find-dirent  if  false ?release exit  then    ( dirent )
[else]
   my-args set-root  $resolve-path  if  false ?release exit  then  ( dirent )

   begin
      \ We now have the dirent for the file at the end of the string
      dup ftype@  case                                   ( dirent )
         4      of  to pwd  true exit  endof           \ Directory
         8      of  dirino@ do-file  ?release exit  endof
         d# 10  of
            dir-link  if  false ?release exit  then  ( dirent )
         endof
         ( default )             
            2drop false ?release exit
      endcase                                       ( dirent )
   again
;
: close  ( -- )  release-buffers  ;
: size  ( -- d.size )  ?play-log file-size 0  ;
: read  ( adr len -- actual )
   ?play-log                            ( adr len )
   clip-size tuck			( len' len' adr len' )
   begin
      file-size  seek-ptr -  min	( len' len' adr len'' )
      2dup 'base-adr -rot move		( len' len' adr len'' )
      update-ptr			( len' len' adr len'' )
      rot over - -rot + over		( len' len'-len'' adr+len'' len'-len'' )
   ?dup 0=  until			( len' len'-len'' adr+len'' len'-len'' )
   2drop
;
: load  ( adr -- len )
   ?free-file-buf  to file-buf
   play-log
   file-size
;
: next-file-info  ( id -- false | id' s m h d m y len attributes name$ true )
   dup 0=  if  drop prep-dirents  dirents  then
   advance-dirent  if  false exit  then  ( dirent )
   dup >r +dirent     ( id' r: dirent )
   0 0 0  0 0 0       ( id' s m h  d m y  r: dirent )
   0  ( ... len,for_now )
   0  ( ... attributes,for_now )
   r> fname$ true
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
