purpose: Metacompiler target configuration for PowerPC
\ See license at end of file

only forth also meta definitions
defer init-relocation-t
defer set-relocation-bit-t

decimal

h# c000 constant max-kernel                 \ Maximum size of the kernel

only forth also meta assembler definitions
: normal ( -- )   \ Perform target-dependent assembler initialization
;

only forth also meta definitions

: lobyte th 0ff and ;
: hibyte 8 >> lobyte ;

2 constant /w-t
4 constant /l-t
/l-t constant /n-t
/l-t constant /a-t
/a-t constant /thread-t
/l-t constant /token-t
/l-t constant /link-t
/token-t constant /defer-t
/n-t th 800 * constant user-size-t
/n-t th 100 * constant ps-size-t
/n-t th 200 * constant rs-size-t
/l-t constant /user#-t

\ 32 bit host Forth compiling 32-bit target Forth
: l->n-t ; immediate
: n->l-t ; immediate
: n->n-t ; immediate
: s->l-t ; immediate

[ifdef] little-endian
\ little-endian versions
\ The address munging (7 xor) with c@/!-t is due to the fact that
\ the system loads the target image in big-endian mode, and then
\ switches to little-endian mode after executing a few instructions.
: c!-t ( n add -- ) >hostaddr 7 xor c! ;
: w!-t ( n add -- )  over lobyte over c!-t  ca1+ swap hibyte swap c!-t  ;
: l!-t ( l add -- )  >r lwsplit swap r@ w!-t r> /w-t + w!-t  ;
: c@-t ( target-address -- n ) >hostaddr 7 xor c@ ;
: w@-t ( target-address -- n )  dup c@-t swap 1+ c@-t 8 << or  ;
: l@-t ( target-address -- n )  dup >r /w-t + w@-t  r> w@-t  swap wljoin  ;
[else]
\ big-endian versions
: c!-t ( n add -- ) >hostaddr c! ;
: w!-t ( n add -- )  over hibyte over c!-t  ca1+ swap lobyte swap c!-t  ;
: l!-t ( l add -- )  ( set-swap-bit-t )  >r lwsplit r@ w!-t r> /w-t + w!-t  ;
: c@-t ( target-address -- n ) >hostaddr c@ ;
: w@-t ( target-address -- n )  dup c@-t 8 << swap 1+ c@-t or  ;
: l@-t ( target-address -- n )  dup >r /w-t + w@-t  r> w@-t  wljoin  ;
[then]

: le-l!-t ( l add -- )  >r lwsplit swap r@ w!-t r> /w-t + w!-t  ;
: be-l!-t ( l add -- )  >r lwsplit      r@ w!-t r> /w-t + w!-t  ;

: !-t  ( n add -- ) l!-t ;
: @-t  ( target-address -- n ) l@-t ;

\ Store target data types into the host address space.
: c-t!  ( c host-address -- )  c!  ;
: w-t!  ( w host-address -- )
   over hibyte  over c-t!  ca1+  swap lobyte swap c-t!
;
: l-t!  ( l host-address -- )  >r  lwsplit  r@ w-t!  r> /w-t + w-t!  ;
: n-t!  ( n host-address -- )  l-t!  ;

: c,-t ( byte -- )  here-t dup set-swap-bit-t  1 allot-t  c!-t ;
: w,-t ( word -- )  here-t /w-t allot-t w!-t ;
: l,-t ( long -- )  here-t /l-t allot-t l!-t ;

: ,-t ( n -- )  l,-t ;  \ for 32 bit stacks
: ,user#-t ( user# -- )  l,-t  ;

: a@-t ( target-address -- target-address )  l@-t  ;
: a!-t ( token target-address -- )  ( set-relocation-bit-t )  l!-t  ;
: token@-t ( target-address -- target-acf )  a@-t  ;
: token!-t ( acf target-address -- )  a!-t  ;

: rlink@-t  ( occurrence -- next-occurrence )  a@-t  ;
: rlink!-t  ( next-occurrence occurrence -- )  token!-t  ;


\ Machine independent
: a,-t  ( adr -- )  here-t /a-t allot-t  a!-t  ;
: token,-t ( token -- )  here-t /token-t allot-t  token!-t  ;

\ These versions of linkx-t are for absolute links
: link@-t ( target-address -- target-address' )  a@-t  ;
: link!-t ( target-address target-address -- )  a!-t  ;
: link,-t ( target-address -- )  a,-t  ;

: a-t@ ( host-address -- target-address )
[ also forth ]
   dup  origin here within  over up@  dup user-size +  within  or  if
[ previous ]
      l@
   else
      hostaddr> a@-t
   then
;
: a-t! ( target-address host-address -- )
[ also forth ]
   dup  origin here within  over up@  dup user-size +  within  or  if
[ previous ]
      l!
   else   
      hostaddr> a!-t
   then
;
: rlink-t@  ( host-adr -- target-adr )  a-t@  ;
: rlink-t!  ( target-adr host-adr -- )  a-t!  ;

: token-t@ ( host-address -- target-acf )  a-t@  ;
: token-t! ( target-acf host-address -- )  a-t!  ;
: link-t@  ( host-address -- target-address )  a-t@  ;
: link-t!  ( target-address host-address -- )  a-t!  ;

\ Machine independent
: a-t, ( target-address -- )  here  /a-t allot  a-t!  ;
: token-t, ( target-address -- )  here  /token-t allot  token-t!  ;
: >body-t  ( cfa-t -- pfa-t )
   \ The code fields of DOES> and ;CODE words contain an extra token
   " dodoes" ['] labels $vfind  if
      execute
      over token@-t  =  if  /token-t +  then
   else
      drop
   then
   /token-t +
;


\ 32 constant #threads-t
1 constant #threads-t
create (threads-t)    #threads-t 1+ /link-t * allot
: threads-t  ( -- adr )  (threads-t)  7 + 7 invert and  ;

: $hash-t  ( adr len voc-ptr -- thread )
   -rot nip #threads-t 1- and  /thread-t * +
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
   user-size-t alloc-mem is userarea-t
   userarea-t user-size-t  erase
;

: >user-t ( cfa-t -- user-address-t )
   >body-t
   @-t
   userarea-t  +
;

: n>link-t ( anf-t -- alf-t )  /link-t - ;
: l>name-t ( alf-t -- anf-t )  /link-t + ;

decimal
/l constant #align-t
/l constant #talign-t
/l constant #linkalign-t
/l constant #acf-align-t
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
: acf-align-t  ( -- )  talign-t  ;

: entercode ( -- )
   only forth also labels also meta also ppc-assembler
   [ also ppc-assembler ]
   ['] $ppc-assem-do-undefined is $do-undefined
   [ previous ]
\   assembler
;

\ Next 5 are Machine Independent
: cmove-t ( from to-t n -- )
  0 do over c@  over c!-t  1+ swap 1+ swap loop  2drop
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
  init-swap-t
  threads-t   #threads-t /link-t * bounds  do
     origin-t i link-t!
  /link +loop
  threads-t current-t !
;

\ For compiling branch offsets used by control constructs.
\ These compile relative branches.

/l-t constant /branch
: branch! ( offset addr-t -- )
   over - ( from offset ) swap
   l!-t
;
: branch, ( offset -- )
   here-t -
   l,-t
;

\ Store actions for some data structures.  This has to be in this
\ file because it depends on the location of the user area (in some
\ versions, the user area has to be in the dictionary for
\ relocation to work right, but in other versions, the user area
\ is elsewhere.  Ultimately, separate relocation for the user area is
\ needed.

: isuser   ( n acf -- )     >user-t n-t!  ;
: istuser  ( acf1 acf -- )  >user-t token-t!  ;
: isvalue  ( n acf -- )     >user-t n-t!  ;
: isdefer  ( acf acf -- )   >user-t token-t!  ;

: thread-t!  ( thread adr -- )  link-t!  ;

only forth also meta also definitions
: install-target-assembler  ( -- )
   [ assembler ]
\   ['] dp-t   is asmdp
   ['] here-t  is here
   ['] allot-t is asm-allot
   ['] l@-t    is asm@
   ['] l!-t    is asm!
   [ meta ]
;
: install-host-assembler  ( -- )
   [ assembler ] resident-assembler [ meta ]
;

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
