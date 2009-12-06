\ See license at end of file
purpose: Block-method additions to subrange.fth device to make a RAMdisk device

\ Define ramdisk-base before loading this file

0 0  ramdisk-base (u.)  " /" begin-package

" ramdisk" device-name
0 value /device  \ Range size, set later with set-size

external
my-address my-space /device reg

0 value offset			\ seek pointer

\ Reduce adr,len as necessary to fit within the actual device size
: clip-size  ( adr len -- adr actual )
   offset +   /device min  offset -     ( adr actual )
;

\ Update the seek pointer to reflect the result of the previous read or write
: update-ptr  ( actual -- actual )  dup offset +  to offset  ;

external

\ Standard interface methods for a byte-granularity device
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
: size  ( -- d )  /device u>d  ;

\ Device-specific method to set the device size when it is known
: set-size  ( d -- )  drop to /device  ;

\ Standard interface methods for block-granularity access
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
