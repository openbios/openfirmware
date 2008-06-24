purpose: Device that represents a subrange of its parent
\ See license at end of file

\ This is device that accesses a subrange of its parent's address space

\ /device must be defined externally as the length of the subrange
\ my-space is the base of the subrange
my-address my-space /device reg

0 value offset			\ seek pointer

: clip-size  ( adr len -- adr actual )
   offset +   /device min  offset -     ( adr actual )
;
: update-ptr  ( actual -- actual )  dup offset +  to offset  ;

: seek-parent  ( n -- )  my-space +  u>d " seek" $call-parent drop  ;

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
   offset seek-parent                           ( adr actual )
   " read" $call-parent				( actual )
   update-ptr
;
: write  ( adr len -- actual )
   clip-size					( adr actual )
   offset seek-parent                           ( adr actual )
   " write" $call-parent			( actual )
   update-ptr
;
: size  ( -- d )  /device 0  ;

\ LICENSE_BEGIN
\ Copyright (c) 2008 FirmWorks
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
