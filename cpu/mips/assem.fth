purpose: Forth Assembler for MIPS
\ See license at end of file

: set-relocation-bit  ;

\ requires case.f
\ alias l0< 0<
\ alias l<> <>

\ requires string-array.f

vocabulary mips-assembler
also mips-assembler definitions

alias lor or	\ Because "or" gets redefined in the assembler

defer here	\ For switching between resident and meta assembling
defer asm-allot	\ For switching between resident and meta assembling
defer asm@	\ For switching between resident and meta assembling
defer asm!	\ For switching between resident and meta assembling

\ Install as a resident assembler
: resident  ( -- )
   [ forth ] ['] here  [ mips-assembler ] is here
   [ forth ] ['] allot [ mips-assembler ] is asm-allot
   [ forth ] ['] @     [ mips-assembler ] is asm@
   [ forth ] ['] n!    [ mips-assembler ] is asm!
;
resident

decimal

\ This is used for delay slot optimization.  This variable is set
\ to the starting address of each code sequence, to the address following
\ the delay slot of each branch instruction, and to the target address
\ of forward branches.  If "next" notices that the value in delay-barrier
\ is the same as "here", it won't move the previous instruction into
\ its next's delay slot.
nuser delay-barrier
: block-delay  ( -- )  here la1+ delay-barrier !  ;
: block-here   ( -- )  here delay-barrier !  ;

h#     .ffff constant immedmask
h#     .7fff constant maximmed
h# ffff.8000 constant minimmed
h#        1f constant regmask
h# 1000.0000 constant regmagic

\ Bias register constants outside the range of signed immediate values
: reg  ( n -- )  regmagic +  ;
: register  \ name  ( n -- )
   create ,  does> @ reg
;

\ Register names; these just return constants.

 0 register $0   1 register $1   2 register $2   3 register $3
 4 register $4   5 register $5   6 register $6   7 register $7
 8 register $8   9 register $9  10 register $10 11 register $11
12 register $12 13 register $13 14 register $14 15 register $15
16 register $16 17 register $17 18 register $18 19 register $19
20 register $20 21 register $21 22 register $22 23 register $23
24 register $24 25 register $25 26 register $26 27 register $27
28 register $28 29 register $29 30 register $30 31 register $31

alias $at  $1
alias $kt0 $26
alias $kt1 $27
alias $gp  $28
alias $sp  $29
alias $a0  $4
alias $a1  $5
alias $a2  $6
alias $a3  $7
alias ra  $31
alias s0  $16
alias s1  $17
alias s2  $18
alias s3  $19
alias s4  $20
alias s5  $21
alias s6  $22
alias s7  $23
alias s8  $30
alias t0  $8
alias t1  $9
alias t2  $10
alias t3  $11
alias t4  $12
alias t5  $13
alias t6  $14
alias t7  $15
alias t8  $24
alias t9  $25
alias k0  $26
alias k1  $27
alias v0  $2
alias v1  $3

32 register $f0   33 register $f1  34 register $f2   35 register $f3
36 register $f4   37 register $f5  38 register $f6   39 register $f7
40 register $f8   41 register $f9  42 register $f10  43 register $f11
44 register $f12  45 register $f13 46 register $f14  47 register $f15
48 register $f16  49 register $f17 50 register $f18  51 register $f19
52 register $f20  53 register $f21 54 register $f22  55 register $f23
56 register $f24  57 register $f25 58 register $f26  59 register $f27
60 register $f28  61 register $f29 62 register $f30  63 register $f31

\ Test operand values to see what kind of operand they are.

: 16-bit?  ( n -- flag )   minimmed maximmed between  ;

: ?freg  ( r -- r )
   dup  $f0 $f30 between 0=  abort" Floating point register required"
;

: ?ireg  ( r -- r )
   dup  $0 $31 between 0=  abort" Integer register required"
;

\ Words to encode operands into their appropriate fields

: setbits  ( opcode -- )  here asm!  /l asm-allot  ;
: opaddr  ( -- addr )  here /l - ;
: addbits  ( bits -- )  opaddr asm@ +  opaddr asm!  ;
: >regfld  ( reg shift -- bits )  swap regmask land  swap lshift  ;
: regset  ( reg shift -- )  >regfld addbits  ;
: rs   ( rs -- )  21 regset ;
: rd   ( rd -- )  11 regset ;
: rt   ( rt -- )  16 regset ;
: sa   ( re -- )   6 regset ;

: uimmed  ( value -- )  immedmask land  addbits  ;
: immed  ( value -- )
   dup 16-bit? 0= abort" Immediate operand doesn't fit in 16 bits"
   uimmed
;

\ Set the opcode field
: set-op  ( n -- )  d# 26 lshift  setbits  ;

: special ( n -- )  0 set-op  addbits  ;
: regimm  ( n -- )  1 set-op  rt  ;
: special2 ( n -- )  34 set-op  addbits  ;

\ Define the various opcodes according to their formats.
octal

: ld:  ( opcode -- )	\ Load instructions
   create ,  does>  ( rs imm rt opc-adr -- )  @ set-op   rt immed rs
;
32 ld: ldl  33 ld: ldr
40 ld: lb   41 ld: lh    42 ld: lwl   43 ld: lw
44 ld: lbu  45 ld: lhu   46 ld: lwr   47 ld: lwu
57 ld: cache
60 ld: ll   61 ld: lwc1  62 ld: lwc2  63 ld: pref  \ pref is  rs imm hint
64 ld: lld  65 ld: ldc1  66 ld: ldc2  67 ld: ld

: st:  ( opcode -- )	\ Store instructions
   create ,  does>  ( rt rs imm  opc-adr -- )  @ set-op   immed rs rt
;
50 st: sb  51 st: sh    52 st: swl  53 st: sw  54 st: sdl   55 st: sdr  56 st: swr
70 st: sc  71 st: swc1  72 st: swc2            74 st: scd   75 st: sdc1
76 st: sdc2  77 st: sd

: 2op:  ( opcode -- )	\ Two-operand instructions (add, sub, etc)
   create ,  does>  ( rs rt rd opc-adr -- )  @  special   rd rt rs
;
40 2op: add   41 2op: addu   42 2op: sub   43 2op: subu
44 2op: and   45 2op: or     46 2op: xor   47 2op: nor
52 2op: slt   53 2op: sltu
54 2op: dadd  55 2op: daddu  56 2op: dsub  57 2op: dsubu

: lui  ( imm rt -- )
   o# 17 set-op rt
   dup h# ffff > abort" Immediate operand doesn't fit in 16 bits"
   addbits
;
: sethi  ( imm rt -- )  swap d# 16 >> swap lui  ;

: li   ( n dst -- )
   swap dup   h# ffff land  -rot          ( nlow dst n )
   dup  0  h# ffff  between  if           ( nlow dst n )
      drop  15 set-op  rt  $0 rs uimmed   \ dst nlow  dst  ori
      exit
   then                                   ( nlow dst n )

   dup  h# ffff.8000  -1  between  if     ( nlow dst n )
      drop  11 set-op  rt  $0 rs uimmed   \ $0 nlow  dst  addiu
      exit
   then                                   ( nlow dst n )

   \ We have to use two instructions unless the low 16 bits are 0
   d# 16 >>  over  lui                    ( nlow dst )
   over  if
      15 set-op  dup rt rs uimmed            \ dst nlow  dst  ori
   else
      2drop
   then
;      

alias set li

\ XXX we need to handle the case where immed is too big for 16 bits,
\ loading $at in that case.
: ?set-immed  ( rs imm rt op -- rs imm rt op )
   2 pick  16-bit?  if  exit  then   ( rs imm rt op )
   rot $at li                        ( rs rt op )
   30 + special  rd  $at rt  rs
   r> drop
;   
: ?set-uimmed  ( rs imm rt op -- rs imm rt op )
   2 pick  h# 10000 u<  if  exit  then   ( rs imm rt op )
   rot $at li                        ( rs rt op )
   30 + special  rd  $at rt  rs
   r> drop
;   
  
: imm:  ( opcode -- )	\ Two-operand immediate instructions (addi, etc)
   create ,  does>  ( rs imm rt opc-adr -- ) @  ?set-immed set-op  rt uimmed rs
;
10 imm: addi  11 imm: addiu  12 imm: slti  13 imm: sltiu
30 imm: daddi 31 imm: daddiu

: uimm:  ( opcode -- )	\ Two-operand immediate instructions (addi, etc)
   create ,  does>  ( rs imm rt opc-adr -- ) @  ?set-uimmed set-op  rt uimmed rs
;
14 uimm: andi  15 uimm: ori    16 uimm: xori

: jmpi:  ( opcode -- )	\ Jump absolute
   create ,  does>  ( target opc-adr -- )  @  set-op
   dup h# fc00.0000 land  here h# fc00.0000 land <>
   abort" Jump target outside of current 28-bit bank"
   2 >> h# 3ff.ffff land addbits
   block-delay
;
02 jmpi: j  03 jmpi: jal

: jr    ( rs -- )     o# 10 special  rs     block-delay  ;
: jalr  ( rs rd -- )  o# 11 special  rd rs  block-delay  ;

: shift:  ( opcode -- )	\ Shift instructions
   create ,  does>  ( rt sa rd opc-adr -- )  @  special rd sa rt
;
00 shift: sll     02 shift: srl     03 shift: sra
70 shift: dsll    72 shift: dsrl    73 shift: dsra
74 shift: dsll32  76 shift: dsrl32  77 shift: dsra32
: shiftv:  ( opcode -- )	\ Shift instructions
   create ,  does>  ( rt rs rd opc-adr -- )  @  special rd rs rt
;
04 shiftv: sllv   06 shiftv: srlv   07 shiftv: srav
24 shiftv: dsllv  26 shiftv: dsrlv  27 shiftv: dsrav

: mul:  ( opcode -- )	\ Two-operand instructions with implicit destination
   create ,  does>  ( rs rt opc-adr -- )  @  special  rt rs
;
31 mul: mult   31 mul: multu   32 mul: div   33 mul: divu
34 mul: dmult  35 mul: dmultu  36 mul: ddiv  37 mul: ddivu
60 mul: tge    61 mul: tgeu    62 mul: tlt   63 mul: tltu
64 mul: teq    66 mul: tne

: fhilo:  ( opcode -- )	\ HI and LO access
   create ,  does>  ( rd opc-adr -- )  @  special  rd
;
: thilo:  ( opcode -- )	\ HI and LO access
   create ,  does>  ( rd opc-adr -- )  @  special  rs
;
20 fhilo: mfhi  21 thilo: mthi  22 fhilo: mflo  23 thilo: mtlo

: dset  ( d reg -- )
   >r  r@ set  r@ 0 r@  dsll32  ( d.low )
   dup 0< swap                  ( negative? d.low )
   $at set                      ( negative? )
\   [ also forth ]  if  [ previous ]
if
       $at 0 $at dsll32  $at 0 $at dsrl32  \ Zero high bits
then
\   [ also forth ]  then  [ previous ]
   $at r@  r>  daddu
;


: >br-offset   ( target-adr br-adr -- offset )
   4 + -                                                ( byte-offset )
   2 >>a						( word-offset )
   dup 16-bit? 0= abort" Branch offset doesn't fit in 16 bits"
   immedmask land
;
: br-offset  ( adr -- )
   opaddr >br-offset  addbits
   block-delay
;
: br2:  ( opcode -- )	\ 2-operand conditional branches
   create ,  does>  ( adr rs rt opc-adr -- )  @  set-op  rt rs br-offset
;
04 br2: beq  05 br2: bne  24 br2: beql  25 br2: bnel

: br1:  ( opcode -- )	\ 1-operand conditional branches
   create ,  does>  ( adr rs opc-adr -- )  @  set-op  rs br-offset
;
06 br1: blez  07 br1: bgtz  26 br1: blezl  27 br1: bgtzl

: brx:  ( opcode -- )	\ 1-operand conditional branches (extensions)
   create ,  does>  ( adr rs opc-adr -- )  @  regimm  rs br-offset
;
00 brx: bltz    01 brx: bgez    02 brx: bltzl    03 brx: bgezl
20 brx: bltzal  21 brx: bgezal  22 brx: bltzall  23 brx: bgezall

: bal  ( adr -- )  $0 bgezal  ;

: cop0  ( -- )  o# 20 set-op  ;
: cop1  ( -- )  o# 21 set-op  ;

: brf0:  ( adr opcode -- )	\ Floating-point branches
   create ,  does>  @ cop0  d# 16 << addbits  br-offset
;
: brf1:  ( adr opcode -- )	\ Floating-point branches
   create ,  does>  @ cop1  d# 16 << addbits  br-offset
;
400 brf0: bc0f  402 brf0: bc0fl  401 brf0: bc0t  403 brf0: bc0tl
400 brf1: bc1f  402 brf1: bc1fl  401 brf1: bc1t  403 brf1: bc1tl

: trapi:  ( opcode -- )	\ Trap immediate
   create ,  does>  ( rs imm opc-adr -- )  @  regimm  immed rs  block-here
;
10 trapi: tgei   11 trapi: tgeiu  12 trapi: tlti
13 trapi: tltiu  14 trapi: teqi   16 trapi: tnei

: syscall  ( -- )  14 special  block-here  ;
: break    ( -- )  15 special  block-here  ;
: sync     ( -- )  17 special  block-here  ;

: dbreak  ( -- )  77 special2  block-here  ;
: dret    ( -- )  76 special2  block-here  ;
: mtdr    ( dbreg rt -- )  75 special2  4 rs rt rd  ;
: mfdr    ( dbreg rt -- )  75 special2  0 rs rt rd  ;

d# 16 constant single
d# 17 constant double
d# 19 constant fixed
double value float-mode

: set-cop  ( apf -- )  @ cop1  addbits float-mode rs  ;

: fr2:  ( opcode -- )  \ 2-operand floating point computation instructions
   create ,
   does>  ( fs ft fd -- )  set-cop   ( fs ft fd )   sa rt rd
;   
00 fr2: addf    01 fr2: subf     02 fr2: mulf    03 fr2: divf

: fr:  ( opcode -- )  \ 1-operand floating point computation instructions
   create ,
   does>  ( fs fd -- )  set-cop   ( fs fd )   sa 0 rt rd
;   

04 fr: sqrt     05 fr: abs      06 fr: movf    07 fr: negf
14 fr: round.w  15 fr: trunc.w  16 fr: ceil.w  17 fr: floor.w
40 fr: cvt.s    41 fr: cvt.d
44 fr: cvt.w
60 fr: cxx

: fc:  ( opcode -- )  \ floating point comparison instructions
   create ,
   does>  ( ft fs -- )  set-cop   ( ft fs )   0 sa  rd  rt
;   


: fc1:  ( opcode -- )
   create ,  does>  ( fs rt -- )  @ cop1  rs  rt rd
;
0 fc1: mfc1   2 fc1: cfc1   4 fc1: mtc1   6 fc1: ctc1

: mfc0   ( cpreg rt -- )  cop0  0 rs  rt rd  ;
: mtc0   ( cpreg rt -- )  cop0  4 rs  rt rd  ;
: dmfc0  ( cpreg rt -- )  cop0  1 rs  rt rd  ;
: dmtc0  ( cpreg rt -- )  cop0  5 rs  rt rd  ;
: tlbp   ( -- )  cop0  h# 0200.0008 addbits  ;
: tlbr   ( -- )  cop0  h# 0200.0001 addbits  ;
: tlbwi  ( -- )  cop0  h# 0200.0002 addbits  ;
: tlbwr  ( -- )  cop0  h# 0200.0006 addbits  ;
: eret   ( -- )  cop0  h# 0200.0018 addbits  block-here  ;

: fmt:  ( format-code -- )
   \ Replace FMT field with correct format
   create ,  does>  opaddr asm@  h# 03e0.0000 invert land  opaddr asm!  @ rs
;
d# 16 fmt: .s   d# 17 fmt: .d   d# 20 fmt: .w

hex

\ Standard assembler macros
: nop  $0 0 $0 sll  ;

: inhibit-delay   nop  ;

: la  ( n dst -- )  swap set-relocation-bit swap li  ;
\ : ulh
\ : ulhu
\ : ulw
\ : ush
\ : usw
\ : abs
\ : neg
\ : negu
\ : not
\ : div
\ : divu
\ : mul
\ : mulo
\ : mulou
\ : rem
\ : remu
\ : rol
\ : seq
\ : sle
\ : sleu
\ : sgt
\ : sgtu
\ : sge
\ : sgeu
\ : sne
\ : bgt   ( adr imm src -- )
\ : bge   ( adr imm src -- )
\ : bgeu  ( adr imm src -- )
\ : bgtu  ( adr imm src -- )
\ : blt   ( adr imm src -- )
\ : ble   ( adr imm src -- )
\ : bleu  ( adr imm src -- )
\ : bltu  ( adr imm src -- )
\ : bal   ( adr -- )
\ : move  ( src dst -- )

\ XXX edited to here

: asm-align  ( boundary -- )
   1-  begin  dup here land  while  nop  repeat
;

\ Control transfer instructions

hex
: -cond  ( condition -- not-condition )
   dup h# 1000.0000 land  if  h# 0400.0000  else  h# 0001.0000  then
   [ forth ] xor [ mips-assembler ]
;

: brif  ( adr cond -- )  setbits br-offset  ;
   
\ 6 branch: brfif ( address reg condition -- )
\ 7 branch: brcif ( address reg condition -- )
: bra  ( adr -- )  $0 bgez  ;
: branch!  ( target-adr branch-adr -- )
   tuck >br-offset  h# 1000.0000 + swap asm!
;
: put-branch  ( target-adr branch-adr -- )  branch!  ;


\ Structured conditionals

: <mark  ( -- <mark )  here  ;
: >mark  ( -- >mark )  here  ;
: >resolve  ( >mark -- )
   here over >br-offset over asm@ +  swap asm!
   block-here
;
\ >+resolve is used when the resolution follows a branch, so the delay slot
\ must be skipped  (block-delay is not needed, because the back branch did it)
: >+resolve  ( >mark -- )
   here la1+ over >br-offset over asm@ +  swap asm!
;
: <resolve  ( -- )  ;

: but     ( mark1 mark2 -- mark2 mark1 )  swap  ;
: yet     ( mark -- mark mark )  dup  ;

: ahead   ( -- >mark )          >mark  here 4 +  bra  ;
: if      ( cond -- >mark )     >mark  here 4 +  rot -cond  brif  ;
: then    ( >mark -- )          >resolve  ;
: else    ( >mark -- >mark1 )   ahead  but  >+resolve  ;
: begin   ( -- <mark )          <mark  ;
: until   ( <mark cond -- )     -cond brif  ;
: again   ( <mark -- )          bra  ;
: repeat  ( <mark >mark -- )    again  >+resolve  ;
: while   ( <mark cond -- <mark >mark )  if  but  ;

\ Define these last to delay overloading of the forth versions

hex

: +rs  ( rs template -- template' )  swap d# 21 >regfld lor  ;
: +rt  ( rs template -- template' )  swap d# 16 >regfld lor  ;

: =  ( rs rt -- cond )  1000.0000  +rt +rs  ;
: <> ( rs rt -- cond )  1400.0000  +rt +rs  ;

: 0<=  ( rs -- cond )  1800.0000 +rs  ;
: 0>   ( rs -- cond )  1c00.0000 +rs  ;
: 0<   ( rs -- cond )  0400.0000 +rs  ;
: 0>=  ( rs -- cond )  0401.0000 +rs  ;


\ \ Floating-point operations; these aren't needed for the kernel
\ 
\ : set-opf  ( opcode-adr -- )  34 2 set-op   @  5 l<<  addbits  ;
\ : ffop  \ name  ( opcode -- )
\   create ,
\   does>  ( frs frd opc-adr -- )  set-opf  ?freg rd  ?freg rs2
\ ;
\ 0c9 ffop fstod   0cd ffop fstox
\ 0c6 ffop fdtos   0ce ffop fdtox
\ 0c7 ffop fxtos   0cb ffop fxtod
\ 
\ 001 ffop fmovs   005 ffop fnegs   009 ffop fabss
\ 029 ffop fsqrts  02a ffop fsqrtd  02b ffop fsqrtx
\ 
\ 0c4 ffop fitos   0c8 ffop fitod   0cc ffop fitox
\ 
\ 0c1 ffop fstoir  0c2 ffop fdtoir  0c3 ffop fxtoir
\ 0d1 ffop fstoi   0d2 ffop fdtoi   0d3 ffop fxtoi
\ 
\ : f2op  \ name  ( opcode -- )
\   create ,
\   does>  ( frs1 frs2 frd opc-adr -- )
\   set-opf  ?freg rd  ?freg rs2  ?freg rs
\ ;
\ 041 f2op fadds   042 f2op faddd   043 f2op faddx
\ 045 f2op fsubs   046 f2op fsubd   047 f2op fsubx
\ 049 f2op fmuls   04a f2op fmuld   04b f2op fmulx
\ 04d f2op fdivs   04e f2op fdivd   04f f2op fdivx
\ 
\ : fcmpop  \ name  ( opcode -- )
\    create ,
\    does>  ( frs1 frs2 opc-adr -- )
\    set-opf  1 td 19 <<  addbits   ?freg rs2  ?freg rs
\ ;
\ 051 fcmpop fcmps   052 fcmpop fcmpd   053 fcmpop fcmpx
\ 055 fcmpop fcmpes  056 fcmpop fcmped  057 fcmpop fcmpex

previous definitions

headers

: fix-immed16  ( n adr -- )
   tuck l@ h# ffff.0000 and or swap l!
;

: fix-set32  ( n adr -- )
   >r lwsplit
   r@ fix-immed16
   r> /l + fix-immed16
;

\ LICENSE_BEGIN
\ Copyright (c) 2009 FirmWorks
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
