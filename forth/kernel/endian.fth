\ See license at end of file
purpose: endian-specific operators

[ifndef] le-w@
: le-w@   ( a -- w )   dup    c@ swap ca1+    c@ bwjoin  ;
[then]
[ifndef] be-w@
: be-w@   ( a -- w )   dup ca1+    c@ swap    c@ bwjoin  ;
[then]
[ifndef] le-l@
: le-l@   ( a -- l )   dup le-w@ swap wa1+ le-w@ wljoin  ;
[then]
[ifndef] be-l@
: be-l@   ( a -- l )   dup wa1+ be-w@ swap be-w@ wljoin  ;
[then]

[ifndef] le-w!
: le-w!   ( w a -- )   >r wbsplit r@ ca1+    c! r>    c!  ;
[then]
[ifndef] be-w!
: be-w!   ( w a -- )   >r wbsplit r@    c! r> ca1+    c!  ;
[then]
[ifndef] le-l!
: le-l!   ( l a -- )   >r lwsplit r@ wa1+ le-w! r> le-w!  ;
[then]
[ifndef] be-l!
: be-l!   ( l a -- )   >r lwsplit r@ be-w! r> wa1+ be-w!  ;
[then]

: le-l,   ( l -- )     here /l allot le-l!  ;

64\ : le-x@   ( a -- l )   dup le-l@ swap la1+ le-l@ lxjoin  ;
64\ : be-x@   ( a -- l )   dup la1+ be-l@ swap be-l@ lxjoin  ;
64\ : le-x!   ( l a -- )   >r xlsplit r@ la1+ le-l! r> le-l!  ;
64\ : be-x!   ( l a -- )   >r xlsplit r@ be-l! r> la1+ be-l!  ;
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
