\ See license at end of file
purpose: Encode and decode Sun XDR data types

headerless
: +xu     ( ul -- )    lbsplit +xb +xb +xb +xb  ;
: -xu     ( -- l )     -xb -xb -xb -xb  swap 2swap swap  bljoin  ;
: +xl     ( l -- )     +xu  ;
: -xl     ( -- l )     -xu  ;
: +xflag  ( flag -- )  0<> 1 and  +xu  ;
: -xflag  ( -- flag )  -xu 0<>  ;
[ifdef] notdef
: +xux    ( ux -- )    xlsplit swap >r +xu r> +xu  ;
: -xux    ( -- ux )    -xu >r  -xu  r> lxjoin  ; 
: +xx     ( x -- )     xlsplit swap >r +xu r> +xu  ;
: -xx     ( -- ux )    -xux  ;
[then]
: +xopaque  ( adr len -- )
   tuck  bounds  ?do  i c@ +xb  loop               ( len )
   3 and  ?dup  if  4 swap  do  0 +xb  loop  then
;
: -xopaque  ( len -- adr )
   x$  over >r                     ( len adr rem-len r: adr )
   rot 4 round-up /string  to x$   ( r: adr )
   r>
;
: +x$  ( adr len -- )  dup +xu  +xopaque  ;
: -x$  ( -- adr len )  -xu  dup  -xopaque  swap  ;
\ fixed-length array: element0, element1, element2, ...
\ variable-length array: #elements(u), element0, element1, element2, ...
\ structure: field0, field1, ...
\ union: discriminant(u), arm0, arm1, ...
headers
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
