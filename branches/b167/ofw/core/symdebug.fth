\ See license at end of file
purpose: Symbolic debugging extensions

\
\ initsyms  ( adr len -- )
\	Initializes the symbol table.  adr is the address of the header
\	of a memory image of an a.out file, and len is the length of the
\	file.
\
\ <symname>  ( -- value )
\	Typing the name of a symbol leaves its value on the stack
\
\ >sym	( value -- offset symnane )
\	symname is a packed string which is the name of the symbol whose
\	value is closest to, but not greater than, "value" .  Offset
\	is the positive difference between value and the symbol's value.
\
\ The disassembler is modified so that disassembled addresses are displayed
\ symbolically.
\
\ spread  ( -- distance )
\	A value which controls the symbolic display of disassembled
\	addresses.  If the distance from the address to the nearest smaller
\	symbol is less then the spread value , the address will be
\	displayed as "symname+offset"; otherwise just the address
\	will be displayed.  The initial value of spread is hex 1000 (4K).

\ needs a.out-header  ../sun/aout.fth
\ needs /sym  ../unix/nlist.fth

headerless
0 value strings
0 value /strings
0 value symbols
0 value /symbols
0 value symbol-offset  \ For use when the program is loaded at the wrong place

defer >string
defer >value
defer >sym_type

0 value /symtab-entry  

[ifdef] /aout-symbol
0 value fileaddr  \ Holds addr where file is copied, starting w/ text seg.

: syms@  ( -- symbol-table-addr )  fileaddr syms0 +  ;
: strings@  ( -- strings-addr )  fileaddr string0 +  ;

: >a.out-sym_strx  ( sym-entry -- cstr )  sym_strx l@  strings +  ;
: >a.out-sym_value  ( sym-entry -- symbol-address )  sym_value l@  symbol-offset -  ;
: >a.out-sym_type  ( sym-etry --  valid-sym? )  sym_type c@  4 9 between  ;

' >a.out-sym_strx   is >string
' >a.out-sym_value  is >value
' >a.out-sym_type   is >sym_type

/aout-symbol to /symtab-entry
[then]

: all-syms  ( -- end-syms start-syms )  symbols /symbols  bounds  ;

: $sym>entry  ( adr,len -- sym-entry true | adr,len false )
   /symbols   if                          ( adr,len )
      all-syms  do                        ( adr,len )
	 2dup  i >string cscount  $=  if  ( adr,len )
	    2drop  i true  unloop exit    ( sym-entry true )
         then	                          ( adr,len )
      /symtab-entry +loop                 ( adr,len )
   then                                   ( adr,len )
   false                                  ( adr,len false )
;
: $sym>  ( adr,len -- sym-value true | adr,len false )
   $sym>entry  if  >value  true  else  false  then
;

0 value min-sym  \ Holds closest ( <= ) symbol to last .adr
0 value max-sym  \ Holds closest ( >  ) symbol to last .adr
0 value target  \ Holds address being symbolized
h# 1000 value spread   \ Maximum allowed displacement

: ubetween  ( val min max -- )  >r over u<=  swap r> u<=  and ;
: already-within?  ( -- flag )  \ Do previous saved values bracket target?
    max-sym  if
      target  min-sym >value   max-sym >value 1-  ubetween
    else false   \ Don't try it if uninitialized or at max memory
    then
;
: compute-limits  ( oldmin oldmax testsym -- min' max' )
    dup >value >r  -rot  ( testsym min max ) ( rs: testval )
    2dup r@ -rot  ubetween  ( testsym min max between? ) ( rs: testval )
    if r@ target u>   ( testsym min max new-max? )  ( rs: testval )
      if   drop  swap is max-sym  r>   ( min max' )
      else nip   swap is min-sym  r> swap  ( min' max )
      then
    else  rot r> 2drop
    then
;
: find-nearest  ( -- )   \ Min-sym points to final selection
    symbols is min-sym   0 is max-sym
    0  -1  \ Starting min, max values
    all-syms do   ( min max )
       \
       i >sym_type  if  i  compute-limits  then
    /symtab-entry +loop    ( min max )
    2drop
;

headerless
0 value name-to-value  ( -- name-to-value-func )
0 value value-to-name  ( -- value-to-name-func )

: >sym  ( addr -- offset adr len )
    symbol-offset +  is target     ( )
    already-within?  0= if  find-nearest  then
    target  min-sym >value  -  ( offset )
    dup spread u<  if   \ Only print if offset isn't too big
      min-sym >string  cscount  ( offset adr len )
    else
      drop target 0 0
    then
;
: .offset ( offset -- )
   5  swap  ?dup  if                          ( len offset )
      ." +"  base @ >r  hex (u.)  r> base !   ( len adr,len )
      tuck type - 1-                          ( len' )
   then  1 max spaces
;

headers
\ User word to print nearest symbol for 'addr'
: 8u.h  ( n -- )  push-hex  (.8) type  pop-base  ;

: .adr  ( addr -- )
   dup origin  u>=  if  8u.h  exit  then
   dup   /symbols if  >sym  else  0 0  then  ( addr offset adr len )
   dup  if                              ( addr offset adr len )
      \ Display  name[+offset]  if name is not null
      2swap >r  8u.h  space  type  r> .offset  exit
   then  3drop
                   ( addr )

   dup >r  do-value-to-sym  if   ( offset adr,len ) ( r: addr )
      r> 8u.h space  type .offset  exit
   else                          ( addr ) ( r: addr )
      r>  drop                   ( addr )
   then                          ( addr )

   value-to-name  if	            ( addr )
      value-to-name  call32	    ( addr retval )
      dup l@ l->n -1 <>  if         ( addr retval )
	 swap 8u.h space            ( retval )
	 dup l@ swap la1+ cscount   ( offset name,len )
	 type  .offset  exit        (  )
      then  drop                    ( addr )
   then	                            ( addr )

   \ No symbolic info available display as number
   8u.h
;

headerless
0 value prev-n2v
0 value prev-v2n
headers

: set-symbol-lookup  (  n2v v2n -- old-n2v  old-v2n )
   name-to-value value-to-name 2swap    ( old-n2v old-v2n  n2v v2n )
   is value-to-name is name-to-value    ( old-n2v old-v2n )
   0 to prev-n2v  0 to prev-v2n         ( old-n2v old-v2n )
;

warning @ warning off
: symbol-lookup-off ( -- )
   symbol-lookup-off
   name-to-value ?dup  if  to prev-n2v  then
   value-to-name ?dup  if  to prev-v2n  then
   0 to name-to-value  0 to value-to-name
;
: symbol-lookup-on ( -- )
   symbol-lookup-on
   prev-n2v ?dup  if  to name-to-value  then
   prev-v2n ?dup  if  to value-to-name  then
;
warning !

headerless
: $sym-handle-literal?  ( adr,len -- handled? )
   2dup 2>r ($handle-literal?)  if  ( r: adr,len )
      2r> 2drop true  exit
   then  2r>                        ( adr,len )

   $sym>  if  1  do-literal true  exit  then

   do-sym-to-value  if  1 do-literal  true  exit  then

   name-to-value  if                     ( adr,len )
      encode-string over here - allot    ( encoded$ )
      drop  name-to-value  call32  nip   ( retval )
      dup l@ l->n  if                    ( retval )
	 drop false                      ( false )
      else                               ( pstr retval )
	 la1+  l@  1 do-literal  true    ( true )
      then  exit                         ( flag )
   then  2drop false 		         ( false )
;
' $sym-handle-literal?  is $handle-literal?

[ifdef] allocate-symtab
[ifdef] /aout-symbol
: copysyms  ( dst-adr -- )
   is symbols
   symbols /symbols +  is  strings
   syms@     symbols  /symbols  move
   strings@  strings  /strings  move
;
\ Another way to calculate "/strings":
\ : /strings  ( -- n )  /syms  if  strings@ @  else  0  then  ;

: (initsyms)  ( file-adr file-size -- )
   swap is fileaddr  ( file-size )
   /text - /data - /reloc - /syms -  is /strings  ( )
   syms@ is symbols  strings@ is strings  /syms is /symbols
   ['] $sym-handle-literal? is $handle-literal?
   /symbols /strings +  allocate-symtab  ( adr )  copysyms

\ XXX What we really need to do:
\   compact the symbol table by removing the boring names (e.g.
\   sccsid) and the boring symbols (e.g. constant names, file names)
\   At the same time, extract the corresponding names into a
\   different area of memory, changing the pointers to 16 bit
\   shifted pointers, and eliminating the type fields.
\   allocate some virtual memory in the monitor's region.
\   allocate physical memory, removing it from the piece list
\   copy the symbol table into that memory
;

headers
: initsyms  ( file-adr file-size -- )
   over a.out-header  /a.out-header  move  ( file-adr file-size )
   ['] >a.out-sym_strx   is >string
   ['] >a.out-sym_value  is >value
   ['] >a.out-sym_type   is >sym_type
   /aout-symbol to /symtab-entry
   (initsyms)
;
[then]
[then]

\ Patch symbolic debugger into disassembler
\ also disassembler
' .adr  is showaddr	\ For disassembler
' .adr  is .subname	\ For ctrace
\ only forth also definitions
headers
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
