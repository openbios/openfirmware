purpose: Post-fixup of metacompiled vocabularies for MIPS
\ See license at end of file

\ Nasty kludge to resolve the to pointer to the does> clause of vocabulary
\ within "forth".  The problem is that the code field of "forth" contains
\ a call instruction to the does> clause of vocabulary.  This call is a 
\ forward reference which cannot be resolved in the same way as compiled
\ addresses.

: used-t  ( definer-acf child-acf -- )
   [ also meta ] token!-t [ previous ]
;

: fix-vocabularies  ( -- )
   [""] <vocabulary>  also symbols  find   previous  ( acf true | str false )
   0= abort" Can't find <vocabulary> in symbols"
   dup resolution@ >r               ( acf )  ( Return stack: <vocabulary>-adr )
   dup first-occurrence@                     ( acf occurrence )
   \ Don't let fixall muck with this entry later
   0 rot >first-occurrence !		     ( occurrence )
   begin  another-occurrence?  while         ( occurrence )
      dup [ meta ] token@-t [ forth ] swap   ( next-occurrence occurrence )
      \ Calculate the longword offset to the vocabulary does> clause
      r@ swap used-t
   repeat
   r> drop
;

\ LICENSE_BEGIN
\ Copyright (c) 2009 FirmWorks
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
