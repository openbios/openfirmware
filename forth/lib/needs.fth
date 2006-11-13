\ See license at end of file

\ Implements needs and \needs.  These work as follows:
\
\ needs foo tools.fth
\
\ If foo is not defined, the file tools.fth will be loaded, which should
\ define foo.  If foo is already defined, nothing will happen.
\
\ \needs foo <arbitrary Forth commands>
\
\ If foo is not defined, the rest of the line is executed, else it is ignored

: needs  \ wordname filename  ( -- )
   safe-parse-word $canonical $find  if  ( cfa +-1 )
      drop  safe-parse-word 2drop
   else
      2drop safe-parse-word included
   then
;
: \needs ( -- ) ( Input Stream: desired-word  more-forth-commands )
   safe-parse-word $canonical $find  if  ( cfa +-1 )
      drop  postpone \
   else                                  ( adr len )
      2drop
   then
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
