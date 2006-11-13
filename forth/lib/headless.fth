\ See license at end of file

\ Creates headerless dictionary entries, by putting the headers as
\ aliases in the transient space.
\
\ Nested headerless commands are *not* allowed.
\ Headerless within transient space *is* allowed (by ignoring the
\   headerless command.  Thus the head and body are both transient.)
\
\ XXX For SPARC only!!  68000 kernel has flag byte in a different
\ place!!!

\ Created structure:
\ Transient - link token (2 or 4 bytes, aligned)
\             name field
\             flag byte (=20 for alias, or 60 if immediate)
\             padding bytes (0,1,2 or 3), value 0
\             pointer token (points to acf in resident space)
\
\ Resident -  acf (2 or 4 bytes, aligned)
\             apf ...
\
\ Use as follows (within a given source file):
\   headerless
\ (these words are now headerless)
\ : blah  ... ;
\   headers
\ (these words are now with heads)
\ : blah  ... ;
\
\ Use as follows (file-level control):
\   fload extensions/transien.fth
\   transient fload extensions/dispose.fth resident (file will be discarded)
\   fload extensions/alias.fth  ( if needed )
\   transient fload extensions/headless.fth resident (file will be discarded)
\ fload blah.fth ... (desired heads will be discarded later)
\ transient fload blah2.fth resident  (entire file will be discarded later)
\   true is suppress-headerless?
\ fload blahblah.fth ... (all heads are preserved)
\   false is suppress-headerless?
\ fload blah.fth ... (desired heads will be discarded later)
\ ...
\   dispose  (all transient heads and files are discarded)
\   (or .dispose to print statistics messages as well)
\
\ If it is desired to perform more than one dispose cycle, then dispose.fth and
\ headless.fth should be fload'ed normally, *not* into transient!

\ needs transient transien.fth

decimal

\ New version of ($header), puts name in transient
: ($headerless)  ( adr len -- )
   acf-align
   transient  ($header)  acf-align  there token,  resident
   flagalias
   acf-align	\ To set lastacf again
;

: make-headerless  ( -- )  ['] ($headerless)  is  $header  ;
: make-headerfull  ( -- )  ['] ($header)      is  $header ;

false value headerless?
: headerless  ( -- )
   transient? 0=  suppress-headerless? 0=  and
   if  make-headerless  1 is headerless?  then
;

: headers  ( -- )
   transient? 0=  if  make-headerfull  false is headerless?  then
;

: -headers  ( -- )
   headerless?  if  headerless? 1+ is headerless?  else  headerless  then
;

: +headers  ( -- )
   headerless? 1 <=  if  headers  else  headerless? 1- is headerless?  then
;

: alias  \ new-name old-name  ( -- )
   headerless?  if
      parse-word
      transient  ($header)
      hide $defined $?missing reveal   ( old-acf n )
      \ We have to create a code field, because setalias is expecting
      \ there to be one (which it may subsequently remove!)
      colon-cf setalias
      resident
   else
      alias
   then
;

: transient  ( -- )
   headerless? abort" Transient within headerless not allowed"
   transient
;

\ This can be used to turn on headers for words that don't really
\ need to be visible from the standpoint of a user at the ok prompt,
\ but that are used across the compilation boundary between, for
\ example, basefw.dic and fw.dic
defer partial-headers  ' headerless is partial-headers

alias internal headerless
alias public   headers
alias private  headerless
alias partial-headers headers

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
