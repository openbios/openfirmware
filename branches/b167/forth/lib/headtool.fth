\ See license at end of file

\ Tools to make headerless definitions easier to live with.
\ To reheader the headerless words, download the headers file via dl.

headers
: r  ( offset -- adr )  origin+  ;      \ Relocate - offset -> absolute address
: rx ( offset -- )  r execute  ;

\  The format of each line of the "headers" file produced by the OBP
\	    make  process is:
\     h#  <Offset>  <headerless:|header:>  <name>
\
\  After reading the "headers" file through these definitions, it should
\  be possible to find a name for most definitions.

also hidden also definitions

vocabulary re-heads	\  Re-created headers

forth definitions

\  Re-create headers by making them an alias for the actual name.  Keep them
\  within the special re-created headers' vocabulary.  If they are leftover
\  transient words, i.e., outside the dictionary, ignore them...
: headerless:  \ name  ( offset -- )   compile-time
               \       ( ??? -- ??? )  run-time
   r dup in-dictionary? parse-word rot if
	  ['] re-heads  cached-make flagalias  acf-align token,
   else
	  3drop
   then
;

: header:      \ name  ( offset -- )   compile-time
               \       ( ??? -- ??? )  run-time
   drop [compile] \
;


\  Before faking-out a headerless name, scan the vocabulary of
\  the re-created headers.  Fake-out the name only if it isn't found.
: find-head  ( cfa -- nfa )
   ['] re-heads follow begin	( cfa )
      another?			( cfa nfa flag )
   while			( cfa nfa )
      2dup name> token@		( cfa nfa cfa cfa2 )
      = if			( cfa nfa )
	 nip exit		( nfa )
      else
	 drop			( cfa )
      then			( cfa )
   repeat			( cfa )
   fake-name			( nfa )
;


\  Set the search-order to include the re-created headers' vocabulary

root definitions
: only ( -- ) only re-heads also ;

\  Plug the routine to scan the re-created headers' vocabulary in to
\	the word that looks up names.  It does no harm to have it plugged
\	in place even if the headers file has not been read, because the
\	initial link-pointer in the re-created headers' vocabulary is null.

patch find-head fake-name >name

previous previous definitions
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
