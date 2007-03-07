\ See license at end of file
\needs mmap fload ioports.fth

: usage  ( -- )  ." CaFe SD exerciser.  Type help for more info." cr  ;
: help  ( -- )
   ." CaFe SD exerciser commands:" cr
   ."   All numbers are automatically in hex" cr
   cr
   ."   <offset> r            \ Display the 32-bit value" cr
   ."   <value> <offset> w    \ Write a 32-bit value" cr
   ."   <offset> <len>  ldump \ Dump a range of SD locations" cr
   ."   bye                   \ Quit the program" cr
   cr
   ." You can also use any Forth programming language command" cr
   cr
   ." Examples:" cr
   ." 315c r" cr
   ." 60006 315c w" cr
;

usage

hex
fe01.0000 4000 mmap constant sd

: sdl@  ( offset -- l )  sd + l@  ;
: sdw@  ( offset -- w )  sd + w@  ;
: sdb@  ( offset -- b )  sd + c@  ;

: sdl!  ( l offset -- )  sd + l!  ;
: sdw!  ( w offset -- )  sd + w!  ;
: sdb!  ( b offset -- )  sd + c!  ;

: r  ( offset -- )  sdl@ u.  ;
: w  ( l offset -- )  sdl!  ;
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
