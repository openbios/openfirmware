\ See license at end of file
\ Target configuration - 386

only forth also definitions

defer init-relocation-t
defer set-relocation-bit-t

decimal

meta assembler definitions
: normal ( -- )   \ Perform target-dependent assembler initialization
;

only forth also meta definitions

: lobyte th 0ff and ;
: hibyte 8 >> lobyte ;

\t16-t 2 constant tshift-t
2 constant /w-t
4 constant /l-t
/l-t constant /n-t
\t16-t /w-t constant /a-t
\t32-t /l-t constant /a-t
/a-t constant /thread-t
\t16-t /w-t constant /token-t
\t32-t /l-t constant /token-t
\t16-t /w-t constant /link-t
\t32-t /l-t constant /link-t
/token-t constant /defer-t
[ifdef] omit-files
/n-t th 100 * constant user-size-t
[else]
[ifdef] big-endian-t	\ reloc code uses 300 in both cases. should we?????
/n-t th 600 * constant user-size-t
[else]
/n-t th c00 * constant user-size-t
[then]
[then]
/n-t th 100 * constant ps-size-t
/n-t th 100 * constant rs-size-t
\t16-t /w-t constant /user#-t
\t32-t /l-t constant /user#-t

user-size-t th 10000 + constant max-kernel-t

\ 32 bit host Forth compiling 32-bit target Forth
: l->n-t ; immediate
: n->l-t ; immediate
: n->n-t ; immediate
: s->l-t ; immediate

: c!-t ( n add -- ) >hostaddr c! ;
: c@-t ( target-address -- n ) >hostaddr c@ ;

[ifdef] big-endian-t
\ This is for the version that simulated big-endian for binary
\ compatibility with 68K
: le-w!-t ( n add -- )  over lobyte over c!-t  ca1+ swap hibyte swap c!-t  ;
: le-l!-t ( l add -- )  >r lwsplit swap r@ le-w!-t r> /w-t + le-w!-t ;

: le-w@-t ( target-address -- n )  dup c@-t swap 1+ c@-t 8 << or  ;
: le-l@-t ( target-address -- n )
   dup >r /w-t + le-w@-t  r> le-w@-t  swap wljoin
;
: le@  ( adr -- l )  @ lbsplit  2swap swap 2swap swap bljoin  ;
: le!  ( l adr -- )  >r  lbsplit  2swap swap 2swap swap bljoin  r>  !  ;

: w!-t ( n add -- )  over hibyte over c!-t   ca1+ swap lobyte swap c!-t  ;
: l!-t ( l add -- )  >r lwsplit r@ w!-t r> /w-t + w!-t ;

: w@-t ( target-address -- n )  dup c@-t 8 << swap 1+ c@-t or  ;
: l@-t ( target-address -- n )  dup >r /w-t + w@-t  r> w@-t  wljoin  ;
[else]
\ Intel processors are little-endian
: w!-t ( n add -- )  over lobyte over c!-t  ca1+ swap hibyte swap c!-t  ;
: l!-t ( l add -- )  >r lwsplit swap r@ w!-t r> /w-t + w!-t  ;

: w@-t ( target-address -- n )  dup c@-t swap 1+ c@-t 8 << or  ;
: l@-t ( target-address -- n )  dup >r /w-t + w@-t  r> w@-t  swap wljoin  ;

alias le-w!-t w!-t
alias le-l!-t l!-t
alias le-w@-t w@-t
alias le-l@-t l@-t
[then]
: !-t  ( n add -- ) l!-t ;
: @-t  ( target-address -- n ) l@-t ;

\ Store target data types into the host address space.
: c-t!  ( c host-address -- )  c!  ;
: w-t!  ( w host-address -- )
   over lobyte  over c-t!  ca1+  swap hibyte swap c-t!
;
: l-t!  ( l host-address -- )  >r  lwsplit  swap r@ w-t!  r> /w-t + w-t!  ;
: n-t!  ( n host-address -- )  l-t!  ;
: l-t@  ( host-address -- l )  compilation-base - l@-t  ;

\ Next 3 are machine-independent
: c,-t ( byte -- )  dp-t @ c!-t 1 dp-t +! ;
: w,-t ( word -- )  dp-t @ w!-t /w-t dp-t +! ;
: l,-t ( long -- )  dp-t @ l!-t /l-t dp-t +! ;

: ,-t ( n -- )  l,-t ;  \ for 32 bit stacks
: ,user#-t ( user# -- )
\t32-t  l,-t
\t16-t  w,-t
;

: a@-t ( target-address -- target-address )
\t16-t   w@-t tshift-t <<  origin-t +
[ifdef] big-endian-t
         le-l@-t
[else]
\t32-t   l@-t
[then]
;
: a!-t ( token target-address -- )
  set-relocation-bit-t
\t16-t   swap  origin-t -  tshift-t >>  swap  w!-t
[ifdef] big-endian-t
         le-l!-t
[else]
\t32-t   l!-t
[then]
;
: token@-t ( target-address -- target-acf )  a@-t  ;
: token!-t ( acf target-address -- )  a!-t  ;

: rlink@-t  ( occurrence -- next-occurrence )
\t16-t   w@-t 1 <<  origin-t +
\t32-t   a@-t
;
: rlink!-t  ( next-occurrence occurrence -- )
\t16-t   swap  origin-t -  1 >>  swap  w!-t
\t32-t   token!-t
;

\ Machine independent
: a,-t  ( adr -- )  here-t /a-t allot-t  a!-t  ;
: token,-t ( token -- )
   here-t /token-t allot-t  token!-t
;

\ These versions of linkx-t are for absolute links
: link@-t ( target-address -- target-address' )  a@-t  ;
: link!-t ( target-address target-address -- )  a!-t  ;
: link,-t ( target-address -- )  a,-t  ;

: a-t@ ( host-address -- target-address )
\t16-t  w@ tshift-t <<  origin-t +
[ifdef] big-endian-t
        le@
[else]
\t32-t  l-t@
[then]
;
: a-t! ( target-address host-address -- )
\t16-t  swap origin-t -  tshift-t >> swap w!
[ifdef] big-endian-t
        le!
[else]
\t32-t  l-t!
[then]
;
: rlink-t@  ( host-adr -- target-adr )
\t16-t  w@ 1 <<  origin-t +
[ifdef] big-endian-t
        le@
[else]
\t32-t  l-t@
[then]
;
: rlink-t!  ( target-adr host-adr -- )
\t16-t  swap origin-t -  1 >> swap w!
[ifdef] big-endian-t
        le!
[else]
\t32-t  l-t!
[then]
;

: token-t@ ( host-address -- target-acf )  a-t@  ;
: token-t! ( target-acf host-address -- )  a-t!  ;

: link-t@  ( host-address -- target-address )  a-t@  ;
: link-t!  ( target-address host-address -- )
   dup hostaddr>  dup origin-t here-t within  if  set-relocation-bit-t  then
   drop

   a-t!
;

\ Machine independent
: a-t, ( target-address -- )  here  /a-t allot  a-t!  ;
: token-t, ( target-address -- )
   here  /token-t allot  token-t!
;
: >body-t ( cfa-t -- pfa-t )  /n-t +  ;   \ Indirect threaded

[ifdef] big-endian-t
d# 4 constant #threads-t
[else]
1 constant #threads-t
[then]
create threads-t   #threads-t /link-t * allot

: $hash-t ( str-addr voc-ptr -- thread )
   nip swap c@  #threads-t 1- and  /thread-t * +
;

\ Should allocate these dynamically.
\ The dictionary space should be dynamically allocated too.

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

: (>user-t)    ( cfa-t -- user-address-t )
   >body-t
\t32-t   @-t
\t16-t  w@-t
   userarea-t  + 
;
: >user-t  ( cfa-t -- user-address-h )
   (>user-t)  >hostaddr
;

: n>link-t ( anf-t -- alf-t )  /link-t - ;
: l>name-t ( alf-t -- anf-t )  /link-t + ;

decimal
[ifdef] big-endian-t
4 constant #align-t
4 constant #talign-t
[else]	\ reloc uses 2 ...
4 constant #align-t
4 constant #talign-t
[then]
#align-t constant #acf-align-t

\t16-t 1 tshift-t << constant #linkalign-t
\t32-t 1 constant #linkalign-t
: aligned-t  ( n1 -- n2 )  #align-t 1- +  #align-t negate and  ;
: acf-aligned-t  ( n1 -- n2 )  #acf-align-t 1- +  #acf-align-t negate and  ;

\ NullFix bl -> 0
: align-t ( -- )
   begin   here-t #align-t  1- and   while   0 c,-t   repeat
;
: talign-t ( -- )
   begin   here-t #talign-t 1- and   while   0 c,-t   repeat
;
: linkalign-t  ( -- )
   begin   here-t #linkalign-t 1- and   while   0 c,-t   repeat
;
\t16-t : acf-align-t  ( -- )   align-t  ;
\t32-t : acf-align-t  ( -- )  talign-t  ;

: entercode ( -- )
   only forth also labels also meta also 386-assembler
\   assembler
   [ assembler ] normal [ meta ]
;

\ Next 4 are Machine Independent
: cmove-t ( from to-t n -- )
  0 ?do over c@  over c!-t  1+ swap 1+ swap loop  2drop
;
: place-cstr-t  ( adr len cstr-adr-t -- cstr-adr-t )
   >r  tuck r@ swap cmove-t  ( len ) r@ +  0 swap c!-t  r>
;
: "copy-t ( from to-t -- )
  over c@ 2+  cmove-t
;
: toggle-t ( addr-t n -- ) swap >r r@ c@-t xor r> c!-t ;

: clear-threads-t  ( hostaddr -- )
   #threads-t /link-t * bounds  do
      origin-t i link-t!
   /link +loop
;
: initmeta  ( -- )
   init-relocation-t
   threads-t clear-threads-t  threads-t current-t !
;

\ For compiling branch offsets used by control constructs.
\ These compile relative branches.

\t16-t /w-t constant /branch
\t32-t /l-t constant /branch
: branch! ( from-t target-addr-t -- )
   over -  swap  ( offset from-t )
\t16-t   w!-t
\t32-t   l!-t
;
: branch, ( target-t -- )
   here-t -
\t16-t   w,-t
\t32-t   l,-t
;

\ Store actions for some data structures.  This has to be in this
\ file because it depends on the location of the user area (in the
\ 680x0 version, the user area has to be in the dictionary for
\ relocation to work right, but that is not true for the SPARC
\ version.  Ultimately, separate relocation for the user area is
\ needed.  The relocation probably should be automatic, by looking
\ at the storage address.

: isuser  ( n acf -- )  >user-t n-t!  ;
: istuser ( acf1 acf -- )  (>user-t) set-relocation-bit-t >hostaddr token-t!  ;
: isvalue ( n acf -- )  >user-t n-t!  ;
: isdefer ( acf acf -- )  (>user-t) set-relocation-bit-t >hostaddr token-t!  ;
: thread-t!  ( thread adr -- )  link-t!  ;

only forth also meta also definitions
: install-target-assembler  ( -- )
   [ also assembler ]
\   ['] dp-t   is asmdp
   ['] here-t  is here
   ['] allot-t is asm-allot
   ['] c!-t    is asm8!
\   [ previous ]   ['] set-relocation-bit-t
\   [ also assembler ] is asm-set-relocation-bit
   [ previous meta ]
;
: install-host-assembler  ( -- )
   [ assembler ] resident 
\   [ meta ]  ['] set-relocation-bit
\   [ assembler ] is asm-set-relocation-bit
[ meta ]
;
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
