\ See license at end of file
purpose: Access primitives for descriptor tables.

\ Far pointers to the beginnings of descriptor tables
\ "farp" is "offset selector"

defer idt  ( -- farp )
defer gdt  ( -- farp )
defer ldt  ( -- farp )
defer environ-ptr  ( -- farp )

: (ldt)    ( -- farp )  0  ldtr@  ;
' (ldt) is ldt

\ Add an offset to a far pointer.
: far+  ( farp-offset farp-sel offset -- farp-offset' farp-sel )  rot + swap  ;

\ Fetch and store far pointers
: farp@  ( adr -- offset sel )  dup le-l@  swap la1+ le-w@  ;
: farp!  ( offset sel adr -- )  tuck la1+ le-w!  le-l!  ;

\ 4-byte far access
: far-l@  ( farp -- l )  spacel@  ;
: far-l!  ( l farp -- )  spacel!  ;

\ 8-byte far access
: far-x@  ( farp -- ls ms )  2dup far-l@  -rot  4 far+ far-l@  ;
: far-x!  ( ls ms farp -- )  rot 2 pick 2 pick 4 far+  far-l!  far-l!  ;
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
