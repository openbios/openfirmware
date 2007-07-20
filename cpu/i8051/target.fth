\ See license at end of file
\ Target configuration - i8051

only forth also definitions

decimal

only forth also meta definitions

: note-string-t  ( adr len -- adr len )  ;

: lobyte h# 0ff and ;
: hibyte 8 rshift lobyte ;

2 constant /w-t
: /l-t true abort" /l-t called" ;
: l,-t true abort" l,-t called" ;
/w-t constant /n-t
/w-t constant /a-t
/a-t constant /thread-t
3 constant /token-t   \ ljmp <adr>
/w-t constant /link-t
/token-t constant /defer-t
h# 80 constant user-size-t
\ /n-t h# 100 * constant ps-size-t
\ /n-t h# 100 * constant rs-size-t
/w-t constant /user#-t

\ user-size-t h# 10000 + constant max-kernel-t

\ 32 bit host Forth compiling 16-bit target Forth

: n->n-t ; immediate
: n->l-t ; immediate
: s->l-t ; immediate

: c!-t ( n add -- ) >hostaddr c! ;
: c@-t ( target-address -- n ) >hostaddr c@ ;

\ Store data in little endian
: w!-t ( n add -- )  over lobyte over c!-t  ca1+ swap hibyte swap c!-t  ;
: w@-t ( target-address -- n )  dup c@-t swap 1+ c@-t 8 << or  ;

\ ljmp addresses are big endian
: be-w!-t  ( n target-address -- )  over lobyte over ca1+ c!-t  swap hibyte swap c!-t  ;
: be-w@-t  ( target-address -- n )  dup + c@-t swap c@-t 8 << or  ;

alias le-w!-t w!-t
alias le-w@-t w@-t

: !-t  ( n add -- ) w!-t ;
: @-t  ( target-address -- n ) w@-t ;

\ Store target data types into the host address space.
: c-t!  ( c host-address -- )  c!  ;
: w-t!  ( w host-address -- )
   over lobyte  over c-t!  ca1+  swap hibyte swap c-t!
;
: n-t!  ( n host-address -- )  w-t!  ;

\ Next 2 are machine-independent
: c,-t ( byte -- )  dp-t @ c!-t 1 dp-t +! ;
: w,-t ( word -- )  dp-t @ w!-t /w-t dp-t +! ;

: ,-t ( n -- )  w,-t ;
: ,user#-t ( user# -- )  w,-t  ;

: a@-t ( target-address -- target-address )  w@-t  origin-t +  ;
: a!-t ( token target-address -- )  swap  origin-t -  swap  w!-t  ;
: token@-t ( target-address -- target-acf )  1+ a@-t  ;
: token!-t ( acf target-address -- )  h# 12 over c!-t  1+ be-w!-t  ;  \ lcall instruction

: rlink@-t  ( occurrence -- next-occurrence )  w@-t  origin-t +  ;
: rlink!-t  ( next-occurrence occurrence -- ) swap  origin-t -  swap  w!-t  ;

: a,-t  ( adr -- )  here-t /a-t allot-t  a!-t  ;

\ These versions of linkx-t are for absolute links
: link@-t ( target-address -- target-address' )  a@-t  ;
: link!-t ( target-address target-address -- )  a!-t  ;
: link,-t ( target-address -- )  a,-t  ;

: a-t@ ( host-address -- target-address )  w@  origin-t +  ;
: a-t! ( target-address host-address -- ) swap origin-t -  swap w!  ;
: rlink-t@  ( host-adr -- target-adr )  w@  origin-t +  ;
: rlink-t!  ( target-adr host-adr -- )  swap origin-t -  swap w!  ;

: token-t@ ( host-address -- target-acf )  a-t@  ;
: token-t! ( target-acf host-address -- )  a-t!  ;

: link-t@  ( host-address -- target-address )  a-t@  ;
: link-t!  ( target-address host-address -- )  a-t!  ;

: a-t, ( target-address -- )  here  /a-t allot  a-t!  ;
: token-t, ( target-address -- )  here  /token-t allot  token-t!  ;

\ Dictionary linked list; the list head is in the metacompiler environment
\ during metacompilation
1 constant #threads-t
create threads-t   #threads-t /link-t * allot

\ Choose the dictionary list head based on the word name
: $hash-t  ( str-addr voc-ptr -- thread )
   nip swap c@  #threads-t 1- and  /thread-t * +
;

\ The user area image lives in the host address space.
\ We wish to store into the user area with -t commands so as not
\ to need separate words to store target items into host addresses.
\ That is why user+ returns a target address.

\ Machine Independent

0 constant userarea-t
: setup-user-area ( -- )
   here-t  ['] userarea-t >body  l!
   here-t  ['] init-user-area >body !
   user-size-t allot-t
   userarea-t >hostaddr user-size-t  erase
;

: >body-t ( cfa-t -- pfa-t )  3 + w@-t  ;

: (>user-t)    ( cfa-t -- user-address-t )  >body-t  w@-t  userarea-t  +  ;
: >user-t  ( cfa-t -- user-address-h )  (>user-t)  >hostaddr  ;

: n>link-t ( anf-t -- alf-t )  /link-t - ;
: l>name-t ( alf-t -- anf-t )  /link-t + ;

decimal
1 constant #align-t
1 constant #talign-t
#align-t constant #acf-align-t

1 constant #linkalign-t
: aligned-t  ( n1 -- n2 )  #align-t 1- +  #align-t negate and  ;
: acf-aligned-t  ( n1 -- n2 )  #acf-align-t 1- +  #acf-align-t negate and  ;

: align-t ( -- )
   begin   here-t #align-t  1- and   while   0 c,-t   repeat
;
: talign-t ( -- )
   begin   here-t #talign-t 1- and   while   0 c,-t   repeat
;
: linkalign-t  ( -- )
   begin   here-t #linkalign-t 1- and   while   0 c,-t   repeat
;
: acf-align-t  ( -- )   align-t  ;

: entercode ( -- )
   only forth also labels also meta also 8051-assembler
;

\ Next 4 are Machine Independent
: cmove-t ( from to-t n -- )
   0 ?do over c@  over c!-t  1+ swap 1+ swap loop  2drop
;
: place-cstr-t  ( adr len cstr-adr-t -- cstr-adr-t )
   >r  tuck r@ swap cmove-t  ( len ) r@ +  0 swap c!-t  r>
;
: "copy-t ( from to-t -- )  over c@ 2+  cmove-t  ;
: toggle-t ( addr-t n -- ) swap >r r@ c@-t xor r> c!-t  ;

: clear-threads-t  ( hostaddr -- )
   #threads-t /link-t * bounds  do
      origin-t i link-t!
   /link +loop
;
: initmeta  ( -- )
\   init-relocation-t
   threads-t clear-threads-t  threads-t current-t !
;

\ For compiling branch offsets used by control constructs.
\ These compile relative branches.

\ XXX this is wrong.  We need to do some stuff like "lcall zerosense; jz <target>"
/w-t constant /branch
: branch! ( from-t target-addr-t -- )  over -  swap  ( offset from-t )   w!-t  ;
: branch, ( target-t -- )  here-t -  w,-t  ;

\ Store actions for some data types.

: isuser  ( n acf -- )  >user-t n-t!  ;
: istuser ( acf1 acf -- )  (>user-t) >hostaddr token-t!  ;
: isvalue ( n acf -- )  >user-t n-t!  ;
: isdefer ( acf acf -- )  (>user-t) >hostaddr token-t!  ;
: thread-t!  ( thread adr -- )  link-t!  ;

only forth also meta also definitions
: install-target-assembler  ( -- )
   [ also assembler ]
   ['] here-t  is here
   ['] allot-t is asm-allot
   ['] c!-t    is asm8!
   ['] c@-t    is asm8@
   [ previous meta ]
;
: install-host-assembler  ( -- )  [ assembler ] resident [ meta ]  ;

\ LICENSE_BEGIN
\ Copyright (c) 2007 FirmWorks
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
