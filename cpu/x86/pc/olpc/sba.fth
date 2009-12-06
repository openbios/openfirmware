\ See license at end of file
purpose: Subrange device to access Secure Boot Area between boot record and first partition

d# 512 constant /sector
/sector instance buffer: sector-buf

0 instance 2value image-size
0 instance 2value seek-ptr
external
\ Expose for the OLPC security scheme
0 instance 2value offset

: clip-size  ( adr len -- adr len' )
   u>d seek-ptr d+                 ( adr d.endptr )
   2dup image-size d>  if          ( adr d.endptr )
      2drop image-size             ( adr d.endlimit )
   then                            ( adr d.endlimit )
   seek-ptr d- drop                ( adr len' )
;
: update-ptr  ( len' -- len' )  dup u>d seek-ptr d+  to seek-ptr  ;

: ptable-adr  ( -- start )  sector-buf  h# 1be +  ;

: open  ( -- flag )
   sector-buf /sector " read" $call-parent  /sector <>  if  false exit  then
   sector-buf h# 1fe + le-w@  h# aa55  <>  if  false exit  then      \ FDisk?
   ptable-adr 4 + c@  7 <>  if  false exit  then   \ NTFS?
   ptable-adr 8 + le-l@  /sector um* to image-size
   h# 10 /sector um* to offset
   true
;

external
: seek  ( d.offset -- status )
   2dup image-size d>  if  2drop true  exit  then  \ Seek offset too big
   to seek-ptr
   seek-ptr offset d+  " seek" $call-parent
;
: size  ( -- d.size )  image-size  ;
: read  ( adr len -- actual )
   clip-size                     ( adr len' )
   " read" $call-parent          ( len' )
   update-ptr                    ( len' )
;


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
