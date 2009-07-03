\ See license at end of file

\ Metacompiler source for Forth kernel code words.

meta
hex

\ Allocate and clear the initial user area image
setup-user-area

extend-meta-assembler

\ ---- Assembler macros that reside in the host environment
\ and assemble code for the target environment

\ Forth Virtual Machine registers

:-h rp  bp ;-h   :-h [rp]  [bp] ;-h   \ return stack pointer
:-h ip  si ;-h   :-h [ip]  [si] ;-h   \ interpreter pointer
:-h w   ax ;-h   :-h [w]   [ax] ;-h   \ working register
:-h up  di ;-h   :-h [up]  [di] ;-h   \ user pointer

\ Macros:

:-h ainc  ( ptr -- )  /n # rot add  ;-h
:-h adec  ( ptr -- )  /n # rot sub  ;-h

\ Get a token
:-h tget  ( src dst -- )
;-h
\ Get a branch offset
:-h bget  ( src dst -- )
;-h
:-h /cf  4  ;-h         \ X should be in target.fth
:-h [apf]  ( -- src )  /cf [w]  ;-h
:-h 1push  ax push  ;-h
:-h 2push  dx push  ax push  ;-h

:-h /n* /n * ;-h

[ifdef] omit-files
\ assembler macro to assemble next
:-h next
   meta-asm[  ax lods  0 [ax] jmp  ]meta-asm
;-h
[else]
\ assembler macro to assemble next
:-h next
   meta-asm[  up jmp  ]meta-asm
;-h
[then]

:-h c;    next end-code  ;-h

\ assembler macro to swap bytes
:-h ?bswap-ax  ( -- )
[ifdef] big-endian-t
   meta-asm[
   \ The 486 can do this in 1 instruction (BSWAP), which the 386 doesn't have
   ax bx mov
   d# 16 # cl mov	\ shift count
   bh bl xchg		\ swap low bytes
   bx cl shl		\ move to high word
   ax cl shr		\ move high bytes to low word
   ah al xchg		\ swap them
   bx ax add		\ merge words
   ]meta-asm
[then]
;-h

:-h 'user#  \ name  ( -- user# )
    [ meta ]-h  '  ( acf-of-user-variable )  >body-t @-t
;-h
:-h 'user  \ name  ( -- user-addressing-mode )
    [ assembler ]-h   'user# [up]
;-h
:-h 'body  \ name  ( -- variable-apf )
    [ meta ]-h  '  ( acf-of-user-variable )  >body-t
;-h
 
\ Create the code for "next" in the user area
\ compile-in-user-area

here-t
mlabel >next  assembler
userarea-t dp-t !
   ax lods  0 [ax] jmp
   nop nop nop nop nop
end-code
dp-t !
\ restore-dictionary

d# 32 equ #user-init	\ Leaves space for the shared "next"

meta-compile

code-field: docolon 
   \ ??? perhaps we can use "4 [w] ip lea"
   rp adec   ip  0 [rp] mov   w ainc   w ip mov
c;

code-field: docreate
   w ainc   w push
c;

code-field: dovariable
   w ainc   w push
c;

code-field: dolabel
   w ainc   w push
c;

code-field: douser
   [apf] ax mov  ?bswap-ax   up ax add   1push
c;

code-field: dovalue
   [apf] ax mov  ?bswap-ax   up ax add   0 [ax] ax mov  ?bswap-ax  1push
c;

code-field: dodefer
   [apf] ax mov  ?bswap-ax   up ax add   0 [ax] w mov   0 [w] jmp
end-code

code-field: doconstant
   [apf] ax mov  ?bswap-ax   1push
c;

code-field: do2constant
   [apf] dx mov
[ifdef] big-endian-t
   dx ax mov  ?bswap-ax  ax dx mov
[then]
   /cf /n + [w] ax mov  ?bswap-ax
   2push
c;

code-field: dodoes
   rp adec   ip  0 [rp] mov   ip pop
   w ainc   w push
c;

:-h place-cf-t  ( action-apf -- )  acf-align-t token,-t  ;-h

:-h code-cf       ( -- )  acf-align-t here-t /token-t + token,-t  ;-h
:-h label-cf      ( -- )  dolabel       place-cf-t  align-t  ;-h
:-h colon-cf      ( -- )  docolon       place-cf-t  ;-h
:-h constant-cf   ( -- )  doconstant    place-cf-t  ;-h
:-h create-cf     ( -- )  docreate      place-cf-t  ;-h
:-h variable-cf   ( -- )  dovariable    place-cf-t  ;-h
:-h user-cf       ( -- )  douser        place-cf-t  ;-h
:-h value-cf      ( -- )  dovalue       place-cf-t  ;-h
:-h defer-cf      ( -- )  dodefer       place-cf-t  ;-h
:-h startdoes     ( -- )  
   meta-asm[  ax ax xchg  ax ax xchg  ax ax xchg  dodoes #) call
   ]meta-asm  ;-h	\ need to pad to 8 bytes for decompiler
\ The forward reference will be resolved later by fix-vocabularies
:-h vocabulary-cf ( -- )  compile-t <vocabulary>  ;-h


\ ---- Run-time words compiled by compiling words.

code bswap  (s n1 -- n2 )
   ax pop

   \ The 486 can do this in 1 instruction (BSWAP), which the 386 doesn't have
   ax bx mov
   d# 16 # cl mov	\ shift count
   bh bl xchg		\ swap low bytes
   bx cl shl		\ move to high word
   ax cl shr		\ move high bytes to low word
   ah al xchg		\ swap them
   bx ax add		\ merge words

   1push
c;

code (lit)   (s -- n )  ax lods  ?bswap-ax  1push  c;
code (llit)  (s -- l )  ax lods  ?bswap-ax  1push  c;
[ifdef] big-endian-t
code (dlit)  (s -- d )  ax lods  ?bswap-ax  ax  bx mov
			ax lods  ?bswap-ax  1push  bx push  c;
[else]
code (dlit)  (s -- d )  ax lods  ?bswap-ax  1push
			ax lods  ?bswap-ax  1push  c;
[then]

\ Execute a Forth word given a code field address
code execute   (s acf -- )   w pop   0 [w] jmp   end-code

\ High level branch.  The branch offset is compiled in-line.
code branch (s -- )
mloclabel bran1
[ifdef] big-endian-t
   0 [ip] ax mov  ?bswap-ax  ax ip add
[else]
   0 [ip] ip add
[then]
c;

\ May need to change for 16-bit branch offsets
:-h skipbranch  ( -- )  [ assembler ]-h  ip ainc  ;-h

\ High level conditional branch.
code ?branch (s f -- )  \ Takes the branch if the flag is false
   ax pop   ax ax or   bran1 je   skipbranch
c;

\ Run time word for loop
code (loop)  (s -- )
   1 # ax mov
   ax 0 [rp] add   bran1 jno  3 /n* # rp add   skipbranch
c;

\ Run time word for +loop
code (+loop) (s increment -- )
   ax pop
   ax 0 [rp] add   bran1 jno  3 /n* # rp add   skipbranch
c;

code unloop  (s -- )  3 /n* # rp add   c;

\ Run time word for ?do
code (?do)  (s l i -- )
   ax pop   bx pop   ax bx cmp  = if  bran1 #) jmp  then
[ifdef] big-endian-t
   bx push  ax push
   ip dx mov    0 [ip] ax mov  ?bswap-ax  ax dx add   rp adec   dx 0 [rp] mov
   ax pop   bx pop      \ i in ax  l in bx
[else]
   ip dx mov    0 [ip] dx add   rp adec   dx 0 [rp] mov
[then]
   ip ainc  80000000 # bx add   rp adec   bx 0 [rp] mov
   bx ax sub                    rp adec   ax 0 [rp] mov
\ ??? how about sp rp xchg  ... dx push bx push ax push  sp rp xchg
c;

\ Run time word for do
code (do)  (s l i -- )
[ifdef] big-endian-t
   ax pop   bx pop      \ i in ax  l in bx

   bx push  ax push
   ip dx mov    0 [ip] ax mov  ?bswap-ax  ax dx add   rp adec   dx 0 [rp] mov
   ax pop   bx pop      \ i in ax  l in bx
[else]
   ax pop   bx pop      \ i in ax  l in bx
   
   ip dx mov    0 [ip] dx add   rp adec   dx 0 [rp] mov
[then]
   ip ainc  80000000 # bx add   rp adec   bx 0 [rp] mov
   bx ax sub                    rp adec   ax 0 [rp] mov
\ ??? how about sp rp xchg  ... dx push bx push ax push  sp rp xchg
c;
meta

\ Loop index for current do loop
code i  (s -- n )   0 [rp] ax mov   /n [rp] ax add   1push  c;

\ Loop limit for current do loop
code ilimit  ( -- n )  1 /n* [rp] ax mov  80000000 # ax sub  1push  c;

\ Loop index for next enclosing do loop
code j   (s -- n )  3 /n* [rp] ax mov   4 /n* [rp] ax add   1push  c;

\ Loop limit for next enclosing do loop
code jlimit  ( -- n )  4 /n* [rp] ax mov  80000000 # ax sub  1push  c;

code (leave)  (s -- )
mloclabel pleave
   2 /n* [rp] ip mov   3 /n* # rp add
c;

code (?leave)  (s f -- )   ax pop   ax ax or   pleave jne   c;

code (of)  ( selector test -- [ selector ] )
   bx pop  ax pop   \ Test in bx, Selector in ax
   ax bx cmp  0= if  skipbranch next  then         \ Skip branch; execute code
   ax push  bran1 #) jmp                           \ Jump to next test
end-code

\ (endof) is the same as branch, and (endcase) is the same as drop,
\ but redefining them this way makes the decompiler much easier.
code (endof)    (s -- )    bran1 #) jmp  end-code
code (endcase)  (s n -- )  ax pop  c;

mloclabel yes  assembler   true # ax mov   1push   c;
mloclabel no   assembler  false # ax mov   1push   c;

\ Convert a character to a digit according to the current base
mloclabel fail assembler  ax ax sub   1push  c;

code digit  (s char base -- digit true | char false )
  dx pop   ax pop   ax push   ascii 0 # al sub   fail jb
  9 # al cmp   > if
     11 # al cmp   fail jb    \ Bad if > '9' and < 'A'
     \ if > 'A', subtract 'A'-'0'-10, otherwise subtract 'a'-'0'-10
     30 # al cmp  > if  27 # al sub  else  7 # al sub  then
  then
  dl al cmp   fail jae   al dl mov
  ax pop   true # ax mov   2push
c;

\ Copy cnt characters starting at from-addr to to-addr.  Copying is done
\ strictly from low to high addresses, so be careful of overlap between the
\ two buffers.

code cmove  ( src dst cnt -- )  \ Copy from bottom to top
  di dx mov
  cld   ip bx mov   ds ax mov   ax es mov
  cx pop   di pop   ip pop
  rep   byte movs   bx ip mov
  dx di mov
c;

code cmove>  ( src dst cnt -- )  \ Copy from top to bottom
  di dx mov
  std   ip bx mov   ds ax mov   ax es mov   cx pop
  cx dec   di pop   ip pop   cx di add   cx ip add   cx inc
  rep   byte movs   bx ip mov   cld
  dx di mov
c;

: move   ( from to len -- )
   -rot   2dup u< if   rot cmove>   else   rot cmove   then
;

code and  (s n1 n2 -- n3 )   bx pop   ax pop   bx ax and   1push c;
code or   (s n1 n2 -- n3 )   bx pop   ax pop   bx ax or    1push c;
code xor  (s n1 n2 -- n3 )   bx pop   ax pop   bx ax xor   1push c;

code lshift  (s n1 cnt -- n2 )  cx pop   ax pop   ax cl shl   1push c;
code rshift  (s n1 cnt -- n2 )  cx pop   ax pop   ax cl shr   1push c;

code <<   (s n1 cnt -- n2 )  cx pop   ax pop   ax cl shl   1push c;
code >>   (s n1 cnt -- n2 )  cx pop   ax pop   ax cl shr   1push c;
code >>a  (s n1 cnt -- n2 )  cx pop   ax pop   ax cl sar   1push c;

code +    (s n1 n2 -- n3 )   bx pop   ax pop   bx ax add   1push c;
code -    (s n1 n2 -- n3 )   bx pop   ax pop   bx ax sub   1push c;

code invert  (s n1 -- n2 )   ax pop   ax not   1push c;
code negate  (s n1 -- n2 )   ax pop   ax neg   1push c;

: abs   (s n1 -- n2 )  dup 0<  if  negate  then   ;

: min  (s n1 n2 -- n3 )  2dup  >  if  swap  then  drop  ;
: max  (s n1 n2 -- n3 )  2dup  <  if  swap  then  drop  ;
: umin (s u1 u2 -- u3 )  2dup u>  if  swap  then  drop  ;
: umax (s u1 u2 -- u3 )  2dup u<  if  swap  then  drop  ;

code up@  (s -- addr )  up push  c;
code sp@  (s -- addr )  sp push  c;
code rp@  (s -- addr )  rp push  c;
code up!  (s addr -- )  up pop   c;
code sp!  (s addr -- )  sp pop   c;
code rp!  (s addr -- )  rp pop   c;
code >r   (s n -- )     ax pop   rp adec   ax 0 [rp] mov   c;
code r>   (s -- n )     0 [rp] ax mov   rp ainc   1push c;
code r@   (s -- n )     0 [rp] ax mov             1push c;
code 2>r  (s n1 n2 -- )  8 #  rp  sub   0 [rp] pop   4 [rp] pop  c;
code 2r>  (s -- n1 n2 )  4 [rp] push  0 [rp] push   8 #  rp  add  c;
code 2r@  (s -- n1 n2 )  4 [rp] push  0 [rp] push   c;

code exit (s -- )       0 [rp] ip mov   rp ainc  c;
code unnest (s -- )     0 [rp] ip mov   rp ainc  c;

code >ip  (s n -- )     ax pop   rp adec   ax 0 [rp] mov   c;
code ip>  (s -- n )     0 [rp] ax mov   rp ainc   1push c;
code ip@  (s -- n )     0 [rp] ax mov             1push c;
: ip>token  ( ip -- token-adr )  /token -  ;

code tuck  (s n1 n2 -- n2 n1 n2 )
   ax pop   dx pop   ax push   2push
c;
code nip   (s n1 n2 -- n2 )   ax pop   dx pop   1push c;
code flip  (s w1 -- w2 )   ax pop   ah al xchg   1push c;

assembler definitions
:-h leaveflag  (s condition -- )
\ macro to assemble code to leave a flag on the stack
   if
      true  # ax mov
   else
      false # ax mov
   then
   1push
;-h
:-h unary-test  (s condition -- )  ax pop  ax ax or   ( cond ) leaveflag   ;-h
meta definitions
code 0=  (s n -- f )  0=  unary-test  c;
code 0<> (s n -- f )  0<> unary-test  c;
code 0<  (s n -- f )  0<  unary-test  c;
code 0<= (s n -- f )  <=  unary-test  c;
code 0>  (s n -- f )  >   unary-test  c;
code 0>= (s n -- f )  0>= unary-test  c;

assembler definitions
:-h compare
   ax pop  bx pop  ax bx cmp
   leaveflag
;-h
meta definitions

code <   (s n1 n2 -- f )  <   compare c;
code >   (s n1 n2 -- f )  >   compare c;
code =   (s n1 n2 -- f )  0=  compare c;
code <>  (s n1 n2 -- f )  <>  compare c;
code u>  (s n1 n2 -- f )  u>  compare c;
code u<= (s n1 n2 -- f )  u<= compare c;
code u<  (s n1 n2 -- f )  u<  compare c;
code u>= (s n1 n2 -- f )  u>= compare c;
code >=  (s n1 n2 -- f )  >=  compare c;
code <=  (s n1 n2 -- f )  <=  compare c;

code drop (s n -- )      ax pop    c;
code dup  (s n -- n n )  ax pop   ax push  1push c;
code over (s n1 n2 -- n1 n2 n1 )  dx pop   ax pop   ax push  2push c;
code swap (s n1 n2 -- n2 n1 )     dx pop   ax pop   2push c;
code rot  (s n1 n2 n3 -- n2 n3 n1 )  dx pop  bx pop  ax pop  bx push  2push c;
code -rot (s n1 n2 n3 -- n3 n1 n2 )  bx pop  ax pop  dx pop  bx push  2push c;
code 2drop  (s d -- )  ax pop  ax pop  c;
code 2dup   (s d -- d d )    ax pop   dx pop   dx push   ax push   2push c;
code 2over  (s d1 d2 -- d1 d2 d1 )
   cx pop   bx pop   ax pop   dx pop   dx push   ax push
   bx push  cx push  2push
c;
code 2swap  (s d1 d2 -- d2 d1 )
   cx pop   bx pop   ax pop   dx pop
   bx push  cx push  2push
c;
\ ??? Here is one of the few places where we could use the scaled indexing mode
code pick   (s nm ... n1 n0 k -- nm ... n2 n0 nk )
   bx pop   bx shl  bx shl  sp bx add   0 [bx] ax mov   1push
c;  
 
code 1+  (s n1 -- n2 )  ax pop   ax inc            1push c;
code 2+  (s n1 -- n2 )  ax pop   ax inc   ax inc   1push c;
code 1-  (s n1 -- n2 )  ax pop   ax dec            1push c;
code 2-  (s n1 -- n2 )  ax pop   ax dec   ax dec   1push c;

code 2/  (s n1 -- n2 )  ax pop   ax sar            1push c;
code u2/ (s n1 -- n2 )  ax pop   ax shr            1push c;
code 2*  (s n1 -- n2 )  ax pop   ax shl            1push c;
code 4*  (s n1 -- n2 )  ax pop   ax shl   ax shl   1push c;
code 8*  (s n1 -- n2 )  ax pop   ax shl   ax shl   ax shl   1push c;

code on  (s addr -- )   bx pop   true # 0 [bx] mov   c;
code off (s addr -- )   bx pop  false # 0 [bx] mov   c;

[ifdef] big-endian-t
: +! (s n addr -- )  tuck @ + swap !  ;

\ requires alignment on a word boundary

code d@     (s addr -- n )   bx pop   0 [bx] push   4 [bx] push  c;
code le-@   (s addr -- n )   bx pop   0 [bx] push   c;
code le-l@  (s addr -- l )   bx pop   0 [bx] push   c;
code @      (s addr -- n )   bx pop   0 [bx] ax mov  ?bswap-ax  1push   c;
code l@     (s addr -- n )   bx pop   0 [bx] ax mov  ?bswap-ax  1push   c;
code le-w@  (s addr -- w )  bx pop   ax ax sub   op: 0 [bx] ax mov   1push  c;
code w@  (s addr -- w )
   bx pop   ax ax sub   op: 0 [bx] ax mov   ah al xchg  1push
c;
code <w@  (s addr -- sw )
   bx pop   ax ax sub   op: 0 [bx] ax mov   ah al xchg  cwde  1push
c;
code c@  (s addr -- c )   bx pop   ax ax sub   0 [bx] al mov  1push c;

: unaligned-@   (s addr -- n )  @  ;
: unaligned-l@  (s addr -- l )  l@ ;
: unaligned-w@  (s addr -- w )  w@  ;

\ 16-bit token version doesn't require alignment on a word boundary
code le-!   (s n addr -- )   bx pop   0 [bx] pop  c;
code le-l!  (s l addr -- )   bx pop   0 [bx] pop  c;

code !      (s n addr -- )   dx pop   ax pop  ?bswap-ax  ax 0 [dx] mov  c;
code d!     (s low high addr -- )  
   dx pop   ax pop  ?bswap-ax  ax 4 [dx] mov  ax pop  ?bswap-ax  ax 0 [dx] mov
c;
code l!     (s n addr -- )   dx pop   ax pop  ?bswap-ax  ax 0 [dx] mov  c;
code le-w!  (s w addr -- )  bx pop   ax pop  op: ax 0 [bx] mov  c;
code w!  (s w addr -- )
   bx pop   ax pop  ah al xchg  op: ax 0 [bx] mov
c;


code c!  (s c addr -- )   bx pop   ax pop       al 0 [bx] mov   c;
code le-2@  (s addr -- d )   bx pop   4 [bx] dx mov  0 [bx] ax mov  2push c;
: 2@  (s addr -- d )  le-2@  swap bswap swap bswap  ;
code le-2!  (s d addr -- )   bx pop   0 [bx] pop   4 [bx] pop   c;
: 2!  (s addr -- d )  >r  swap bswap swap bswap  r> le-2!  ;

: unaligned-!   (s n addr -- )   !  ;
: unaligned-l!  (s n addr -- )   !  ;
: unaligned-w!  (s w addr -- )   w!  ;

[else]
code +! (s n addr -- )  bx pop   ax pop   ax 0 [bx] add   c;

\ requires alignment on a word boundary
code d@     (s addr -- n )   bx pop   0 [bx] push   4 [bx] push  c;
code le-@   (s addr -- n )   bx pop   0 [bx] push   c;
code le-l@  (s addr -- l )   bx pop   0 [bx] push   c;
code @   (s addr -- n )  bx pop   0 [bx] push   c;
code l@  (s addr -- l )  bx pop   0 [bx] push   c;
code le-w@  (s addr -- w )  bx pop   ax ax sub   op: 0 [bx] ax mov   1push  c;
code w@  (s addr -- w )  bx pop   ax ax sub   op: 0 [bx] ax mov   1push c;
code <w@ (s addr -- w )  bx pop   ax ax sub   op: 0 [bx] ax mov  cwde  1push c;
code c@  (s addr -- c )  bx pop   ax ax sub   0 [bx] al mov  1push c;

code unaligned-@   (s addr -- n )   bx pop   0 [bx] push   c;
code unaligned-l@  (s addr -- l )   bx pop   0 [bx] push   c;
code unaligned-w@  (s addr -- w )   bx pop   ax ax sub   op: 0 [bx] ax mov   1push c;

\ 16-bit token version doesn't require alignment on a word boundary
code le-!   (s n addr -- )   bx pop   0 [bx] pop  c;
code le-l!  (s l addr -- )   bx pop   0 [bx] pop  c;
code !   (s n addr -- )   bx pop   0 [bx] pop   c;
code d!     (s low high addr -- )
   dx pop   ax pop  ax 4 [dx] mov  ax pop  ax 0 [dx] mov
c;
code l!  (s l addr -- )   bx pop   0 [bx] pop   c;
code le-w!  (s w addr -- )  bx pop   ax pop  op: ax 0 [bx] mov  c;
code w!  (s w addr -- )   bx pop   ax pop   op: ax 0 [bx] mov   c;
code c!  (s c addr -- )   bx pop   ax pop       al 0 [bx] mov   c;
code 2@  (s addr -- d )   bx pop   4 [bx] dx mov  0 [bx] ax mov  2push c;
code 2!  (s d addr -- )   bx pop   0 [bx] pop   4 [bx] pop   c;

code unaligned-d!  (s d addr -- )   bx pop   4 [bx] pop   0 [bx] pop   c;
code unaligned-!   (s n addr -- )   bx pop   0 [bx] pop   c;
code unaligned-l!  (s n addr -- )   bx pop   0 [bx] pop   c;
code unaligned-w!  (s w addr -- )   bx pop   ax pop   op: ax 0 [bx] mov   c;
[then]

: instruction!  (s n adr -- )  !  ;

code fill  (s start-addr count char -- )
   di dx mov
   cld   ds ax mov   ax es mov   ax pop   cx pop   di pop
   rep   al stos
   dx di mov
c;

code wfill  (s start-addr count char -- )
   di dx mov
   cld   ds ax mov   ax es mov   ax pop   cx pop  1 # cx shr  di pop
   rep   ax op: stos
   dx di mov
c;

code lfill  (s start-addr count char -- )
   di dx mov
   cld   ds ax mov   ax es mov   ax pop   cx pop  2 # cx shr  di pop
   rep   ax stos
   dx di mov
c;

\ Skip initial occurrences of bvalue, returning the residual length
code bskip  ( adr len bvalue -- residue )
   di dx mov
   ax pop         \ BX: compare value
   cx pop         \ CX: Length
   di pop         \ SI: address
   cld  repz byte scas
   <>  if  cx inc  then
   dx di mov
   cx push
c;

\ Skip initial occurrences of lvalue, returning the residual length
code lskip  ( adr len lvalue -- residue )
   di dx mov
   ax pop         \ BX: compare value
   cx pop         \ CX: Length
   2 # cx shr     \ Convert CX to longword count
   di pop         \ SI: address
   cld  repz scas
   <>  if  cx inc  then
   dx di mov
   2 # cx shl  cx push
c;

code noop (s -- )  c;

code n->l (s n.unsigned -- l ) c;
: s>d  (s n -- d )  dup 0<  ;  \ Depends on  true=-1, false=0

: lwsplit (s l -- w.low w.high )  \ split a long into two words
   dup  ffff and  swap 10 >>  
;
: wljoin (s w.low w.high -- l )  10 <<  swap  ffff and  or  ;

code ca+  (s addr index -- addr+index*/c )
   bx pop   ax pop   bx ax add   1push
c;
code wa+  (s addr index -- addr+index*/w )
   bx pop  bx shl  ax pop   bx ax add   1push
c;
code la+  (s addr index -- addr+index*/l )
   bx pop  bx shl  bx shl  ax pop   bx ax add   1push
c;
code na+  (s addr index -- addr+index*/n )
   bx pop  bx shl  bx shl  ax pop   bx ax add   1push
c;
code ta+  (s addr index -- addr+index*/t )
   bx pop  bx shl  bx shl  ax pop   bx ax add   1push
c;

code ca1+  (s addr -- addr+/c )       ax pop   ax inc            1push c;
code char+ (s addr -- addr+/c )       ax pop   ax inc            1push c;
code wa1+  (s addr -- addr+/w )       ax pop   ax inc   ax inc   1push c;
code la1+  (s addr -- addr+/l )       ax pop   ax ainc           1push c;
code na1+  (s addr -- addr+/n )       ax pop   ax ainc           1push c;
code cell+ (s addr -- addr+/n )       ax pop   ax ainc           1push c;
code ta1+  (s addr -- addr+/token )   ax pop   ax ainc           1push c;

1 constant /c
2 constant /w
4 constant /l
/l constant /n

code /c*   (s n -- n*/c )   c;
code chars (s n -- n*/c )   c;
code /w*   (s n -- n*/w )   ax pop   ax shl   1push c;
code /l*   (s n -- n*/l )   ax pop   ax shl   ax shl   1push c;
code /n*   (s n -- n*/n )   ax pop   ax shl   ax shl   1push c;
code cells (s n -- n*/n )   ax pop   ax shl   ax shl   1push c;

mloclabel >upper  assembler
   ascii a # al cmp  0>=  if
      ascii z 1+ # al cmp   0< if   ascii a ascii A - # al sub   then
   then
   ret
end-code

code upc (s char -- upper-case-char )   ax pop   >upper #) call   1push c;

mloclabel >lower  assembler
   ascii A # al cmp  0>=  if
      ascii Z 1+ # al cmp   0< if   ascii a ascii A - # al add   then
   then
   ret
end-code

code lcc  (s char -- lower-case-char )  ax pop  >lower #) call  1push c;

code c@+  (s addr -- addr+1 len )
   bx pop   ax ax sub   0 [bx] al mov   bx inc   bx push  1push
c;

mloclabel nomore   assembler   dx si mov   bx di mov   cx push   next end-code

mloclabel mismatch  assembler
   0< if  -1 # cx mov  else  1 # cx mov  then  nomore #) jmp
end-code

\ string compare - case sensitive
code comp      (s addr1 addr2 len -- -1 | 0 | 1 )
   si dx mov   di bx mov   cx pop   di pop   si pop   nomore jcxz
   ds ax mov  ax es mov   repz   byte cmps   nomore je  mismatch jne
   \ We don't put "mismatch" in-line here because mlabel aligns
   \ the dictionary pointer
end-code

\ string compare - case insensitive
code caps-comp  (s addr1 addr2 len -- -1 | 0 | 1 )
   si dx mov   di bx mov   cx pop   di pop   si pop
   begin
      nomore jcxz   0 [si] al mov  >upper #) call  si inc
        al ah mov   0 [di] al mov  >upper #) call  di inc
      al ah cmp  mismatch jne   cx dec
   again
end-code

code 3drop  ( n1 n2 n3 -- )  ax pop  ax pop  ax pop  c;
: 3dup   ( a b c -- a b c a b c )  2 pick  2 pick  2 pick  ;
: pack  (s str-addr len to -- to )
   2dup >r >r
   3dup  1+ swap move  c! drop
   r> r>  tuck + 1+ 0 swap c!
;
code 4drop  (s n1 n2 n3 n4 -- )
   ax pop  ax pop  ax pop  ax pop
c;
code 5drop  (s n1 n2 n3 n4 n5 -- )
   ax pop  ax pop  ax pop  ax pop  ax pop
c;

code (')  (s -- acf )   ax lods   1push c;

\ Modifies caller's ip to skip over an in-line string
code skipstr (s -- addr len)
   0 [rp] bx mov       \ Get string address in bx
   ax ax sub
   0 [bx] al mov       \ Get length byte in ax

   bx inc              \ Address of data bytes
   bx push             \ Put addr on stack

   ax push             \ Put len on stack

   bx ax add           \ Skip the string
   #talign-t #  ax add   \ Round up to token boundary + null byte
   #talign-t negate #  ax  and	\ Align
   ax 0 [rp] mov       \ Put the modified ip back
c;
code (")  (s -- addr len)
   ax ax sub	       \ Clear high bytes
   al lodsb            \ Get length byte in al
   ip push             \ Push address of data bytes
   ax push             \ Push length
   ax ip add           \ Skip the string
   #talign-t #  ip add   \ Round up to token boundary + null byte
   #talign-t negate #  ip and	\ Align
c;
code count  (s addr -- addr+1 len )
   bx pop   ax ax sub   0 [bx] al mov   bx inc   bx push  1push
c;

\ code origin  (s -- addr )   ax ax sub   1push c;
\ origin is defined later as a constant
\ code origin+  (s offset -- addr )   c;
\ code origin-  (s offset -- addr )   c;
\ for now, use high-level...
: origin+  (s offset -- addr )   origin +  ;
: origin-  (s offset -- addr )   origin -  ;

\ ---- Support words for the incremental compiler

: acf-align  (s -- )
   begin  here #acf-align 1- and  while  0 c,  repeat
   here 'lastacf token!
;

\ Place the code field
: place-cf  (s action-adr -- )  origin+ acf-align  token,  ;

: code-cf  (s -- )   acf-align  here ta1+ token,  ;
: >code  ( acf-of-code-word -- address-of-start-of-machine-code )  >body  ;
: code?  ( acf -- f )  \ True if the acf is for a code word
   dup token@  swap >body  =
;

: next  ( -- )  h# ff c,  h# e7 c,  ;	\ up jmp

: create-cf    (s -- )  docreate   place-cf  ;
: variable-cf  (s -- )  dovariable place-cf  ;

\ place-does compiles a "dodoes #) call" instruction
[ifdef] big-endian-t
: place-does   (s -- )
   \ Three noops, so the following call instruction will end 4-byte-aligned
   90 c,  90 c,  90 c,
   e8 c,  dodoes  here 4 allot  swap here - swap  le-!
;
[else]               \ 1 noop for word-alignment (for relocation)
: place-does   (s -- )
   \ Add enough noops to force the following 5-byte call instruction
   \ to end at a token alignment boundary
\   #talign-t 1  ?do  90 c,  loop
   90 c,  90 c,  90 c,
   e8 c,  dodoes  origin+  here 4 + - ,
;
[then]

: place-;code  (s -- )  ;

\ Ip is assumed to point to (;code .  flag is true if
\ the code at ip is a does> clause as opposed to a ;code clause.
: does-ip?   (s ip -- ip' flag )
   ta1+     \ Skip past the (;code token
   dup c@  h# e8  =  if    \ is a DOES> clause
      5 +   true           \ Skip the   DODOES #) CALL  instruction
   else
      dup  c@  h# 90  =  if   \ is an aligned DOES> clause
         8 +  true
      else                 \ is a ;CODE clause
         false
      then
   then
;

: put-cf  (s action-clause-addr where -- )  token!  ;

\ uses  sets the code field of the indicated word so that
\ it will execute the code at action-clause-adr
: uses  ( action-clause-adr xt -- )  put-cf  ;

\ used  sets the code field of the most-recently-defined word so that
\ it executes the code at action-clause-adr
: used  ( action-clause-adr -- )  lastacf  uses  ;

: colon-cf      (s -- )  docolon    place-cf  ;
: colon-cf?     (s possible-acf -- flag )
   word-type  ['] colon-cf  word-type =
;

: user-cf       (s -- )  douser      place-cf  ;
: value-cf      (s -- )  dovalue     place-cf  ;
: constant-cf   (s -- )  doconstant  place-cf  ;
: defer-cf      (s -- )  dodefer     place-cf  ;
: 2constant-cf  (s -- )  do2constant place-cf  ;

\t16 2 constant /branch
\t32 4 constant /branch
: branch, ( offset -- )
\t32 ,
\t16 w,
;
: branch@  ( -- offset )
\t16 w@
\t32 @
;
: branch! ( offset where -- )
\t16 w!
\t32 !
;
\ >target depends on the way that branches are compiled
: >target  ( ip-of-branch-instruction -- target )  ta1+ dup branch@ +  ;

headerless
/a constant /a
code a@  ( adr1 -- adr2 )   bx pop   0 [bx] push   c;
\ [ifdef] big-endian-t
: a!  ( adr1 adr2 -- )  set-relocation-bit  le-!  ;
\ [else]
\ code a!  ( adr1 adr2 -- )   bx pop   0 [bx] pop    c;
\ [then]
: a,  ( adr -- )  here  /a allot  a!  ;

/token constant /token
code token@ (s addr -- cfa )   bx pop   0 [bx] push   c;
\ [ifdef] big-endian-t
: token!  ( adr1 adr2 -- )  set-relocation-bit  le-!  ;
\ [else]
\ code token! (s cfa addr -- )   bx pop   0 [bx] pop    c;
\ [then]
: token,  (s cfa -- )  here  /token allot  token!  ;

: null  ( -- link )  origin  ;
: !null-link   ( adr -- )  origin swap link!  ;
: !null-token  ( adr -- )  origin swap token!  ;
: non-null?  ( link -- false | link true )
   dup origin <>  dup  0=  if  nip  then
;

: get-token?     ( adr -- false | acf  true )  token@ non-null?  ;
: another-link?  ( adr -- false | link true )  link@  non-null?  ;


origin-t constant origin
   /n negate allot-t  origin-t token,-t  ( make origin relocatable )


\ The "word type" is a number which distinguishes one type of word
\ from another.  This is highly implementation-dependent.

\ For the i386 implementation, the magic number returned by word-type
\ is the absolute address of the action code.

: word-type  (s acf -- word-type )  token@  ;

: body>  (s pfa -- cfa )   /token -  ;
: >body  (s cfa -- pfa )   /token +  ;
\t16 2 constant /user#
\t32 4 constant /user#

\ Move to a machine alignment boundary.
\ i386 allows arbitrary alignment

[ifdef] big-endian-t
create big-endian
[then]

: round-up  ( adr granularity -- adr' )  1-  tuck +  swap invert and  ;
: (align)  ( size granularity -- )
   1-  begin  dup here and  while  0 c,  repeat  drop
;
: aligned  (s adr -- adr' )  #align round-up  ;
: acf-aligned  (s adr -- adr' )  #acf-align round-up  ;
: acf-align  (s -- )  #acf-align (align)   here 'lastacf token!  ;

code um*  (s n1 n2 -- d )  ax pop   bx pop   bx  mul   dx ax xchg   2push c;
code m*   (s n1 n2 -- d )  ax pop   bx pop   bx imul   dx ax xchg   2push c;

code um/mod  (s d1 n1 -- rem quot )
   bx pop   dx pop   ax pop   bx  div   2push
c;
code sm/rem  (s d1 n1 -- rem quot )
   bx pop   dx pop   ax pop   bx idiv   2push
c;

code dnegate  (s d# -- d#' )
   bx pop   cx pop   ax ax sub   ax dx mov
   cx dx sub   bx ax sbb   2push
c;

code 2nip  ( d1 d2 -- d2 )  ax pop  bx pop  dx pop  dx pop  bx push  1push c;

: dabs  ( d# -- d# )  dup 0<  if  dnegate  then  ;
: dmax  ( d1 d2 -- d3 )  2over 2over  d-  nip 0<  if  2swap  then  2drop  ;

code d+  ( x1 x2 -- x3 )
   ax pop  bx pop  cx pop  dx pop
   bx dx add
   cx ax adc
   dx push
   ax push
c;
code d-  ( x1 x2 -- x3 )
   bx pop  cx pop  ax pop  dx pop
   cx dx sub
   bx ax sbb
   dx push
   ax push
c;

: m/mod  (s d# n1 -- rem quot )
   dup >r  2dup xor >r  >r dabs r@ abs  um/mod
   swap r>  0< if  negate  then
   swap r> 0< if
      negate over if  1- r@ rot - swap  then
   then
   r> drop
;
: fm/mod  ( d# n1 -- rem quot )  m/mod  ;
: *      (s n1 n2 -- n3 )   m* drop   ;
: u*     (s n1 n2 -- n3 )  um* drop   ;
: /mod   (s n1 n2 -- rem quot )   >r  s>d  r>  m/mod  ;
: u/mod  (s n1 n2 -- rem quot )   >r    0  r>  m/mod  ;
: /      (s n1 n2 -- quot )   /mod  nip   ;
: mod    (s n1 n2 -- rem )    /mod  drop  ;
: */mod  (s n1 n2 n3 -- rem quot )  >r  m*  r>  m/mod  ;
: */     (s n1 n2 n3 -- n1*n2/n3 )   */mod  nip  ;

: ul*    (s ul u  -- ul.prod )  *  ;

\ : /mod  (s dividend divisor -- remainder quotient )
\   \ Check if either factor is negative
\     2dup               ( n1 n2 n1 n2)
\     or 0< if           ( n1 n2)
\     
\         \ Both factors not non-negative do division by:
\         \ Take absolute value and do unsigned division
\         \ Convert to truncated signed divide by:
\         \  if dividend is negative then negate the remainder
\         \  if dividend and divisor have opposite signs then negate the quotient
\         \ Then convert to floored signed divide by:
\         \  if quotient is negative and remainder is non-zero
\         \    add divisor to remainder and decrement quotient
\ 
\         2dup swap abs swap abs  ( n1 n2 u1 u2)     \ Absolute values
\ 
\         u/mod              ( n1 n2 urem uqout)     \ Unsigned divide
\         >r >r              ( n1 n2) ( uquot urem)
\ 
\         over 0< if         ( n1 n2) ( uquot urem)  
\             r> negate >r                   \ Negative dividend; negate remainder
\         then               ( n1 n2) ( uquot trem)
\    
\         swap over          ( n2 n1 n2) ( uquot trem)
\         xor 0< if          ( n2) ( uquot trem)
\             r> r>
\             negate         ( n2 trem tquot)  \ Opposite signs; negate quotient
\            -rot            ( tquot n2 trem)
\             dup 0<> if 
\                 +          ( tquot rem) \ Negative quotient & non-zero remainder
\                 swap 1-    ( rem quot)  \ add divisor to rem. & decrement  quot.
\             else
\                 nip swap   ( rem quot)
\             then
\         else
\             drop r> r>     ( rem quot)
\         then
\ 
\     else   \ Both factors non-negative
\ 
\         u/mod          ( rem quot)
\     then
\ ;

userarea-t constant init-user-area

\ Execute a Forth word given a pointer to a code field address
: perform   (s addr-of-acf -- )  token@ execute  ;

\ Select a vocabulary thread by hashing the lookup name.
code hash  (s str-addr voc-ptr -- thread )
   ax pop
   \ The next line is equivalent to ">threads", which in this
   \ implementation happens to be the same as ">body >user"
   /cf [ax] ax mov   ?bswap-ax   up ax add

   dx pop
[ifdef] big-endian-t
   bx bx xor
   1 [dx] bl mov		\ Get count byte
   #threads-t 1- #  bx  and	\ Modulo number of threads
   bx shl  bx shl		\ Convert to longword index
   bx ax add
[then]
   1push
c;

\ Search a vocabulary thread (link) for a name matching string.
\ If found, return its code field address and -1 if immediate, 1 if not
\ immediate.  If not found, return the string and 0.

\ Name field:
\     name: forth-style packed string, no tag bits
\     flag: 40 bit is immediate bit
\ Padding is optionally inserted between the name and the flags
\ so that the byte after the flag byte is on an even boundary.

code ($find-next)  (s adr len link -- adr len alf true  |  adr len false )
\ Registers:
\ ax     alf of word being tested
\ bx     string
\ si     anf of word being tested
\ dx     scratch
\ cx	 used as count for rep instruction

   ds ax mov  ax es mov	\ Ensure es is correct

   ax		pop	\ link
   0 [sp]  dx	mov	\ string length (not consumed)
   4 [sp]  bx	mov	\ string address (not consumed)
   bp           push	\ Save RP
   si		push	\ Save IP
   di		push	\ Save UP
   cx      cx   xor	\ Clear high bytes

   here-t 5 + #)  call	\ Figure out the origin address
   here-t
   bp pop
   origin-t - #  bp  sub

   ahead
   begin

      /link #  ax  sub	\ >link
      ax       si  mov	\ Link address of word to test

      si           dec  \ >length-byte
      0 [si]   cl  mov	\ Get count/tag byte
      h# 1f #  cl  and	\ remove tag bits, leaving the word length in cl
      cx       si  sub	\ Skip back to beginning of name field

      bx       di  mov	\ Get string address into compare register
      repz byte cmps	\ Compare strings
      0= if		\ If the strings match, the Z bit will be set
                        \ Are the strings are the same length?
         0 [si]  cl  mov	\ Count/tag byte
	 h# 1f # cl  and	\ remove tag bits
         dl      cl  cmp         
         =  if			\ We found it ...
	    di       pop	\ Restore UP
	    si	     pop	\ Restore IP
	    bp       pop	\ Restore RP

            ax       push	\ Push alf above pstr
            true #   ax  mov
	    1push  		\ True on top of stack means "found"
	    next
         then
      then

   but then
      \ The names did not match, so check the next name in the list
      0 [ax]  ax  mov	\ Fetch next link
      ax      bp  cmp	\ Test for end of list
   0= until

   \ If we get here, we've checked all the names with no luck
   di           pop     \ Restore UP
   si		pop	\ Restore IP
   bp           pop	\ Restore RP
   ax       ax  xor
   1push        	\ Return 0 for "not found"
c;

: ?negate  (s n1 n2 -- n3 )  if  negate  then  ;
: wflip  (s l1 -- l2 )  lwsplit swap wljoin  ;  \ word swap

code cset    (s byte-mask addr -- )  bx pop  ax pop           al 0 [bx] or   c;
code creset  (s byte-mask addr -- )  bx pop  ax pop  ax not   al 0 [bx] and  c;
code ctoggle (s b addr -- )          bx pop  ax pop           al 0 [bx] xor  c;
code toggle  (s addr byte-mask -- )  ax pop  bx pop           al 0 [bx] xor  c;

code s->l (s n.signed -- l )   c;
code l->n (s l -- n )  c;
code n->a (s n -- a )  c;
code l->w (s l -- w )  bx pop  ax ax xor  op: bx ax mov  1push c;
code n->w (s n -- w )  bx pop  ax ax xor  op: bx ax mov  1push c;

code l>r  (s l -- )   ax pop   rp adec   ax 0 [rp] mov   c;
code lr>  (s -- l )   0 [rp] ax mov   rp ainc   1push c;
code lr@  (s -- l )   0 [rp] ax mov             1push c;  

code /t*  (s n -- n*/t )   ax pop   ax shl   ax shl   1push c;

#align-t     constant #align
#talign-t    constant #talign
#acf-align-t constant #acf-align
: align  (s -- )  #align (align)  ;
: taligned  (s adr -- adr' )  #talign round-up  ;
: talign  (s -- )  #talign (align)  ;

true constant in-little-endian?

\ [ifdef] big-endian-t
\ : >name   ( acf -- anf )
\    1- begin  1-  dup c@  bl >  until	\ Find the end of the name
\    /token 1- invert and		\ Move to token boundary
\    begin  dup c@  bl >=  while  /token -  repeat
\ ;
\ [then]

code lmove  ( src dst len -- )
   di dx mov
   cld
   si bx mov
   ds ax mov
   ax es mov
   cx pop     \ Len
   di pop     \ dst
   si pop     \ src
   2 #  cx  shr  \ longword count
   repnz  movs
   bx si mov
   dx di mov
c;

\ Code words to support the file system interface

\ signed mixed mode addition (same as + on 32-bit machines)
: ln+   (s n1 n2 -- n3 )  +  ;

\ &ptr is the address of a pointer.  fetch the pointed-to
\ character and post-increment the pointer
 
[ifdef] big-endian-t
: @c@++  ( &ptr -- char )  dup @ c@  1 rot +!  ;
[else]
code @c@++ ( &ptr -- char )
   bx pop   0 [bx] cx mov   ax ax sub  0 [cx] al mov
   cx inc   cx 0 [bx] mov   1push
c;
[then]
 
\ &ptr is the address of a pointer.  store the character into
\ the pointed-to location and post-increment the pointer

[ifdef] big-endian-t
: @c!++  ( char &ptr -- )  tuck @ c!  1 swap +!  ;
[else]
code @c!++ ( char &ptr -- )
   bx pop   0 [bx] cx mov   ax pop   al 0 [cx] mov
   cx inc   cx 0 [bx] mov
c;
[then]

\ Low-level character processing routines:
\ skipbl   -   skip leading white space     ( interpreter )
\ scanbl   -   collect non-white characters ( interpreter )
\ skipto   -   skip to next occurrence of a character ( comments )
\ scanto   -   collect characters until next occurrence of a character ( word )
\
\ These routines, used solely by getword, getcword, and skipcword,
\ are not intended to be called by the user.  They are written in code
\ so the compiler will be fast.
\
\ These perform roughly the same function as EXPECT in Fig-Forth, except
\ that they do the "right things":
\ a) They allow words to span buffer boundaries
\ b) If the delimiter is not blank, leading delimiters are NOT skipped.
\ c) If the delimiter is blank, leading delimiters are skipped,
\    furthermore all control characters are treated as delimiters.
\    Carriage returns, linefeeds, tabs, form-feeds, etc can thus be
\    included in files.
\ d) A separate word (skipcword) is used for skipping comments.
\    It does not store the characters it scans, so the comment can be
\    arbitrarily long without worry of overflowing the word buffer.

\ Nonblanks from the buffer starting at addr are appended to the end of str
code scanbl  ( endaddr addr str -- endaddr [ addr' ] delimiter )
   \ di - str   si - addr   bx - endaddr   ax - byte   cx - scr   dx - save
   si      dx   mov		\ Save IP
   ds      ax   mov   ax es mov \ Ensure es points to the right place
   ax           pop		\ destination string
   si           pop		\ buffer address (source string)
   bx           pop		\ buffer end address
\ cx pop cx push
   bx           push		\ end address is not consumed   
   di           push		\ Save UP
   ax      di   mov		\ Destination string
   di	        push		\ temporarily store str start address on stack
   ax      ax   sub		\ clear high bytes
   0 [di]  al   mov		\ Length byte of destination string
   di           inc		\ Address of destination string data
   ax      di   add		\ End address of destination string
   begin
      bx   si   cmp		\ while not end of buffer
   u< while			\ Continue while more buffered bytes
      al        lodsb		\ get the next character
      \ The next line can't use "bl" because that looks like a register!
      h# 20 #  al  cmp		\ Look for a terminating white character
      <= if			\ Exit if delimiter found
         0 #  0 [di]  movb	\ Null-terminate the string for jollies
	 cx           pop	\ Start address of destination string
	 cx      di   sub	\ Calculate string length
	 di           dec	\ Don't count length byte in string length
         di      bx   mov
	 bl   0 [cx]  movb	\ Store string length
         di	      pop	\ Restore UP
         si           push	\ Push addr'
         dx      si   mov	\ Restore IP
	 1push			\ Actual delimiter on top of stack
	 next
      then
      al        stosb		\ Append non-delimiter to destination string
      \ Haven't found the delimiter yet.
   repeat

   \ Ran out of buffer
   cx           pop	\ Start address of destination string
   cx      di   sub	\ Calculate string length
   di           dec	\ Don't count length byte in string length
   di      bx   mov
   bl   0 [cx]  movb	\ Store string length

   dx      si   mov	\ Restore IP
   -1 #    ax   mov
   di           pop	\ Restore UP
   1push        	\ Return -1 as delimiter
c;

code skipbl ( endaddr addr -- endaddr [ addr' ] delimiter )
   \ si - addr   bx - endaddr   ax - byte
   si      dx   mov     \ Save IP
   si		pop	\ addr
   bx		pop	\ endaddr
   bx		push	\ endaddr is not consumed
   ax      ax   sub     \ Clear high bits

   begin
      bx   si	cmp	\ while not end of buffer
   u< while
      al	lodsb	\ get the next character (Delay slot)
      \ The next line can't use "bl" because that looks like a register!
      h# 20 #  al  cmp	\ Look for a terminating non-white character
      >  if
         si	dec	\ Undo the extra increment (don't consume the char)
         si	push	\ Push addr'
         dx  si mov     \ Restore IP
	 1push		\ Actual delimiter on top of stack
         next
      then
   \ Haven't found the delimiter yet.
   repeat
   \ Ran out of buffer
   dx       si  mov     \ Restore IP
   -1 #	    ax  mov
   1push        	\ Return -1 as delimiter
c;

code scanto ( char endaddr addr str -- char endaddr [ addr' ] delimiter )
   \ di - str   si - addr   bx - endaddr   ax - byte   cx - char   dx - save
   si      dx   mov		\ Save IP
   ds      ax   mov   ax es mov \ Ensure es points to the right place
   ax           pop		\ destination string
   si           pop		\ buffer address (source string)
   bx           pop		\ buffer end address
   cx		pop		\ char
   cx		push		\ char is not consumed
   bx           push		\ end address is not consumed   
   di           push		\ Save UP
   ax      di   mov		\ destination string
   di	        push		\ temporarily store str start address on stack
   ax      ax   sub		\ clear high bytes
   0 [di]  al   mov		\ Length byte of destination string
   di           inc		\ Address of destination string data
   ax      di   add		\ End address of destination string
   begin
      bx   si   cmp		\ while not end of buffer
   u< while			\ Continue while more buffered bytes
      al        lodsb		\ get the next character
      cl    al  cmp		\ Look for a terminating delimiter character
      = if			\ Exit if delimiter found
         0 #  0 [di]  movb	\ Null-terminate the string for jollies
	 cx           pop	\ Start address of destination string
	 cx      di   sub	\ Calculate string length
	 di           dec	\ Don't count length byte in string length
         di      ax   mov
	 al   0 [cx]  movb	\ Store string length
         di           pop	\ Restore UP
         si           push	\ Push addr'
         dx      si   mov	\ Restore IP
	 1push			\ Actual delimiter on top of stack
	 next
      then
      al        stosb		\ Append non-delimiter to destination string
      \ Haven't found the delimiter yet.
   repeat

   \ Ran out of buffer
   cx           pop	\ Start address of destination string
   cx      di   sub	\ Calculate string length
   di           dec	\ Don't count length byte in string length
   di      ax   mov
   al   0 [cx]  movb	\ Store string length

   dx      si   mov	\ Restore IP
   di           pop	\ Restore UP
   -1 #    ax   mov
   1push        	\ Return -1 as delimiter
c;

code skipto ( char endaddr addr -- char endaddr [ addr' ] delimiter )
   \ di - addr   cx - endaddr-addr   ax - char
   ds ax mov  ax es mov \ Ensure es points to the right place
   di      dx   mov	\ Save UP
   di		pop	\ addr
   cx		pop	\ endaddr
   ax		pop	\ char
   ax		push	\ char is not consumed
   cx		push	\ endaddr is not consumed
   di      cx	sub	\ max count = endaddr-addr
   0<> if		\ Pre-test for max count = 0
      repnz byte scas	\ Skip non-delimiters
      0= if		\ Did repnz terminate by finding a delimiter?
         di	push	\ Push addr'
         dx  di mov	\ Restore UP
         1push		\ Return actual delimiter (== char !)
         next
      then
   \ Haven't found the delimiter yet.
   then

   \ Ran out of buffer
   dx     di mov	\ Restore UP
   -1 #	  ax mov
   1push                \ Return -1 as delimiter
c;
\ "adr1 len2" is the longest initial substring of the string "adr1 len1"
\ that does not contain the character "char".  "adr2 len1-len2" is the
\ trailing substring of "adr1 len1" that is not included in "adr1 len2".
\ Accordingly, if there are no occurrences of that character in "adr1 len1",
\ "len2" equals "len1", so the return values are "adr1 len1  adr1+len1 0"

code split-string  ( adr1 len1 char -- adr1 len2  adr1+len2 len1-len2 )
   si dx mov		\ Save
   bx pop		\ char
   0 [sp] cx mov	\ len1
   4 [sp] si mov	\ adr1

   ahead begin
      al      lodsb	\ Get the next character
      bl  al  cmp	\ Compare to delimiter
      = if		\ Exit if delimiter found
         cx   inc	\ Account for pre-decrement of count
	 cx 0 [sp] sub	\ len2
	 si   dec	\ Account for incremented address
	 si   push	\ adr2
	 cx   push	\ len1-len2
         dx   si  mov	\ Restore
	 next
      then
   but then
      cx dec
   0< until

   \ The test character is not present in the input string

   si   push
   cx   inc		\ Account for pre-decrement of count
   cx   push

   dx si mov		\ Restore
c;

\ Splits a buffer into two parts around the first line delimiter
\ sequence.  A line delimiter sequence is either CR, LF, CR followed by LF,
\ or LF followed by CR.
\ adr1 len2 is the initial substring before, but not including,
\ the first line delimiter sequence.
\ adr2 len3 is the trailing substring after, but not including,
\ the first line delimiter sequence.

code parse-line  ( adr1 len1 -- adr1 len2  adr1+len2 len1-len2 )
   si dx mov		\ Save
   0 [sp] cx mov	\ len1
   4 [sp] si mov	\ adr1
   h# 0a #  bh  mov	\ Delimiter 1
   h# 0d #  bl  mov	\ Delimiter 2

   ahead begin
      al      lodsb	\ Get the next character
      bh al cmp  <> if  bl al cmp  then  \ Compare to delimiters

      = if		\ Exit if delimiter found
         cx inc			\ len2 doesn't include the delimiter
	 cx  0 [sp]  sub	\ len2
         cx dec
         \ Check next character too, unless we're at the end of the buffer
         0<>  if
            0 [si]  ah  mov	\ Get next character
            bh al cmp  = if	\ Compare it to the other delimiter
	       bl ah cmp
            else
	       bh ah cmp
            then
	    =  if
               cx   dec		\ Consume the second delimiter too
	       si   inc		\ Consume the second delimiter too
            then
         then
	 si   push	\ adr2
	 cx   push	\ len1-len2
         dx   si  mov	\ Restore
	 next
      then
   but then
      cx dec
   0< until

   \ There is no line delimiter in the input string

   si   push
   cx   inc		\ Account for pre-decrement of count
   cx   push

   dx si mov		\ Restore
c;

code skipwhite  ( adr len -- adr' len' )
   si dx mov
   cld
   cx pop
   cx cx or  0<>  if
      si pop
      begin
         al lods
         h# 20 # al cmp  >  if
            si dec  si push
            cx push  dx si mov
            next
         then
      loopa
      si push
   then
   cx push
   dx si mov
c;

\ Adr2 points to the delimiter or to the end of the buffer
\ Adr3 points to the character after the delimiter or to the end of the buffer
code scantowhite  ( adr1 len1 -- adr1 adr2 adr3 )
   si dx mov
   cld
   cx pop
   0 [sp] si mov
   cx cx or  0<>  if
      begin
         al lods
         h# 20 # al cmp  <=  if
            si dec si push
            si inc si push
            dx si mov
            next
         then
      loopa
   then
   si push
   si push
   dx si mov
c;

code skipchar  ( adr len char -- adr' len' )
   si dx mov
   cld
   bx pop         \ char in bx
   cx pop
   cx cx or  0<>  if
      si pop
      begin
         al lods
         bl al cmp
      loope
      0<>  if  cx inc  si dec  then
      si push
   then
   cx push
   dx si mov
c;

\ Adr2 points to the delimiter or to the end of the buffer
\ Adr3 points to the character after the delimiter or to the end of the buffer
code scantochar  ( adr1 len1 char -- adr1 adr2 adr3 )
   si dx mov
   cld
   bx pop
   cx pop
   0 [sp] si mov
   cx cx or  0<>  if
      begin
         al lods
         bl al cmp
      loopne
      =  if
         si dec si push
         si inc si push
         dx si mov
         next
      then
   then
   si push
   si push
   dx si mov
c;

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
