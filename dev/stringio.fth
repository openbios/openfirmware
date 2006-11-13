\ See license at end of file
purpose: String buffer I/O package - collects written data for later

dev /packages
new-device

headerless
d# 1024 constant /granule
0 constant buflen
0 value stringbuf
0 instance value position
0 instance value buftop

headers
" stringio" device-name

headerless
: ?extend  ( adr len -- adr len )
   dup position +  buflen >  if    ( adr len )
      dup position +  /granule +   ( adr len new-size )
      stringbuf over resize  if    ( adr len new-size adr' )
         2drop                     ( adr len )
      else                         ( adr len new-size adr' )
         to stringbuf  to buflen   ( adr len )
      then                         ( adr len )
   then                            ( adr len )
;
: setup  ( adr len endptr -- len' adr len' buf-adr )
   swap position +   min  position -       ( adr len' )
   tuck                                    ( len' adr len' )
   stringbuf position +                    ( len' adr len' buf-adr )
   over position + to position             ( len' adr len' buf-adr )
;

headers
: open  ( -- flag )
   buflen 0=  if
      /granule alloc-mem to stringbuf
      /granule to buflen
   then
   true
;
: close  ( -- )  ;
: size  ( -- ud )  position 0  ;
: seek  ( ud -- error? )
   0<>  over buftop u>  or  if  drop true exit  then  ( u )
   to position  false
;
: write  ( adr len -- actual )
   ?extend  buflen setup swap move
   position buftop max  to buftop
;
: read   ( adr len -- actual )  buftop setup -rot move  ;
: written  ( -- adr len )  stringbuf position  ;
: clear  ( -- )  0 to position  0 to buftop  ;

finish-device
device-end

headerless
0 value string-ih
0 value old-stdout

headers
: collect(  ( -- )
   string-ih 0=  if  " "  " stringio" $open-package to string-ih  then
   string-ih 0= abort" Can't open string buffer package"
   stdout @ to old-stdout
   " clear" string-ih $call-method
   string-ih stdout !
;
: )collect  ( -- adr len )
   " written" string-ih $call-method
   old-stdout stdout !
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
