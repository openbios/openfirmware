\ See license at end of file

\ High level versions of string utilities needed for sifting

only forth also hidden also definitions
decimal
forth definitions
\ True if str1 is a substring of str2
: substring?   ( adr1 len1  adr2 len2 -- flag )
   rot tuck     ( adr1 adr2 len1  len2 len1 )
   <  if  3drop false  else  tuck $=  then
;

headerless
: unpack-name ( anf where -- where) \ Strip funny chars from a name field
   swap name>string rot pack
;
\ hidden definitions
: 4dup   ( n1 n2 n3 n4 -- n1 n2 n3 n4 n1 n2 n3 n4 )  2over 2over  ;

headers
\ forth definitions
: sindex  ( adr1 len1 adr2 len2 -- n )
   0 >r
   begin  ( adr1 len1 adr2' len2' )
      \ If string 1 is longer than string 2, it is not a substring
      2 pick over  >  if  r> 5drop  -1 exit   then
      4dup substring?  if  4drop r> exit  then
      \ Not found, so remove the first character from string 2 and try again
      swap 1+ swap 1-
      r> 1+ >r
   again
;
only forth also definitions

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
