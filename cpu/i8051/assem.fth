
vocabulary 8051-assembler
: assembler  8051-assembler  ;
assembler also definitions

defer asm8@	 also forth ' c@    previous   is asm8@
defer asm8!	 also forth ' c!    previous   is asm8!
defer here	 also forth ' here  previous   is here
defer asm-allot	 also forth ' allot previous   is asm-allot

\ append values to the end of a code definition which is being built.
\ always little-endian:
: asm8,   ( n -- )  here 1 asm-allot asm8!  ;

d# -1 constant #
d# -2 constant @R0
d# -3 constant @R1
d# -4 constant R7
d# -5 constant R6
d# -6 constant R5
d# -7 constant R4
d# -8 constant R3
d# -9 constant R2
d# -10 constant R1
d# -11 constant R0
d# -12 constant A

\ Port bits
: bitnum:  create , does> @ +  ;
8 0 do  i bitnum:  loop   .0 .1 .2 .3 .4 .5 .6 .7

\ SFRs
h# 80 constant p0
h# 81 constant sp
h# 82 constant dpl
h# 83 constant dph
h# 87 constant pcon
h# 88 constant tcon
h# 89 constant tmod
h# 8a constant tl0
h# 8b constant tl1
h# 8c constant th0
h# 8d constant th1
h# 90 constant p1
h# 98 constant scon
h# 99 constant sbuf \ not bit-addressable
h# a0 constant p2
h# a8 constant ie
h# b0 constant p3
h# b8 constant ip
h# d0 constant psw
h# e0 constant acc
h# f0 constant b

\ KB3700 extensions/changes
h# 80 constant p0ie  \ Bits enable corresponding interrupt
h# 86 constant pcon2 \ Various, see KB3700 manual (page 35)
h# 90 constant p1ie  \ Bits enable corresponding interrupt
h# 9a constant scon2 \ Extended baud rate divisor, low byte
h# 9b constant scon3 \ Extended baud rate divisor, high byte
h# b0 constant p3ie  \ Bits enable corresponding interrupt 
h# d8 constant p0if  \ Bits report corresponding interrupt status
h# e8 constant p1if  \ Bits report corresponding interrupt status
h# f8 constant p3if  \ Bits report corresponding interrupt status


: acall  ( adr -- )     \ ppp1.0001 llll.llll
   \ XXX check that adr matches high 5 bits of PC
   h# 7ff and  wbsplit        ( low high )
   5 lshift  h# 11 or  asm8,  ( low )
   asm8,
;
: ajmp  ( adr -- )     \ ppp1.0001 llll.llll
   \ XXX check that adr matches high 5 bits of PC
   h# 7ff and  wbsplit        ( low high )
   5 lshift  h# 01 or  asm8,  ( low )
   asm8,
;

: iram,  ( n -- )
   dup h# ff >  abort" IRAM address too large"
   asm8,
;

: immed,  ( n -- )
   dup h# ff >  abort" Immediate value too large"
   asm8,
;
: byte-offset?  ( offset -- flag )  h# -80 h# 7f between  ;
: rel!  ( to from -- )
   tuck  1+ -    ( from offset )
   dup byte-offset? 0= abort" Bad branch offset"
   swap asm8!
;
: rel,  ( n -- )  here rel!  1 asm-allot  ;

: add  ( n [ # or @ ] -- )
   dup #  =  if  drop h# 24 asm8,  immed,  exit  then

   dup @R0  =  if  drop h# 26 asm8,  exit  then
   dup @R1  =  if  drop h# 27 asm8,  exit  then
   dup R0 R7 between  if  R0 -  h# 28 + asm8,  exit  then

   h# 25 asm8,  iram,
;

: addc  ( n [ # or @ ] -- )
   dup #  =  if  drop h# 34 asm8,  immed,  exit  then

   dup @R0  =  if  drop h# 36 asm8,  exit  then
   dup @R1  =  if  drop h# 37 asm8,  exit  then
   dup R0 R7 between  if  R0 -  h# 38 + asm8,  exit  then

   h# 35 asm8,  iram,
;

: subb  ( n # | n | @Rn | Rn ] -- )
   dup #  =  if  drop   h# 94 asm8,  immed, exit  then

   dup @R0  =  if  drop h# 96 asm8,  exit  then
   dup @R1  =  if  drop h# 97 asm8,  exit  then
   dup R0 R7 between  if  R0 -  h# 98 + asm8,  exit  then

   h# 95 asm8,  iram,
;

: anl  ( n # | n | @Rn | Rn ] -- )
   dup #  =  if  drop  h# 54 asm8,  immed,  exit  then

   dup @R0  =  if  drop h# 56 asm8,  exit  then
   dup @R1  =  if  drop h# 57 asm8,  exit  then
   dup R0 R7 between  if  R0 -  h# 58 + asm8,  exit  then
   h# 55 asm8,  iram,
;

: anlr  ( iram -- )  h# 52 asm8,  asm8,  ;
: anli  ( data iram -- )  h# 53 asm8,  asm8,  asm8,  ;  \ ANL iramadr,#data
: anlc  ( bit-addr -- )  h# 82 asm8, asm8, asm8,  ;
: anlc/ ( bit-addr -- )  h# b0 asm8, asm8, asm8,  ;

: orl  ( n # | n | @Rn | Rn ] -- )
   dup #  =  if  drop  h# 44 asm8,  immed,  exit  then

   dup @R0  =  if  drop h# 46 asm8,  exit  then
   dup @R1  =  if  drop h# 47 asm8,  exit  then
   dup R0 R7 between  if  R0 -  h# 48 + asm8,  exit  then

   h# 45 asm8,  iram,
;

: orlr  ( iram -- )  h# 42 asm8,  asm8,  ;
: orli  ( data iram -- )  h# 43 asm8,  asm8,  asm8,  ;  \ ANL iramadr,#data
: orlc  ( bit-addr -- )  h# 72 asm8, asm8, asm8,  ;
: orlc/ ( bit-addr -- )  h# a0 asm8, asm8, asm8,  ;

: xrli  ( data iram -- )  h# 63 asm8,  asm8,  asm8,  ;  \ XRL iramadr,#data
: xrl  ( n # | n | @Rn | Rn ] -- )
   dup #  =  if  drop  h# 64 asm8,  immed,  exit  then

   dup @R0  =  if  drop h# 66 asm8,  exit  then
   dup @R1  =  if  drop h# 67 asm8,  exit  then

   dup R0 R7 between  if  R0 -  h# 68 + asm8,  exit  then

   h# 65 asm8,  iram,
;

: mov  ( ? -- )   \ a,src
   dup #  =  if  drop  h# 74 asm8,  immed,  exit  then

   dup @R0  =  if  drop h# e6 asm8,  exit  then
   dup @R1  =  if  drop h# e7 asm8,  exit  then

   dup R0 R7 between  if  R0 -  h# e8 + asm8,  exit  then

   h# e5 asm8,  iram,
;

: movr  ( ? -- )  \ dst,a
   dup @R0  =  if  drop h# f6 asm8,  exit  then
   dup @R1  =  if  drop h# f7 asm8,  exit  then

   dup R0 R7 between  if  R0 -  h# f8 + asm8,  exit  then

   h# f5 asm8,  iram,
;

: movc  ( bit -- )  h# a2 asm8,  asm8,  ;

: movi  ( data ea -- )  \ ea,#data
   dup @R0  =  if  drop h# 76 asm8,  immed,  exit  then
   dup @R1  =  if  drop h# 77 asm8,  immed,  exit  then

   dup R0 R7 between  if  R0 -  h# 78 + asm8,  immed, exit  then
   h# 75 asm8,  iram,  immed,
;

: mov_to_iram  ( ea iram -- )  \ iram,ea
   swap
   dup @R0  =  if  drop h# 86 asm8,  iram,  exit  then
   dup @R1  =  if  drop h# 87 asm8,  iram,  exit  then

   dup R0 R7 between  if  R0 -  h# 88 + asm8,  iram, exit  then
   h# 85 asm8,  iram,  iram,
;

: mov_from_iram  ( iram ea -- )  \ ea,iram
   dup @R0  =  if  drop h# a6 asm8,  iram,  exit  then
   dup @R1  =  if  drop h# a7 asm8,  iram,  exit  then

   dup R0 R7 between  if  R0 -  h# a8 + asm8,  iram, exit  then
   drop true abort" illegal addressing mode"
;

: xchg  ( n | @Rn | Rn ] -- )
   dup @R0  =  if  drop h# c6 asm8,  exit  then
   dup @R1  =  if  drop h# c7 asm8,  exit  then

   dup R0 R7 between  if  R0 -  h# c8 + asm8,  exit  then

   h# c5 asm8,  iram,
;

: dec  ( n | A | @Rn | Rn ] -- )
   dup A =  if  drop   h# 14 asm8,  exit  then

   dup @R0  =  if  drop h# 16 asm8,  exit  then
   dup @R1  =  if  drop h# 17 asm8,  exit  then
   dup R0 R7 between  if  R0 -  h# 18 + asm8,  exit  then

   h# 15 asm8,  iram,
;

: djnz  ( adr n | @Rn | Rn ] -- )
   dup R0 R7 between  if  R0 -  h# d8 + asm8, rel,  exit  then

   h# d5 asm8,  iram,  rel,
;

: inc  ( n | A | @Rn | Rn ] -- )
   dup A =  if  drop   h# 04 asm8,  exit  then

   dup @R0  =  if  drop h# 06 asm8,  exit  then
   dup @R1  =  if  drop h# 07 asm8,  exit  then
   dup R0 R7 between  if  R0 -  h# 08 + asm8,  exit  then

   h# 05 asm8,  iram,
;

: orlr  ( iram -- )  h# 62 asm8,  asm8,  ;
: orli  ( data iram -- )  h# 63 asm8,  asm8,  asm8,  ;  \ ANL iramadr,#data

: cjne  ( adr n # | n | @Rn | Rn ] -- )
   dup #  =  if  drop  h# b4 asm8, immed, rel,  exit  then

   dup @R0  =  if  drop h# b6 asm8,  rel, exit  then
   dup @R1  =  if  drop h# b7 asm8,  rel, exit  then

   dup R0 R7 between  if  R0 -  h# b8 + asm8,  rel, exit  then

   h# b5 asm8,  iram,  rel,
;

: cpl   ( bit -- )  h# b2 asm8, asm8,  ;
: clr   ( bit -- )  h# c2 asm8, asm8,  ;
: setb  ( bit -- )  h# d2 asm8, asm8,  ;
: jc    ( reladdr -- )  h# 40 asm8, rel,  ;
: jnc   ( reladdr -- )  h# 50 asm8, rel,  ;
: jz    ( reladdr -- )  h# 60 asm8, rel,  ;
: jnz   ( reladdr -- )  h# 70 asm8, rel,  ;
: sjmp  ( reladdr -- )  h# 80 asm8, rel,  ;
: jb    ( reladdr bit -- )  h# 20 asm8, asm8, rel,  ;
: jbc   ( reladdr bit -- )  h# 10 asm8, asm8, rel,  ;
: jnb   ( reladdr bit -- )  h# 30 asm8, asm8, rel,  ;

: 1mi  create c, does> c@ asm8, ;

h# d6 1mi xchd_a,@R0
h# d7 1mi xchd_a,@R1

h# 00 1mi nop

h# 22 1mi ret
h# 32 1mi reti

h# 03 1mi rr
h# 13 1mi rrc
h# 23 1mi rl
h# 33 1mi rlc
h# 73 1mi jmp@a+dptr
h# a3 1mi incdptr
h# b3 1mi cplc
h# c3 1mi clrc
h# d3 1mi setbc

h# 84 1mi div
h# a4 1mi mulab
h# c4 1mi swapa
h# d4 1mi da
h# e4 1mi clra
h# f4 1mi cpla

h# e0 1mi movx_a,@dptr
h# e2 1mi movx_a,@r0
h# e3 1mi movx_a,@r1
h# f0 1mi movx_@dptr,a
h# f2 1mi movx_@r0,a
h# f3 1mi movx_@r1,a
h# 83 1mi movc_a,@a+pc
h# 93 1mi movc_a,@a+dptr

: ladr,  ( adr -- )  wbsplit asm8, asm8,  ;
: ljmp  ( adr -- )  h# 02 asm8, ladr,  ;
: lcall ( adr -- )  h# 12 asm8, ladr,  ;

: push ( iram -- )  h# c0 asm8, iram,  ;
: pop  ( iram -- )  h# d0 asm8, iram,  ;

: xjmp  ( adr -- )
\ Turn off this optimizations for now for simplicity
\   dup here -  byte-offset?  if  sjmp  else  ljmp  then
   ljmp
;
: xcall  ( adr -- )
\ Turn off this optimizations for now for simplicity
\   dup  here 2+  xor h# f800 and  ( adr page-different? )
\   if  lcall  else  acall  then   ( adr )
   lcall
;
: put-ljmp  ( to from -- )
   >r
   h# 12 r@ asm8!   ( to r: from )
   wbsplit          ( to.lo to.hi r: from )
   r@ 1+ asm8!      ( to.lo r: from )
   r> 2+ asm8!      ( )
;

hex

h# 10 constant bit-set?&clr \ JBC
h# 20 constant bit-clr?     \ JB
h# 30 constant bit-set?     \ JNB
h# 40 constant no-carry?    \ JC
h# 50 constant carry?       \ JNC
h# 60 constant 0<>          \ JZ
h# 70 constant 0=           \ JNZ

: put-cond ( [ bit# ] cond -- )
   dup asm8,                 \ Conditional branch
   h# 40 <  if  asm8,  then  \ Include bit# if necessary
;

\ >mark must return the address of the opcode, not the address
\ of the offset, in order for loclabel.fth to work.
: >mark  ( -- from )  here  ;
: >resolve  ( from -- )
   dup asm8@ h# 40 <  if  2+  else  1+  then  \ Skip opcode [ and bit# ]
   here  swap  rel!
;
: <mark  ( -- to )  here  ;
: <resolve  ( to -- )  rel,  ;

: but  ( mark1 mark1 -- mark2 mark1 )  swap  ;
: yet  ( mark -- mark mark )  dup  ;

\ Assemble DJNZ in either Rn or direct form
: ,loop  ( to [ iram | reg ] -- )     
   dup R0 R7 between  if    ( to reg )
      R0 -  h# d8 +  asm8,  ( to )      \ 2-byte Rn form
   else                     ( to iram )
      h# d5 asm8,  asm8,    ( to iram ) \ 3-byte direct form
   then                     ( to )
   <resolve
;

\ After we start redefining control structure words, we have to be
\ careful not to use them with the expectation of their Forth meanings.
: if     ( [ bit# ] cond -- from )  >mark >r   put-cond  0 asm8,  r>  ;
: until  ( to [ bit# ] cond -- )  h# 10 xor  put-cond  here rel!  ;

: then   ( from -- )        >resolve  ;
: begin  ( -- to )          <mark   ;
: ahead  ( -- from )        h# 80  if  ;               \ SJMP
: else   ( from -- from' )  ahead  but  then  ;
: again  ( to -- )          h# 80 asm8,  <resolve  ;   \ SJMP
: while  ( to -- from to )  if  but  ;
: repeat ( from to -- )     again  then  ;

only forth also definitions

\ If xxxx.1rrr bit is set, it is a regular form where the EA is R0..7
\ If xxxx.0100 the EA is often #immed
\ If xxxx.0101 the EA is often iram
\ If xxxx.0110 the EA is always @R0
\ If xxxx.0111 the EA is always @R1

\  nop             0000.0000

\  jbc bit reladr  0001.0000 bit reladr
\  jb  bit reladr  0010.0000 bit reladr
\  jnb bit reladr  0011.0000 bit reladr

\  jc   reladr     0100.0000 reladr
\  jnc  reladr     0101.0000 reladr
\  jz   reladr     0110.0000 reladr
\  jnz  reladr     0111.0000 reladr
\  sjmp reladr     1000.0000 reladr

\  movx_a,@dptr    1110.0000
\  movx_@dptr,a    1111.0000

\  acall           ppp1.0001 llll.llll
\  ajmp            ppp0.0001 llll.llll

\  orl c,/bit      1010.0000 n n
\  anl c,/bit      1011.0000 n n
\  push            1100.0000 iram
\  pop             1101.0000 iram

\  orl c,bit       0111.0010 n n
\  anl c,bit       1000.0010 n n
\  clr bit         1100.0010 bit
\  setb bit        1101.0010 bit


\  ljmp  adr       0000.0010 adr adr
\  lcall adr       0001.0010 adr adr
\  ret             0010.0010
\  reti            0011.0010

\  movx_a,@r0      1110.0010
\  movx_@r0,a      1111.0010

\  rr              0000.0011
\  rrc             0001.0011
\  rl              0010.0011
\  rlc             0011.0011

\  jmp@a+dptr      0111.0011
\  movc_a,@a+pc    1000.0011
\  movc_a,@a+dptr  1001.0011

\  clrc            1100.0011
\  setbc           1101.0011
\  movx_a,@r1      1110.0011
\  movx_@r1,a      1111.0011

\  div             1000.0100  (shoehorned into mov iram,ea)
\  mulab           1010.0100  (shoehorned into mov ea,iram)
\  swap            1100.0100  (shoehorned into xchg)
\  da              1101.0100  (shoehorned into djnz)
\  clra            1110.0100  (shoehorned into mov a,ea)

\  xchd a,@r0      1101.0110  (shoehorned into djnz)
\  xchd a,@r1      1101.0111  (shoehorned into djnz)

\  inc         0000.mmmm
\  dec         0001.mmmm
\  add         0010.mmmm
\  addc        0011.mmmm
\  orl         0100.mmmm
\  anl         0101.mmmm
\  xrl         0110.mmmm
\  mov ea,#    0111.mmmm data
\  mov iram,ea 1000.mmmm iram
\  subb        1001.mmmm
\  mov ea,iram 1010.mmmm iram
\  cjne        1011.mmmm idata reladdr (cplc shoehorned at 3, cplbit at 2)
\  xchg        1100.mmmm reladdr
\  djnz        1101.mmmm reladdr   (da shoehorned at 4, xchd at 6,7)
\  mov a,ea    1110.mmmm           (clr shoehorned at 4)
\  mov ea,a    1111.mmmm           (cpla shoehorned at 4)
\  cpl a       1111.0100

\  undef       1010.0101 \ shoehorned into mov ea,iram (redundant with 85)
