\ See license at end of file
purpose: Convert binary data to hex for use in FCode programs

\ bintostr  ( "filename" "output-filename" -- )
\     Converts the contents of a binary file into lines of the form:
\         " "(nn nn nn nn nn ... nn )" $,
\     where nn is the ASCII hex representation of a byte.

\ This is intended for use with FCode programs that need to embed large
\ arrays of binary data.  The obvious Forth code:
\     create my-data  12 c, 34 c, 56 c, 78 c, ab c, cd c, de c, f0 c,
\ is inefficient in its use of space in the FCode binary file, as each number
\ consumes 6 FCode bytes - 5 for the literal number and one for the "c,".
\ The "overhead" is thus 400% of the useful data.  The overhead could be
\ reduced to 50% by using "l," with 32-bit numbers, but that can introduce
\ byte-order problems when used with 8-bit data.

\ A more efficient solution for large arrays is:
\     : $, ( adr len -- )  here over allot  swap move  ;
\     create my-data
\     " "(12 34 56 78 )" $,
\     " "(9a bc de f0 )" $,
\ This form requires 4 bytes of overhead per string, and each string can have
\ up to 255 bytes.  Thus, the overhead can be as low as 1.5%

\needs push-hex  : push-hex  ( -- r: old-base )  r> base @ >r >r  hex  ;
\needs pop-base  : pop-base  ( r: base -- )  r> r> base ! >r  ;

d# 256 buffer: strbuf
\ d# 255 constant maxstr   \ Lowest overhead
d# 80 constant maxstr    \ 5% overhead, avoids tokenizer line-length limitation
\ d# 23 constant maxstr    \ Prettier output, but 17% overhead

: otype  ( adr len -- )  ofd @ fputs  ;

: bytes>string  ( adr len -- )
   push-hex
   " "" ""(" otype
   bounds  ?do  i c@  <# bl hold u# u# u#> otype  loop
   " )"" $," otype fcr
   pop-base
;

: $bintostr  ( filename output-filename -- )
   $read-open  $new-file
   begin  strbuf maxstr  ifd @ fgets  dup 0>  while
      strbuf swap bytes>string
   repeat
   ifd @ fclose
   ofd @ fclose
;
: bintostr  ( "filename" "output-filename" -- )
  safe-parse-word safe-parse-word 2swap $bintostr
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
