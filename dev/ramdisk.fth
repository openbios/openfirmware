\ See license at end of file
purpose: Block-method additions to subrange.fth device to make a RAMdisk device

0 0  " b000000"  " /" begin-package
   " ramdisk" device-name
   h# 3800000 constant /device

external
\ /device must be defined externally as the length of the subrange
\ my-space is the base of the subrange
my-address my-space /device reg

0 value offset			\ seek pointer

: clip-size  ( adr len -- adr actual )
   offset +   /device min  offset -     ( adr actual )
;
: update-ptr  ( actual -- actual )  dup offset +  to offset  ;

external
: open  ( -- flag )  0 to offset  true  ;
: close  ( -- )  ;

: seek  ( d.offset -- status )
   0<>  over /device u>  or  if  drop true  exit  then  \ Seek offset too large
   to offset
   false
;
: read  ( adr len -- actual )
   clip-size					( adr actual )
   tuck  offset my-space +  -rot  move          ( actual )
   update-ptr
;
: write  ( adr len -- actual )
   clip-size					( adr actual )
   tuck  offset my-space +  swap  move          ( actual )
   update-ptr
;
: size  ( -- d )  /device 0  ;


h# 200 value block-size
: #blocks  ( -- n )  /device block-size /  ;
: read-blocks  ( adr block# #blocks -- actual-#blocks )
   swap block-size um* seek  if  2drop 0 exit  then  ( adr #blocks )
   block-size * read  block-size *
;
: write-blocks  ( adr block# #blocks -- actual-#blocks )
   swap block-size um* seek  if  2drop 0 exit  then  ( adr #blocks )
   block-size * write  block-size *
;

end-package

\ LICENSE_BEGIN
\ Copyright (c) 2009 FirmWorks
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
