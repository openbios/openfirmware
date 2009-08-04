\ See license at end of file
purpose: x86 assembler

only forth also definitions
decimal
caps on

\ ?condition is no longer used. remove it?
\ : ?condition true <> abort" conditionals not paired "  ;

vocabulary 386-assembler
: assembler  386-assembler  ;
assembler also definitions

\ The 8086 Assembler was written by Mike Perry, and modified for
\ 32-bit 386/486 use by Mitch Bradley, and modified for
\ memory modes by Mike Perry.
\ To create an assembler language definition, use the defining word "CODE".
\ It must be terminated with either "END-CODE" or its synonym "C;".
\ How the assembler operates is a very interesting example of the power
\ of "CREATE DOES>".
\ Basically the instructions are categorized and a defining word is
\ created for each category.  When the mnemonic for the instruction
\ is interpreted, it compiles the instruction.
\ The assembler is postfix. Operands and addressing modes leave values 
\ on the stack for the opcode mnemonics to resolve.

\ NEW: real/protected switching.
\ memory modes
0 constant real-mode#
1 constant protected-mode#
protected-mode# value memory-mode

: real-mode	  ( - bool )         real-mode# is memory-mode  ;
: protected-mode  ( - bool )    protected-mode# is memory-mode  ;
alias 16-bit real-mode
alias 32-bit protected-mode

: real?		( - bool )   memory-mode      real-mode# =  ;
: protected?	( - bool )   memory-mode protected-mode# =  ;

: real-only		( -- )    protected? abort" Real Mode Only "  ;
: protected-only	( -- )    real? abort" Protected Mode Only "  ;

\ Deferring the definitions of the commas, marks, and resolves
\   allows the same assembler to serve for both the System- and the
\   Meta-Compiler.

\ in fact, doing so makes possible cross-compiling, transient definitions,
\ compiling to a buffer, compiling to a virtual buffer, 

\ also, no reason not to load several assemblers at once.


defer asm-set-relocation-bit

defer asm8@		forth ' c@    assembler   is asm8@
defer asm8!		forth ' c!    assembler   is asm8!
defer here		forth ' here  assembler   is here
defer asm-allot		forth ' allot assembler   is asm-allot

\ append values to the end of a code definition which is being built.
\ always little-endian:
: asm8,   ( n -- )  here 1 asm-allot asm8!  ;
: asm16,  ( n -- )  wbsplit swap asm8, asm8,  ;
: asm32,  ( n -- )  lwsplit swap asm16, asm16,  ;
: asm16!  ( w adr -- )  >r wbsplit r@ 1+ asm8!  r> asm8!  ;
: asm32!  ( l adr -- )  >r lwsplit r@ 2+ asm16!  r> asm16!  ;

false value address-ov
false value data-ov
: op:   ( -- )   true is data-ov     h# 66 asm8,  ;
: ad:   ( -- )   true is address-ov  h# 67 asm8,  ;
: clear-ov   ( -- )   false is data-ov   false is address-ov  ;

: op16?  ( -- flag )  real? data-ov xor  ;

: (asm,)  ( flag -- )  real? xor if   asm16,   else   asm32,   then  ;
: adr,    ( n -- )  address-ov (asm,)  ;
: asm,    ( n -- )  data-ov    (asm,)  ;

: 16bit?  real? address-ov xor  ;

: 16-only	( -- )    16bit? 0=  abort" Real Mode Only "  ;
: 32-only	( -- )    16bit? abort" Protected Mode Only "  ;

\ Now the fun begins...
\ In this 80x86 assembler, register names are cleverly defined constants.

\ The value returned by registers and by modes such as #) contains
\ both mode and register information. The instructions use the
\ mode information to decide how many arguments exist, and what to
\ assemble.

\ Like many CPUs, the 8086 uses many 3 bit fields in its opcodes
\ This makes octal ( base 8 ) natural for describing the registers

octal

\ REG  creates a word which is a calculated constant.
\ REGS creates batches of words. It just puts REG in a DO LOOP.
: reg    ( group mode  -- )   11 *  swap 1000 * or   constant  ;
: regs   ( modes group -- )   swap 0 ?do   dup i reg   loop drop  ;

: pmreg  ( group mode -- )   reg   does> @  protected-only  ;
: pmregs ( mode group -- )   swap 0 do  dup i pmreg  loop  drop ;

: rmreg  ( group mode -- )   reg   does> @  real-only  ;
: rmregs ( mode group -- )   swap 0 do  dup i rmreg  loop  drop ;

: 32reg  ( group mode -- )   reg   does> @  32-only  ;
: 32regs ( mode group -- )   swap 0 do  dup i 32reg  loop  drop ;

: 16reg  ( group mode -- )   reg   does> @  16-only  ;
: 16regs ( mode group -- )   swap 0 do  dup i 16reg  loop  drop ;

10 0 REGS        AL      CL      DL      BL     AH    CH    DH    BH
10 1 REGS        AX      CX      DX      BX     SP    BP    SI    DI

10 2 16REGS  [bx+si] [bx+di] [bp+si] [bp+di]   [si]  [di]  [bp]  [bx]

10 1 pmREGS     EAX     ECX     EDX     EBX    ESP     EBP   ESI   EDI
10 2 32REGS    [EAX]   [ECX]   [EDX]   [EBX]  [ESP]   [EBP] [ESI] [EDI]
 3 2 pmREGS     [AX]    [CX]    [DX]

 2 4 32reg      [SP] 

 6 3   REGS      ES      CS      SS      DS     FS      GS
 3 4   REGS       #      #)     S#)

\ notice that some words are defining words which create other words,
\ or in other words, some words make other words...
\ sorry, my mind was miles away!

\ a few addressing modes depend on the memory mode.
: [bx]  16bit? if  [bx]  else  [ebx]  then  ;
: [si]  16bit? if  [si]  else  [esi]  then  ;
: [di]  16bit? if  [di]  else  [edi]  then  ;
: [bp]  16bit? if  [bp]  else  [ebp]  then  ;


\ Not all of the following exist in all implementations of
\ x86 chips, Caveat Emptor.
 5 0 reg cr0  5 1 reg cr1  5 2 reg cr2  5 3 reg cr3
 5 4 reg cr4  5 5 reg cr5  5 6 reg cr6  5 7 reg cr7

 6 0 reg dr0  6 1 reg dr1  6 2 reg dr2  6 3 reg dr3
 6 4 reg dr4  6 5 reg dr5  6 6 reg dr6  6 7 reg dr7

 7 0 reg tr0  7 1 reg tr1  7 2 reg tr2  7 3 reg tr3
 7 4 reg tr4  7 5 reg tr5  7 6 reg tr6  7 7 reg tr7

\ Note! the "disp [ESP]" addressing mode doesn't exist.  That encoding is used
\ instead for scaled-index addressing, available only in protected mode.

10 1 REGS     /0    /1    /2    /3    /4    /5    /6    /7

[ESP] value base-reg
[ESP] value index-reg
 000  value scale-factor

-1 constant [NOB]      \ "null" base register for scaled indexing

\ The 10000 bit is carefully chosen to lie outside the fields used
\ to identify the register type, so as not to confuse SPEC?

[ESP] 10000 or  constant [SIB]      \ special code generated by *N words

\ Scaled indexing address mode.  Examples:
\   1234 [ESI]  [EBP] *4
\      0 [ESP]  [EBP] *1
\   5678 [NOB]  [ESI] *2

\ another defining word, scale:
: scale:  \ name  ( scale-factor -- )
   create c,
   does>  	( disp base-reg index-reg apf -- disp mr )
      c@ is scale-factor  is index-reg  is base-reg  [SIB]
;

000 scale: *1  100 scale: *2  200 scale: *4  300 scale: *8

\ The "no index" encoding isn't useful for any register
\ other than [ESP] because the other registers can be used
\ with the mod-r/m forms.
\      0 [ESP]  [NOX]
\     55 [ESP]  [NOX]
\   2345 [ESP]  [NOX]
\ XXX I don't think this is necessary anymore because of improvmements
\ in the handling of scaled indexing mode.
\ : [NOX]  ( disp base-reg -- disp mr )  [ESP] *1  ;

\ MD  defines words which test for various addressing modes.
: MD   CREATE  1000 * ,  DOES>  @ SWAP 7000 AND =  ;

\ R8? R16? MEM? SEG? #?  test for mode equal to 0 thru 4.
0 MD R8?   1 MD R16?   2 MD MEM?   3 MD SEG?   4 MD #?
\ 5 for   i MD   next    R8? R16? MEM? SEG? #?
\ or: " R8? R16? MEM? SEG? #?" " 5 for   i MD   next" eval-from

: spec?  ( n -- f )  [ also forth ] 7000 and 5000 >=  [ previous ]  ;

\ REG?  tests for any register mode
: REG?   (S n -- f )   7000 AND 2000 <  ;

\ BIG?  tests offsets size. True if won't fit in one byte.
: small?   ( n -- flag )   -200 177 between  ;
: big?     ( n -- flag )   small? 0=  ;

\ RLOW  mask off all but low register field.
: RLOW   (S n1 -- n2 )    7 AND ;

\ RMID  mask off all but middle register field.
: RMID   (S n1 -- n2 )   70 AND ;

\ SIZE  true for 16 or 32 bit, false for 8 bit.
VARIABLE SIZE   SIZE ON

: normal   ( -- )   size on   clear-ov  ;

\ BYTE  set size to 8 bit.
: BYTE   (S -- )   SIZE OFF ;

\ OP,  for efficiency. OR two numbers and assemble.
: OP,    (S N OP -- )   OR ASM8,  ;

\ WF,  assemble opcode with W field set for size of register.
: WF,   (S OP MR -- )   R16? 1 AND OP,  ;

\ SIZE,  assemble opcode with W field set for size of data.
: SIZE,  (S OP -- OP' )   SIZE @ 1 AND OP,  ;

\ ,/C,  assemble either 8 or 16 bits.
: ,/C,   (S n f -- )   IF  ASM,  ELSE  ASM8,  THEN  ;

: MOD-RM,  ( mr rmid mod -- )  -ROT RMID SWAP RLOW OR OP,  ;
: SIB,     ( base index scale -- )  MOD-RM,  ;

\ RR,  assemble register to register instruction.
: RR,    (S MR1 MR2 -- )   300 mod-rm,  ;

\ These words perform most of the addressing mode encoding.
\ : SIB?   ( -- flag )   [SIB] =  ;

\ Assemble mod-r/m byte and s-i-b byte if necessary
: SOP,  ( mr rmid mod -- )
   16bit? 0=  if
      2 pick  [SIB] =  if			( [SIB] rmid mod )
	 [ESP] -rot  mod-rm,			( [SIB] ) \ Scaled index mode
	 drop					( )
	 base-reg index-reg scale-factor SIB,   
	 exit
      then					( mr rmid mod )
      2 pick  [ESP] =  if			( mr rmid mod )
	 mod-rm,				( )	\ disp[ESP] uses SIB
	 [ESP] [ESP] 0 SIB,			( )
	 exit
      then					( mr rmid mod )
   then						( mr rmid mod )
   mod-rm,					( )	\ Not scaled index mode
;

\ MEM,  handles memory reference modes.  It takes a displacement,
\   a mode/register, and a register, and encodes and assembles them.
: MEM,   (S DISP MR RMID -- )
   \ The absolute address mode is encoded in place of the
   \ (nonexistent) "<no-displacement> [EBP]" mode.

   OVER #) =  IF
      16bit?  if  6  else  5  then
      swap 0 mod-rm, DROP  ADR,  EXIT
   THEN  ( disp mr rmid )

   16bit? 0=  if
      \ Special case for "0 [EBP]" ; use short 0 displacement
      \ instead of [EBP] (there is no [EBP] addressing mode
      \ because that encoding is used for 32-bit displacement.)

      2 PICK 0=  2 PICK [EBP] =  AND  IF           ( disp mr rmid )
	 100 MOD-RM,  ASM8,  EXIT
      THEN                                         ( disp mr rmid )

      \ Special case for "disp32 [no-base-reg] [index-reg] *scale"
      OVER [SIB] =  IF                             ( disp mr rmid )
\	 protected-only
	 base-reg [NOB] =  IF                      ( disp mr rmid )
	    0 MOD-RM,                              ( disp mr rmid )
	    5 index-reg 0 SIB,                     ( disp )
	    R> ADR,                                ( )
	    EXIT
	 THEN                                      ( disp rmid mr )
      THEN                                         ( disp rmid mr )
   then
   
   2 PICK BIG?  IF  200 SOP, ADR,    EXIT  THEN ( disp mr rmid ) \ disp[reg] 
   2 PICK 0<>   IF  100 SOP, ASM8,   EXIT  THEN ( disp mr rmid ) \ disp8[reg]
                      0 SOP, DROP               ( )              \ [reg]
;

\ WMEM,  uses MEM, after packing the register size into the opcode
: WMEM,   (S DISP MEM REG OP -- )   OVER WF, MEM,  ;

\ R/M,  assembles either a register to register or a register to
\  or from memory mode.
: R/M,   (S MR REG -- )
   OVER REG? IF  RR,  ELSE  MEM,  THEN  ;

\ WR/SM,  assembles either a register mode with size field, or a
\   memory mode with size from SIZE. Default is 16 (or 32) bit. Use BYTE
\   for 8 bit size.
: WR/SM,   (S R/M R OP -- )   2 PICK DUP REG?
   IF  WF, RR,  ELSE  DROP SIZE, MEM,  THEN  ;

\ INTER  true if inter-segment jump, call, or return.
VARIABLE INTER

\ FAR  sets INTER true.  Usage:  FAR JMP,   FAR CALL,   FAR RET.
: FAR    (S -- )   INTER ON  ;

\ ?FAR  sets far bit, clears flag.
: ?FAR   (S n1 -- n2 )   INTER @ IF  10 OR  THEN  INTER OFF ;

\
\ Create defining words for various classes of Machine Instructions
\

\ 0MI  define one byte constant segment overrides
: 0MI   CREATE  C,  DOES>  C@ ASM8,  ;

\ 1MI  define one byte constant instructions.
: 1MI   CREATE  C,  DOES>  C@ ASM8,  normal  ;

\ 2MI  define ascii adjust instructions.
: 2MI   CREATE  C,  DOES>  C@ ASM8,  12 ASM8,  normal  ;

: prefix-0f  h# 0f asm8,  ;

variable long-offsets  long-offsets off

\ 3MI  define branch instructions, with one or two bytes of offset.
: 3MI	\ conditional branches
   ( op -- )	create  c,  
   ( dest -- )	does>   c@		( dest op )
      swap here 2+ - 			( op disp )
      dup small?  long-offsets @  0= and  if	( op disp8 )
	 swap asm8, asm8,
      else				( op disp )
	 prefix-0f  swap h# 10 + asm8,
	 op16? if  2  else  4  then  -	 adr,
      then
      normal
;

\ 4MI  define LDS, LEA, LES instructions.
: 4MI   CREATE  C,
   DOES>  C@  dup h# b2 h# b5 between  if prefix-0f then  ASM8,  MEM,
      normal  
;

\ 5MI  define string instructions.
: 5MI   CREATE  C,  DOES>  C@ SIZE,  normal  ;

\ 6MI  define other string instructions.
: 6MI   CREATE  C,  DOES>  C@ SWAP WF,  normal  ;

\ 7MI  define multiply and divide instructions.
: 7MI   CREATE  C,  DOES>  C@ 366 WR/SM, normal  ;

: OUT  ( al | ax	dx | imm # -- )
   H# E6  SWAP  # =  IF  ( al|ax imm op )
      ROT WF, ASM8,      ( )
   ELSE                  ( al|ax op )
      10 OR  SWAP WF,    ( )
   THEN
   normal  
;  
: IN  ( dx | imm,#	al | ax -- )
   H# E4  ROT  # =  IF   ( imm al|ax op )
      SWAP WF, ASM8,     ( )
   ELSE                  ( al|ax op )
      10 OR  SWAP WF,    ( )
   THEN
   normal  
;

\ 9MI  define increment/decrement instructions.
: 9MI   CREATE  C,  DOES>  C@  OVER R16?
      IF  100 OR SWAP RLOW OP,  ELSE  376 WR/SM,  THEN  normal  
;

\ 10MI  define shift/rotate instructions.
\ : 10MI  CREATE  C,  DOES>  C@ OVER CL =
\    IF  NIP 322  ELSE  320  THEN  WR/SM,  ;

\ *NOTE*  To allow both 'ax shl' and 'ax cl shl', if the register
\ on top of the stack is cl, shift second register by cl. If not,
\ shift top ( only) register by one.
\ ??? if we do this sort of thing, we should keep track of stack depth.
\ it is not hard; either sp@ or depth suffices.

\ For 'ax 5 # shl' and '5 # ax shl'
\ the immediate byte must be compiled after everything else.

: 10mi     ( op -- )   create  c,
   does>  c@		( r/m cl op | r/m n # op | n # r/m op | r/m op )
      over #  = if			( r/m n # op )
	 nip swap dup big? tuck 2>r	( r/m op big? )
	 1 and 300 or wr/sm,    2r>	( n big? )
	 if    asm,   else   asm8,  then
	 exit
      then		( r/m cl op | n # r/m op | r/m op )
      2 pick # = if			( n # r/m op )
	 rot drop rot dup big? tuck 2>r	( r/m op big? )
	 1 and 300 or wr/sm,    2r>	( n big? )
	 if    asm,   else   asm8,  then
	 exit 
      then		( r/m cl op | r/m op )
      over cl = if	( r/m cl op )
	 nip 322	( r/m op op' )
      else		( r/m op )	\ shift by 1 implicitly
	 320		( r/m op op' )
      then		( r/m op op' )
      wr/sm,  
      normal  
;

\ 11MI  define calls and jumps.
\  notice that the first byte stored is E9 for jmp and E8 for call
\  so  C@ 1 AND  is 0 for call,  1 for jmp.
\  syntax for direct intersegment:   address segment #) FAR JMP

\ ???
: 11MI
   CREATE  C, C,   DOES>                        ( [ dst ] mode apf )
   OVER #) =  IF                                ( dst mode apf )
      NIP C@ INTER @  IF                        ( offset segment code )
         1 AND  IF  352  ELSE  232  THEN  ASM8, ( offset segment )
         SWAP asm, ASM16,  INTER OFF            ( )
      ELSE					( dst code )
         SWAP HERE 2+ -  SWAP                   ( rel-dst code )
         2DUP 1 AND SWAP BIG? 0= AND  IF        ( rel-dst code )
            2 OP,  ASM8,                        ( )
         ELSE                                   ( rel-dst code )
	    ASM8,  op16? if
	       1- asm16,
	    else
	       3 - asm32,
	    then				
         THEN					( )
      THEN					( )
   ELSE                                         ( mode apf )
      OVER S#) = IF  NIP #) SWAP  THEN          ( mode' apf )
      377 ASM8, 1+ C@ ?FAR  R/M,
   THEN
   normal  
;

\ 12MI  define pushes and pops.
: 12MI  ( dst mr -- )
   CREATE  C, C, C, C, C, DOES>       ( dst apf )
   OVER REG?  IF                      ( dst apf )   \ General register
      C@ SWAP RLOW OP,                ( )
   ELSE                               ( dst apf )
      1+ OVER SEG?  IF                ( dst apf' )  \ Segment register
         OVER FS >=  IF		      ( dst apf' )  \ FS or GS
	    prefix-0f  3 + C@         ( dst opcode )
            SWAP GS = IF  10 OR  THEN ( opcode' )
	    ASM8,                     ( )
         ELSE			      ( dst apf' )  \ CS, DS, ES, or SS
            C@ RLOW SWAP RMID OP,     ( )
         THEN
      ELSE                            ( dst apf' )
         OVER # =  IF                 ( dst apf' )  \ Immediate
	    2+ C@                     ( val # opcode )
	    SIZE @  0= IF  2 OR  THEN ( val # opcode' )
	    ASM8,  DROP ASM,          ( )
         ELSE                         ( dst apf' )  \ Memory
            DUP 1+ C@ ASM8,  C@ MEM,  ( )
         THEN
     THEN
   THEN
   normal  
;

\ 14MI  defines returns.    RET    FAR RET    n +RET   n FAR +RET
: 14MI  ( op -- )
   CREATE  C,  DOES>
   \ This is definitely supposed to be asm16, not asm32
   C@ DUP ?FAR ASM8,  1 AND 0=  IF  ASM16,  THEN
   normal  
;

\ 13MI  define arithmetic and logical instructions.
: 13MI  ( src dst -- )
   CREATE  C,  DOES>                         ( src dst apf )
   C@ >R                                     ( src dst )  ( r: op )
   DUP REG?  IF                              ( src dst ) \ Dst is register
      OVER REG?  IF                          ( src dst )
         R> OVER WF, SWAP RR,                ( )         \ Register -> register
      ELSE                                   ( src dst )
         OVER DUP MEM? SWAP #) = OR  IF      ( src dst )
            R> 2 OR WMEM,                    ( src dst ) \ Memory -> register
         ELSE                                ( src dst )
            NIP  DUP RLOW 0=   IF            ( immed dst )
               R> 4 OR OVER WF, R16? ,/C,    ( )         \ imm -> accumulator
            ELSE                             ( immed dst )  \ imm -> register
               OVER BIG? OVER R16? 2DUP AND  ( immed dst big? r16? wbit )
              -ROT 1 AND SWAP INVERT OVER 0<>
			        AND 2 AND OR ( immed dst flag 0|1|3 )
               200 OP,                       ( immed dst flag  )
               SWAP RLOW 300 OR R> OP,  ,/C, ( )
            THEN
         THEN
      THEN
   ELSE                                      ( src disp dst )  \ Dst is memory
      ROT DUP REG?  IF                       ( src disp dst )  \ reg -> mem
         R> WMEM,                            ( )
      ELSE                                   ( disp src disp dst ) \ imm -> mem
         DROP                                ( disp src disp )
         2 PICK BIG? DUP INVERT 2 AND 200 OR
         SIZE, -ROT R> MEM,
         SIZE @ AND ,/C,
      THEN
   THEN
   normal  
;

\ Used for LGDT, SGDT, LIDT, SIDT, LLDT, SLDT,
: 15mi  \ name ( reg-field second-byte -- )
   create  c,  3 << c,
   does>  h# f asm8,  dup c@ dup >r asm8,       ( adr ) ( r: mode )
   1+ c@  r> [ also forth ] if  mem,  else  r/m,  then  [ previous ]
   normal  
;
0 1 15mi sgdt   1 1 15mi sidt   0 0 15mi sldt  1 0 15mi str
2 1 15mi lgdt   3 1 15mi lidt   2 0 15mi lldt  3 0 15mi ltr

\ LSS, LFS, LGS 
: 16MI  CREATE  C,  DOES>  C@  prefix-0f  ASM8,  MEM,  normal  ;

\ SHLD, SHRD
: 17MI  \ name ( [ cl | imm ] reg r/m -- )
   CREATE  C,  DOES>  C@  prefix-0f  here >r  ASM8,  ( [ cl | imm ] reg r/m r: opadr )
   dup reg?  if  swap  else  rot  then               ( [ cl | imm ] r/m reg r: opadr )
   r/m,                                              ( [ cl | imm ] r: opadr )
   # =  if  ASM8, r> drop  else  r@ c@ 1+ r> c!  then
;

\ TEST  bits in dest
: TEST   (S source dest -- )
   DUP REG?  IF
      OVER REG?  IF  204 OVER WF, SWAP RR,  EXIT THEN

      OVER DUP MEM? SWAP #) = OR  IF   204 WMEM,  EXIT THEN

      NIP  DUP RLOW 0=  IF   250 OVER WF,  R16? ,/C,  EXIT THEN  \ imm -> acc

      366 OVER WF,  DUP RLOW 300 OP,  R16? ,/C,

   ELSE                                               \ *   -> mem
      ROT DUP REG?  IF  204 WMEM,  EXIT THEN          \ reg -> mem

      DROP  366 SIZE,  0 MEM,  SIZE @ ,/C,   \ imm -> mem
   THEN
   normal  
;

HEX
: ESC   (S source ext-opcode -- )   RLOW 0D8 OP, R/M,  ;

: SETIF  ( dest condition -- )  0F ASM8,  024 XOR ASM8,  R/M,  ;

\ INT  assemble interrupt instruction.
: INT   (S N -- )   0CD ASM8,  ASM8,  ;

\ XCHG  assemble register swap instruction.
: XCHG   (S MR1 MR2 -- )
   DUP REG?  IF
      DUP EAX =  IF
         DROP RLOW 90 OP,
      ELSE
         OVER EAX =  IF
            NIP  RLOW 90 OP,
         ELSE
            86 WR/SM,
         THEN
      THEN
   ELSE
      ROT 86 WR/SM,
   THEN
   normal  
;

\ Encoding of special register moves:
\ 0F c,
\ 0x22 for normal->special direction, 0x20 for special->normal direction
\ or with  0 for CRx, 1 for DRx, 4 for TRx
: special-mov  ( s d -- )
   prefix-0f
   [ also forth ]
   dup spec?  if  h# 22  else  swap h# 20  then   ( norm-reg spec-reg opcode )
   over o# 7000 and case
      o# 5000 of  0  endof
      o# 6000 of  1  endof
      o# 7000 of  4  endof
   endcase                 ( norm-reg spec-reg opcode modifier )
   [ previous ]
   op,                     ( norm-reg spec-reg )
   rr,
;

\ MOV  as usual, the move instruction is the most complicated.
\  It allows more addressing modes than any other, each of which
\  assembles something more or less unique.

: (MOV)   (S S D -- )
   \ Stack diagram at the decision level is ( src dst )
   DUP SEG?  IF  8E ASM8, R/M,  EXIT   THEN         ( s d )

   dup spec?  if  special-mov  exit  then
   DUP REG?  IF                                     ( s d )  \ *   -> reg
      over spec?  if  special-mov  exit  then
      OVER #) = OVER RLOW 0= AND  IF                ( s d )  \ abs -> acc
         A0 SWAP WF,   DROP ADR,  EXIT              ( s d )
      THEN

      OVER SEG?  IF  SWAP 8C ASM8, RR,  EXIT  THEN  ( s d )  \ seg -> reg

      OVER # =  IF                                  ( s d )  \ imm -> reg
         NIP DUP R16? SWAP RLOW
         OVER 8 AND OR B0 OP, ,/C,
         EXIT
      THEN

      8A OVER WF, R/M,                              ( )      \ r/m -> reg

   ELSE                                             ( s d d ) \ *   -> mem
      ROT DUP SEG?  IF  8C ASM8, MEM,  EXIT THEN    ( s d d ) \ seg -> mem

      DUP # =  IF                                   ( s d d ) \ imm -> mem
         DROP C6 SIZE, 0 MEM,  SIZE @ ,/C,  EXIT
      THEN

      OVER #) = OVER RLOW 0= AND   IF               ( s d d ) \ abs -> acc
         A2 SWAP WF,  DROP   ADR,  EXIT
      THEN

      88 OVER WF, R/M,                              ( )       \ reg -> mem
   THEN
;
: MOV  (MOV)  normal  ;

\ Use "byte movsx" for the r8 form, "movsx" for the r16 form
: movsx  ( r/m r -- )  prefix-0f  h# be size,  r/m,  ;
: movzx  ( r/m r -- )  prefix-0f  h# b6 size,  r/m,  ;

\ Most instructions are defined here. Those mnemonics in
\ parenthetic comments are defined earlier or not at all.

HEX
\ CS: DS: ES: SS: assemble segment over-ride instructions.
2E 0MI CS:
36 0MI SS:
3E 0MI DS:
26 0MI ES:
64 0MI FS:
65 0MI GS:

 37  1MI AAA     D5  2MI AAD     D4  2MI AAM     3F  1MI AAS
 10 13MI ADC     00 13MI ADD     20 13MI AND  10 E8 11MI CALL
 98  1MI CWDE    F8  1MI CLC     FC  1MI CLD     FA  1MI CLI
 F5  1MI CMC     38 13MI CMP     A6  5MI CMPS    99  1MI CWD
 27  1MI DAA     2F  1MI DAS     08  9MI DEC     30  7MI DIV
       ( ESC )   F4  1MI HLT     38  7MI IDIV    28  7MI IMUL
       ( IN )    00  9MI INC     6C  5MI INS     ( INT )
0CE  1MI INTO   0CF  1MI IRET    E3  3MI JCXZ    
 
 77  3MI JA      73  3MI JAE     72  3MI JB      76  3MI JBE
 74  3MI JE      7F  3MI JG
 7D  3MI JGE     7C  3MI JL      7E  3MI JLE  20 E9 11MI JMP
 75  3MI JNE     71  3MI JNO     79  3MI JNS     70  3MI JO
 7A  3MI JPE     7B  3MI JPO     78  3MI JS     
 
 9F  1MI LAHF
 C5  4MI LDS     8D  4MI LEA     C4  4MI LES     B4 16MI LFS
 B5 16MI LGS     F0  1MI LOCK   0AC  6MI LODS    E2  3MI LOOPA
 E1  3MI LOOPE   E0  3MI LOOPNE  B2 16MI LSS 

       ( MOV )   0A4  5MI MOVS    20  7MI MUL     18  7MI NEG
 90  1MI NOP      10  7MI NOT     08 13MI OR      ( OUT )
 6E  5MI OUTS

    A1  58  8F 07 58 12MI POP     60  1MI PUSHA   9D  1MI POPF
    A0  68 0FF 36 50 12MI PUSH    61  1MI POPA    9C  1MI PUSHF
 10 10MI RCL      18 10MI RCR
 F2  1MI REP      F2  1MI REPNZ   F3  1MI REPZ
 C3 14MI RET      00 10MI ROL      8 10MI ROR     9E  1MI SAHF
 38 10MI SAR      18 13MI SBB    0AE  5MI SCAS          ( SEG )
 20 10MI SHL      28 10MI SHR     F9  1MI STC     FD  1MI STD
 FB  1MI STI     0AA  6MI STOS    28 13MI SUB           ( TEST )
 9B  1MI WAIT           ( XCHG )  D7  1MI XLAT    30 13MI XOR
 C2 14MI +RET

0AC 17MI SHRD    0A4 17MI SHLD

: invd    ( -- )  prefix-0f  h# 08 asm8,  ;
: wbinvd  ( -- )  prefix-0f  h# 09 asm8,  ;
: wrmsr   ( -- )  prefix-0f  h# 30 asm8,  ;
: rdtsc   ( -- )  prefix-0f  h# 31 asm8,  ;
: rdmsr   ( -- )  prefix-0f  h# 32 asm8,  ;
: cpuid   ( -- )  prefix-0f  h# a2 asm8,  ;  \ Arg in %eax, results in ax,bx,dx,cx

\ Structured Conditionals
\ single pass forces fixed size. optimize for small, fast structures:
\ always use 8-bit offsets.

\ Assembler version of forward/backward mark/resolve.

: >MARK     (S -- addr )  HERE  ;  \ Address of opcode, not offset byte
: >RESOLVE  (S addr -- )  
   long-offsets @  if
      dup asm8@ h# 0f =  if  2+  else  1+  then  ( offset-adr )
      here over   ( offset-adr target-adr offset-adr )
      real?  if       ( offset-adr target-adr offset-adr )
         2 + -  swap asm16!  \ 2-byte offset
      else
         4 + -  swap asm32!  \ 4-byte offset
      then
   else
      1+ here over 1+ - dup big? abort" branch offset is too large "
      swap asm8! 
   then
;
: <MARK     (S -- addr )  HERE   ;
: <RESOLVE  (S addr op -- )  
   swap here 2+ -  dup small? if	( op offset )
      swap asm8,  asm8,  
   else
      swap dup h# 0eb = if		( offset op )
	 drop here 2+ +                 ( addr )
         #) jmp
      else
	 prefix-0f  h# 10 + asm8,	( offset )
	 real? if 2 else 4 then - adr,
      then
   then
;

: BUT  ( mark1 mark1 -- mark2 mark1 )  SWAP  ;

HEX

\ One of the very best features of FORTH assemblers is the ability
\ to use structured conditionals instead of branching to nonsense
\ labels.
: IF
   >MARK swap
   long-offsets @  if
      dup h# eb =  if
         drop h# e9 asm8,
      else
         prefix-0f  h# 10 + asm8,
      then
      real?  if  0 asm16,  else  0 asm32,  then
   else
      ASM8,  0 asm8,
   then
;
: THEN    >RESOLVE   ;
: BEGIN   <MARK   ;
: UNTIL   <RESOLVE   ;
: AHEAD   0EB IF          ;
: ELSE    AHEAD  BUT   THEN   ;
: AGAIN   0EB UNTIL   ;
: WHILE   IF   BUT  ;
: REPEAT  AGAIN   THEN   ;

\ These conditional test words leave the opcodes of conditional
\ branches to be used by the structured conditional words.
\   For example,
\    5 # ECX CMP   0< IF   EAX EBX ADD   ELSE   EAX EBX SUB   THEN
\    begin   dx al in   tbe # al and   0<> until

\ It is tempting to use "CS" for "Carry Set", but that conflicts
\ with the CS register.

75 CONSTANT 0=   74 CONSTANT 0<>   79 CONSTANT 0<
75 CONSTANT  =   74 CONSTANT  <>   73 CONSTANT CARRY?   72 CONSTANT NO-CARRY?
78 CONSTANT 0>=  7D CONSTANT <     7C CONSTANT >=
7F CONSTANT <=   7E CONSTANT >     73 CONSTANT U<
72 CONSTANT U>=  77 CONSTANT U<=   76 CONSTANT U>
71 CONSTANT OV	 E3 CONSTANT CXNZ

\ why lose DO ???
\ XXX : DO      # ECX MOV   HERE   ;
DECIMAL

\ aliases
: movb    byte mov  ;
: movsb   byte movs ;
: lodsb   byte lods ;
: stosb   byte stos ;
: insb    byte ins  ;
: outsb   byte outs ;

only forth also definitions
assembler also
alias real? real?
alias real-mode real-mode
alias protected-mode protected-mode
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
