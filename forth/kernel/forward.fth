\ See license at end of file

\ Metacompiler forward referencing code, target-independent

only forth also meta also forth definitions

\ Symbol entries in "symbols" vocabulary:

\    The "first-occurrence" field is the head of a linked list
\ its value is a pointer to an occurrence of this word in the
\ target dictionary.  Each node in the list is one 16-bit word.
\ The last node contains 0.  If there are no occurrences, the
\ first-occurrence field contains 0.
\    The "resadd" field contains the compilation address of the
\ word, or 0 if the word hasn't been defined yet.
\    Symbols should probably be "does>" words, but aren't for
\ historical reasons.

: >first-occurrence ( acf -- first-occurrence-add ) >body ;
: >resolution  ( acf -- resolution-add ) >first-occurrence /a-t + ;
: >action      ( acf -- action-add ) >resolution /token-t + ;
: >info        ( acf -- info-addr ) >action /token +  ;

: first-occurrence@ ( acf -- first-occurrence )  >first-occurrence rlink-t@  ;
: first-occurrence! ( first-occurrence acf -- )  >first-occurrence rlink-t!  ;
: resolution@ ( acf -- resolution ) >resolution token-t@ ;
: resolution! ( resolution acf -- ) >resolution token-t! ;
: info@       ( acf -- info )  >info c@  ;
: info!       ( info acf -- )  >info c!  ;

\ Add a new occurrence of word to the linked-list of occurrences.
\ The "first-occurrence" field is the head of the list.  If the list
\ is empty, it contains 0.  If the list isn't empty, it contains the
\ non-relocated target address of the most-recent
\ occurrence of the word.  That location, in turn, points to the
\ previous occurrence.  The last one in the list contains 0.

: addlink  ( acf -- )
   here-t
   over first-occurrence@   ( acf occurrence old-first-link )
   over rlink!-t            ( acf occurrence )  \ link old list to occurrence
   swap first-occurrence!   ( )  \ link occurrence to head-of-list-node
   /token-t allot-t
;

variable lastacf-s
variable lastanf-s

: isunknown  ( acf -- )
   drop  ." Unknown `is' action." cr
;

\ Establish the action to be performed by a target word when it
\ is the target of "is"
: setaction  ( acf -- )  lastacf-s @  >action token!  ;

: $makesym  ( adr len -- acf )   \ makes a new symbol entry
   ['] symbols $vcreate
   here body>             \ leave acf for downstream code
   0  a-t,                \ initialize first-occurrence
   0  token-t,            \ initialize resolution
   ['] isunknown token,   \ initialize action
   0  c,		  \ info ( headers/headerless & immediate )
   does>
      \ When a target symbol executes, it compiles itself into the
      \ target dictionary by adding a reference to itself to the list.
      body>  ( acf )
      dup immediate?
      if
         .name
         ."  is immediate in the target system but it" cr
         ." is not defined in the metacompiler." cr abort
      else
         addlink
      then

;
: makesym ( str -- acf )  count $makesym  ;  \ makes a new symbol entry

: resolved?  ( acf -- flag )  \ true if already resolved
   resolution@ origin-t u>
;

\ Words to manipulate the symbol table vocabulary at the end of compilation.

: .x  ( -- )
   depth 30 u<  if  base @ >r hex .s r> base !  else  ." Underflow"  then
;

\ Is there another entry in this list of occurrences?
: another-occurrence?  ( current-occurrence -- [ current-occurrence ] flag )
   dup  origin-t u>  if  true  else  drop false  then
;

\ resolve is used to replace all the references chained to
\ its argument acf with the associated referent
variable debugflag debugflag off
: resolve ( acf -- )  \ replace all links with the resolution
   dup resolution@ >r      ( return-stack: resloution )
   first-occurrence@       ( first-occurrence )
   \ If there are no occurrences, the resolution is just put in the
   \ "first-occurrence" field, which doesn't hurt anything
   begin   another-occurrence?     while
      \ first grab link to next occurrence before clobbering it
      dup rlink@-t          ( current-occurrence next-occurence )
      r@ rot  token!-t      \ put the resolution value in the current-occ.
      ( next-occurrence )
   repeat
   r> drop
;

\ Print the addresses of all the places where this word is used
: where-used  ( acf -- )
   first-occurrence@  ( first-occurrence )
   begin  another-occurrence?   while  dup u. token@-t  repeat
;

\ For each target symbol, prints the name of the word,
\ its compilation address, and all the places it's used.
\ Basically a cross-reference listing for the word.
: show  ( acf -- )  \ name, resolution, occurrences
   dup  .name   dup resolution@ u.   where-used
;

\ Find the named target symbol
: n'  \ name  ( voc-acf -- acf )
\ CROSS   [compile] ""
   safe-parse-word rot  $vfind 0=  if  type ."  not found" abort  then
;

\ Display all the target symbols
: nwords  ( voc-cfa -- )
   follow  begin   another?   while   .id 2 spaces   repeat
;

: nheads ( -- )
   base @ >r hex
   ['] symbols follow  begin   another?   while  ( anf )
      dup name> resolution@ ." h# "              ( anf acf )
      <# u# u# u# u# u# u# u#> type              ( anf )
      dup name> info@ 3 and case                 ( anf )
	 0  of  ."  header: "      endof
	 1  of  ."  header: "      endof
	 2  of  ."  headerless: "  endof
      endcase    dup .id                         ( anf )
      name>  info@ h# 80 and  if  ." immediate"  then  cr
   repeat
   r> base !
;

\ Display a cross-reference list
: cref  ( voc-cfa -- )
   follow  begin   another?   while   name> cr show   repeat
;

\ Display undefined forward references
: undef  ( voc-cfa -- )
   follow  begin  another?  while
     dup name> resolved? 0=  ( lfa f )
     if  .id space  else  drop  then
   repeat
;

\ Replace all the references with the resolution address
: fixall  ( voc-cfa -- )
   follow  begin  another?  while
      dup name> dup resolved?  if  ( lfa acf )
	 resolve  drop
      else  drop .id ." not defined" cr then
   repeat
;
variable warning-t  \ warning for target
warning-t off

only forth also meta also definitions


\ Finds the acf of the symbol whose name is str, or makes it if it
\ doesn't already exist.
: $findsymbol  ( str -- acf )  $sfind 0=  if  $makesym  then  ;

\ Defines a new target symbol with name str.
\ If a symbol with the same name exists and has already been resolved,
\ a new one is created and a warning message is printed.
\ If a symbol of the same name exists but is unresolved (a forward reference),
\ a new one is not created.

: $create-s  ( str -- acf )
   2dup $findsymbol    ( str acf )
   dup resolved?  if   ( str acf )
      drop             ( str )
      warning-t @  if  ( str )
	 2dup type ."  isn't unique in target" cr
      then
      $makesym      ( acf )
   else nip nip     ( acf )
   then             ( acf )
   dup lastacf-s !  >name lastanf-s !
;

\ Set the precedece bit on the most-recently-resolved symbol.
\ We can't do this with immediate-h because the symbol we need to make
\ immediate isn't necessarily the last one for which a header was
\ created.  It could have been a forward reference, with the header
\ created long ago.
: immediate-s  ( -- )
   lastanf-s @ n>flags  dup c@ h# 40 xor swap c!    \ fix symbol table
   lastacf-s @ dup info@ h# 80 or swap info!
;

\ hide-t temporarily prevents the most-recently-created word from being
\ found.  It is used when creating a colon definition, so that a colon
\ definition may refer to a previous word with the same name as itself,
\ without resulting in recursion.
\
\ reveal-t is the inverse of hide-t, allowing the most-recently-created
\ word to be found again.
\
\ In the normal Forth kernel, hide is implemented by unhooking the most
\ recent word from the dictionary.  That implementation doesn't work in
\ the metacompiler, because due to forward referencing, the current colon
\ definition is not necessarily the most-recently-created symbol.
\ Instead, we use a technique similar to the old FIG-Forth "smudge", where
\ the name is altered to make it unrecognizable.  "Smudge" was a toggle,
\ which suffered from the problem that sometimes "smudge" would inadvertantly
\ be executed one too many times, thus leaving the word hidden when it
\ should have been visible.  To eliminate this, we use separate words
\ hide and reveal.

: hide-t  ( -- )
   lastanf-s @  name>string drop  dup c@  th 80  or  swap c!
;
: reveal-t  ( -- )
   lastanf-s @  name>string drop  dup c@  th 80  invert and  swap c!
;
: .lastname  ( -- )
   \ This hack gets around the fact that symbol headers are "smudged"
   lastanf-s @ ?dup if  name>string  h# 1f and  bounds  ?do  i c@ h# 7f and emit  loop  then
;

\ "compile-t takes a string and compiles a reference to that word in the
\ target dictionary.  In the case of a forward reference, this may
\ involve creating an entry in the symbol vocabulary.  Even if the
\ word has already been defined, we don't emplace the compilation address
\ yet.  Instead, we just add this location to a linked list of references
\ to the word.  For what its's worth, this makes generating a
\ cross-reference list easy at the end of the metacompilation.

: $compile-t  ( adr len -- )  $findsymbol ( acf ) addlink  ;

\ compile-t is used inside a definition.  It takes an in-line string
\ argument and stores the string somewhere in the definition.  When the
\ definition executes, that string is $compile-t'd.  This allows
\ immediate words to compile run-time words, even if the run-time
\ word hasn't yet been defined in the target system.

\ example : foo   compile-t bar   ;
\ when foo executes, it will then search for the word bar and
\ compile a reference to it.  The STRING bar is stored within foo

: compile-t  \ name  ( -- )
   [compile] [""]  compile count  compile $compile-t
; immediate
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
