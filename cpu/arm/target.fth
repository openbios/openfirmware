purpose: Target-dependent definitions for metacompiling the kernel for ARM
\ See license at end of file

hex
defer init-relocation-t
defer set-relocation-bit-t

18000 constant max-kernel           \ Maximum size of the kernel

only forth also  meta also definitions


variable protocol?   protocol? off        \ true -> information about compiled code
variable last-protocol

: .data         ( n adr -- )
        push-hex
        last-protocol @ 0ffffff0 and  over 0ffffff0  and <>
        over d# 12 and  3 * d# 15 + dup >r  #out @ <  or
        if      cr 0ffffff0 and dup  last-protocol !  9 u.r
        else    drop
        then
        r> to-column  8 u.r
	pop-base
;
: .protocol  ( c t-adr -- )  protocol? @  if  2dup .data  then  ;

: lobyte        0ff and ;
: hibyte        8 >> lobyte ;

         2 constant /w-t
         4 constant /l-t
      /l-t constant /n-t
      /l-t constant /a-t
      /a-t constant /thread-t
      /l-t constant /token-t
      /l-t constant /link-t
/token-t   constant /defer-t
/n-t th 1000 * constant user-size-t
/n-t th 200 * constant ps-size-t
/n-t th 200 * constant rs-size-t
/l-t constant /user#-t

\ 32 bit host Forth compiling 32-bit target Forth
: l->n-t ; immediate
: n->l-t ; immediate
: n->n-t ; immediate
: s->l-t ; immediate

: c!-t  ( n adr -- )  >hostaddr c! ;
: c@-t  ( adr -- n )  >hostaddr c@ ;
\ : w!-t  ( n adr -- )    .protocol >hostaddr le-w! ;
\ : w@-t  ( t-adr -- n )  >hostaddr le-w@ ;

: l!-t  ( l adr -- )    .protocol >hostaddr le-l! ;
: l@-t  ( t-adr -- l )  >hostaddr le-l@ ;

: !-t   ( n adr -- )    l!-t ;
: @-t   ( t-adr -- n )  l@-t ;

\ Store target data types into the host address space.
: c-t!  ( c h-adr -- )  c! ;
\ : w-t!  ( w h-adr -- )  le-w! ;
: l-t!  ( l h-adr -- )  le-l! ;
: n-t!  ( n h-adr -- )  l-t!  ;

: c-t@  ( host-address -- c )  c@  ;
: l-t@  ( host-address -- l )  le-l@  ;

\ Next 3 are machine-independent
\ Next 3 are machine-independent
: c,-t ( byte -- )  here-t    1 allot-t c!-t ;
: w,-t  true abort" Called w,-t"  ;
\ : w,-t ( word -- )  here-t /w-t allot-t w!-t ;
: l,-t ( long -- )  here-t /l-t allot-t l!-t ;

: ,-t      ( adr -- )           l,-t ;
: ,user#-t ( user# -- )         l,-t ;

: a@-t     ( t-adr -- t-adr )   l@-t ;
: a!-t     ( token t-adr -- )   set-relocation-bit-t l!-t ;
: token@-t ( t-adr -- t-adr )   a@-t  ;
: token!-t ( token t-adr -- )   a!-t  ;

: rlink@-t  ( occurrence -- next-occurrence )  a@-t  ;
: rlink!-t  ( next-occurrence occurrence -- )  token!-t  ;


\ Machine independent
: a,-t     ( adr -- )   here-t /a-t allot-t  a!-t  ;
: token,-t ( token -- ) here-t /token-t allot-t  token!-t  ;

\ These versions of linkx-t are for absolute links
: link@-t  ( t-adr -- t-adr' )   a@-t  ;
: link!-t  ( t-adr t-adr -- )    a!-t  ;
: link,-t  ( t-adr -- )          a,-t  ;
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

: token-t@ ( host-adr -- t-adr ) a-t@  ;
: token-t! ( t-adr host-adr -- ) a-t!  ;
: link-t@  ( host-adr -- t-adr ) a-t@  ;
: link-t!  ( t-adr host-adr -- ) a-t!  ;

\ Machine independent
: a-t,     ( t-adr -- )         here /a-t allot  a-t!  ;
: token-t, ( t-adr -- )         here /token-t allot token-t! ;
: >body-t  ( cfa-t -- pfa-t )
        dup l@-t  ff000000 and eb000000 =
        if /l-t + then ;

1 constant #threads-t       \ Must be a power of 2
create threads-t   #threads-t 1+ /link-t * allot

: $hash-t   ( adr len voc-ptr -- thread )
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
: setup-user-area       ( -- )
        here-t  is userarea-t
        user-size-t allot-t
        userarea-t >hostaddr user-size-t  erase ;

: >user-t   ( cfa-t -- user-adr-t )   >body-t @-t  userarea-t + >hostaddr  ;
: n>link-t  ( anf-t -- alf-t )        /link-t - ;
: l>name-t  ( alf-t -- anf-t )        /link-t + ;

decimal
/l constant #align-t
/l constant #talign-t
/l constant #linkalign-t
/l constant #acf-align-t
: aligned-t ( n1 -- n2 )  #align-t 1- +  #align-t negate and  ;
: acf-aligned-t  ( n1 -- n2 )  #acf-align-t 1- +  #acf-align-t negate and  ;

\ NullFix bl -> 0
: align-t ( -- )
   begin  here-t #align-t  1- and   while   0 c,-t   repeat
;
: talign-t ( -- )
   begin   here-t #talign-t 1- and   while   0 c,-t   repeat
;
: linkalign-t  ( -- )
   begin   here-t #linkalign-t 1- and   while   0 c,-t   repeat
;
: acf-align-t  ( -- )  talign-t  ;

: entercode     ( -- )
   only forth also labels also meta also arm-assembler
   [ also arm-assembler also helpers ]
   ['] $arm-assem-do-undefined is $do-undefined
   [ previous previous ]
   align-t
;

\ Next 5 are Machine Independent
: cmove-t   ( from to-t n -- )
        2dup 2>r
        0 do    over c@  over c!-t  ca1+ swap ca1+ swap loop 2drop
        2r> protocol? @ 
        if      base @ >r  hex  last-protocol off
                cr ." String at" over 6 u.r space ascii " emit bounds
                do      i c@-t dup bl <
                        if drop else emit then
                loop    ascii " emit r> base !
        else    2drop
        then ;
: place-cstr-t  ( adr len cstr-adr-t -- cstr-adr-t )
   >r  tuck r@ swap cmove-t  ( len ) r@ +  0 swap c!-t  r>
;
: "copy-t   ( from to-t -- )
        over c@ 2+  cmove-t ;
: toggle-t  ( addr-t n -- )
        protocol? @
        if      cr ." Toggle at"  base @ >r hex 2dup swap  6 u.r  3 u.r
                last-protocol off r> base !
        then
        swap >r r@ c@-t xor r> c!-t ;

: clear-threads-t  ( hostaddr -- )
   #threads-t /link-t * bounds  do
      origin-t i link-t!
   /link +loop
;
: initmeta      ( -- )
        init-relocation-t
        threads-t   #threads-t /link-t * bounds
        do  origin-t i link-t!
        threads-t current-t !
        /link +loop
        last-protocol on ;

\ For compiling branch offsets/addresses used by control constructs.
/l-t constant /branch

\rel    : branch!      ( from to -- )  over -  swap  l!-t  ;
\rel    : branch,      ( to -- )       here-t -  l,-t  ;

\abs    : branch!      ( from to -- )  swap a!-t  ;
\abs    : branch,      ( to -- )      a,-t  ;

\ Store actions for some data structures.  This has to be in this
\ file because it depends on the location of the user area (in the
\ ARMx version, the user area is in the dictionary for
\ relocation to work right, but that is not true for the SPARC
\ version.  Ultimately, separate relocation for the user area is
\ needed.  The relocation probably should be automatic, by looking
\ at the storage address.

: isuser        ( n acf -- )            >user-t n-t!  ;
: istuser       ( acf1 acf -- )         >user-t token-t!  ;
: isvalue       ( n acf -- )            >user-t n-t!  ;
: isdefer       ( acf acf -- )          >user-t token-t!  ;

: thread-t!     ( thread adr -- )       link!-t  ;


only forth also meta also definitions
: install-target-assembler
        [ assembler also helpers ]
        ['] allot-t is asm-allot
        ['] here-t  is here
\        ['] c!-t    is byte!
        ['] l!-t    is asm!
        ['] l@-t    is asm@
        ['] set-relocation-bit-t is asm-set-relocation-bit
       [ previous previous ]
;
: install-host-assembler  ( -- )
\ XXX Just punt for now.
;

decimal

\ LICENSE_BEGIN
\ Copyright (c) 2008 FirmWorks
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
