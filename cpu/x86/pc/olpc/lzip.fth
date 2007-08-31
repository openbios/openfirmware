\ See license at end of file
purpose: Package for treating the data at load-base as a device

dev /
new-device
" lzip" device-name

headerless
0 instance value seek-ptr
0 instance value image-size
0 instance value base-adr

headers
external
: seek  ( d.offset -- status )
   0<>  over image-size u>  or  if  drop true  exit  then \ Seek offset too big
   to seek-ptr
   false
;

: open  ( -- flag )
   0 to seek-ptr                                    ( )
   load-base to base-adr                            ( )
   file-size @ to image-size                        ( )
   my-args  dup  if                                 ( adr len )
      " zip-file-system"  find-package  0=  if      ( adr len ph )
         2drop false exit
      then                                          ( adr len ph )
      interpose
   else			                            ( adr len )
      2drop                                         ( )
   then                                             ( )
   true                                             ( true )
;
: close  ( -- )  ;
: size  ( -- d.size )  image-size  0  ;
: read  ( adr len -- actual )
   seek-ptr +  image-size min  seek-ptr -	( adr len' )
   tuck						( len adr len )
   base-adr seek-ptr + -rot  move		( len )
   dup seek-ptr +  to seek-ptr			( len )
;
\ Having a load method is pointless since the image is already at load-base

finish-device
device-end

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
