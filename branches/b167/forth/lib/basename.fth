\ See license at end of file
purpose: Directory/filename parsing functions

\needs lex  fload ${BP}/forth/lib/lex.fth
\needs 2nip : 2nip  ( $1 $2 -- $2 )  2swap 2drop  ;

: basename  ( path$ -- name$ )
   begin  " /\:" lex  while  3drop  repeat
;
: dirname  ( path$ -- name$ )  2dup basename  nip -  ;
: rootname  ( name$ -- rootname$ )
   " ." lex  0=  if  exit  then       ( rem$ head$ delim )
   drop 2swap                         ( adr len name$ )
   begin  " ." lex  while             ( adr len rem$ head$ delim )
      drop +                          ( adr len rem$ adr' )
      >r 2swap drop r> over -  2swap  ( adr len' rem$ )
   repeat                             ( adr len rem$ )
   2drop                              ( adr len )
;
: extension  ( name$ -- extension$ )
   basename
   over 0 2swap                       ( adr len name$ )
   begin  " ." lex  while             ( adr len rem$ head$ delim )
      drop + 1+                       ( adr len rem$ adr' )
      >r 2swap drop r> over -  2swap  ( adr len' rem$ )
   repeat                             ( adr len rem$ )
   2nip                               ( rem$ )
;
d# 256 buffer: log-file-name
: $enclose  ( name$ prefix$ extension$ -- )
   2swap log-file-name place
   2swap basename rootname log-file-name $cat
   log-file-name $cat
   log-file-name count
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
