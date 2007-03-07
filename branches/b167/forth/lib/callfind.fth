\ See license at end of file

\ Callfinder
\ The place to start searching is implementation-dependent.
\ The best place would be at the lowest Forth definition in the
\ dictionary.

decimal

\needs 3drop  : 3drop 2drop drop ;

: .calls  ( cfa -- )
   hi-segment-base
   begin ( cfa search-start )
      2dup hi-segment-limit  tsearch	( acf last [ found-at ] f )
   while  dup  .caller cr		( acf last found-at)
      exit?  if  3drop exit  then
      nip ta1+
   repeat drop				( acf )
   lo-segment-base
   begin				( cfa search-start )
      2dup lo-segment-limit  tsearch	( acf last [ found-at ] f )
   while  dup  .caller cr		( acf last found-at)
      exit?  if  3drop exit  then
      nip ta1+
   repeat 2drop
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
