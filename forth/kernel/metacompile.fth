\ See license at end of file

forth definitions
vocabulary transition

meta definitions

h# 80 constant metacompiling

\ Non-immediate version which is compiled inside several
\ meta and transition words
: literal-t  ( n -- )  n->l-t compile-t (lit) ,-t  ;

\ vocabularies:
\ transition
\ symbols  \ entries are does> words
\ labels   \ entries are constants
\ meta
\
\ Compiling:  order:  transition symbols labels
\   If found in transition, execute it
\   If found in symbols, execute it
\      If is immediate, complain (should have been in transition)
\   If not found, addlink
\
\ Interpreting: meta
\
: metacompile-do-literal  ( n -- )
   state @  metacompiling =  if
[ifndef] oldhack
      2 =  if  ." oops double number "  cr  source type  cr  drop  then
[then]
      literal-t
   else
      (do-literal)
   then
;

: metacompile-do-defined  ( acf -1 | acf 1 -- )
   drop execute
;
: $metacompile-do-undefined  ( adr len -- ) \ compile a forward reference
   $compile-t
;

\ XXX need to include labels in the search path when interpreting

\ XXX switch search order when going from metacompiling to interpreting
\ and back.
\ 3 states:
\ interpreting is just the normal interpret state, with labels in the search
\ path
\ compiling is just the normal compile state, with labels in the search path
\ metacompiling is the special state.

: meta-base  ( -- )  only forth also labels also meta also   ;
: meta-compile  ( -- )  meta-base definitions  ;
: meta-assemble  ( -- )  meta-base assembler  ;
: extend-meta-assembler  ( -- )  meta-assemble also definitions  ;
: meta-asm[  ( -- )  also meta assembler  ; immediate
: ]meta-asm  ( -- )  previous  ; immediate

variable doestarget

\ "resolves" gives a name to the run-time clause specified by the most-
\ recently-defined "does>" or ";code" word.  A number of defining words
\ assume that their appropriate run-time clause will be resolved with a
\ particular word.  For instance, "vocabulary" refers to a run-time clause
\ called <vocabulary>.  When the run-time code for vocabularies is defined
\ in the kernel source, "resolves" is used to associate its address with
\ the name <vocabulary>.  See the kernel source for examples.

: resolves \ name ( -- )
   doestarget @   safe-parse-word $findsymbol  resolution!
;

\ This is a smart equ which defines words that can be later used
\ inside colon definitions, in which case they will compile their
\ value as a literal.  Perhaps these should be created in the
\ labels vocabulary.

: $equ  ( value adr len -- )
   [ forth ] ['] labels $vcreate , immediate
   does>  \ ( -- value )  or  ( -- )
   @
   [ meta ] state @ metacompiling = if literal-t then
;
: equ  \ name  ( value -- )
   safe-parse-word $equ
;

\ Tools for building control constructs.  The details of the branch
\ target (offset or absolute, # of bytes, etc) are hidden in
\ /branch branch, and branch!  which are defined earlier.

: >mark    (s -- addr ) here-t here-t branch, ;
: >resolve (s addr -- ) here-t branch! ;
: <mark    (s -- addr ) here-t ;
: <resolve (s addr -- ) branch, ;
: ?comp    (s -- ) state @ metacompiling <> abort" compile only" ;

\   "Transition" words.  Versions of compiling words which are defined
\ in the host environment but which compile code into the target
\ environment.
\   Once compiling words are redefined, care must be taken to select
\ the old instance of that word for use in other definitions.  For instance,
\ when "if" is redefined, subsequent definitions will frequently want to use
\ the old "if", so the search order must be explicitly controlled in order
\ to access the old one instead of the new one.

: target  (s -- )  only forth also transition  ; immediate

transition definitions

\ Set the search path to exclude the transition vocabulary so that
\ we can define transition words but still use the normal versions
\ of compiling words like  if  and  [compile]
: host    (s -- )  only forth also meta        ; immediate

\ Transition version of control constructs.

: of      ( [ addresses ] 4 -- 5 )
   host  ?comp  4 ?pairs  compile-t (of)    >mark  5  target
; immediate

: case    ( -- 4 )  host  ?comp  csp @ !csp  4  target  ; immediate
: endof   ( [ addresses ] 5 -- [ one more address ] 4 )
   host  5 ?pairs  compile-t  (endof)   >mark  swap  >resolve  4  target
; immediate
: endcase ( [ addresses ] 4 -- )
   host  4 ?pairs  compile-t (endcase)
   begin  sp@ csp @ <>  while  >resolve  repeat
   csp !
   target
; immediate

: if      host   ?comp  compile-t ?branch >mark        target  ; immediate
: ahead   host   ?comp  compile-t  branch >mark        target  ; immediate
: else    host   ?comp  compile-t  branch >mark
                 swap  >resolve                        target  ; immediate
: then    host   ?comp >resolve                        target  ; immediate

: begin   host   ?comp  <mark                          target  ; immediate
: until   host   ?comp  compile-t ?branch <resolve     target  ; immediate
: while   host   ?comp  compile-t ?branch >mark  swap  target  ; immediate
: again   host   ?comp  compile-t  branch <resolve     target  ; immediate

: repeat  host   ?comp  compile-t branch <resolve >resolve  target  ; immediate

: ?do     host   ?comp  compile-t (?do)    >mark  target  ; immediate
: do      host   ?comp  compile-t (do)     >mark  target  ; immediate
: leave   host   ?comp  compile-t (leave)         target  ; immediate
: ?leave  host   ?comp  compile-t (?leave)        target  ; immediate
: loop    host   ?comp  compile-t (loop)
          dup /branch +  <resolve >resolve        target  ; immediate
: +loop   host   ?comp  compile-t (+loop)
          dup /branch +  <resolve >resolve        target  ; immediate

\ Transition version of words which compile numeric literals
: literal ( n -- )
   host  literal-t  target
; immediate

: ascii  \ string  ( -- char )
   host  bl word 1+ c@ state @  if  literal-t  then  target
; immediate

: control  \ string ( -- char )
   host  bl word 1+ c@ bl 1- and state @  if  literal-t  then  target
; immediate

: [char]  \ string  ( -- char )
   host  bl word 1+ c@ literal-t  target
; immediate

: th  \ string  ( -- n )
   host  base @ >r hex
   parse-word  $handle-literal?  0=  if
      ." Bogus number after th" cr
   then
   r> base !  target
; immediate

: td  \ string  ( -- n )
   host  base @ >r decimal
   parse-word  $handle-literal?  0=  if
      ." Bogus number after td" cr
   then
   r> base !  target
; immediate
alias h# th
alias d# td

\ From now on we start to see familiar words with "-h" suffixes.  These
\ are aliases for the familiar word, used because we have redefined the
\ word to operate in the target environment, but we still need to use the
\ original word.  Rather that having to do [ forth ] foo [ meta ] all the
\ time, we make an alias foo-h for foo.

forth definitions

alias '-h      '
alias [']-h   [']
alias :-h     :
alias ;-h     ;
alias ]-h     ]
alias forth-h forth
alias immediate-h immediate
alias is-h    is

\ Transition versions of tick and bracket-tick.  Forward references
\ are not permitted with tick because there is no way to know how
\ the address will be used.  The mechanism for eventually resolving
\ forward references depends on the assumption that the forward
\ reference resolves to a compilation address that is compiled into
\ a definition.  This assumption doesn't hold for tick'ed words, so
\ we don't allow them to be forward references.

meta definitions
: ' ( -- acf )
   safe-parse-word
   2dup $sfind  if  ( adr len acf )  \ The word has already been seen
       dup resolved?  ( adr len acf flag )
       if   nip  nip  resolution@  ( resolution )  exit   then
       drop
   then               ( adr len adr len  |  adr len )
   type ."  hasn't been defined yet, so ' won't work" cr
   abort
;

: [']-t  \ name ( -- )
   compile-t (')    safe-parse-word  $compile-t
; immediate

: place-t  ( adr len to-t -- )
   2dup + 1+  0 swap c!-t        \ Put a null byte at the end
   2dup c!-t  1+ swap cmove-t
;

\ Emplace a string into the target dictionary
: ,"-t  \ string"  ( -- )  \ cram the string at here
   td 34 ( ascii " ) word count              ( adr len )
   here-t                                    ( adr len here )
   over 2+ note-string-t allot-t  talign-t   ( adr len here )
   place-t
;

transition definitions
: ."      host  compile-t (.")     ,"-t  target  ; immediate
: abort"  host  compile-t (abort") ,"-t  target  ; immediate
: "       host  compile-t (")      ,"-t  target  ; immediate
: p"      host  compile-t ("s)     ,"-t  target  ; immediate

\ Bogus 1024 constant b/buf

meta also assembler definitions
: end-code
   meta-compile
\   current @ context !
;
previous definitions

\ Some debugging words.  Allow the printing of the name of words as they
\ are defined.  threshhold is the number of words that must be defined
\ before any printing starts, and granularity is the interval between
\ words that are printed after the threshhold is crossed.  This is very
\ useful if the metacompiler crashes, because it helps you to locate
\ where the crash occurred.  If needed, start with threshhold = 0 and
\ granularity = 20, then set threshhold to whatever word was printed
\ before the crash and granularity to 1.

forth definitions
variable #words       0 #words !
variable threshold   10000 threshold !
variable granularity 10 granularity !
variable prev-depth  0 prev-depth ! ( expected depth )
: .debug ( -- )
   threshold @ -1 <>  if
      base @  decimal  #words @ 5 .r space  base !
      [ also meta ] .lastname [ previous ]
      depth 0 <> if  space .x  then  cr
   then
;
: ?debug ( -- )
   \ The "2" counts 1 for the flag that was just computed and 1 for the
   \ number of stack entries that we expect to see in the normal course
   \ of compiling values and constants.
   depth  prev-depth @ <>  depth 2 >  and  if
      .debug  depth prev-depth !
   else
      #words @ threshold @ >=
      if  #words @ granularity @ mod
	 0= if  .debug  then
      then
   then
   1 #words +!
;

meta definitions

0 value  lastacf-t	\ acf of the most-recently-created target word

variable show?		\ True if we should show all the symbols
show? off


\ Header control:
\   The kernel can be compiled in 3 modes:
\      always-headers:      All words have headers  (default mode)
\      never-headers:       No words have headers
\      sometimes-headers:   Words have headers unless "headerless" is active

\ -1 : never   0 : always  1 : yes  2 : no

variable header-control   0 header-control !

: headerless  ( -- )  header-control @  0>  if  2 header-control !  then  ;
: headers     ( -- )  header-control @  0>  if  1 header-control !  then  ;

: always-headers     ( -- )   0 header-control !  ;
: sometimes-headers  ( -- )   1 header-control !  ;
: never-headers      ( -- )  -1 header-control !  ;

: make-header?  ( -- flag )  header-control @  0 1 between  ;



: initmeta  ( -- )  initmeta  0 is lastacf-t  ;

variable flags-t

\ Creates a header in the target image
: $really-header-t  (s str -- )
   \ Find the metacompiler's copy of the threads
   2dup current-t @  $hash-t                  ( str thread )

   -rot dup 1+ /link-t +                      ( thread str,len n )
   here-t + dup acf-aligned-t swap - allot-t  ( thread str,len )


   tuck here-t over 1+ note-string-t allot-t  ( thread len str,len adr )
   place-cstr-t  over + c!-t                  ( thread )

\tagvoc-t  here-t 1- dup c@-t h# 80 or swap c!-t
\tagvoc-t  here-t 1- flags-t !

\nottagvoc-t   here-t flags-t !  0 c,-t     \ place the flags byte


   \ get the link to the top word           ( thread )
   dup link-t@                              ( thread top-word )

   \ link the existing list to the new word
   link,-t                                 ( thread )

   \ link the thread to the new word
   here-t swap link-t!


;
: showsym  ( str -- )
   base @ >r hex
   here-t 8 u.r  ( drop )  space type cr
   r> base !
;
: $meta-execute  ( pstr -- )
   ['] labels $vfind  if
      execute
   else
      ['] meta $vfind  if  execute  else   type  ." ?"  abort  then
   then
;
2variable last-header$
: $header-t  (s name$ cf$ -- )   \ Make a header in the target area
   2>r
   2dup last-header$ 2!
   2dup $create-s                            \ symbol table entry
   \ Make header unless headerless
   make-header?  if  2dup $really-header-t  then
   \Tags  $header-t-hook
   acf-align-t
   show? @  if  showsym  else  2drop  then

   here-t is lastacf-t	\ Remember where the code field starts

   here-t  lastacf-s @  resolution!    \ resolve it

   header-control @ 3 and  lastacf-s @ info!

   2r> $meta-execute
;

\ Perform a create for the target system.  This includes making or
\ resolving a symbol table entry.  A partial code field may be generated.

: header-t  \ name  ( name-str -- )
   safe-parse-word 2swap $header-t
;

\ Automatic allocation of space in the user area
variable #user-t
/n constant #ualign-t
: ualigned-t ( n -- n' )  #ualign-t 1- + #ualign-t negate and  ;

: ualloc-t  ( n -- next-user-# )  \ allocate n bytes and leave a user number
   ( #bytes )  #user-t @  over #ualign-t >=  if
      ualigned-t dup #user-t !
   then  ( #bytes user# )

   swap #user-t +!
;

: isconstant  ( acf -- n )  >body-t @-t  ;
: constant  \ name  ( n -- )
   safe-parse-word  3dup $equ
   " constant-cf"  $header-t    s->l-t ,-t
   ['] isconstant setaction    ?debug
;

: iscreate  ( acf -- addr )  >body-t  ;       \ This isn't used
: create  \ name  ( -- )
   " create-cf" header-t
   ['] iscreate setaction    ?debug
;

: isvariable  ( n acf -- )  >body-t !-t  ;
: variable  \ name  ( -- )
   " variable-cf" header-t   0 n->n-t ,-t
   ['] isvariable setaction    ?debug
;

\ isuser is in target.fth
: user  \ name   ( user# -- )
   " user-cf" header-t          n->n-t ,user#-t
   ['] isuser     setaction    ?debug
;
: nuser  \ name  ( -- )
   /n-t ualloc-t user
;

\ istuser is in target.fth
: tuser  \ name  ( -- )
   /token-t ualloc-t user ['] istuser setaction
;

: isauser  ( adr acf -- )  >user-t a-t!  ;
: auser  \ name  ( -- )
   /a-t ualloc-t user ['] istuser setaction
;

\ isvalue  is in target.fth
: value  \ name  ( n -- )
   safe-parse-word  3dup $equ
   " value-cf" $header-t     /n-t ualloc-t  n->n-t  ,user#-t
   lastacf-t  isvalue
   ['] isvalue setaction    ?debug
;
\ : buffer:  \ name  ( size -- )
\    " buffer-cf" header-t
\    /n-t ualloc-t n->n-t ,user#-t	\ user#
\    n->n-t ,-t			\ size
\    here-t  buffer-link-t a-t@  a,-t  buffer-link-t ha-t!
\ ;
: code  \ name  ( -- )
   " code-cf" header-t       entercode  ?debug
;

: $label  ( name$ -- )
   show? @  if  2dup showsym  then
   also labels definitions
   ['] labels $vcreate  here-t ,  immediate-h
   previous definitions
   does> @
   state @  case
      metacompiling of            literal-t  endof
      true          of  [compile] literal    endof
   endcase
;
: label  \ name  ( -- )
   safe-parse-word  2dup  " label-cf" $header-t   entercode  ( name$ )
   $label
;

\ Creates a label that will only exist in the metacompiler;
\ When later executed, the label returns the target address where the
\ label was defined.  No changes are made to the target image as a result
\ of defining the label.

: mlabel  \ name  ( -- )  ( Later:  -- adr-t )
   safe-parse-word  align-t acf-align-t $label
;
: mloclabel  \ name  ( -- )  ( Later:  -- adr-t )
   safe-parse-word  $label
;

: code-field:  \ name  ( -- )
\   label
   mlabel  meta-assemble  entercode
;

\ This vocabulary allocates space for its threads in the user area
\ instead of in the dictionary.  It is therefore ROMable.  The existence
\ of the voc-link in the dictionary does not compromise this, since
\ the voc-link is only written once, when the vocabulary is created.
lvariable voc-link-t
: voc-link,-t  (s -- )
   lastacf-t  voc-link-t @   a,-t
   voc-link-t  !
;
: isvocabulary  ( threads acf -- )
   >user-t  ( threads threadsaddr-t )
   #threads-t 0
   do
      over link-t@ over link-t!  ( threads threadsaddr-t )
      /link-t +   swap  /link-t +  swap
   loop
   2drop
;

: set-threads-t  ( name$ -- )
   " forth"  $=  if
      threads-t  lastacf-t  isvocabulary
   else
      lastacf-t >user-t  clear-threads-t
   then
;

: definitions-t  ( -- )  context-t @ >user-t current-t !  ;

\ If we make several metacompiled vocabularies, we need to initialize
\ the threads with link, to  make them relocatable
: vocabulary  \ name  ( -- )
   safe-parse-word  2dup   " vocabulary-cf" $header-t   ( name )
   \ The 1 extra thread is the "last" field
\nottagvoc-t ( make threads )  #threads-t 1+ /link-t * ualloc-t   ( name$ user# )
\tagvoc-t    ( make threads )  #threads-t /link-t * ualloc-t   ( name$ user# )
   n->n-t ,user#-t                                      ( name$ )
   voc-link,-t                                          ( name$ )
   2dup set-threads-t                                   ( name$ )
   ['] isvocabulary setaction
   ['] meta $vcreate lastacf-t ,
   ?debug
   does> @ context-t !
;
\ /defer-t  is the number of user area bytes to alloc for a deferred word

\ isdefer  is in target.fth
: defer-t  \ name  ( -- )
   " defer-cf" header-t   /defer-t ualloc-t n->n-t ,user#-t
   ?debug
   ['] isdefer setaction
;

: compile-in-user-area  ( -- compilation-base here )
   compilation-base  here-t
   0 dp-t !  userarea-t is compilation-base  \ Select user area
;
: restore-dictionary  ( compilation-base here -- )
   dp-t !  is compilation-base
;

transition definitions
: does>     (s -- )
   host
   compile-t (does>)
   \ XXX the alignment should be done in startdoes; it is incorrect
   \ to assume that acf alignment is sufficient (code alignment might
   \ be stricter).
   align-t acf-align-t here-t doestarget !
   " startdoes" $meta-execute
   target
; immediate

: ;code     (s -- )
   host
   ?csp  compile-t (;code)   align-t  acf-align-t  here-t doestarget !
   " start;code" $meta-execute
   [compile] [  reveal-t  entercode
   target
;  immediate

: [compile]  \ name  ( -- )
   host  safe-parse-word  $compile-t  target
; immediate

meta definitions

\ Initialization of variables, defers, vocabularies, etc.
\ This version is NOT immediate, so it shouldn't be used inside
\ target-compiled colon definitions
: is  \ word  ( ? -- )
   safe-parse-word  $sfind  if        ( acf )
      dup resolution@                 ( acf-s acf-t )
      swap >action token@ execute
   else
      type ." ?" cr
   then
;

only forth also meta also definitions

\ Initialization of variables, defers, vocabularies, etc.
\ This version is immediate, and may be used inside
\ target-compiled colon definitions
: is-t  \ word  ( ? -- )
   compile-t (is)  safe-parse-word $compile-t
; immediate

: metacompile-do-undefined  ( pstr -- ) \ compile a forward reference
   count $compile-t
;

: ]-t  ( -- )
   ['] metacompile-do-defined   is-h do-defined
[ifndef] oldhack
   ['] $metacompile-do-undefined is-h $do-undefined
[else]
   ['] metacompile-do-undefined is-h do-undefined
[then]
   ['] metacompile-do-literal   is-h do-literal
   metacompiling state !
   only forth labels also forth symbols also forth transition
;
: [-t  ( -- )
   [compile] [
   meta-base
; immediate
: ;-t  ( -- )
   ?comp  ?csp  compile-t unnest  reveal-t  [compile] [-t
; immediate

only forth also meta also definitions
: immediate  ( -- )
   flags-t @  th 40 toggle-t       \ fix target header
   immediate-s				\ fix symbol table
;

: iscolon  ( acf -- )
   drop
   ." Colon and code definitions can't be used with IS while metacompiling" cr
;
: :-t  \ name  ( -- )
   !csp  " colon-cf" header-t   hide-t  ]-t   ?debug
   ['] iscolon  setaction
;

\ Turn on the metacompiler by
\ changing the words used by the assembler to store into the dictionary.
\ They should store into the target dictionary instead of the host one.

only forth meta also forth also definitions
: metaon  ( -- )
   meta-compile
   install-target-assembler
;
: metaoff  ( -- )
   forth definitions
   install-host-assembler
;

meta assembler definitions
: 'body   \ name ( -- apf )
  [ meta ]
    '  ( acf-of-variable )
    >body-t
  [ assembler ]
;

meta definitions
alias :   :-t
alias ]   ]-t
alias /n  /n-t
alias /w  /w-t
alias /l  /l-t
alias /a  /a-t
alias #talign #talign-t
alias /token /token-t
alias /link  /link-t
alias ,   ,-t
alias l,  l,-t
alias w,  w,-t
alias c,  c,-t
alias defer  defer-t

alias 16\  16\
alias 32\  32\
alias 64\  64\
alias \itc \itc-t
alias \dtc \dtc-t
alias \t16 \t16-t
alias \t32 \t32-t
alias \tagvoc \tagvoc-t
alias \nottagvoc \nottagvoc-t

alias here   here-t
alias origin origin-t

transition definitions
alias [    [-t
alias ;    ;-t
alias is   is-t
alias [']  [']-t
alias 16\  16\
alias 32\  32\
alias 64\  64\
alias \itc \itc-t
alias \dtc \dtc-t
alias \t16 \t16-t
alias \t32 \t32-t
alias \tagvoc \tagvoc-t
alias \nottagvoc \nottagvoc-t
alias .(   .(
alias (    (
alias (s   (
alias \    \
\ alias iftrue     iftrue
\ alias ifend      ifend
\ alias otherwise  otherwise
\ alias ifdef      ifdef
\ alias ifndef     ifndef
alias [ifdef]  [ifdef]
alias [ifndef] [ifndef]
alias [if]     [if]
alias [else]   [else]
alias [then]   [then]

only forth also meta assembler definitions
alias .(   .(
alias (    (
alias (s   (
alias \    \

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
