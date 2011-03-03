\ See license at end of file

\ Local labels for the assembler.
\ A local label can be inserted in an assembly-language program
\ to mark a position.  A relative branch instruction can then reference
\ that location by its local name.
\
\ Local label names:               0 L:  1 L:  2 L:  3 L:  etc.
\ Local label forward references:  0 F:  1 F:  etc
\ Local label backward references: 0 B:  1 B:  etc
\
\ There are 5 local labels, numbered 0 to 4.
\ Each local label may be referenced from up to 10 locations.
\
decimal
also assembler definitions

headerless
20 constant #references-max
20 constant #labels-max

#labels-max  #references-max *  /n* buffer: references
#labels-max /n* buffer: local-labels
#labels-max /n* buffer: next-references

: >reference  ( index -- adr )  /n* #references-max *  references +  ;

: >label  ( index -- adr )  local-labels swap na+  ;

: >next-reference  ( index -- adr )  next-references swap na+  ;

: resolve-forward-references  ( label# -- )
   dup >next-reference @
   [ also forth ] swap [ previous ] >reference

   ?do  i @  >resolve  /n +loop
;

\ Erase all forward references from this label
: clear-label  ( label# -- )  dup >reference  swap >next-reference  !   ;

headers
: L:  ( label# -- )
   dup resolve-forward-references       ( label# )
   dup >label   over >next-reference !  ( label# )
   dup clear-label                      ( label# )
   >label   <mark [ also forth ] swap [ previous ] !
;

: B:  ( label# -- adr )   \ Find the address of a backward reference
   >label @  <resolve
;

: F:  ( label# -- adr )   \ Remember a forward reference
   >mark
   over >next-reference @  !
   /n [ also forth ] swap [ previous ] >next-reference +!
   here   \ the address we leave is a dummy
;

headerless
: (init-labels)  ( -- )
   #labels-max  0   do  i clear-label  loop
;

defer init-labels
' (init-labels) is init-labels

also forth definitions
headers
: code  \ name  ( -- )
   code  [ also assembler ] init-labels [ previous ]
;
: label  \ name  ( -- )
   label  [ also assembler ] init-labels [ previous ]
;
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
