\ See license at end of file
\ Copyright 2006 Firmworks  All Rights Reserved

\ From io.fth

decimal

\ Emit is a two-level vector.
\ The low level is (emit and the high level is emit.
\ The low-level vector just selects the output device.
\ The high-level vector performs other processing such as keeping
\ track of the current position on the line, pausing, etc.
\ Terminal control with escape sequences should use the low-level vector
\ to prevent a pause from garbling the escape sequence.
\ Key is a two-level vector.
\ The low level is (key and the high level is key.
\ The low-level vector just selects the output device.
\ The high-level vector performs other processing such as switching
\ the input stream between different windows.

defer (type  ( adr len -- ) \ Low-level type; just outputs characters
defer type   ( adr len -- ) \ High-level type
defer (emit ( c -- )   \ Low level emit; just puts out the character
defer emit  ( c -- )   \ Higher level; keeps track of position on the line, etc
defer (key  ( -- c )   \ Low level key; just gets key
defer key   ( -- c )   \ Higher level; may do other nonsense
defer key?   ( -- f )   \ Is a character waiting?
defer bye    ( -- )     \ Exit to the operating system, if any
defer error-exit  ( -- )  \ Error exit to the operating system
defer (interactive? ( -- f ) \ Is input coming from the keyboard?
defer interactive? ( -- f ) \ Is input coming from the keyboard?
' (interactive? is interactive?

defer accept  ( adr len -- )	\ Read up to len characters from keyboard

defer alloc-mem  ( #bytes -- address )
defer free-mem   ( adr #bytes -- )
defer resize     ( adr #bytes -- adr' ior )

defer sync-cache  ( adr len -- )  ' 2drop is sync-cache
defer $getenv     ( adr len -- false | adr' len' true )

defer #out   ( -- adr )
defer #line  ( -- adr )
defer cr     ( -- )

\ Default actions
: key1  ( -- char )  begin  pause key?  until  (key  ;
: emit1  ( char -- )  pause (emit 1 #out +!  ;
: type1  ( adr len -- )  pause  dup #out +!  (type  ;
: default-type  ( adr len -- )
   0 max  bounds ?do  pause  i c@ (emit  loop
;
: null-$getenv  ( adr len -- true )  2drop true  ;

\ headerless		\ from campus version
nuser (#out        \ number of characters emitted
\ headers		\ from campus version
nuser (#line       \ the number of lines sent so far

\ Install defaults
' emit1       is emit
' type1       is type
' key1        is key
' (#out       is #out
' (#line      is #line
' null-$getenv  is $getenv

decimal

 7 constant bell
 8 constant bs
10 constant linefeed
13 constant carret

\ Obsolescent, but required by the IEEE 1275 device interface
nuser span			\ number of characters received by expect
: expect  ( adr len -- )  accept span !  ;

defer newline-pstring
: newline-string  ( -- adr len )  newline-pstring count  ;
: newline  ( -- char )  newline-string + 1-  c@  ; \ Last character

: space  (s -- )   bl emit   ;
: spaces   (s n -- )   0  max  0 ?do  space  loop  ;
: backspaces  (s n -- )  dup negate #out +!  0 ?do bs (emit loop  ;
: beep  (s -- )  bell (emit  ;
: (lf  (s -- )  1 #line +!  linefeed (emit  ;
: (cr  (s -- )  carret (emit  ;
: lf   (s -- )  #out off  (lf  ;
: crlf   (s -- )  (cr lf  ;

0 value tib

0 value #-buf
headerless
: init  ( -- )  init
   [ /n h# 10 * 8 + ] literal dup alloc-mem + is #-buf
   /tib    alloc-mem   is tib
;
headers

nuser base         \ for numeric input and output

nuser hld          \ points to last character held in #-buf
: hold   (s char -- )   -1 hld +!   hld @ c!   ;
: <#     (s -- )     #-buf  hld  !  ;
: sign   (s n -- )  0< if  ascii -  hold  then  ;
\ for upper case hex output, change 39 to 7
: >digit (s n -- char )  dup 9 >  if  39 +  then  48 +  ;
: u#     (s u1 -- u2 )
   base @ u/mod  ( nrem u2 )   swap  >digit  hold    ( u2 )
;
: u#s    (s u -- 0 )     begin  u#  dup   0=  until  ;
: u#>    (s u -- addr len )    drop  hld  @  #-buf  over  -  ;

: mu/mod (s d n1 -- rem d.quot )
   >r  0  r@  um/mod  r>  swap  >r  um/mod  r>
;

: #      (s ud1 -- ud2 )
   base @ mu/mod ( nrem ud2 )  rot     >digit  hold    ( ud2 )
;
: #s     (s ud -- 0 0 )  begin   #  2dup or  0=  until  ;
: #>     (s ud -- addr len )     drop  u#>  ;

: (u.)  (s u -- a len )  <# u#s u#>   ;
: u.    (s u -- )       (u.)   type space   ;
: u.r   (s u len -- )     >r   (u.)   r> over - spaces   type   ;
: (.)   (s n -- a len )   dup abs  <# u#s   swap sign   u#>   ;
: s.    (s n -- )       (.)   type space   ;
: .r    (s n l -- )     >r   (.)   r> over - spaces   type   ;
: 0.r   (s n l -- )     >r (u.) r> over - 0 max  0  ?do  ascii 0 emit  loop  type ;

: (.2)  (s u -- a len )  <# u# u# u#>   ;
: (.4)  (s u -- a len )  <# u# u# u# u# u#>   ;
: (.8)  (s u -- a len )  <# u# u# u# u# u# u# u# u# u#>   ;
: .2   (s n -- )   (.2)  type space  ;

[ifndef] run-time
headerless
: (ul.) (s ul -- a l )  n->l  <# u#s u#>   ;
headers
: ul.   (s ul -- )      (ul.)   type space   ;
headerless
: ul.r  (s ul l -- )    >r   (ul.)   r> over - spaces   type  ;

: (l.)  (s l -- a l )   dup l->n lnswap  labs   <# u#s   nlswap sign  u#>   ;
headers
: l.    (s l -- )       base @ d# 10 = if (l.) else (ul.) then type space   ;
headerless
: l.r   (s l l -- )     >r   (l.)   r> over - spaces   type   ;
headers
[then]

\ smart print that knows that signed hex numbers are uninteresting
: .    (s n -- ) base @ 10 = if s. else u. then  ;
: n.   (s n -- ) base @ 10 = if s. else u. then  ;
\ : .     (s n -- )       (.)   type space   ;
: ?     (s addr -- )    @  n.  ;

: (.s        (s -- )
   depth 0 ?do  depth i - 1- pick n.  loop
;
: .s         (s -- )
   depth 0<
   if   ." Stack Underflow "  sp0 @ sp!
   else depth
        if (.s else ." Empty " then
   then
;
: ".  (s pstr -- )  count type  ;

\ From stresc.fth

\ These words use the string-scanning routines to get strings out of
\ the input stream.

\ ",  --> given string, emplace the string at here and allot space
\ ,"  --> accept a "-terminated string and emplace it.
\ "   --> accept a "-terminated string and leave addr len on the stack
\ ""  --> accept a blank delimited string and leave it's address on the stac
\ [""]--> accept a blank delimited string and emplace it.
\         At run time, leave it's address on the stack

\  The improvements allow control characters and 8-bit binary numbers to
\  be embedded into string literals.  This is similar in principle to the
\  "\n" convention in C, but syntactically tuned for Forth.
\
\  The escape character is '"'.  Here is the list of escapes:
\
\     ""	"
\     "n	newline
\     "r	carret
\     "t	tab
\     "f	formfeed
\     "l	linefeed
\     "b	backspace
\     "!	bell
\     "^x	control x, where x is any printable character
\     "(HhHh)   Sequence of bytes, one byte for each pair of hex digits Hh
\               Non-hex characters will be ignored
\
\     "<whitespace> terminates the string, as usual
\
\     " followed by any other printable character not mentioned above is
\          equivalent to that character.
\
\  This new syntax is completely backwards compatible with old code, since
\  the only legal previous usage was "<whitespace>
\
\  Contrived example:
\
\  	" This is "(01,328e)"nA test xyzzy "!"! abcdefg""hijk"^bl"
\
\                   ^^^^^^  ^              ^ ^         ^     ^
\                  3 bytes  newline      2 bells       "     control b
\
\  The "(HhHhHhHh) should come in particularly handy.
\
\  Note: "n (newline) happens to be the same as "l (linefeed) under Unix,
\  but this is not true for all operating systems.


[ifndef] run-time
0 value "temp
headerless
d# 1024 1+ /n-t +  aligned-t  constant /stringbuf  \ 1024 bytes + /n for length + 1 for null
0 value stringbuf
0 value $buf
: init  ( -- )
   init
   /stringbuf 2* alloc-mem dup is stringbuf  is "temp
   /stringbuf alloc-mem is $buf
;

headers
: switch-string  ( -- )
   stringbuf  dup "temp =  if  /stringbuf +  then  is "temp
;

: npack  (s str-addr len to -- to )
   tuck !                  ( str-adr to )
   tuck ncount move        ( to )
   0  over ncount +  c!    ( to )
;

: $nsave  ( adr1 len1 adr2 -- adr2 len1 )  npack ncount  ;

: $ncat  ( adr len  npstr -- )  \ Append adr len to the end of npstr
   >r  r@ ncount +     ( adr len end-adr )  ( r: npstr )
   swap dup >r         ( adr endadr len )  ( r: npstr len )
   cmove  r> r>        ( len npstr )
   dup @ rot + over !  ( npstr )
   ncount +  0 swap c! \ Null-terminate the end for later convenience
;


: $save  ( adr1 len1 adr2 -- adr2 len1 )  pack count  ;

: $cat  ( adr len  pstr -- )  \ Append adr len to the end of pstr
   >r  r@ count +   ( adr len end-adr )  ( r: pstr )
   swap dup >r      ( adr endadr len )  ( r: pstr len )
   cmove  r> r>     ( len pstr )
   dup c@ rot + over c!  ( pstr )
   count +  0 swap c!     \ Always keep a null terminator at the end
;

headerless
: add-char  ( char -- )  $buf ncount + c!  $buf @ 1+ $buf !  ;

: nextchar  ( adr len -- false | adr' len' char true )
   dup  0=  if  nip exit  then   ( adr len )
   over c@ >r  swap 1+ swap 1-  r> true
;

: nexthex  ( adr len -- false | adr' len' digit true )
   begin
      nextchar  if         ( adr' len' char )
	 d# 16 digit  if   ( adr' len' digit )
	    true true      ( adr' len' digit true done )
	 else              ( adr' len' char )
	    drop false     ( adr' len' notdone )
	 then              ( adr' len' digit true done | adr' len' notdone )
      else                 (  )
	 false true        ( false done )
      then
   until
;
: get-hex-bytes  ( -- )
   ascii ) parse                    ( adr len )
   caps @  if  2dup lower  then     ( adr len )
   begin  nexthex  while            ( adr' len' digit1 )
      >r  nexthex  0= ( ?? ) abort" Odd number of hex digits in string"
      r>                            ( adr'' len'' digit2 digit1 )
      4 << +  add-char              ( adr'' len'' )
   repeat
;
\ : get-char  ( -- char )  input-file @ fgetc  ;
: get-char  ( -- char|-1 )
   source  >in @  /string  if  c@  1 >in +!  else  drop -1  then
;

headers
: get-escaped-string  ( -- adr len )
   0 $buf !
   begin
      ascii " parse   $buf $ncat
      get-char  dup bl <=  if  drop $buf ncount exit  then  ( char )
      case
         ascii n of  newline            add-char  endof
         ascii r of  carret             add-char  endof
         ascii t of  control I          add-char  endof
         ascii f of  control L          add-char  endof
         ascii l of  linefeed           add-char  endof
         ascii b of  control H          add-char  endof
         ascii ! of  bell               add-char  endof
         ascii ^ of  get-char h# 1f and add-char  endof
         ascii ( of  get-hex-bytes                endof
         ( default ) dup                add-char
      endcase
   again
;

: .(  \ string)  (s -- )
   ascii ) parse type
; immediate

\ : (   \ string  (s -- )  \ Skips to next )
\    ascii ) parse 2drop
\ ; immediate
[then]

: ",    (s adr len -- )
   dup 2+ taligned  here swap  note-string  allot  place
;

: n",    (s adr len -- )
   dup 1+ na1+ taligned  here swap  note-string  allot  nplace
;

[ifndef] run-time
: ,"  \ string"  (s -- )
   get-escaped-string  ",
;

: ."  \ string"  (s -- )
   +level compile (.")   ," -level
; immediate

: compile-string  ( adr len -- )
   state @  if
      dup  d# 255 >  if
         compile (n") n",
      else
         compile (") ",
      then
   else
      switch-string "temp $nsave
   then
;
: s"  \ string   (s -- adr len )
   ascii " parse compile-string
; immediate

: "   \ string"  (s -- adr len )
   get-escaped-string compile-string
; immediate

: [""]  \ word  (s Compile-time: -- )
        (s Run-time: -- pstr )
   compile ("s)  safe-parse-word ",
; immediate

\ Obsolete
: ["]   \ string"  (s -- str )
   compile ("s)    ,"
; immediate

: \  \ rest-of-line  (s -- )      \ skips rest of line
   -1 parse 2drop
; immediate

: compile-pstring  ( adr len -- )
   state @  if
      compile ("s) ",
   else
      switch-string "temp npack
   then
;
: ""   \ name  ( -- pstr )
   safe-parse-word  compile-pstring
; immediate

: p"   \ string"  ( -- pstr )
   get-escaped-string  compile-pstring
; immediate

: c"   \ string"  ( -- pstr )
   ascii " parse  compile-pstring
; immediate
[then]

create nullstring 0 c, 0 c,

\ Words for copying strings
\ Places a series of bytes in memory at to as a packed string
: place     (s adr len to-adr -- )  pack drop  ;
: nplace    (s adr len to-adr -- )  npack drop  ;

: place-cstr  ( adr len cstr-adr -- cstr-adr )
   >r  tuck r@ swap cmove  ( len ) r@ +  0 swap c!  r>
;

: even      (s n -- n | n+1 )  dup 1 and +  ;

\ Nullfix
: +str  (s pstr -- adr )     count + 1+ taligned ;

: +nstr  (s pstr -- adr )     ncount + 1+ taligned ;

\ Copy a packed string from "from-pstr" to "to-pstr"
: "copy (s from-pstr to-pstr -- )      >r count r> place ;

\ Copy a packed string from "from-pstr" to "to-pstr", returning "to-pstr"
: "move (s from-pstr to-pstr -- to-pstr )   >r count r> pack  ;

\ : count      (s adr -- adr+1 len )  dup 1+   swap c@   ;
: /string  ( adr len cnt -- adr' len' )  tuck - -rot + swap  ;

: printable?  ( n -- flag ) \ true if n is a printable ascii character
   dup bl th 7f within  swap  th 80  th ff  between  or
;
: white-space? ( n -- flag ) \ true is n is non-printable? or a blank
   dup printable? 0=  swap  bl =  or
;

: -leading  ( adr len -- adr' len' )
   begin  dup  while   ( adr' len' )
      over c@  white-space? 0=  if  exit  then
      swap 1+ swap 1-
   repeat
;

: -trailing  (s adr len -- adr len' )
   dup  0  ?do   2dup + 1- c@   white-space? 0=  ?leave  1-    loop
;

: upper  (s adr len -- )  bounds  ?do i dup c@ upc swap c!  loop  ;
: lower  (s adr len -- )  bounds  ?do i dup c@ lcc swap c!  loop  ;

nuser caps
: f83-compare  (s adr adr2 len -- -1 | 0 | 1 )
   caps @  if  caps-comp  else  comp  then
;
headers
\ Unpacked string comparison
: +-1  ( n -- -1|0|+1 )  0< 2* 1+  ;
: compare  (s adr1 len1 adr2 len2 -- same? )
   rot 2dup 2>r min             ( adr1 adr2 min-len )  ( r: len2 len1 )
   comp dup  if                 ( +-1 )
      2r> 2drop                 ( +-1 )  \ Initial substrings differ
   else                         ( 0 )
      drop  2r> -               ( diff ) \ Initial substrings are the same
      \ This is tricky.  We want to convert zero to zero, positive
      \ numbers to -1, and negative numbers to +1.  Here's how it works:
      \ "dup  if  ..  then" leave 0 unchanged, and nonzero number are
      \ transformed as follows:
      \       +n  -n
      \ 0>    -1   0
      \ 2*    -2   0
      \ 1+    -1   1
      dup  if  0> 2* 1+  then
   then
;
\ $= can be defined as "compare 0=", but $= is used much more often,
\ and doesn't require all the tricky argument fixups, so it makes
\ sense to define $= directly, so it runs quite a bit faster.
: $=  (s adr1 len1 adr2 len2 -- same? )
   rot tuck  <>  if  3drop false exit  then   ( adr1 adr2 len1 )
   comp 0=    
;

\ From comment.fth

\ Comments that span multiple lines

\ Turn this variable on to make long comments apply to the keyboard too.
\ This is useful for cutting and pasting bits of code into a Forth
\ system.
variable long-comments
: (  \ "comments)"  ( -- )
   begin
      >in @  [char] ) parse       ( >in adr len )
      nip +  >in @  =             ( delimiter-not-found? )
      long-comments @  source-id  -1 0 between  0=  or  and  ( more? )
   while                          ( )
      refill  0=
   until  then
; immediate

\ From catchsel.fth

\ Special version of catch and throw for Open Firmware.  This version
\ saves and restores the "my-self" current package instance variable.

0 value my-self

nuser handler   \ Most recent exception handler

: catch  ( execution-token -- error# | 0 )
                        ( token )  \ Return address is already on the stack
   sp@ >r               ( token )  \ Save data stack pointer
   my-self >r           ( token )  \ Save current package instance handle
   handler @ >r         ( token )  \ Previous handler
   rp@ handler !        ( token )  \ Set current handler to this one
   execute              ( )        \ Execute the word passed in on the stack
   r> handler ! ( )                \ Restore previous handler
   r> drop              ( )        \ Discard saved package instance handle
   r> drop              ( )        \ Discard saved stack pointer
   0                    ( 0 )      \ Signify normal completion
;

: throw  ( ??? error# -- ??? error# )  \ Returns in saved context
   dup  0=  if  drop exit  then        \ Don't throw 0
   handler @ rp!        ( err# )       \ Return to saved return stack context
   r> handler !         ( err# )       \ Restore previous handler
   r> is my-self        ( err# )       \ Restore package instance handle
                        ( err# )       \ Remember error# on return stack
                        ( err# )       \ before changing data stack pointer
   r> swap >r           ( saved-sp )   \ err# is on return stack
   sp! drop r>          ( err# )       \ Change stack pointer
   \ This return will return to the caller of catch, because the return
   \ stack has been restored to the state that existed when CATCH began
   \ execution .
;

\ From kernel2.fth

\ Kernel colon definitions
decimal
 0 constant 0     1 constant 1      2 constant 2      3 constant 3
 4 constant 4     5 constant 5      6 constant 6      7 constant 7
 8 constant 8
-1 constant true  0 constant false
32 constant bl
\ 64 constant c/l

: bounds  (s adr len -- adr+len adr )  over + swap  ;

: roll    (s nk nk-1 ... n1 n0 k -- nk-1 ... n1 n0 nk )
   >r  r@ pick   sp@ dup  na1+
   r> 1+ /n*
   cmove> drop
;

: 2rot  (s a b c d e f -- c d e f a b )  5 roll  5 roll  ;

: ?dup   (s n -- [n] n )  dup if   dup   then   ;
: between (s n min max -- f )  >r over <= swap r> <= and  ;
: within  (s n1 min max+1 -- f )  over -  >r - r> u<  ;
 
: erase      (s adr len -- )   0 fill   ;
: blank      (s adr len -- )   bl fill   ;
: pad        (s -- adr )       here 300 +   ;
: depth      (s -- n )         sp@ sp0 @ swap - /n /   ;
: clear      (s ?? -- Empty )  sp0 @ sp!  ;

: hex        (s -- )   16 base !  ;
: decimal    (s -- )   10 base !  ;
: octal      (s -- )    8 base !  ;
: binary     (s -- )    2 base !  ;

: ?enough   (s n -- )  depth 1- >   ( -4 ) abort" Not enough Parameters"  ;

hex
ps-size-t constant ps-size
rs-size-t constant rs-size

: dump-chars  ( adr -- )
   h# 10  bounds  do
     i c@  dup  bl h# 80 within  if  emit  else  drop ." ."  then
   loop
;
: bdump  (s adr len -- )
   base @ >r  hex
   bounds  ?do
      i 8 u.r  ." : "  i  h# 10  bounds  do
         i /l bounds  do  i c@ .2  loop  space
      /l +loop
      i  dump-chars
      cr
   h# 10 +loop
   r> base !
;
: wdump  (s adr len -- )
   base @ >r  hex
   bounds  ?do
      i 8 u.r  ." : "  i  h# 10  bounds  do
         i w@ 4 u.r space space
      /w +loop
      i  dump-chars
      cr
   h# 10 +loop
   r> base !
;
: ldump  (s adr len -- )
   base @ >r  hex
   bounds  ?do
      i 8 u.r  ." : "  i  h# 10  bounds  do
         i l@ 8 u.r space space
      /l +loop
      i  dump-chars
      cr
   h# 10 +loop
   r> base !
;


: abort  (s ?? -- )  mark-error  -1 throw  ;

\ Run-time words used by the compiler; also used by metacompiled programs
\ even if the interactive compiler is not present

nuser abort"-adr
nuser abort"-len
nuser show-aborts
: set-abort-message  ( adr len -- )
   show-aborts @  if  ." Abort: " 2dup type cr  then
   abort"-len !  abort"-adr !  mark-error
;
: abort-message  ( -- adr len )  abort"-adr @  abort"-len @  ;
: (.")  (s -- )           skipstr type  ;
: $abort  ( adr len -- )  set-abort-message  -2 throw  ;
: (abort")   (s f -- )
   if  skipstr $abort  else  skipstr 2drop  then
;
: ?throw  ( flag throw-code -- )  swap  if  throw  else  drop  then  ;
: ("s)  (s -- str-addr )  skipstr  ( addr len )  drop 1-  ;

nuser 'lastacf         \ acf of latest definition
: lastacf  ( -- acf )  'lastacf token@  ;

\ [ifndef] round-down
: round-down  ( adr granularity -- adr' )  1- invert and  ;
\ [then]
: round-up  ( adr granularity -- adr' )  1-  tuck +  swap invert and  ;
: (align)  ( size granularity -- )
   1-  begin  dup here and  while  0 c,  repeat  drop
;

\ From compiler.fth

hex

nuser state        \ compilation or interpretation
nuser dp           \ dictionary pointer

\ This can't use token@ and token! because the dictionary pointer
\ needs to temporarily contain odd byte offset because of c,
: here  (s -- addr )  dp @  ;

fffffffc value limit
: unused  ( -- #bytes )  limit here -  ;

defer allot-error
: allot  (s n -- )
   dup pad + d# 100 + limit  u>  if  allot-error  then
   dup  dp +!   ( n )
   dup 0<  if	\ Clear relocation bitmap if alloting a negative amount
      here swap negate clear-relocation-bits
   else
      drop
   then
;

[ifdef] run-time

:-h immediate ( -- )
\ Don't fix the target header because there isn't one!
\   lastacf-t @ 1-  th 40 toggle-t       \ fix target header
   \ We can't do this with immediate-h because the symbol we need to make
   \ immediate isn't necessarily the last one for which a header was
   \ created.  It could have been a forward reference, with the header
   \ created long ago.
   lastacf-s @ >flags  th 40 toggle        \ fix symbol table
;-h

: allot-abort  (s size -- size )
   ." Dictionary overflow - here "  here .  ." limit " limit .  cr
   ( -8 ) abort
;

[else]

: allot-abort  (s size -- size )
   ." Dictionary overflow - here "  here .  ." limit " limit .  cr
   ( -8 ) abort
;

[then]

' allot-abort is allot-error

: ,      (s n -- )       here   /n allot   unaligned-!   ;
: c,     (s char -- )    here  dup set-swap-bit  /c allot   c!   ;
: w,     (s w -- )       here   /w allot   w!   ;
: l,     (s l -- )       here   /l allot   unaligned-l!   ;
64\ : x,     (s x -- )       here   /x allot   unaligned-!   ;
[ifdef] big-endian-t
: d,     (s d -- )       here   2 /n* allot   2!   ;
[else]
: d,     (s d -- )       swap , ,   ;
[then]

: compile,  (s cfa -- )  token, ;
: compile  (s -- )   ip> dup ta1+ >ip   token@ compile,  ;

: ?pairs  (s n1 n2 -- )   <>  ( -22 ) abort" Control structure mismatch" ;

[ifndef] run-time

\ Compiler and state error checking
: ?comp   (s -- )  state @  0= ( -14 ) abort" Compilation Only " ;
: ?exec   (s -- )  state @     ( -29 ) abort" Execution Only " ;

: $defined   (s -- adr len 0 | xt +-1 )  safe-parse-word $find  ;
: $?missing  ( +-1 | adr len 0 -- +-1 )
   dup 0=  if  drop  .not-found  ( -13 ) abort  then
;
: 'i  ( "name" -- xt +-1 )  $defined $?missing  ;
: literal     (s n -- )
\t16   dup -1  h# fffe  between  if
\t16      compile (wlit) 1+ w,
\t16   else
\t16      compile  (lit)  ,
\t16   then

64\ \t32   dup -1 h# 0.ffff.fffe n->l between  if
64\ \t32      compile (llit) 1+ l,
64\ \t32   else
    \t32      compile (lit) ,
64\ \t32   then
;  immediate
: lliteral  (s l -- )  compile (llit) l,  ; immediate
: dliteral  (s l -- )  compile (dlit) d,  ; immediate

: safe-parse-word  ( -- adr len )
   parse-word dup 0=  ( -16 ) abort" Unexpected end-of-line"
;
: char  \ char (s -- n )
   safe-parse-word drop c@
;
: [char]  \ char  (s -- )
   char  1 do-literal
; immediate
: ascii  \ char (s -- n )
   char  1 do-literal
; immediate
: control  \ char  (s -- n )
   char  bl 1- and  1 do-literal
; immediate

: '   \ name  (s -- cfa )
   'i drop
;
: [']  \ name  (s -- )  ( Run time: -- acf )
   +level ' compile (') compile, -level
; immediate
: [compile]  \ name  (s -- )
   ' compile,
; immediate
: postpone  \ name  (s -- )
   'i  0<  if  compile compile  then  compile,
; immediate

: recurse  (s -- )  lastacf compile,  ; immediate

\ : dumpx  \ name  (s -- )
\   blword 10 dump
\ ;

: abort"  \ string"  (s -- )
   +level  compile (abort")  ,"  -level
; immediate

[then]

\ Control Structures

decimal
headerless
nuser saved-dp
nuser saved-limit
nuser level
headers
[ifdef] run-time
: +level  ( -- )  ;
: -level  ( -- )  ;
[else]
headerless
h# 400 /token-t * constant /compile-buffer
nuser 'compile-buffer
: compile-buffer  ( -- adr )  'compile-buffer @  ;
: init  ( -- )
   init
   level off   /compile-buffer alloc-mem 'compile-buffer !
;
: reset-dp  ( -- )  saved-dp @ dp !  saved-limit @ is limit  ;

headers
: 0level  ( -- )  level @  if  level off  reset-dp  then  ;

: +level  ( -- )
   level @  if
      1 level +!
   else
      state @ 0=  if	\ If interpreting, begin temporary compilation
         1 level !  here saved-dp !  limit saved-limit !
	 compile-buffer dp !  compile-buffer /compile-buffer +  is limit
	 ]
      then
   then
;
: -level  ( -- )
   state @ 0= ( -22 ) abort" Control structure mismatch"
   level @  if
      -1 level +!
      level @ 0=  if
         \ If back to level 0, execute the temporary definition
         compile unnest  reset-dp
         [compile] [  compile-buffer >ip
      then
   then
;
[then]

headerless
: +>mark    (s acf -- >mark )  +level compile,  here 0 branch,  ;
: +<mark    (s -- <mark )      +level  here  ;
: ->resolve (s >mark -- )      here over - swap branch!  -level  ;
: -<resolve (s <mark acf -- )  compile,  here - branch,  -level  ;
headers

: but      ( m1 m2 -- m2 m1 )  swap  ;
: yet      ( m -- m m )  dup  ;
: cs-pick  ( mn .. m0 n -- mn .. m0 mn )  pick  ;
: cs-roll  ( mn .. m0 n -- mn-1 .. m0 mn )  roll  ;

: begin   ( -- <m )        +<mark				; immediate
: until   ( <m -- )        ['] ?branch -<resolve		; immediate
: again   ( <m -- )        ['] branch  -<resolve		; immediate

: if      ( -- >m )        ['] ?branch +>mark			; immediate
: ahead   ( -- >m )        ['] branch  +>mark			; immediate
: then    ( >m -- )        ->resolve				; immediate

: repeat  ( >m <m -- )     [compile] again      [compile] then	; immediate
: else	  ( >m1 -- >m2 )   [compile] ahead  but [compile] then	; immediate
: while   ( <m -- >m <m )  [compile] if     but			; immediate

: do      ( -- >m <m )     ['] (do)    +>mark     +<mark	; immediate
: ?do     ( -- >m <m )     ['] (?do)   +>mark     +<mark	; immediate
: loop    ( >m <m -- )     ['] (loop)  -<resolve  ->resolve	; immediate
: +loop   ( >m <m -- )     ['] (+loop) -<resolve  ->resolve	; immediate

\ XXX According to ANS Forth, LEAVE and ?LEAVE no longer have to be immediate
: leave   ( -- )   compile (leave)                              ; immediate
: ?leave  ( -- )   compile (?leave)                             ; immediate

: @user#  (s apf -- user# )
\t32  l@
\t16  w@
;
: >user  (s pfa -- addr-of-user-var )  @user# up@ +  ;

: user#,  ( #bytes -- user-var-adr )
   here swap ualloc
\t32   l,
\t16   w,
   >user
;

[ifndef] run-time
: .id     (s anf -- )  name>string type space  ;
: .name   (s acf -- )  >name .id  ;
[then]

nuser warning      \ control of warning messages
-1       is warning

[ifndef] run-time

\ Dr. Charles Eaker's case statement
\ Example of use:
\ : foo ( selector -- )
\   case
\     0  of  ." It was 0"   endof
\     1  of  ." It was 1"   endof
\     2  of  ." It was 2"   endof
\     ( selector) ." **** It was " dup u.
\   endcase
\ ;
\ The default clause is optional.
\ When an of clause is executed, the selector is NOT on the stack
\ When a default clause is executed, the selector IS on the stack.
\ The default clause may use the selector, but must not remove it
\ from the stack (it will be automatically removed just before the endcase)

\ At run time, (of) tests the top of the stack against the selector.
\ If they are the same, the selector is dropped and the following
\ forth code is executed.  If they are not the same, execution continues
\ at the point just following the the matching ENDOF

: case   ( -- 0 )   +level  0                            ; immediate
: of     ( -- >m )  ['] (of)     +>mark                  ; immediate
: endof  ( >m -- )  ['] (endof)  +>mark  but  ->resolve  ; immediate

: endcase  ( 0 [ >m ... ] -- )
   compile (endcase)
   begin  ?dup  while  ->resolve  repeat
   -level
; immediate

[then]

\ From interp.fth

\ The Text Interpreter

\ Input stream parsing

\ Error reporting
defer mark-error  ' noop is mark-error
defer show-error  ' noop is show-error
: where  ( -- )  mark-error show-error  ;

: lose  (s -- )  true ( -13) abort" Undefined word encountered "  ;

\ Number parsing
hex
: >number  (s ud1 c-addr1 u1 -- ud2 c-addr2 u2 )
  \ convert double number, leaving address of first unconverted byte
   begin  dup  while                  ( ud adr len )
      over c@  base @  digit          ( ud adr len  digit true  |  char false )
      0=  if  drop exit  then         ( ud adr len  digit )
      >r  2swap  r>                   ( adr len ud  digit )
      swap base @ um*  drop           ( adr len ud.low  digit ud.high' )
      rot base @ um*  d+              ( adr len  ud' )
      2swap  1 /string                ( ud' adr len )
   repeat                             ( ud' adr len )
;
: numdelim?  ( char -- flag )  dup ascii . =  swap ascii , =  or  ;
: $dnumber?  ( adr len -- [ n .. ] #cells )
   0 0  2swap                                         ( ud $ )
   dup  0=  if  4drop  0  exit  then            ( ud $ )
   over c@ ascii - =                                  ( ud $ neg? )
   dup  >r  negate /string                            ( ud $' )  ( r: neg? )

   \ Convert groups of digits possibly separated by periods or commas
   begin  >number  dup 1 >  while                     ( ud' $' )
      over c@ numdelim?  0=  if                       ( ud' $' )
         r> 5drop  0  exit				( ud' $' )
      then                                            ( ud' $' )
      1 /string                                       ( ud' $' )
   repeat                                             ( ud' $' )

   if                                                 ( ud adr )
      \ Do not accept a trailing comma, thus preventing,
      \ for example, "c," from being interpreted as a number
      c@  ascii . =  if                               ( ud )
         true                                         ( ud dbl? )
      else                                            ( ud )
         r> 3drop  0  exit
      then                                            ( ud dbl? )
   else                                               ( ud adr )
      drop false                                      ( ud dbl? )
   then                                               ( ud dbl? )

   over or  if                                        ( ud )
      r>  if  dnegate  then  2
   else
      drop  r>  if  negate  then  1
   then
;

defer do-defined    ( cfa -1 | cfa 1  -- ?? )
defer $do-undefined  ( adr len -- )

headers
defer do-literal
: (do-literal)  ( n 1 | d 2 -- n | d | )
   state @  if
      2 =  if  [compile] dliteral  else  [compile] literal  then
   else
      drop
   then
;
' (do-literal) is do-literal
defer $handle-literal?  ( adr len -- handled? )
: ($handle-literal?)  ( adr len -- handled? )
   $dnumber?  dup  if  do-literal true  then
;
' ($handle-literal?) is $handle-literal?

headers
: $compile  ( adr len -- ?? )
   2dup  2>r                        ( adr len )  ( r: adr len )
   $find  dup  if                   ( xt +-1 )
      2r> 2drop do-defined          ( )
   else                             ( adr' len' 0 )
      3drop                         ( )
      2r@ $handle-literal?  0=  if  ( )
         2r@  $do-undefined         ( )
      then
      2r> 2drop
  then
;
headerless
: interpret-do-defined  ( cfa -1 | cfa 1 -- ?? )  drop execute  ;
: compile-do-defined    ( cfa -1 | cfa 1 -- )
  0> if    execute   \ if immediate
     else  compile,  \ if not immediate
     then
;
headers
0 value 'error-word
: .not-found  ( adr len -- )  where  type ."  ?" cr  ;
\ Abort after an undefined word in interpret state
: $interpret-do-undefined  ( adr len -- )
   d# 32 min 'error-word pack  count
   set-abort-message  d# -13 throw
;
\ Compile a surrogate for an undefined word in compile state
: $compile-do-undefined    ( adr len -- )  .not-found  compile lose  ;

defer [ immediate
headerless
: ([)  (s -- )
  ['] interpret-do-defined    ['] do-defined    (is
  ['] $interpret-do-undefined ['] $do-undefined (is
  state off
;
' ([) is [

headers
defer ]
headerless
: (])  (s -- )
  ['] compile-do-defined     ['] do-defined    (is
  ['] $compile-do-undefined  ['] $do-undefined (is
  state on
;
' (]) is ]

headers
\ Run-time error checking
: ?stack  (s ?? -- )
   sp@  sp0 @  swap       u<  ( -4 ) abort" Stack Underflow"
   sp@  sp0 @  ps-size -  u<  ( -3 ) abort" Stack Overflow"
;

defer ?permitted  ' noop is ?permitted

defer interpret
: (interpret  (s -- )
   begin
\     ?stack
      parse-word dup
   while
      ?permitted
      $compile
   repeat
   2drop
;
' (interpret  is interpret

\ Ensure that the cursor in on an empty line.
: ??cr  ( -- )  #out @  if  cr  then  ;

\ This hack is for users of window systems.  If you pick up with the
\ mouse an entire previous command line, including the prompt, then
\ paste it into the current line, Forth will ignore the prompt.
: ok  ( -- )  ;

defer status  ( -- )  ' noop is status


\ A hook for automatic pagination

defer mark-output  ( -- )  ' noop is mark-output


\ Prompts the user for another line of input.  Executed only if the input
\ stream is coming from a terminal.

defer (ok) ( -- )
: "ok" ." ok " ;
' "ok" is (ok)

defer reset-page
' noop is reset-page
: do-prompt  ( -- )  reset-page prompt  ;

\ From kernport.fth

\ fload ${BP}/forth/kernel/splits.fth
\ fload ${BP}/forth/kernel/endian.fth

\ Some 32-bit compatibility words

\ These are for links that are just the same as addresses
/a constant /link
: link@  (s addr -- link )  a@  ;
: link!  (s link addr -- )  a!  ;
: link,  (s link -- )       a,  ;

headerless

: l*      (s l1 l2 -- l.product )   * ;
: lnswap  (s l n -- n l )           swap ;
: l0=     (s l -- f )               0= ;
: ldup    (s l -- l l )             dup ;
headers
: nlswap  (s n l -- l n )           swap ;
: ldrop   (s l -- )                 drop ;
headerless
: l2dup   (s l1 l2 -- l1 l2 l1 l2 ) 2dup ;
: lswap   (s l1 l2 -- l2 l1 )       swap ;
: l=      (s l1 l2 -- f )           = ;
: lnover  (s l n -- l n l )         over ;
: land    (s l1 l2 -- l3 )          and ;
headers

[ifndef] run-time

: labs    (s l1 l2 -- l3 )          abs ;
: l+      (s l1 l2 -- l3 )          + ;
: l-      (s l1 l2 -- l3 )          - ;
: lnegate (s l1 l2 -- l3 )          negate ;
: l2/     (s l1 l2 -- l3 )          2/ ;
: lmin    (s l1 l2 -- l3 )          min ;
: lmax    (s l1 l2 -- l3 )          max ;

\itc : \itc ; immediate
\itc : \dtc  [compile] \ ; immediate
\itc : \ttc  [compile] \ ; immediate
\dtc : \itc  [compile] \ ; immediate
\dtc : \dtc ; immediate
\dtc : \ttc  [compile] \ ; immediate
\ttc : \itc  [compile] \ ; immediate
\ttc : \dtc  [compile] \ ; immediate
\ttc : \ttc ; immediate
\t8  : \t8  ; immediate
\t8  : \t16  [compile] \ ; immediate
\t8  : \t32  [compile] \ ; immediate
\t16 : \t8   [compile] \ ; immediate
\t16 : \t16 ; immediate
\t16 : \t32  [compile] \ ; immediate
\t32 : \t8   [compile] \ ; immediate
\t32 : \t16  [compile] \ ; immediate
\t32 : \t32 ; immediate
16\ : 16\  ; immediate
16\ : 32\  [compile] \  ; immediate
16\ : 64\  [compile] \  ; immediate
32\ : 16\  [compile] \  ; immediate
32\ : 32\  ; immediate
32\ : 64\  [compile] \  ; immediate
64\ : 16\  [compile] \  ; immediate
64\ : 32\  [compile] \  ; immediate
64\ : 64\  ; immediate
[then]

\ From definers.fth

\ Extensible Layer            Defining Words
headers

defer $header

defer header		\ Create a new word

: (header)  \ name  ( -- )
   safe-parse-word $header
;

' (header) is header

: $create  ( adr len -- )  $header  create-cf  ;

: create  \ name  (s -- )
   header create-cf
;

nuser csp          \ for stack position error checking
: !csp   (s -- )   sp@ csp !   ;
: ?csp   (s -- )   sp@ csp @ <>   ( -22 ) abort" Stack Changed "  ;

: (;code)   (s -- )  ip>  aligned acf-aligned  used   ;
: (does>)   (s -- )  ip>  acf-aligned  used   ;

defer do-entercode
' noop is do-entercode

: code  \ name  (s -- )
   header  code-cf  !csp  do-entercode
;

defer do-exitcode
' noop is do-exitcode

: end-code  ( -- )
   do-exitcode  ?csp
;
: c;  ( -- )  next  end-code  ;

: ;code     (s -- )
   ?csp   compile  (;code)  align acf-align  place-;code
   [compile] [   reveal   do-entercode
; immediate

: does>   (s -- )
   state @  if
     compile (does>)
   else
     here  aligned acf-aligned  used  !csp not-hidden  ]
   then
   align acf-align  place-does
; immediate

: :        (s -- )  ?exec  !csp   header  hide   ]  colon-cf  ;
: :noname  (s -- xt )  ?exec  not-hidden     ]  colon-cf  lastacf  !csp  ;
: ;        (s -- )
   ?comp  ?csp   compile unnest   reveal   [compile] [
; immediate

: recursive  (s -- )   reveal  ; immediate

: constant  \ name  (s n -- )
   header constant-cf  ,
;
: user  \ name  (s user# -- )
   header user-cf
\t32  l,
\t16  w,
;
: value  \ name  (s value -- )
   header value-cf  /n user#,  !
;
: variable  \ name  (s -- )
   header variable-cf  0 ,
;
: wvariable  \ name  (s -- )
   create variable-cf 0 w,
;

\ defer (is is
\ Also known as execution vectors.
\ Usage:   defer bar
\ : foo ." Hello" ;  ' foo is bar
\ Alternatively: ' foo ' bar (is

\ Since the execution of an execution vector doesn't leave around
\ information about which deferred word was used, we have to try
\ to find it by looking on the return stack
\ if the vector was EXECUTE'd, we don't know what it was.  This
\ will be the case if the deferred word was interpreted from the
\ input stream

: crash ( -- )  \ unitialized execution vector routine
   \ The following line may not always work right for token-threaded code
   \ with variable-length tokens
   ip@ /token - token@         \ use the return stack to see who called us
   dup word-type  ['] emit word-type =  if  .name  ." <--"  then
   ." deferred word not initialized" abort
;

\ Allocates a user area location to hold the vector
: defer  \ name  (s -- )
   header  defer-cf
   ['] crash   /token user#,   token!	\ Allocate user location
;

: 2constant  \ name  (s d# -- )
   header 2constant-cf  swap  , ,
;
: 2variable  \ name (s -- )
   create 0 , 0 ,   (s -- apf )
;

\ buffer:  \ name  ( size -- )
\       Defines a word which returns the address of a buffer of the
\       requested size.  The buffer is allocated at initialization
\       time from free memory, not from the dictionary.

auser buffer-link
0   is buffer-link

headerless
: make-buffer  ( size -- )
   here body> swap     ( acf size )
   0 /n user#,  !      ( acf size )
   ,                   ( acf )
   buffer-link link@  link,  buffer-link link!
;

headers
: do-buffer  ( apf -- adr )
   dup >user @  if          ( apf )
      >user @               ( adr )
   else                     ( apf )
      dup /user# + @        ( apf size )
      dup alloc-mem         ( apf size adr )
      dup rot erase         ( apf adr )
      dup rot >user !       ( adr )
   then
;
: (buffer:)  ( size -- )
   create-cf  make-buffer  does> do-buffer
;

headers
: buffer:  \ name  ( size -- )
   header (buffer:)
;

: >buffer-link ( acf -- link-adr )  >body /user# + 1 na+  ;

headerless
: clear-buffer:s ( -- )
   buffer-link                         ( next-buffer-word )
   begin  another-link?  while         ( acf )
      dup >body  >user  off            ( acf )
      >buffer-link                     ( prev-buffer:-acf )
   repeat                              ( )
;

: init  ( -- )  init  clear-buffer:s  ;
headers

\ From tagvoc.fth

\ Implementation of vocabularies.  Vocabularies are lists of word names.
\ The following operations may be performed on vocabularies:
\    find-word  - Search for a given word
\    "header    - Create a new word in the "current" vocabulary
\    trim       - Remove all words in a vocabulary created after an address
\    another?   - Enumerate all the the words
\
\ Each word name in a vocabulary has the following attributes:
\    immediate flag  - Controls compilation of that word
\

\ Find a potential name field address
: find-name  ( acf -- anf )  >link l>name  ;

\ The test for a valid header searches backward for the first byte
\ that appears to be a name length byte.  Then the length of the
\ name field implied by the length byte is compared with the actual
\ length, calculated by subtracting anf from acf.  Finally, the characters
\ in the name are checked to make sure that the name contains only printable
\ characters.

: >name?  ( acf -- anf good-name? )
   dup  find-name                      ( acf anf )
   tuck name>string                    ( anf acf name-adr name-len )
   dup 0=  if  3drop false exit  then  ( anf acf name-adr name-len )
   + /link + acf-aligned               ( anf acf test-acf )
   <>  if  false exit  then            ( anf )

   \ Check for bogus (non-printable) characters in the name.
   dup name>string                     ( anf adr len )
   true -rot  bounds ?do               ( anf true )
      i c@  bl  h# 7f  between  0=  if  0= leave  then
   loop                                ( anf good-name? )
;

\ Address conversion operators
: n>link   ( anf -- alf )  1+  ;
: l>name   ( alf -- anf )  1- ;
: n>flags  ( anf -- aff )  ;
: name>    ( anf -- acf )  n>link link>  ;
: link>    ( alf -- acf )  /link +  ;
: >link    ( acf -- alf )  /link -  ;
: >flags   ( acf -- aff )  >name n>flags  ;
: name>string  ( anf -- adr len )  dup c@ h# 1f and  tuck - swap  ;
: l>beginning  ( alf -- adr )  l>name name>string drop  ;
: >threads  ( acf -- ath )  >body >user  ;

nuser last

headerless

nuser tag-file

decimal
[ifdef] omit-files
: $tagout 2drop ;
[else]
: $tag-field  ( $ -- )  tag-file @ fputs  ;
: tag-char  ( char -- )  tag-file @ fputc  ;
: $tagout  ( name$ -- )
   tag-file @ 0=  if  2drop exit  then
   source-id -1 =  if  2drop exit  then
   $tag-field  9 tag-char
   source-id file-name  $tag-field  9 tag-char
   base @ decimal  source-id file-line (.) $tag-field  base !
   newline-string $tag-field
;
[then]

: $make-header  ( adr len voc-acf -- )
   -rot                        ( voc-acf adr,len )
   2dup $tagout
   dup 1+ /link +              ( voc-acf adr,len hdr-len )

   here +                       ( voc-acf adr,len  addr' )
   dup acf-aligned swap - allot ( voc-acf adr,len )
   tuck here over 1+  note-string  allot     ( voc-acf len adr,len anf )
   place-cstr                  ( voc-acf len anf )
   over + c!                   ( voc-acf )
   here 1- last !              ( voc-acf )
   >threads                    ( threads-adr )
   /link allot here            ( threads-adr acf )

   swap 2dup link@             ( acf threads-adr acf succ-acf )
   swap >link link! link!      (  )

   last @ c@  h# 80 or  last @ c!
;

headers
: >first  ( voc-acf -- first-alf )  >threads  ;

: $find-word  ( adr len voc-acf -- adr len   false | xt +-1 )
   >first  $find-next  find-fixup
;

headerless
: >ptr  ( alf voc-acf -- ptr )
   over  if  drop  else  nip >threads  then
;
: next-word  ( alf voc-acf -- false  |  alf' true )
   >ptr another-link?  if  >link  true  else  false  then
;
: insert-word  ( new-alf old-alf voc-ptr -- )
   >ptr              ( new-alf alf )
   swap link> swap   ( new-acf alf )
   2dup link@        ( new-acf alf  new-acf next-acf )
   swap >link link! link!
;

headers
: remove-word  ( new-alf voc-acf -- )
   >threads                                   ( new-alf prev-link )
   swap link> swap link>                      ( new-acf prev-link )
   begin                                      ( acf prev-link )
      >link
      2dup link@ =  if                        ( acf prev-link )
         swap >link link@ swap link!  exit    (  )
      then                                    ( acf prev-link )
      another-link? 0=                  ( acf [ next-link ] end? )
   until
   drop
;

\ Makes a sealed vocabulary with the top-of-voc pointer in user area
\ parameter field of vocabularies contains:
\ user-#-of-voc-pointer ,  voc-link ,

\ For navigating inside a vocabulary's data structure.
\ A vocabulary's parameter field contains:
\   user#  link
\ The threads are stored in the user area.

: voc>      (s voc-link-adr -- acf )
\   /user# -  body>
;

: >voc-link ( voc-acf -- voc-link-adr )  >body /user# +  ;

: (wordlist)  ( -- )
   create-cf
   /link user#,  !null-link   ( )
   voc-link,
   0 ,				\ Space for additional information
   does> body> context token!
; resolves <vocabulary>

headers
: \tagvoc ; immediate
: \nottagvoc [compile] \ ; immediate

\ From voccom.fth

\ Common routines for vocabularies, independent of name field
\ implementation details

headers
: wordlist  ( -- wid )  (wordlist) lastacf  ;
: vocabulary  ( "name" -- )  header (wordlist)  ;

defer $find-next
' ($find-next) is $find-next

\  : insert-after  ( new-node old-node -- )
\     dup link@        ( new-node old-node next-node )
\     2 pick link!     ( new-node old-node )
\     link!
\  ;
tuser hidden-voc   origin-t is hidden-voc

: not-hidden  ( -- )  hidden-voc !null-token  ;

: hide   (s -- )
   current-voc hidden-voc token!
   last @ n>link current-voc remove-word
;

: reveal  (s -- )
   hidden-voc get-token?  if             ( xt )
      last @ n>link 0  rot  insert-word  ( )
      not-hidden
   then
;

#threads-t constant #threads

auser voc-link     \ points to newest vocabulary

headerless

: voc-link,  (s -- )  \ links this vocabulary to the chain
   lastacf  voc-link link@  link,   voc-link link!
;

headers
: find-voc ( xt - voc-node|false )
   >r voc-link  			( voc-node )
   begin
      another-link? false = if          ( - | voc-node )
         false true			( false loop-flag )
      else				( voc-node )
	 dup voc> 			( voc-node voc-xt )
	 swap >voc-link swap            ( voc-node' voc-xt )
         r@ execute	     		( voc-node' flag )
      then				( voc-node'|false loop-flag )
   until				( voc-node' )
   r> drop				( voc-node|false )
;

headerless
hex
0 value fake-name-buf

headers
: fake-name  ( xt -- anf )
   base @ >r hex
   <#  0 hold ascii ) hold  u#s  ascii ( hold  u#>   ( adr len )
   fake-name-buf $save       ( adr len )
   tuck + 1- tuck            ( anf len adr+len )
   swap 1- h# 80 or swap c!  ( adr )
   r> base !
;

\ Returns the name field address, or if the word is headerless, the
\ address of a numeric string representing the xt in parentheses.
: >name  ( xt -- anf )
   dup >name?  if  nip  else  drop fake-name  then
;

: immediate  (s -- )  last @  n>flags  dup c@  40 or  swap c!  ;
: immediate?  (s xt -- flag )  >flags c@  40 and  0<>  ;
: flagalias  (s -- )  last @  n>flags  dup c@  20 or  swap c!  ;
: .last  (s -- )  last @ .id  ;

: current-voc  ( -- voc-xt )  current token@  ;

0 value canonical-word
headerless
: init  ( -- )
   init
   d# 20 alloc-mem  is fake-name-buf
   d# 32 alloc-mem  is canonical-word
   d# 34 alloc-mem  is 'error-word
;
headers

: $canonical  ( adr len -- adr' len' )
   caps @  if  d# 31 min  canonical-word $save  2dup lower  then
;
: $create-word  ( adr len voc-xt -- )
   >r $canonical r>
   warning @  if
      3dup  $find-word  if   ( adr len voc-xt  xt )
         drop
	 >r 2dup type r> ."  isn't unique " cr
      else                   ( adr len voc-xt  adr len )
         2drop
      then
   then                      ( adr len voc-xt )
   $make-header
;

: ($header)  (s adr len -- )  current-voc $create-word  ;

' ($header) is $header

: (search-wordlist)  ( adr len vocabulary -- false | xt +-1 )
   $find-word  dup  0=  if  nip nip  then
;
: search-wordlist  ( adr len vocabulary -- false | xt +-1 )
   >r $canonical r> (search-wordlist)
;
: $vfind  ( adr len vocabulary -- adr len false | xt +-1 )
   >r $canonical r> $find-word
;

: find-fixup  ( adr len alf true  |  adr len false -- xt +-1  |  adr len 0 )
   dup  if                                        ( adr len alf true )
      drop nip nip                                ( alf )
      dup link> swap l>name n>flags c@            ( xt flags )
      dup  h# 20 and  if  swap token@ swap  then  ( xt' flags )  \ alias?
      h# 40 and  if  1  else  -1  then                           \ immediate?
   then
;

headerless
2 /n-t * ualloc-t user tbuf
headers
: follow  ( voc-acf -- )  tbuf token!  0 tbuf na1+ !  ;

: another?  ( -- false  |  anf true )
   tbuf na1+ @  tbuf token@  next-word  ( 0 | alf true )
   if  dup tbuf na1+ !  l>name  true  else  false  then
;

: another-word?  ( alf|0  voc-acf -- alf' voc-acf anf true  |  false )
   tuck next-word  if    ( voc-acf alf' )
      tuck l>name  true  ( alf' voc-acf anf true )
   else                  ( voc-acf )
      drop  false        ( false )
   then
;

\ Forget

headerless
: trim   (s alf voc-acf -- )
   >r 0                                       ( adr 0 )
   begin  r@ next-word   while                ( adr alf )
      2dup <=  if  dup r@ remove-word  then   ( adr alf )
   repeat                                     ( adr )
   r> 2drop
;

headers

auser fence        \ barrier for forgetting

: (forget)   (s adr -- )	\ reclaim dictionary space above "adr"

   dup fence a@ u< ( -15 ) abort" below fence"  ( adr )

   \ Forget any entire vocabularies defined after "adr"

   voc-link                          ( adr first-voc )
   begin                             ( adr voc )
      \ XXX this may not work with a mixed RAM/ROM system where
      \ RAM is at a lower address than ROM
      link@ 2dup  u<                 ( adr voc' more? )
   while                             ( adr voc )
      dup voc> current-voc =         ( adr voc error? )
      ( -15 ) abort" I can't forget the current vocabulary."
      \ Remove the voc from the search order
      dup voc> (except               ( adr voc )
      >voc-link                      ( adr voc-link )
   repeat                            ( adr voc )
   dup voc-link link!                ( adr voc )

   \ For all remaining vocabularies, unlink words defined after "adr"

   \ We assume that we haven't forgotten all the vocabularies;
   \ otherwise this will fail.  Forgetting all the vocabularies would
   \ crash the system anyway, so we don't worry about it.
   begin                             ( adr voc )
      2dup voc> trim                 ( adr voc )
      >voc-link                      ( adr voc-link-adr )
      another-link? 0=               ( adr voc' )
   until                             ( adr )
   l>beginning  here - allot     \ Reclaim dictionary space
;

: forget   (s -- )
   safe-parse-word   current-voc $vfind  $?missing  drop
   >link  (forget)
;

: marker  ( "name" -- )
   create  #user @ ,
   does> dup @  #user !  body> >link  (forget)
;
headerless
: init ( -- )  init  ['] ($find-next) is $find-next  ;
headers

\ From order.fth

\ Search order.  Maintains the list of vocabularies which are
\ searched while interpreting Forth code.

decimal
16 equ nvocs
nvocs constant #vocs	\ The # of vocabularies that can be in the search path

nvocs /token-t * ualloc-t user context   \ vocabulary searched first
tuser current      \ vocabulary which gets new definitions

#vocs /token * constant /context
: context-bounds  ( -- end start )  context /context bounds  ;

headerless
: shuffle-down  ( adr -- finished? )
   \ The loop goes from the next location after adr to the end of the
   \ context array.
   context-bounds drop  over /token +  ?do    ( adr )
       \ Look for a non-null entry, replace the current entry with that one,
       \ and replace that one with null
       i get-token?  if                       ( adr acf )
          over token!   i !null-token  leave  ( adr )
       then                                   ( adr )
   /token +loop
   drop
;
headers
: clear-context  ( -- )
   context-bounds  ?do  i !null-token  /token +loop
;
headerless
: compact-search-order  ( -- )
   context-bounds  ?do
      i get-token? 0=  if   i shuffle-down  else  drop  then
   /token +loop
;
headers
: (except  ( voc-acf -- )   \ Remove a vocabulary from the search order
   context-bounds  ?do
      dup  i token@  =  if  i  !null-token  then
   /token +loop
   drop compact-search-order
;

nuser prior        \ used for dictionary searches
: $find   (s adr len -- xt +-1 | adr len 0 )
   2dup 2>r
   $canonical        ( adr' len' )
   prior off         ( adr len )
   false             ( adr len found? )
   context-bounds  ?do
      drop
      i get-token?  if                    ( adr len voc )

         \ Don't search the vocabulary again if we just searched it.
         dup prior @ over prior !  =  if  ( adr len voc )
            drop false                    ( adr len false )
         else                             ( adr len voc )
	    $find-word  dup ?leave        ( adr len false )
         then                             ( adr len false )

      else                                ( adr len voc )
         false                            ( adr len false )
      then                                ( adr len false )
   /token +loop                           ( adr len false  |  xt +-1 )
   ?dup  if
      2r> 2drop
   else
      2drop  2r> false
   then
;
: find  ( pstr -- pstr false  |  xt +-1 )
   dup >r count $find  dup  0=  if  nip nip  r> swap  else  r> drop  then
;

\ The also/only vocabulary search order scheme

decimal
: >voc  ( n -- adr )  /token *  context +  ;

vocabulary root   root definitions-t

: also  (s -- )  context  1 >voc   #vocs 2- /token *  cmove>  ;

: (min-search)  root also  ;
defer minimum-search-order  ' (min-search) is minimum-search-order
: forth-wordlist  ( -- wid )  ['] forth  ;
: get-current  ( -- )  current token@  ;
: set-current  ( -- )  current token!  ;

: get-order  ( -- vocn .. voc1 n )
   0  0  #vocs 1-  do
      i >voc token@ non-null?  if  swap 1+  then
   -1 +loop
;
: set-order  ( vocn .. voc1 n -- )
   dup #vocs >  abort" Too many vocabularies in requested search order"
   clear-context
   0  ?do  i >voc token!  loop
;

: only  (s -- )
   clear-context
\   ['] root  #vocs 1- >voc  token!
   minimum-search-order
;

: except  \ vocabulary-name  ( -- )
   ' (except
;
: seal  (s -- )  ['] root (except  ;
: previous   (s -- )
   1 >voc  context  #vocs 2- /token *  cmove
   #vocs 2- >voc  !null-token
;

: definitions  ( -- )  context token@ set-current  ;

: order   (s -- )
   ." context: "
   get-order  0  ?do  .name  loop
   4 spaces  ." current: "  get-current .name
;
: vocs   (s -- )
   voc-link  begin  another-link?  while  ( link )
      #out @ 64 >  if  cr  then
      dup  voc>  .name
      >voc-link
   repeat
;

vocabulary forth   forth definitions-t

\ only forth also definitions
\ : (cold-hook   ( -- )   (cold-hook  only forth also definitions  ;
\ headers

headerless
: init  ( -- )  init  only forth also definitions  ;
headers

\ From is.fth

\ Prefix word for setting the value of variables, constants, user variables,
\ values, and deferred words.  State-smart so it is used the same way whether
\ interpreting or compiling.  Don't use IS in place of ! where speed matters,
\ because IS is much slower than ! .
\
\ Examples:
\
\ 3 constant foo
\ 4 is foo
\
\ defer money
\ ' dollars is money
\ : german ['] marks is money ;

\ Is is a "generic store".
\ Is figures out where the data for a word is stored, and replaces that
\ data.  In this implementation, it is not particularly fast.

\ This is loaded before "order.fth"
\ only forth also hidden also definitions

variable isvar
0 value isval

headerless

[ifdef] run-time
: is-error  ( data acf -- )  true ( -32 ) abort" inappropriate use of `is'"  ;
[else]
: is-error  ( data acf -- )  ." Can't use is with " .name cr ( -32 ) abort  ;
[then]

headers

defer to-hook
' is-error is to-hook

headerless

: >bu  ( acf -- data-adr )  >body >user  ;

create word-types
   ' key    token,-t	\ defer
   ' #user  token,-t	\ user variable
   ' isval  token,-t	\ value
   ' bl     token,-t	\ constant
   ' isvar  token,-t	\ variable
   origin   token,-t	\ END   \ origin should be null

create data-locs
   ' >bu    token,-t	\ defer
   ' >bu    token,-t	\ user variable
   ' >bu    token,-t	\ value
   ' >body  token,-t	\ constant
   ' >body  token,-t	\ variable

create !ops
   ' token! token,-t	\ defer
   ' !      token,-t	\ user variable
   ' !      token,-t	\ value
   ' !      token,-t	\ constant
   ' !      token,-t	\ variable

: associate  ( acf -- true  |  index false )
   word-type  ( n )
   word-types  begin              ( n adr )
      2dup get-token?             ( n adr n  false | acf true )
   while                          ( n adr n acf )
      word-type  = if             ( n adr )
         word-types -  /token /   ( n index )
	 nip false  exit          ( index false )
      then                        ( n adr )
      ta1+                        ( n adr' )
   repeat                         ( n adr n )
   3drop true                     ( true )
;

: +execute  ( index table -- )
   swap ta+ token@ execute        ( )
;

: kerntype?  ( acf -- flag )
   associate  if  false  else  drop true  then  ( flag )
;

headers
: behavior  ( defer-acf -- acf2 )  >bu token@  ;

: (is  ( data acf -- )
   dup  associate  if  is-error  then   ( data acf index )
   tuck data-locs +execute              ( data index data-adr )
   swap !ops +execute                   ( )
;

: >data  ( acf -- data-adr )
   dup associate  if        ( acf )
      >body                 ( data-adr )
   else                     ( acf index )
      data-locs +execute    ( data-adr )
   then                     ( data-adr )
;

\ (is) is a run-time word that is compiled into definitions
: (is)  ( acf -- )  ip> dup ta1+ >ip  token@ (is  ;

[ifndef] run-time

: do-is  ( data acf -- )
   dup kerntype?  if     ( [data] acf )
      state @  if   compile (is)  token,  else  (is   then
   else                    ( [data] acf )
      to-hook
   then
;
\ is is the word that is actually used by applications
: is  \ name  ( data -- )
   ' do-is
; immediate
\ only forth also definitions

[then]

\ A place to put the last word returned by blword
0 value 'word

[ifndef] omit-files
\ From filecomm.fth

decimal

\ buffered i/o  constants
-1 constant eof

nuser delimiter  \ delimiter actually found at end of word
nuser file

\ field creates words which return their address within the structure
\ pointed-to by the contents of file

\ The file descriptor structure describes an open file.
\ There is a pool of several of these structures.  When a file is opened,
\ a structure is allocated and initialized.  While performing an io
\ operation, the user variable "file" contains a pointer to the file
\ on which the operation is being performed.

: bfbase    file @  0 na+  ;   \ starting address of the buffer for this file
: bflimit   file @  1 na+  ;   \ ending address of the buffer for this file
headerless
: bftop     file @  2 na+  ;   \ address past last valid character in the buffer
: bfend     file @  3 na+  ;   \ address past last place to write in the buffer
: bfcurrent file @  4 na+  ;   \ address of the current character in the buffer
: bfdirty   file @  5 na+  ;   \ contains true if the buffer has been modified
: fmode     file @  6 na+  ;   \ not-open, read, write, or modify
: fstart    file @  7 na+  ;   \ Position in file of the first byte in buffer
: fid       file @  9 na+  ;   \ File handle for underlying operating system
: seekop    file @ 10 na+  ;   \ Points to system routine to set the file position
: readop    file @ 11 na+  ;   \ Points to system routine to read blocks
: writeop   file @ 12 na+  ;   \ Points to system routine to write blocks
: closeop   file @ 13 na+  ;   \ Points to system routine to close file
: alignop   file @ 14 na+  ;   \ Points to system routine to align to block boundary
: sizeop    file @ 15 na+  ;   \ Points to system routine to return the file size
: (file-line)    file @ 16 na+  ;   \ Number of line delims that read-line has consumed
: line-delimiter file @ 17 na+  ;   \ The last delimiter at the end of each line
: pre-delimiter  file @ 18 na+  ;   \ The first line delimiter (if any)
: (file-name)    file @ 19 na+  ;   \ The name of the file
/n round-up
headers
20 /n-t * d# 68 +  constant /fd

: set-name  ( adr len -- )
   \ If the name is too long, cut off initial characters (because the
   \ latter ones are more likely to be interesting), and replace the
   \ first character with "?".
   dup d# 64 -  0 max  dup >r  /string  (file-name) place
   r>  if  ascii ? (file-name) 1+ c!  then
;
: file-name  ( fd -- adr len )
   file @ >r  file !  (file-name) count  r> file !
;
: file-line  ( fd -- n )  file @ >r  file !  (file-line) @  r> file !  ;
: setupfd  ( fid fmode sizeop alignop closeop seekop writeop readop -- )
   readop !  writeop !  seekop !  closeop !  alignop !  sizeop !
   fmode !  fid !  0 (file-line) !  0 0 set-name
;

headerless
\ values for mode field
-1  constant not-open
headers
 0  constant read
 1  constant write
 2  constant modify
headerless
modify constant read-write  ( for old programs )

\ Stub routines for readop and writeop
headers
\ These return 0 for the number of bytes actually transferred.
: nullwrite  ( adr count fd -- 0 )  3drop 0  ;
: fakewrite  ( adr count fd -- count )  drop nip  ;
: nullalign  ( d.position fd -- d.position' )  drop  ;
: nullread  ( adr count fd -- 0 )  3drop 0  ;
: nullseek  ( d.byte# fd -- )  3drop  ;
headerless
\ This one pretends to have transferred the requested number of bytes
: fakeread  ( adr count fd -- count )  drop nip  ;

headers
\ Initializes the current descriptor to use the buffer "bufstart,buflen"
: initbuf  ( bufstart buflen -- )
   0 0 fstart 2!   over + bflimit !  ( bufstart )
   dup bfbase ! dup bfcurrent ! dup bfend !  bftop !
   bfdirty off
;

\ "unallocate" a file descriptor
: release-fd  ( fd -- )  file @ >r  file !  not-open fmode !  r> file !  ;
headerless

\ An implementation factor which returns true if the file descriptor fd
\ is not currently in use
: fdavail?  ( fd -- f )  file @ >r  file !  fmode @ not-open =  r> file !  ;

\ These are the words that a program uses to read and write to/from a file.

\ An implementation factor which
\ ensures that the bftop is >= the bfcurrent variable.  bfcurrent
\ can temporarily advance beyond bftop while a file is being extended.

: sync  ( -- )  \ if current > top, move up top
   bftop @ bfcurrent @ u<   if    bfcurrent @  bftop !    then
;

\ If the current file's buffer is modified, write it out
\ Need to better handle the case where the file can't be extended,
\ for instance if the file is a memory array
: ?flushbuf  ( -- )
   bfdirty @   if
      sync
      fstart 2@  fid @  seekop @ execute  ( )
      bftop @ bfbase @  -                 ( #bytes-to-write)
      bfbase @  over                      ( #bytes adr #bytes )
      fid @ writeop @ execute             ( #bytes-to-write #bytes-written )
      u>  ( -37 ) abort" Flushbuf error"
      bfdirty off
      bfbase @   dup bftop !  bfcurrent !
   then
;

: align-byte#  ( d.byte# -- d.aln-byte# )  fid @ alignop @ execute  ;
: byte#-aligned?  ( d.byte# -- flag )  2dup align-byte#  d=  ;

\ An implementation factor which
\ fills the buffer with a block from the current file.  The block will
\ be chosen so that the file address "d.byte#" is somewhere within that
\ block.

: fillbuf  ( d.byte# -- )
   align-byte#              ( d.byte# ) \ Aligns position to a buffer boundary
   2dup fstart 2!           ( d.byte# )
   fid @ seekop @ execute               ( )
   bfbase @   bflimit @ over -          ( adr #bytes-to-read )
   fid @ readop @ execute               ( #bytes-read )
   bfbase @ +   bftop !
   bflimit @  bfend !
;

\ An implementation factor which
\ returns the address within the buffer corresponding to the
\ selected position "d.byte#" within the current file.

: bufaddr>  ( bufaddr -- d.byte# )  bfbase @ - s>d  fstart 2@ d+  ;
: >bufaddr  ( d.byte# -- bufaddr )  fstart 2@ d- drop  bfbase @ +  ;

\ This is called from fputs to open up space in the buffer for block-sized
\ chunks, avoiding prefills that would be completely overwritten.
: prefill?  ( endaddr curaddr -- endaddr curraddr flag )

   \ If the current buffer pointer is not block-aligned, must prefill
   bfcurrent @  bufaddr>  byte#-aligned?  0=  if  true  exit  then  ( end curr )

   2dup -  0 align-byte# drop           ( end curr aln-size )

   \ If the incoming data won't fill a block, must prefill
   ?dup  0=  if  true exit  then        ( end curr aln-size )

   \ If there is still space in the buffer, just open it up for copyin
   bflimit @ bfend @ -  ?dup  if        ( end curr aln-len buffer-avail )
      min  bfend +!  false exit
   then                                 ( end curr aln-len )

   \ Save current on stack because ?flushbuf clears it
   bfcurrent @                          ( end curr aln-len current )

   \ The buffer is full; clear out its old contents
   ?flushbuf                            ( end curr aln-len )

   \ Advance the file pointer to the new buffer starting position
   bufaddr> fstart 2!                   ( end curr aln-len )

   bfbase @ + bflimit @ min  bfend !    ( end curr )  \ Room for new bytes
   bfbase @  dup bftop !  bfcurrent !   ( end curr )  \ No valid bytes yet
   false
;

\ An implementation factor which
\ advances to the next block in the file.  This is used when accesses
\ to the file are sequential (the most common case).

\ Assumes the byte is not already in the buffer!
: shortseek  ( bufaddr -- )
   ?flushbuf                             ( bufaddr )
   bfbase @ - s>d  fstart 2@  d+         ( d.byte# )
   2dup fillbuf                          ( d.byte# )
   >bufaddr  bftop @  umin  bfcurrent !
;

\ Buffer boundaries are transparant
\ end-of-file conditions work correctly
\ The actual delimiter encountered in stored in delimiter.

headers
\ input-file contains the file descriptor which defines the input stream.
nuser input-file

headerless

\ ?fillbuf is called by the string scanning routines after skipbl, scanbl,
\ skipto, or scanto has returned.  ?fillbuf determines whether or not
\ the end of a buffer has been reached.  If so, the buffer is refilled and
\ end? is set to false so that the skip/scan routine will be called again,
\ (unless the end of the file is reached).

: ?fillbuf  ( endaddr [ adr ]  delimiter -- endaddr' addr' end? )
    dup delimiter !  eof =  if ( endaddr )
       shortseek
       bftop @  bfcurrent @    ( endaddr'  addr' )
       2dup u<=                ( endaddr'  addr' end-of-file? )
    else                       ( endaddr addr )
       true            \ True so we'll exit the loop
    then
;

headers
\ Closes the file.
: fclose  ( fd -- )
   file @ >r  file !
   file @  fdavail?  0=  if
      ?flushbuf  fid @ closeop @ execute
      file @  release-fd
   then
   r> file !
;
: close-file  ( fd -- ior )  fclose 0  ;

headerless
\ File descriptor allocation


32         constant #fds
#fds /fd * constant /fds

nuser fds

headerless
\ Initialize pool of file descriptors
: init  ( -- )
   init
   /stringbuf alloc-mem is 'word
   /fds alloc-mem  ( base-address )  fds !
   fds @  /fds   bounds   do   i release-fd   /fd +loop
;

headers
\ Allocates a file descriptor if possible
: (get-fd  ( -- fd | 0 )
   0
   fds @  /fds  bounds  ?do               ( 0 )
      i fdavail?  if  drop i leave  then  ( 0 )
   /fd +loop                              ( fd | 0 )
;

: string-sizeop  ( fhandle -- d.length )  drop  bflimit @  bfbase @ -  0  ;
: hold$  ( adr len -- )
   dup  if
      1- bounds swap  do  i c@ hold  -1 +loop
   else
      2drop
   then
;

: init-delims   ( -- )
   \ initialize the delimiters to the default values for the
   \ underlying operating system, in case the file is initially empty.
   newline-string  case
      1 of  c@         0        endof
      2 of  dup 1+ c@  swap c@  endof
      ( default )  linefeed carret rot
   endcase   pre-delimiter c!  line-delimiter c!
;

: open-buffer  ( adr len -- fd ior )
   2 ?enough
   \ XXX we need a "throw" code for "no more fds"
   (get-fd  ?dup 0=  if  0 true exit  then	( adr len fd )
   file !
   2dup						( adr len )
   initbuf  init-delims				( adr len )
   bflimit @  dup bfend !  bftop !		( adr len )

   0  modify
   ['] string-sizeop  ['] drop  ['] drop
   ['] nullseek  ['] fakewrite  ['] nullread   setupfd  ( adr len )
   $set-line-delimiter

   \ Set the file name field to "<buffer@ADDRESS>"
   base @ >r hex
   bfbase @ <#  ascii > hold  u#s " <buffer@" hold$ u#> set-name
   r> base !

   file @  false
;
[then]

headerless
\ A version that knows about multi-segment dictionaries can be installed
\ if such dictionaries exist.
: (in-dictionary?  ( adr -- )  origin here between  ;
headers
defer in-dictionary? ' (in-dictionary? is in-dictionary?

defer .error#
: (.error#)  ( error# -- )
   dup d# -38  =  if  .file-open-error  else  ." Error " .  then
;

: .abort  ( -- )
   show-error
   drop abort-message type
;

' (.error#) is .error#

defer .error
: (.error)  ( error# -- )
   dup  -13  =  if
      .abort  ."  ?"  cr
   else  dup  -2 =  if
      .abort  cr
   else  dup -1 =  if
      drop
   else
      show-error
      dup in-dictionary?  if  count type  else  .error#  then cr
   then
   then
   then
;
' (.error) is .error

: guarded  ( acf -- )  catch  ?dup  if  .error  then  ;

\ From cold.fth

\ Some hooks for multitasking
\ Main task points to the initial task.  This usage is currently not ROM-able
\ since the user area address has to be later stored in the parameter field
\ of main-task.  It could be made ROM-able by allocating the user area
\ at a fixed location and storing that address in main-task at compile time.

defer pause  \ for multitasking
' noop  is pause

defer init-io    ( -- )
defer do-init    ( -- )
defer cold-hook  ( -- )
defer init-environment  ( -- )

[ifndef] run-time
: (cold-hook  (s -- )
   [compile] [
;

' (cold-hook  is cold-hook
[then]

defer title  ' noop is title

: cold  (s -- )
   decimal
   init-io			  \ Memory allocator and character I/O
   do-init			  \ Kernel
   ['] init-environment guarded	  \ Environmental dependencies
   ['] cold-hook        guarded	  \ Last-minute stuff

   process-command-line

   \ interactive? won't work because the fd hasn't been initialized yet
   (interactive?  if  title  then

   quit
;

[ifndef] run-time
headerless
: single  (s -- )  \ Turns off multitasking
   ['] noop ['] pause (is
;
headers
: warm   (s -- )  single  sp0 @ sp!  quit  ;
[then]

[ifdef] omit-files
: read-line  ( adr len fd -- actual not-eof? error? )  3drop 0 true  ;
: .file-open-error  ( -- )  ;
[else]
\ From disk.fth

\ High level interface to disk files.

headerless

\ If the underlying operating system requires that files be accessed
\ in fixed-length records, then /fbuf must be a multiple of that length.
\ Even if the system allows arbitrary length file accesses, there is probably
\ a length that is particularly efficient, and /fbuf should be a multiple
\ of that length for best performance.  1K works well for many systems.

td 1024 constant /fbuf

headerless

\ An implementation factor which gets a file descriptor and attaches a
\ file buffer to it
headerless
: get-fd  ( -- )
   (get-fd  dup 0= ( ?? ) abort" all fds used "  ( fd )
   file !
   /fbuf alloc-mem  /fbuf initbuf     ( )
;
headers
\ Amount of space needed:
\   #fds * /fd     for automatically allocated file descriptors
\   1 * /fd        for "accept" descriptor
\   tib            for "accept" buffer
\
\ #fds = 8, so total of 9 * /fd  = 9 * 56 = 486 for fds
\ 8 * 1024 +  3 * 128  +  tib
\ Total is ~9K

\ Returns the current position within the current file

: dftell  ( fd -- d.byte# )
   file @ >r  file !  fstart 2@  bfcurrent @ bfbase @ -  0 d+  r> file !
;
: ftell  ( fd -- byte# )  dftell drop  ;

\ Updates the disk copy of the file to match the buffer
headerless
: fflush  ( fd -- )  file @ >r  file !  ?flushbuf  r> file !  ;
headers
\ Starting here, some stuff doesn't have to be in the kernel

\ Sets the position within the current file to "d.byte#".
: dfseek  ( d.byte# fd -- )
   file @ >r  file !
   sync

   \ See if the desired byte is in the buffer
   \ The byte is in the buffer iff offset.high is 0 and offset.low
   \ is less than the number of bytes in the buffer
   2dup fstart 2@ d-                   ( d.byte# offset.low offset.high )
   over bfend @ bfbase @ -  u>= or  if ( d.byte# offset )
      \ Not in buffer
      \ Flush the buffer and get the one containing the desired byte.
      drop ?flushbuf                         ( d.byte# )
      2dup byte#-aligned?  if                ( d.byte# )
         \ If the new offset is on a block boundary, don't read yet,
         \ because the next op could be a large write that fills the buffer.
         fstart 2!                           ( )
         bfbase @  dup bftop !  dup bfend !  ( bufaddr )
      else
         2dup fillbuf                        ( d.byte# )
         >bufaddr                            ( bufaddr )
      then                                   ( bufaddr )
   else
      \ The desired byte is already in the buffer.
      nip nip  bfbase @ +           ( bufaddr )
   then

   \ Seeking past end of file actually goes to the end of the file
   bftop @  umin   bfcurrent !
   r> file !
;
: fseek  ( byte# fd -- )  0 swap dfseek  ;

\ Returns true if the current file has reached the end.
\ XXX This may only be valid after fseek or shortseek
headerless
: (feof?  ( -- f )   bfcurrent @  bftop @  u>=  ;

headers
\ Gets the next byte from the current file
: fgetc  ( fd -- byte )
   file @ >r  file !   bfcurrent @  bftop @  u<
   if   \ desired character is in the buffer
      bfcurrent @c@++
   else \ end of buffer has been reached
      bfcurrent @ shortseek
      (feof?  if  eof  else  bfcurrent @c@++  then
   then
   r> file !
;

\ Stores a byte into the current file at the next position
: fputc  ( byte fd -- )
   file @ >r  file !
   bfcurrent @   bfend @ u>=     ( byte flag )  \ Is the buffer full?
   if  bfcurrent @ shortseek  then     ( byte ) \ If so advance to next buffer
   bfcurrent @c!++  bfdirty on
   r> file !
;

\ An implementation factor
\ Copyin copies bytes starting at current into the file buffer at
\ bfcurrent.  The number of bytes copied is either all the bytes from
\ current to end, if the buffer has enough room, or all the bytes the
\ buffer will hold, if not.
\ newcurrent is left pointing to the first byte not copied.
headerless
: copyin  ( end current -- end newcurrent )
   2dup -                      ( end current remaining )
   bfend @  bfcurrent @  -     ( end current remaining bfremaining )
   min                         ( end current #bytes-to-copy )
   dup if  bfdirty on  then    ( end current #bytes-to-copy )
   2dup  bfcurrent @ swap      ( end current #bytes  current bfcurrent #bytes)
   move                        ( end current #bytes )
   dup bfcurrent +!            ( end current #bytes )
   +                           ( end newcurrent)
;

\ Copyout copies bytes from the file buffer into memory starting at current.
\ The number of bytes copied is either enough to fill memory up to end,
\ if the buffer has enough characters, or all the bytes the
\ buffer has left, if not.
\ newcurrent is left pointing to the first byte not filled.
headerless
: copyout  ( end current -- end newcurrent )
   2dup -                      ( end current remaining )
   bftop @  bfcurrent @  -     ( end current remaining bfrem )
   min                         ( end current #bytes-to-copy)
   2dup bfcurrent @ rot rot    ( end current #bytes  current bfcurrent #bytes)
   move                        ( end current #bytes)
   dup  bfcurrent +!           ( end current #bytes)
   +                           ( end newcurrent )
;
headers
\ Writes count bytes from memory starting at "adr" to the current file
: fputs  ( adr count fd -- )
   file @ >r  file !
   over + swap                    ( endaddr startaddr )
   begin  copyin  2dup u>  while  ( endaddr curraddr )
      sync                        ( endaddr curraddr )
      \ Prefill? tries to avoid unnecessary reads by opening up space
      \ in the buffer for chunks that will completely fill a block.
      prefill?  if                ( endaddr curraddr )
         bfcurrent @ shortseek    ( endaddr curraddr )
      then
   repeat
   2drop
   r> file !
;

\ Reads up to count characters from the file into memory starting
\ at "adr"

: fgets  ( adr count fd -- #read )
   file @ >r  file !
   sync
   over + over  ( startaddr endaddr startaddr )
   begin  copyout  2dup u>
   while
      \ Here there should be some code to see if there are enough remaining
      \ bytes in the request to justify bypassing the file buffer and reading
      \ directly to the user's buffer.  'Enough' = more than one file buffer
      bfcurrent @ shortseek ( startaddr endaddr curraddr )
      (feof?  if  nip swap -  r> file !  exit then
   repeat
   nip swap -
   r> file !
;

\ Returns the current length of the file
: dfsize  ( fd -- d.size )
   file @ >r  file !
   sync
   fstart 2@  bftop @  bfbase @  -  0 d+  ( buffered-position )
   fid @  sizeop @  execute               ( buffered-position file-size )
   dmax
   r> file !
;
: fsize  ( fd -- size )  dfsize drop  ;


\ End of stuff that doesn't have to be in the kernel

defer do-fopen

\ Prepares a file for later access, returning "fd" which is subsequently
\ used to refer to the file.

: fopen  ( name mode -- fd )
   2 ?enough
   get-fd   ( name mode )  over >r  ( name mode )
   dup fmode !          \ Make descriptor busy now, in case of re-entry
   do-fopen  if
      setupfd  file @  r> count set-name
   else
      not-open fmode !  0  r> drop
   then
;

headers

\ Closes all the open files and reclaims their file descriptors.
\ Use this if you see an "all fds used" message.

: close-files ( -- )  fds @  /fds  bounds   do   i fclose   /fd +loop  ;

: create-file  ( name$ mode -- fileid ior )  8 or  open-file  ;

: make  ( name-pstr -- flag )	\ Creates an empty file
   count  r/w  create-file  if  drop false  else  close-file drop true  then
;

\ From readline.fth

headers
0 constant r/o
1 constant w/o
2 constant r/w
4 constant bin
8 constant create-flag

headerless
2 /n-t * ualloc-t user opened-filename
headers

: .file-open-error  ( -- )
   ." The file '"  opened-filename 2@ type  ." ' cannot be opened."
;

: open-file  ( adr len mode -- fd ior )
   file @ >r		\ Guard against re-entrancy

   >r 2dup opened-filename 2! cstrbuf pack r@ fopen   ( fd )  ( r: mode )

   \ Bail out now if the open failed
   dup  0=  if  d# -38  r> drop  r> file !  exit  then

   \ First initialize the delimiters to the default values for the
   \ underlying operating system, in case the file is initially empty.
   init-delims

   \ If the mode is neither "w/o" nor "binary", and the file isn't
   \ being newly created, establish the line delimiter(s) by looking
   \ for the first carriage return or line feed

   dup  r@ bin create-flag or  and 0=  and  r> w/o <> and  if
      dup set-line-delimiter
   then                                           ( fd )
   0                                              ( fd ior )
   r> file !
;
: close-file  ( fd -- ior )
   ?dup  0=  if  0  exit  then
   dup -1 =  if  drop 0  exit  then
   ['] fclose catch  ?dup  if  nip  else  0  then
;

: left-parse-string  ( adr len delim -- tail$ head$ )
   split-string  dup if  1 /string  then  2swap
;

headerless
: remaining$  ( -- adr len )  bfcurrent @  bftop @ over -  ;

: $set-line-delimiter  ( adr len -- )
   carret split-string  dup  if           ( head-adr,len tail-adr,len )
      carret line-delimiter c!            ( head-adr,len tail-adr,len )
      1 >  if                             ( head-adr,len tail-adr )
         dup 1+ c@ linefeed  =  if        ( head-adr,len tail-adr )
            carret pre-delimiter c!       ( head-adr,len tail-adr )
            linefeed line-delimiter c!    ( head-adr,len tail-adr )
         then                             ( head-adr,len tail-adr )
      then                                ( head-adr,len tail-adr )
   else                                   ( adr,len tail-adr,0 )
      2drop  linefeed split-string  if    ( head-adr,len tail-adr )
         0 pre-delimiter c!               ( head-adr,len tail-adr )
         linefeed line-delimiter c!       ( head-adr,len tail-adr )
      then                                ( head-adr,len tail-adr )
   then                                   ( head-adr,len tail-adr )
   3drop                                  ( )
;
: set-line-delimiter  ( fd -- )
   file @ >r  file !  0 0 fillbuf  remaining$  $set-line-delimiter  r> file !
;
: -pre-delimiter  ( adr len -- adr' len' )
   pre-delimiter c@  if
      dup  if
         2dup + 1- c@  pre-delimiter c@  =  if
            1-
         then
      then
   then
;

: parse-line-piece  ( adr len #so-far -- actual retry? )
   >r  2>r  ( r: #so-far adr len )

   remaining$                          ( fbuf$ )
   line-delimiter c@ split-string      ( head$ tail$ )  ( r: # adr len )

   2swap -pre-delimiter                ( tail$ head$')  ( r: # adr len )

   dup r@  u>=  if                     ( tail$ head$ )  ( r: # adr len )
      \ The parsed line doesn't fit into the buffer, so we consume
      \ from the file buffer only the portion that we copy into the
      \ buffer.
      over r@ +  bfcurrent !           ( tail$ head$ )
      drop nip nip                     ( head-adr )  ( r: # adr len )
      2r> dup >r  move                 ( )           ( r: # len )
      2r> + false                      ( actual don't-retry )
      exit
   then                                ( tail$ head$ )  ( r: # adr len )

   \ The parsed line fits into the buffer, so we copy it all in
   tuck  2r> drop  swap  move          ( tail$ head-len )  ( r: # )
   r> +  -rot                          ( actual tail$ )

   \ Consume the parsed line from the file buffer, including the
   \ delimiter if one was found (as indicated by nonzero tail-len)
   tuck  if  1+  then  bfcurrent !     ( actual tail-len )

   \ If a delimiter was found, increment the line number the next time.
   dup if  1 (file-line) +!  then

   \ If a delimiter was found, we need not retry.
   0=                                  ( actual retry? )
;

headers
: read-line  ( adr len fd -- actual not-eof? error? )
   file @ >r  file !
   0
   begin  >r 2dup r>  parse-line-piece  while   ( adr len actual )

      \ The end of the file buffer was reached without filling the
      \ argument buffer, so we refill the file buffer and try again.

      bftop @  ['] shortseek catch  ?dup  if  ( adr len actual x error-code )
         \ A file read error (more serious than end-of-file) occurred
         drop 2swap 2drop  false swap         ( actual false ior )
	 r> file !  exit
      then                                    ( adr len actual )
      remaining$  nip 0=  if                  ( adr len actual )

         \ Shortseek did not put any more characters into the file buffer,
         \ so we return the number of characters that were copied into the
	 \ argument buffer before shortseek was called and a flag.
         \ If no characters were copied into the argument buffer, the
         \ flag is false, indicating end-of-file

         nip  nip  dup 0<>  0                ( #copied not-eof? 0 )
         r> file !  exit
      then                                   ( adr len #copied )
      \ There are more characters in the file buffer, so we update
      \ adr len to reflect the portion of the buffer that has
      \ already been filled.
      dup >r /string r>                     ( adr' len' actual' )
   repeat                                   ( adr len actual )
   nip nip true 0                           ( actual true 0 )
   r> file !
;
\ Some more ANS Forth versions of file operations
: reposition-file  ( d.position fd -- ior )
   ['] dfseek catch  dup  if  nip nip nip  then
;
: file-size  ( fd -- d.size ior )
   ['] dfsize catch  dup if  0 0 rot  then
;
: read-file  ( adr len fd -- actual ior )
   ['] fgets catch  dup  if  >r 3drop 0 r>  then
;
: write-file  ( adr len fd -- actual ior )
   over >r  ['] fputs catch  dup  if   ( x x x ior )  ( r: len )
      r> drop  >r 3drop 0 r>           ( 0 ior )
   else                                ( ior )        ( r: len )
      r> swap                          ( len ior )
   then                                ( actual ior )
;
: flush-file  ( fd -- ior )  ['] fflush  catch  dup  if  nip  then  ;
: write-line  ( adr len fd -- ior )
   dup >r ['] fputs catch  ?dup  if  nip nip nip  r> drop exit  then  ( )
   pre-delimiter c@  if
      pre-delimiter c@  r@  ['] fputc catch  ?dup  if  ( x x ior )
         nip nip  r> drop exit
      then                                             ( )
   then
   line-delimiter c@  r>  ['] fputc catch  dup  if     ( x x ior )
      nip nip exit
   then                                                ( ior )
;
\ Missing: file-status, create-file, delete-file, resize-file, rename-file
[then]

\ From cstrings.fth

\ Conversion between Forth-style strings and C-style null-terminated strings.
\ cstrlen and cscount are defined in cmdline.fth

decimal

headerless
0 value cstrbuf		\ Initialized in
: init  ( -- )  init  102 alloc-mem is cstrbuf  ;

headers
\ Convert an unpacked string to a C string
: $cstr  ( adr len -- c-string-adr )
   \ If, as is usually the case, there is already a null byte at the end,
   \ we can avoid the copy.
   2dup +  c@  0=  if  drop exit  then
   >r   cstrbuf r@  cmove  0 cstrbuf r> + c!  cstrbuf
;

\ Convert a packed string to a C string
: cstr  ( forth-pstring -- c-string-adr )  count $cstr  ;

\ Find the length of a C string, not counting the null byte
: cstrlen  ( c-string -- length )
   dup  begin  dup c@  while  ca1+  repeat  swap -
;
\ Convert a null-terminated C string to an unpacked string
: cscount  ( cstr -- adr len )  dup cstrlen  ;

headers

\ From alias.fth

\ Alias makes a new word which behaves exactly like an existing
\ word.  This works whether the new word is encountered during
\ compilation or interpretation, and does the right thing even
\  if the old word is immediate.

decimal

: setalias  ( xt +-1 -- )
   0> if  immediate  then                ( acf )
   flagalias
   lastacf  here - allot   token,
;
: alias  \ new-name old-name  ( -- )
   create  hide  'i  reveal  setalias
;

\ From ansio.fth

headers
: allocate  ( size -- adr ior )  alloc-mem  dup 0=  ;

\ Assumes free-mem doesn't really need the size parameter; usually true
: free  ( adr -- ior )  0 free-mem 0  ;

headerless
nuser insane

headers
0 value exit-interact?

headerless
\ XXX check for EOF on keyboard stream
: more-input?  ( -- flag )  insane off  true  ;

headers
d# 1024 constant /tib

variable blk

headerless
defer ?block-valid  ( -- flag )  ' false is ?block-valid

headers
variable >in
variable #tib
nuser 'source-id
: source-id  ( -- fid )  'source-id @  ;

nuser 'source
nuser #source
: source-adr  ( -- adr )  'source @  ;
: source      ( -- adr len )  source-adr  #source @  ;
: set-source  ( adr len -- )  #source !  'source !  ;

: save-input  ( -- source-adr source-len source-id >in blk 5 )
   source  source-id  >in @  blk @  5
;
: restore-input  ( source-adr source-len source-id >in blk 5 -- flag )
   drop
   blk !  >in !  'source-id !  set-source
   false
;
: set-input  ( source-adr source-len source-id -- )
   0 0 5 restore-input drop
;
: parse-word  ( -- adr len )
   source >in @ /string  over >r   ( adr1 len1 )  ( r: adr1 )
   skipwhite                       ( adr2 len2 )
   scantowhite                     ( adr2 adr3 adr4 )
   r> - >in +!                     ( adr2 adr3 ) ( r: )
   over -                          ( adr1 len )
;
: parse  ( delim -- adr len )
   source >in @ /string  over >r   ( delim adr1 len1 )  ( r: adr1 )
   rot scantochar                  ( adr1 adr2 adr3 )  ( r: adr1 )
   r> - >in +!                     ( adr1 adr2 ) ( r: )
   over -                          ( adr1 len )
;
: word  ( delim -- pstr )
   source >in @ /string  over >r   ( delim adr1 len1 )  ( r: adr1 )
   rot >r r@ skipchar              ( adr2 len2 )        ( r: adr1 delim )
   r> scantochar                   ( adr2 adr3 adr4 )   ( r: adr1 )
   r> - >in +!                     ( adr2 adr3 ) ( r: )
   over -                          ( adr1 len )
   dup d# 255 >  ( -18 ) abort" Parsed string overflow"
   'word pack                      ( pstr )
;

: refill  ( -- more? )
   blk @  if  1 blk +!  ?block-valid  exit  then

   source-id  -1 =  if  false exit  then
   source-adr					     ( adr )
   source-id  if                                     ( adr )
      /tib source-id read-line
      ( -37 ) abort" Read error in refill"  ( cnt more? )
      over /tib = ( -18 ) abort" line too long in input file"  ( cnt more? )
   else                                              ( adr )
      \ The ANS Forth standard does not mention the possibility
      \ that ACCEPT might not be able to deliver any more input,
      \ but in this implementation, the `keyboard' can be redirected
      \ to a file via the command line, so it is indeed possible for
      \ ACCEPT to have no more characters to deliver.  Furthermore,
      \ we also provide a "finished" flag that can be set to force an
      \ exit from the interpreter loop.
      /tib accept  insane off                        ( cnt )
      dup  if  true  else  more-input?  then         ( cnt more? )
   then                                              ( cnt more? )
   swap  #source !  0 >in !                          ( more? )
;

: (prompt)  ( -- )
   interactive?  if	\ Suppress prompt if input is redirected to a file
      ??cr status
      state @  if
         level @  ?dup if  1 .r  else  ."  "  then  ." ] "
      else
         (ok)
      then
      mark-output
   then
;

: (interact)  ( -- )
   tib /tib 0 set-input
   [compile] [
   begin
      depth 0<  if  ." Stack Underflow" cr  clear  then
      sp@  sp0 @  ps-size -  u<  if  ." Stack Overflow" cr  clear  then
      do-prompt
   refill  while
      ['] interpret catch  ??cr  ?dup if
         [compile] [  .error
	 \ ANS Forth sort of requires the following "clear", but it's a
	 \ real pain and doesn't affect programs, so we don't do it
\        clear
      then
   exit-interact? until then
   false is exit-interact?
;
: interact  ( -- )
   save-input  2>r 2>r 2>r
   (interact)
   2r> 2r> 2r> restore-input  throw
;
: (quit)  ( -- )
   \ XXX We really should clean up any open input files here...
   0 level !  ]
   rp0 @ rp!
   interact
   bye
;

: interpret-lines  ( -- )  begin  refill  while  interpret  repeat  ;

: (evaluate)  ( adr len -- )
   begin  dup  while         ( adr len )
      parse-line  2>r        ( head$ )    ( r: tail$ )
      -1 set-input           ( )          ( r: tail$ )
      interpret              ( )          ( r: tail$ )
      2r>                    ( adr len )
   repeat                    ( adr len )
   2drop
;

: evaluate  ( adr len -- )
   save-input  2>r 2>r 2>r   ( adr len )
   ['] (evaluate) catch  dup  if  nip nip  then   ( error# )
   2r> 2r> 2r> restore-input  throw               ( error# )
   throw
;

defer prompt  ( -- )   ' (prompt) is prompt

defer quit  ' (quit) is quit

[ifdef] omit-files
: process-command-line  ( -- )  ;
[else]
: include-file  ( fid -- )
   /tib 4 + allocate throw	( fid adr )
   save-input 2>r 2>r 2>r       ( fid adr )

   /tib rot set-input

   ['] interpret-lines catch    ( error# )
   source-id close-file drop    ( error# )

   source-adr free drop         ( error# )

   2r> 2r> 2r> restore-input  throw  ( error# )
   throw
;
defer $open-error        ' noop is $open-error
defer include-hook       ' noop is include-hook
defer include-exit-hook  ' noop is include-exit-hook

: include-buffer  ( adr len -- )
   open-buffer  ?dup  if  " <buffer>" $open-error  then  include-file
;

: $abort-include  ( error# filename$ -- )  2drop  throw  ;
' $abort-include is $open-error

: included  ( adr len -- )
   include-hook
   r/o open-file  ?dup  if
      opened-filename 2@ $open-error
   then                 ( fid )
   include-file
   include-exit-hook
;
: including  ( "name" -- )  safe-parse-word included  ;
: fl  ( "name" -- )  including  ;

0 value error-file
: init  ( -- )  init  d# 128 alloc-mem  is error-file  ;
nuser error-line#
nuser error-source-id
nuser error-source-adr
nuser error-#source
: (mark-error)  ( -- )
   \ Suppress message if input is interactive or from "evaluate"
   source-id  error-source-id !
   source-id  0<>  if
      source-id  -1 =  if
         source error-#source !  error-source-adr !
      else
         source-id file-name error-file place
         source-id file-line error-line# !
      then
   then
;
' (mark-error) is mark-error
: (show-error)  ( -- )
   ??cr
   error-source-id @  if
      error-source-id @ -1  =  if
         ." Evaluating: " error-source-adr @ error-#source @  type cr
      else
         error-file count type  ." :"
         base @ >r decimal  error-line# @ (.) type  r> base !
         ." : "
      then
   then
;
' (show-error) is show-error

\ Environment?

defer environment?
: null-environment?  ( c-addr u -- false | i*x true )  2drop false  ;
' null-environment? is environment?

: fload fl ;

: $report-name  ( name$ -- name$ )
   ." Loading " 2dup type cr
;
: fexit ( -- )  source-id close-file drop -1 'source-id !  ;

\ From copyright.fth

: id: [compile] \ ;
: copyright: [compile] \ ;
: purpose: [compile] \ ;
: build-now ;
: command: [compile] \ ;
: in: [compile] \ ;
: dictionary: [compile] \ ;

\ From cmdline.fth

\ Get the arguments passed from the program

\ Returns the command line argument indexed by arg#, as a string.
\ In most systems, the 0'th argument is the name of the program file.
\ If the arg#'th argument doesn't exist, returns 0.
: >arg  ( arg# -- false | arg-adr arg-len true )
   dup #args >=  if  ( arg# )
      drop false
   else              ( arg# )
      args swap na+ @  cscount true
   then
;

variable arg#

\ Get the next argument from the command line.
\ Returns 0 when there are no more arguments.
\ arg# should be set to 1 before the first call.
\ argument number 0 is usually the name of the program file.
: next-arg  ( -- false  | arg-adr arg-len true )
   arg# @  >arg  dup  if  1 arg# +!  then
;

: process-argument  ( adr len -- )
   2dup  " -s"  $=  if       ( adr len )
      2drop next-arg  0= ( ?? ) abort" Missing argument after '-s'"
      evaluate               ( ?? )
   else                      ( adr len )
   2dup  " -"  $=  if        ( adr len )      
      2drop
      interact
   else                      ( adr len )
      included
\     "temp npack  "load      ( ?? )
   then then
;

: process-command-line  ( -- )
   #args  1 <=  if  exit  then
   1 arg# !
   begin  next-arg  while  ( adr len )
      ['] process-argument  catch  ?dup  if  .error  error-exit  then
   repeat
   bye
;
[then]

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
