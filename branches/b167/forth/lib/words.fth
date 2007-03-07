\ See license at end of file

\ Display the WORDS in the Context Vocabulary

decimal

only forth also definitions

: over-vocabulary  (s acf-of-word-to-execute voc-acf -- )
   follow  begin  another?  while   ( acf anf )
      n>link over execute           ( acf )
   repeat  ( acf )  drop
;
: +words   (s -- )
   0 lmargin !  td 64 rmargin !  td 14 tabstops !
   ??cr
   begin  another?  while      ( anf )
     dup name>string nip .tab  ( anf )
     .id                       ( )
     exit? if  exit  then      ( )
   repeat                      ( )
;
: follow-to  (s adr voc-acf -- error? )
   follow  begin  another?  while         ( adr anf )
      over u<  if  drop false exit  then  ( adr )
   repeat                                 ( adr )
   drop true
;
: prior-words  (s adr -- )
   context token@ follow-to  if
      ." There are no words prior to this address." cr
   else
      +words
   then
;

: words  (s -- )  context token@ follow  +words  ;

only definitions forth also
: words    words ;  \ Version for 'root' vocabulary
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
