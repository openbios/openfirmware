\ See license at end of file
purpose: Substring selection

\  0 " |asdf|qwerty|foo|bar" select$ type  ->  asdf
\  1 " |asdf|qwerty|foo|bar" select$ type  ->  qwerty
\  3 " |asdf|qwerty|foo|bar" select$ type  ->  bar
\  4 " |asdf|qwerty|foo|bar" select$ type  ->  aborts with "Too few substrings"
\
\ The first character in the string is the delimiter; it need not be "|".
\ If you want to use a non-printing character, you can get a null into
\ the string with '"0'.  For example:
\
\ 3 " "0asdf"0qwerty"0foo"0bar" select$ type  ->  bar
\
\ The number of substrings is equal to the number of delimiters;
\ if there are 4 delimiters, there are 4 substrings, numbered 0 to 3,
\ and attempts to access substring 4 or greater will cause an error.
\
\ (select$) returns a true flag instead of aborting.

: (select$)  ( n $1 -- true | $2 false )

   dup 0=  if  3drop true exit  then    \ Null string is no good

   \ Remove the first n delimited substrings
   2dup  4 roll 1+  0  do                         ( head$ rem$ )
      2swap 2drop                                 ( rem$ )

      \ If the remaining string is empty, we have run out prematurely
      dup 0=  if  2drop true unloop exit  then    ( rem$ )

      \ Get the leading delimiter and remove it from the string
      over c@ >r  1 /string  r>                   ( rem$' delim )

      \ Split the string around the next occurrence of that delimiter, if any
      split-string                                ( head$ rem$ )
   loop                                           ( head$ rem$ )

   2drop false                                    ( $2 false )
;
: select$  ( n $1 -- $2 )  (select$) abort" Too few substrings"  ;
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
