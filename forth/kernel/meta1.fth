\ See license at end of file

only forth also definitions

vocabulary meta
vocabulary symbols
vocabulary labels

\ This will be set later
0 constant compilation-base

0 constant origin-t
variable dp-t
variable current-t
variable context-t

variable meta-tag-file

\ Return the host address where the given target address is being compiled
: >hostaddr  ( target-address -- host-address )
   origin-t -   compilation-base l+
;
: hostaddr>  ( host-address -- target-address )
   compilation-base l-  origin-t +
;

: allot-t  ( #bytes -- )  dp-t +!  ;

: here-t  ( -- target-adr )  dp-t @  ; 

: target-image  ( l.adr -- )  is compilation-base  ;
: org  ( adr -- )  dup dp-t !  is origin-t  ;

\ voc-ptr is the address of the first thread

: $sfind  ( adr len -- acf [ -1 1 ] | adr len false )
   $canonical  ['] symbols $vfind
;
: sfind  ( str -- acf [ -1 1 ] | str false )
   count $canonical  ['] symbols $vfind
;

\ Version which allows target variables and constants to be interpreted
\ : xconstant ( n -- )
\    current link@ >r  context link@ >r [compile] labels definitions
\       lastword canonical "create ,
\    r> context link! r> current link!
\    does> @
\ ;
\ Version which doesn't
: xconstant ( n -- ) drop ;

\ This is a version of create that creates a word in a specific vocabulary.
\ The vocabulary is passed as an explicit argument. This would be somewhat
\ easier if the search-order stuff was implemented in a less "hard-wired"
\ manner.

: $vcreate  ( adr len voc-cfa -- )
   context link@ >r   current link@ >r   warning @ >r
   context link!  definitions
   warning off
   tag-file @ >r  meta-tag-file @ tag-file !
   $create
   r> tag-file !
   r> warning !   r> current link!   r> context link!
;
\ : vcreate  ( str voc-cfa -- )  count $vcreate  ;
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
