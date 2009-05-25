purpose: MIPS kernel code words
\ See license at end of file

\ TODO - put I in a register

meta
hex

\ Allocate and clear the initial user area image
\ mlabel init-user-area

setup-user-area

only forth also labels also meta assembler also definitions

\ Forth Virtual Machine registers

\ Global Registers

\ Note that the Forth Stack Pointer (r1) is NOT the same register that
\ C uses for the stack pointer (r14).  The hardware does all sorts of
\ funny things with the C stack pointer when you do save and restore
\ instructions, and when the register windows overflow.

: np s1 ;  : base s2 ;  : up s3 ;  : tos s4 ;  : ip s5 ;  : rp s6 ;  : sp $sp ;

: w t0 ;

\ Macros:

\ Parameter Field Address
: apf  ( -- )  w 4  ;

: bubble  ( -- )  nop  ;
: bubble ;

: get   ( ptr dst -- )  0      swap  lw   ;
: put   ( src ptr -- )  0            sw   ;
: move  ( src dst -- )  0      swap  addu  ;
: ainc  ( ptr -- )      dup 4  swap  addiu  ;
: adec  ( ptr -- )      dup -4 swap  addiu  ;
: push  ( src ptr -- )  dup          adec  put  ;
: pop   ( ptr dst -- )  over   -rot  get   ainc  ;

: cmp   ( src dst -- )  $at     subu  ;
: cmpi  ( src imm -- )  negate  $at  addiu  ;
\ NOTE  brif  ( target-adr condition -- )  $at make-branch  ;

\ Take a high-level branch
: take-branch  (s -- )
   ip 0   t0  lw
   bubble
   ip t0  ip  addu
;
: skip-branch  ( -- )
   ip /branch  ip    addiu
;

only forth also labels also meta also assembler definitions

:-h /n*  /n *   ;-h

\ We create the shared code for the "next" routine so that:
\ a) It will be in RAM for speed (ROM is often slow)
\ b) We can use the user pointer as its base address, for quick jumping

[ifdef] put-next-in-user-area
also forth
compilation-base  here-t			\ Save meta dictionary pointer
0 dp-t !  userarea-t is compilation-base	\ Point it to user area
previous
[then]

mlabel (next)   \ Shared code for next; will be copied into user area
   ip 0         w   lw		\ Read the token at the ip location
   bubble
   w  base      w   addu	\ Relocate
   w 0          t1  lw		\ Read the contents of the code field 
   bubble
   t1 base      t1  addu	\ Relocate
   t1               jr		\ Jump to the code
   ip /token-t  ip addiu	\ Advance ip to point to the next token
end-code

[ifdef] put-next-in-user-area
also forth
dp-t !  is compilation-base  previous		\ Restore meta dict. pointer

d# 32 equ #user-init	\ Leaves space for the shared "next"
[else]
0 equ #user-init
[then]


hex meta assembler definitions
\ assembler macro to assemble next
:-h next
   [ assembler ]-h
   \ If it is inappropriate to move the last instruction into the
   \ delay slot of next's "jr" instruction, insert a  nop  to be
   \ moved instead.

   here delay-barrier @  [ meta ]-h =  if  [ assembler ]-h
      nop
   [ meta ]-h  then  [ assembler ]-h

   \ Move the last instruction into the delay slot of the "jr  up"
   here -1 la+ asm@          ( last-instruction )  \ Save instruction
   /l negate asm-allot       ( last-instruction )  \ Erase it
[ifdef] put-next-in-user-area
   up  jr                    ( last-instruction )  \ Replace with "jr"
[else]
   np  jr
\   (next) h# 20 +  j
[then]
   here  /l asm-allot  asm!  ( )                   \ Put instruction after jr
;-h

:-h c;    next end-code ;-h

code-field: docolon  assembler
   ip   rp   push	\ Push the ip register on the return stack
   apf  ip   addiu	\ Set ip to apf of the colon definition
c;

code-field: dovariable
   tos	sp   push	\ Save the top-of-stack register on memory stack
   apf  tos  addiu	\ Put pfa in top-of-stack register
c;

code-field: dolabel
   tos	sp   push	\ Save the top-of-stack register on memory stack
   apf  tos  addiu	\ Put pfa in top-of-stack register
c;

code-field: douser
   tos    sp   push	\ Save the top-of-stack register on memory stack
   apf    t0   lw	\ Get the user number
   bubble
   t0 up  tos  addu	\ Add the base address of the user area into tos
c;

code-field: dovalue
   tos	  sp   push	\ Save the top-of-stack register on memory stack
   apf    t0   lw	\ Get the user area offset from the parameter field
   bubble
   up t0  t0   addu
   t0 0   tos  lw	\ Get the contents of the user area location into tos
c;

code-field: dodefer
   apf      t1  lw	\ Get the user area offset from the parameter field
   bubble
   up t1    t1  addu
   t1 0     w   lw	\ Get the acf stored in that user location
   bubble
   w base   w   addu	\ Relocate
   w 0      t1  lw      \ Get the contents of the code field
   bubble
   t1 base  t1  addu	\ Relocate
   t1           jr	\ Execute that word
   nop
end-code

code-field: doconstant
   tos	sp   push	\ Save the top-of-stack register on memory stack
   apf  tos  lw		\ Get the constant's value into tos register
c;

code-field: do2constant
   sp -8    sp    addiu		\ Make room on the stack
   tos      sp 4  sw		\ Save the old tos on the memory stack
   apf      t1    lw		\ Get the bottom constant's value
   apf 4 +  tos   lw		\ Get the top constant's value
   t1       sp    put		\ Put bottom constant on the memory stack
c;

code-field: dodoes
   \ The child word's code field contains a pointer to the doesclause
   \ The doesclause's code field contains       dodoes jal   sp adec

   tos          sp  push	\ Prepare to push the pfa
   apf 4 +      tos addiu	\ push the pfa (delay slot)
   
   apf          w   lw		\ Set w to acf of the definition

   w  base      w   addu	\ Relocate
   w  0         t1  lw		\ Read the code field contents
   bubble
   t1 base      t1  addu	\ Relocate
   t1               jr		\ Jump to that location
   nop
end-code

:-h code-cf       ( -- )  here /token + aligned  token,-t  align-t  ;-h
:-h label-cf      ( -- )  dolabel    token,-t  align-t  ;-h
:-h colon-cf      ( -- )  docolon    token,-t  ;-h
:-h constant-cf   ( -- )  doconstant token,-t  ;-h
:-h variable-cf   ( -- )  dovariable token,-t  ;-h
:-h user-cf       ( -- )  douser     token,-t  ;-h
:-h value-cf      ( -- )  dovalue    token,-t  ;-h
:-h defer-cf      ( -- )  dodefer    token,-t  ;-h
:-h startdoes     ( -- )  colon-cf             ;-h
:-h start;code    ( -- )  code-cf              ;-h
:-h create-cf     ( -- )  dodoes   token,-t  compile-t noop  ;-h
:-h vocabulary-cf ( -- )  dodoes   token,-t  compile-t <vocabulary>  ;-h

meta definitions

\ dovariable constant dovariable
\ dodoes     constant dodoes

code (lit)  (s -- n )
   tos  sp   push
   ip   tos  get
   ip        ainc
c;

\ Execute a Forth word given a code field address
code execute   (s acf -- )
   tos      w    move	\ Pop stack into t1
   sp       tos  get	\ "
   w  0     t1   lw	\ Read the contents of the code field
   bubble
   t1 base  t1   addu	\ Relocate
   t1            jr	\ Jump to the code
   sp            ainc	\ Finish popping stack in delay slot
end-code

\ High level branch. The branch offset is compiled in-line.
code branch (s -- )
mlabel bran1
   take-branch
c;

\ High level conditional branch.
code ?branch (s f -- )  \ Takes the branch if the flag is false
   tos        t0   move
   sp         tos  get
   bran1  t0  $0   beq
   sp              ainc	\ Delay slot
   skip-branch
c;

\ Run time word for loop
code (loop)  (s -- )
   rp     t0  get
   bubble
   t0 1   t1  addiu	\ Increment index
   bran1  t1  bgez	\ Result still positive; continue looping
   t1     rp  put	\ Write back the loop index in the delay slot

   bran1  t0  bltz	\ Result negative, so check operand
   nop			\ If operand is negative too, continue looping

   \ The internal "i" value went from positive to negative, so the loop ends
   rp 3 /n*  rp  addiu  \ remove loop params from stack
   skip-branch
c;

\ Run time word for +loop
code (+loop) (s increment -- )
   rp      t0   get
   bubble
   t0 tos  t1   addu	\ increment loop index
   t1      rp   put	\ Write back the loop index
   t0 tos  t3   xor	\ Compare operand signs
   sp      tos  get	\ Pop stack
   bran1   t3   bltz	\ Operand signs different
   sp           ainc	\ Delay slot

   t1 t0   t2   xor	\ Compare result with an operand
   bran1   t2   bgez	\ Result has same sign as operand; continue looping
   nop

   \ The result sign differs from the operand signs; so the loop ends
   rp 3 /n*  rp  addiu	\ remove loop params from stack
   skip-branch
c;

\ Run time word for do
code (do)  (s l i -- )
   tos  t1       move   \ i in t1 
   sp   t0       get    \ l in t0
   sp /n    tos  lw
   sp 2 /n*  sp  addiu
mlabel pd0 ( -- r: loop-end-offset l+0x8000 i-l-0x8000 )
   ip      rp  push     \ remember the do offset address
   skip-branch		\ Skip the do offset
   h# 8000.0000 t2  sethi
   t0 t2   t0  addu
   t0      rp  push
   t1 t0   t1  subu
   t1      rp  push
c;
meta

\ Run time word for ?do
code (?do)  (s l i -- )
   sp        t0   get    \ l in t0
   tos       t1   move   \ i in t1
   sp /n     tos  lw
   pd0   t1  t0   bne
   sp 2 /n*  sp   addiu	 \ Delay slot
   take-branch
c;

\ Loop index for current do loop
code i  (s -- n )
   tos     sp   push
   rp      tos  get
   rp /n   t0   lw
   bubble
   tos t0  tos  addu
c;

\ Limit value for the enclosing do loop
code ilimit  ( -- n )
   tos     sp   push
   rp /n   tos  lw
   bubble
   h# 8000.0000 t0  sethi
   tos t0  tos  subu
c;

\ Loop index for next enclosing do loop
code j   (s -- n )
   tos       sp   push
   rp 3 /n*  tos  lw
   rp 4 /n*  t0   lw
   bubble
   tos t0    tos  addu
c;
\ Limit value for the next enclosing do loop
code jlimit  ( -- n )
   tos       sp   push
   rp 4 /n*  tos  lw
   bubble
   h# 8000.0000 t0  sethi
   tos t0    tos  subu
c;

code (leave)  (s -- )
mlabel pleave
   rp 2 /n*   ip  lw	    \ Get the address of the ending offset
   rp 3 /n*   rp  addiu	    \ get rid of the loop indices
   take-branch
c;

code (?leave)  (s f -- )
   tos         t0    move
   sp          tos  get
   pleave  t0  $0   bne
   sp               ainc	\ Delay slot
c;

code unloop  ( -- )  rp 3 /n*   rp  addiu  c;  \ Discard the loop indices

code (of)  ( selector test -- [ selector ] )
   sp  t0   pop		\ Test in tos, Selector in t0
   t0  tos  =  if
   t0  tos  move	\ Delay slot - Copy selector to tos
      sp  tos  pop	\ Overwrite tos if selector matches
      skip-branch
      next
   then
   take-branch
c;

\ (endof) is the same as branch, and (endcase) is the same as drop,
\ but redefining them this way makes the decompiler much easier.
code (endof)    (s -- )   take-branch   c;
code (endcase)  (s n -- )   sp  tos  pop   c;

meta-base
assembler
mlabel dofalse
   $0  tos  move
   next
meta

hex
\ Convert a character to a digit according to the current base
code digit  (s char base -- digit true | char false )
   tos     t0   move		\ base in t0
   sp      tos  get		\ char in tos
   bubble
   tos -30 tos  addiu		\ convert to number \  30 is ascii 0
   dofalse tos  bltz		\ Anything less than ascii 0 isn't a digit
   tos     a    cmpi		\ Delay slot - test for >= 10
   $at 0>=  if			\ Try for a letter representing a digit
      tos      ascii A ascii 0 -  cmpi
      dofalse  $at  0< brif	        \ bad if > '9' and < 'A'
      tos      ascii a ascii 0 -  cmpi  \ >= 'a' (delay slot)
      $at 0>=  if
         tos  ascii A ascii 0 -  d# 10 -  negate  tos  addiu  \ (delay slot)
         tos  ascii a ascii A -           negate  tos  addiu
      then
   then
   tos      t0   cmp		\ Compare digit to base
   dofalse  $at  0>= brif	\ Error if digit is bigger than base
   nop
   tos  sp  put			\ Replace the char on the stack with the digit
   $0 -1 tos addiu		\ True to indicate success
c;

\ Copy cnt characters starting at from-addr to to-addr.  Copying is done
\ strictly from low to high addresses, so be careful of overlap between the
\ two buffers.

code cmove  ( src dst cnt -- )  \ Copy from bottom to top
   sp 4    t0   lw	\ Src into t0
   sp 0    t1   lw	\ Dst into t1

   t0 tos  t2   addu	\ t2 = src limit

   t0 t2  <> if
   nop
      
      begin
         t0 0  t3     lbu	\ Load byte
         t0 1  t0     addiu	\ (load delay) Increment src
         t3    t1 0   sb	\ Store byte
      t0 t2  = until
         t1 1  t1     addiu	\ (delay) Increment dst

   then   

   sp 8      tos  lw		\ Delay slot - Reload tos
   sp 3 /n*  sp   addiu		\   "
c;

code cmove>  ( src dst cnt -- )  \ Copy from top to bottom
   sp 4     t0  lw	\ Src into t0
   sp 0     t1  lw	\ Dst into t1

   t0  tos  t2  addu	\ Top of src area
   t1  tos  t1  addu	\ Top of dst area

   t0 t2  <> if		\ Don't do anything if the count is 0.
   nop

      begin
         t2 -1  t3     lbu	\ Load byte
         t2 -1  t2     addiu	\ (load delay) Decrement src
         t3     t1 -1  sb	\ Store byte
      t0 t2  = until
	 t1 -1  t1     addiu	\ (delay) Decrement dst

   then

   sp 8      tos  lw	\ Delete 3 stack items
   sp 3 /n*  sp   addiu	\   "
c;

code and  (s n1 n2 -- n3 )  sp  t0  pop   tos t0  tos  and   c;
code or   (s n1 n2 -- n3 )  sp  t0  pop   tos t0  tos  or    c;
code xor  (s n1 n2 -- n3 )  sp  t0  pop   tos t0  tos  xor   c;
code invert  (s n1 -- n2 )     $0 tos  tos  subu   tos -1  tos  addiu  c;

code lshift  (s n1 cnt -- n2 )  sp  t0  pop   t0 tos  tos  sllv  c;
code rshift  (s n1 cnt -- n2 )  sp  t0  pop   t0 tos  tos  srlv  c;
code <<      (s n1 cnt -- n2 )  sp  t0  pop   t0 tos  tos  sllv  c;
code >>      (s n1 cnt -- n2 )  sp  t0  pop   t0 tos  tos  srlv  c;
code >>a     (s n1 cnt -- n2 )  sp  t0  pop   t0 tos  tos  srav  c;

code +    (s n1 n2 -- n3 )   sp  t0  pop   tos t0  tos  addu   c;
code -    (s n1 n2 -- n3 )   sp  t0  pop   t0 tos  tos  subu   c;
code negate  (s n1 -- n2 )  $0 tos  tos  subu   c;

: abs   (s n1 -- n2 )  dup 0<  if  negate  then   ;

: min   (s n1 n2 -- n3 )  2dup  >  if  swap  then  drop  ;
: max   (s n1 n2 -- n3 )  2dup  <  if  swap  then  drop  ;
: umin  (s u1 u2 -- u3 )  2dup u>  if  swap  then  drop  ;
: umax  (s u1 u2 -- u3 )  2dup u<  if  swap  then  drop  ;

code up@  (s -- addr )  tos sp push   up tos move   c;
code sp@  (s -- addr )  tos sp push   sp tos move   c;
code rp@  (s -- addr )  tos sp push   rp tos move   c;
code up!  (s addr -- )  tos up move   sp tos pop    c;
code sp!  (s addr -- )  tos sp move   sp tos pop    c;
code rp!  (s addr -- )  tos rp move   sp tos pop    c;
code >r   (s n -- )     tos rp push   sp tos pop    c;
code r>   (s -- n )     tos sp push   rp tos pop    c;
code r@   (s -- n )     tos sp push   rp tos get    c;
code 2>r  (s n1 n2 -- )
   rp -8      rp     addiu
   sp  0      t0     lw
   bubble
   t0         rp 4   sw
   tos        rp 0   sw
   sp  4      tos    lw
   sp  8      sp     addiu
c;
code 2r>  (s -- n1 n2 )
   sp -8      sp     addiu
   tos        sp 4   sw
   rp  4      tos    lw
   bubble
   tos        sp 0   sw
   rp  0      tos    lw
   rp  8      rp     addiu
c;
code 2r@  (s -- n1 n2 )
   sp -8      sp     addiu
   tos        sp 4   sw
   rp  4      tos    lw
   bubble
   tos        sp 0   sw
   rp  0      tos    lw
c;

code >ip  (s n -- )     tos rp push   sp tos pop    c;
code ip>  (s -- n )     tos sp push   rp tos pop    c;
code ip@  (s -- n )     tos sp push   rp tos get    c;
: ip>token  ( ip -- token-adr )  /token -  ;

code exit   (s -- )     rp ip pop  c;
code unnest (s -- )     rp ip pop  c;

code tuck  (s n1 n2 -- n2 n1 n2 )
   sp   t0    get
   bubble
   t0   sp    push
   tos  sp 4  sw
c;
code nip   (s n1 n2 -- n2 )
   sp  ainc
c;
code flip  (s w1 -- w2 )  \ byte swap
   tos 18  t0   sll
   t0  10  t0   srl
   tos  8  tos  srl
   tos t0  tos  or
c;

assembler definitions
:-h leaveflag  (s condition -- )
\ macro to assemble code to leave a flag on the stack
   if
   $0  tos  move   \ Delay slot
      $0 -1 tos addiu
   then
;-h

meta definitions
code 0<   (s n -- f )  tos $0 tos slt  $0 tos tos subu   c;
code 0>   (s n -- f )  $0 tos tos slt  $0 tos tos subu   c;
code 0<=  (s n -- f )  $0 tos tos slt  tos -1 tos addiu  c;
code 0>=  (s n -- f )  tos $0 tos slt  tos -1 tos addiu  c;

code 0=   (s n -- f )  tos $0  =   leaveflag  c;
code 0<>  (s n -- f )  tos $0  <>  leaveflag  c;

assembler definitions
:-h compare
   sp  t0  pop
   t0 tos  cmp
;-h
meta definitions

code =    (s n1 n2 -- f )  sp t0 pop  tos t0  = leaveflag  c;
code <>   (s n1 n2 -- f )  sp t0 pop  tos t0 <> leaveflag  c;

code <    (s n1 n2 -- f )  sp t0 pop  t0 tos tos slt    $0 tos tos subu   c;
code >=   (s n1 n2 -- f )  sp t0 pop  t0 tos tos slt    tos -1 tos addiu  c;
code >    (s n1 n2 -- f )  sp t0 pop  tos t0 tos slt    $0 tos tos subu   c;
code <=   (s n1 n2 -- f )  sp t0 pop  tos t0 tos slt    tos -1 tos addiu  c;
code u<   (s n1 n2 -- f )  sp t0 pop  t0 tos tos sltu   $0 tos tos subu   c;
code u>=  (s n1 n2 -- f )  sp t0 pop  t0 tos tos sltu   tos -1 tos addiu  c;
code u>   (s n1 n2 -- f )  sp t0 pop  tos t0 tos sltu   $0 tos tos subu   c;
code u<=  (s n1 n2 -- f )  sp t0 pop  tos t0 tos sltu   tos -1 tos addiu  c;

code drop  (s n -- )      sp   tos  pop    c;
code dup   (s n -- n n )  tos  sp   push   c;
code over  (s n1 n2 -- n1 n2 n1 )  tos sp push    sp 4  tos  lw  c;
code swap  (s n1 n2 -- n2 n1 )
   sp   t0   get
   tos  sp   put
   t0   tos  move
c;
code rot  (s n1 n2 n3 -- n2 n3 n1 )
   sp    t0    get
   sp 4  t1    lw
   t0    sp 4  sw
   tos   sp    put
   t1    tos   move
c;
code -rot  (s n1 n2 n3 -- n3 n1 n2 )
   sp    t0    get
   sp 4  t1    lw
   tos   sp 4  sw
   t1    sp    put
   t0    tos   move
c;
code 2drop  (s d -- )      sp ainc   sp tos pop  c;
code 2dup   (s d -- d d )
   sp     t0    get
   sp -8  sp    addiu
   tos    sp 4  sw
   t0     sp 0  sw
c;
code 2over  (s d1 d2 -- d1 d2 d1 )
   sp -8  sp    addiu
   tos    sp 4  sw
   sp 10  tos   lw
   bubble
   tos    sp 0  sw
   sp 0c  tos   lw
c;
code 2swap  (s d1 d2 -- d2 d1 )
   sp 8  t2    lw
   sp 4  t1    lw
   sp 0  t0    lw
   bubble
   t0    sp 8  sw
   tos   sp 4  sw
   t2    sp 0  sw
   t1    tos   move
c;
code 3drop  (s n1 n2 n3 -- )
   sp 8  tos   lw
   sp c  sp    addiu
c;
code 3dup   (s n1 n2 n3 -- n1 n2 n3 n1 n2 n3 )
   sp 4   t1    lw
   sp 0   t0    lw
   sp -c  sp    addiu
   tos    sp 8  sw
   t1     sp 4  sw
   t0     sp 0  sw
c;
code 4drop  (s n1 n2 n3 n4 -- )
   sp 0c  tos   lw
   sp 10  sp    addiu
c;
code 5drop  (s n1 n2 n3 n4 n5 -- )
   sp 10  tos   lw
   sp 14  sp    addiu
c;

code pick   (s nm ... n1 n0 k -- nm ... n2 n0 nk )
   tos 2   tos  sll   \ Multiply by /n
   sp tos  tos  addu
   tos 0   tos  lw    \ Index into stack
c;  
 
code 1+  (s n1 -- n2 )  tos 1  tos  addiu   c;
code 2+  (s n1 -- n2 )  tos 2  tos  addiu   c;
code 1-  (s n1 -- n2 )  tos -1 tos  addiu   c;
code 2-  (s n1 -- n2 )  tos -2 tos  addiu   c;

code 2/  (s n1 -- n2 )  tos 1  tos  sra   c;
code u2/ (s n1 -- n2 )  tos 1  tos  srl   c;
code 2*  (s n1 -- n2 )  tos 1  tos  sll   c;
code 4*  (s n1 -- n2 )  tos 2  tos  sll   c;
code 8*  (s n1 -- n2 )  tos 3  tos  sll   c;

code on  (s addr -- )
   $0 -1  t0  addiu
   t0  tos  put
   sp  tos  pop
c;
code off  (s addr -- )
   $0  tos  put
   sp  tos  pop
c;

code +!  (s n addr -- )
   sp       t0   get
   tos      t1   get
   bubble
   t1 t0    t1   addu
   t1       tos  put
   sp  4    tos  lw
   sp  8    sp   addiu
c;

code @    (s adr -- n )  tos 0  tos  lw   c;   \ longword aligned
code l@   (s adr -- l )  tos 0  tos  lw   c;   \ longword aligned
code w@   (s adr -- w )  tos 0  tos  lhu  c; \ 16-bit word aligned
code <w@  (s adr -- w )  tos 0  tos  lh   c; \ with sign extension
code c@   (s adr -- c )  tos 0  tos  lbu  c;

code !  (s n adr -- )
   sp 0  t0     lw
   bubble
   t0    tos 0  sw
   sp 4  tos    lw
   sp 8  sp     addiu
c;
code l!   (s n adr -- )
   sp 0  t0     lw
   bubble
   t0    tos 0  sw
   sp 4  tos    lw
   sp 8  sp     addiu
c;
code w!  (s w adr -- )
   sp 0  t0     lw
   bubble
   t0    tos 0  sh
   sp 4  tos    lw
   sp 8  sp     addiu
c;
code c!  (s c adr -- )
   sp 0  t0     lw
   bubble
   t0    tos 0  sb
   sp 4  tos    lw
   sp 8  sp     addiu
c;

code x@   (s adr -- x )   \ doubleword aligned
   tos 0  t0    ld
   sp -4  sp    addiu
   t0     sp 0  sw
   t0 0   tos   dsra32
c;
code x!   (s x adr -- )
   sp 0   t0    lw
   bubble
   t0 0   t0    dsll32
   sp 4   t1    lw
   t1 0   t1    dsll32
   t1 0   t1    dsrl32
   t0 t1  t0    or
   
   t0    tos 0  sd
   sp 8  tos    lw
   sp c  sp     addiu
c;

: instruction!  (s n adr -- )  tuck !  /l sync-cache  ;

: instruction,  (s opcode -- )  here /l allot instruction!  ;

code 2@  (s adr -- d )
   tos      $at move
   $at 4    t0  lw
   t0       sp  push
   $at 0    tos lw
c;
code 2!  (s d adr -- )
   sp  0   t0     lw
   bubble
   t0      tos 0  sw
   sp  4   t0     lw
   bubble
   t0      tos 4  sw
   sp  8   tos    lw
   sp  0c  sp     addiu
c;

code fill (s start-adr count char -- )
			\ char in tos
   sp 0  t0  lw		\ count in t0
   sp 4  t1  lw		\ dst in t1
   bubble
    
   t0 t1  t0  addu	\ limit in t0
   t0 t1  <>  if
   t1 1   t1  addiu	\ (delay) increment dst

      begin
         tos   t1 -1  sb
      t0 t1 = until
         t1 1  t1     addiu	\ (delay) increment dst
   then

   sp 8   tos  lw
   sp 0c  sp   addiu
c;

code lfill (s start-adr count long -- )
			\ long in tos
   sp 0  t0  lw		\ count in t0
   sp 4  t1  lw		\ dst in t1
   bubble
    
   t0 3   t0  addi	\ round up
   t0 2   t0  srl
   t0 2   t0  sll	\ Clear low bits

   t0 t1  t0  addu	\ limit in t0
   t0 t1  <>  if
   t1 4   t1  addiu	\ (delay) increment dst

      begin
         tos   t1 -4  sw
      t0 t1 = until
         t1 4  t1     addiu	\ (delay) increment dst
   then

   sp 8   tos  lw
   sp 0c  sp   addiu
c;

code noop (s -- )  c;

code n->l (s n.unsigned -- l )  c;

code lwsplit (s l -- w.low w.high )  \ split a long into two words
   tos     t0   move
   t0 10   t0   sll
   t0 10   t0   srl
   t0      sp   push
   tos 10  tos  srl
c;
code wljoin (s w.low w.high -- l )
   sp       t0   pop
   t0  10   t0   sll   \ Throw away any high order bits in w.low
   t0  10   t0   srl
   tos 10   tos  sll
   tos t0   tos  or
c;

1 constant /c
2 constant /w
4 constant /l
/l constant /n

code ca+  (s addr index -- addr+index*/c )
   sp       t0   pop
   tos t0   tos  addu
c;
code wa+  (s addr index -- addr+index*/w )
   sp       t0   pop
   tos 1    tos  sll
   tos t0   tos  addu
c;
code la+  (s addr index -- addr+index*/l )
   sp       t0   pop
   tos 2    tos  sll
   tos t0   tos  addu
c;
code na+  (s addr index -- addr+index*/n )
   sp       t0   pop
   tos 2    tos  sll
   tos t0   tos  addu
c;
code ta+  (s addr index -- addr+index*/t )
   sp       t0   pop
   tos 2    tos  sll
   tos t0   tos  addu
c;

code ca1+  (s addr -- addr+/w )      tos 1  tos  addiu   c;
code char+ (s addr -- addr+/w )      tos 1  tos  addiu   c;
code wa1+  (s addr -- addr+/w )      tos 2  tos  addiu   c;
code la1+  (s addr -- addr+/l )      tos 4  tos  addiu   c;
code na1+  (s addr -- addr+/n )      tos 4  tos  addiu   c;
code cell+ (s addr -- addr+/n )      tos 4  tos  addiu   c;
code ta1+  (s addr -- addr+/token )  tos /token  tos  addiu   c;

code /c*   (s n -- n*/c ) c;
code chars (s n -- n*/c ) c;
code /w*   (s n -- n*/w )  tos 1  tos  sll  c;
code /l*   (s n -- n*/l )  tos 2  tos  sll  c;
code /n*   (s n -- n*/n )  tos 2  tos  sll  c;
code cells (s n -- n*/n )  tos 2  tos  sll  c;

: upc  (s char -- upper-case-char )
   dup  ascii a  ascii z  between  if  ( hex ) 20 -  then
;
: lcc  (s char -- upper-case-char )
   dup  ascii A  ascii Z  between  if  ( hex ) 20 +  then
;

code c@+  (s adr -- adr' char )
   tos 1   t0   addiu
   t0      sp   push
   tos 0   tos  lbu
c;

: comp  (s addr1 addr2 len -- -1 | 0 | 1 )
   rot 0 swap  2swap    ( 0 addr1 addr2 len )
   bounds  ?do                                            ( 0 addr1' )
      c@+  i c@  <>  if                                   ( 0 addr1' )
         nip  dup 1- c@  i c@  <  if  -1  else  1  then   ( addr1' flag )
	 swap leave                                       ( flag addr1' )
      then                                                ( 0 addr1' )
   loop
   drop
;

: caps-comp  (s addr1 addr2 len -- -1 | 0 | 1 )
   rot 0 swap  2swap    ( 0 addr1 addr2 len )
   bounds  ?do                                            ( 0 addr1' )
      c@+ lcc  i c@ lcc  <>  if                           ( 0 addr1' )
         nip  dup 1- c@ lcc  i c@ lcc  <
         if  -1  else  1  then                            ( addr1' flag )
	 swap leave                                       ( flag addr1' )
      then                                                ( 0 addr1' )
   loop
   drop
;

: pack  (s str-adr len to -- to )
   dup >r
   2dup c!                 ( str-adr len to )
   1+ 2dup + 0 swap c!     ( str-adr len to+1 )
   swap cmove
   r>
;

\ code pack  (s str-adr len to -- to )
\    sp  t0  pop		\ t0 is len
\    sp  t1  pop		\ t1 is "from"; tos is "to"
\ 
\    t0 ff   t0  andi	\ Never store more than 257 bytes
\ 
\    t0  tos 0    stb	\ Place length byte
\ 
\    tos 1   tos  addiu	\ Offset "to" by 1 to skip past the length byte
\ 
\    tos t0  $at  addu
\    $0      $at  stb	\ Put a null byte at the end
\ 
\    0 F:  bra  		\ jump to the until  branch
\    t0 1    t0    subcc	\ Delay slot
\ 
\    begin
\       t2   tos t0   stb
\       t0 1     t0   subcc
\    0 L:
\    0< until annul
\       t1 t0   t2   ldub	\ Delay slot
\ 
\    tos -1   tos  addiu		\ Fix "to" to point to the length byte
\ c;   

code (')  (s -- acf )
   tos       sp   push
   ip 0      tos  lw
   ip /token ip   addiu
   tos base  tos  addu
c;

\ Modifies caller's ip to skip over an in-line string
code skipstr (s -- adr len)
   sp -8  sp    addiu
   tos    sp 4  sw
   rp  0  t0    lw	\ Get string address in t0
   bubble
   t0  0  tos   lbu	\ Get length byte in tos
   t0  1  t0    addiu	\ Address of data bytes
   t0     sp 0  sw	\ Put adr on stack

   \ Now we have to skip the string
   t0 tos         t0   addu	\ Scr now points past the last data byte
   t0 #talign     t0   addiu	\ Round up to token boundary + null byte
   $0 #talign negate    $at  addiu
   t0 $at         t0   and
   t0             rp 0 sw	\ Put the modified ip back
c;

code (")  (s -- adr len)
   sp -8  sp    addiu
   tos    sp 4  sw
   ip  0  tos   lbu	\ Get length byte in tos
   ip  1  ip    addiu	\ Address of data bytes
   ip     sp 0  sw	\ Put adr on stack

   \ Now we have to skip the string
   ip  tos          ip  addu	\ ip now points past the last data byte
   ip  #talign      ip  addiu	\ Round up to a token boundary, plus null byte
   $0  #talign negate   $at addiu
   ip  $at          ip  and
c;

code count  (s adr -- adr+1 len )
   tos 1   tos	addiu
   tos -1  t0	lbu
   tos     sp	push
   t0      tos	move
c;

\ 0 constant origin
\ here-t 4 -  set-relocation-bit-t  drop
code origin  (s -- addr )
   tos  sp   push
   base tos  move
c;

: origin+  (s n -- adr )  origin +  ;
: origin-  (s n -- adr )  origin -  ;

headers

\ Put a branch instruction to target-adr at where
: put-branch  ( target-adr where -- )
   tuck	4 -  -			( where byte-offset )
   2/ 2/      ffff   and	( where longword-offset )
   1000.0000         or		( where "$0 $0 beq" )
   swap !
;
: acf-align  (s -- )
   begin  here #acf-align 1- and  while  0 c,  repeat
   here 'lastacf token!
;

headerless

\ Place the "standard" code field

: set-cf  (s action-adr -- )
   acf-align  origin+  token,
;

headers
: place-cf  (s action-adr -- )
   acf-align  token,
;
: code-cf  (s -- )  acf-align  here ta1+  aligned token,  align  ;

: >code  ( acf-of-code-word -- address-of-start-of-machine-code )  token@  ;
: code?  ( acf -- f )  \ True if the acf is for a code word
   dup token@  swap >body =
;

\ Assemble "next" routine at the end of a code definition.
\ This is not needed for the kernel to run; it is used later
\ after the resident assembler has been loaded

: next  (s  --- )
   \ (next) j                                        nop
\   0800.0000  [ (next) ] literal h# 20 + 2 >> or ,   0000.0000 ,
   \ np jr              nop
    h# 0220.0008 instruction,      0000.0000 instruction,
;

: create-cf    (s -- )  [ dodoes ]     literal set-cf  ['] noop token,  ;
: variable-cf  (s -- )  [ dovariable ] literal set-cf  ;

: place-;code  (s -- )  code-cf  ;
: place-does   (s -- )  [ docolon ]    literal set-cf  ;

\ Ip is assumed to point to (;code .  flag is true if
\ the code at ip is a does> clause as opposed to a ;code clause.
: does-ip?  ( ip -- ip' flag )
   dup token@  ['] (does>) =  ( ip flag )  swap ta1+ ta1+  swap
;

: put-cf  (s action-clause-adr where -- )  token!  ;   

\ uses  sets the code field of the indicated word so that
\ it will execute the code at action-clause-adr
: uses  (s action-clause-adr xt -- )
   tuck /token + put-cf
   [ dodoes ] literal  origin+  swap put-cf
;

\ used  sets the code field of the most-recently-defined word so that
\ it executes the word at action-clause-adr
: used  (s action-clause-adr -- )  lastacf uses  ;

: colon-cf?  ( possible-acf -- flag )
   dup  token@  [ docolon ] literal origin+ =  if
      /token - token@
      dup  ['] branch   <>
      over ['] ?branch  <> and
      over ['] (of)     <> and
      over ['] (leave)  <> and
      over ['] (?leave) <> and
      over ['] (do)     <> and
      over ['] (?do)    <> and
      swap ['] (lit)    <> and
   else
      drop false
   then
;
: colon-cf      (s -- )  [ docolon ]     literal set-cf  ;
: user-cf       (s -- )  [ douser ]      literal set-cf  ;
: value-cf      (s -- )  [ dovalue ]     literal set-cf  ;
: constant-cf   (s -- )  [ doconstant ]  literal set-cf  ;
: defer-cf      (s -- )  [ dodefer ]     literal set-cf  ;
: 2constant-cf  (s -- )  [ do2constant ] literal set-cf  ;

4 constant /branch
: branch,  ( offset -- )  ,  ;
: branch!  ( offset where -- )  !  ;

headerless
: branch@  ( where -- offset )  @  ;
\ >target depends on the way that branches are compiled
: >target  ( ip-of-branch-instruction -- target )  ta1+ dup branch@ +  ;
headerless

/a constant /a

headers

code a@  ( adr -- adr' )
   tos tos get
   bubble
   tos base  tos addu
c;

\ R : a!  ( adr1 adr2 -- )  set-relocation-bit  l!  ;
code a!  ( adr1 adr2 -- )
   sp         t0   pop
   t0 base    t0   subu
   t0         tos  put
   sp         tos  pop
c;
: a,  ( adr -- )  here  /a allot  a!  ;

/token constant /token
code token@ (s adr -- cfa )
   tos 0     tos  lw
   bubble
   tos base  tos  addu
c;
\ R : token! (s cfa adr -- )  set-relocation-bit l!  ;
code token! (s cfa addr -- )
  sp       t0   get
  bubble
  t0 base  t0   subu
  t0       tos  put
  sp  4    tos  lw
  sp  8    sp   addiu
c;


: token, (s cfa -- )  here  /token allot  token!  ;

: null  ( -- token )  origin  ;
: !null-link   ( adr -- )  null swap link!  ;
: !null-token  ( adr -- )  null swap token!  ;
: non-null?  ( link -- false | link true )
   dup origin =  if  drop false  else  true  then
;
\ code non-null?  ( link -- false | link true )
\    tos  base    cmp
\    <>  if
\    false t0  move       \ Delay slot
\ 
\       tos  sp  push
\       true t0 move
\    then
\    t0  tos  move
\ c;
: get-token?     ( adr -- false | acf  true )  token@ non-null?  ;
: another-link?  ( adr -- false | link true )  link@  non-null?  ;

\ The "word type" is a number which distinguishes one type of word
\ from another.  This is highly implementation-dependent.

\ For the MIPS implementation, the magic number returned by word-type
\ is the absolute address of the action code.

: long-cf?  (s acf -- flag )  token@ origin-  [ dodoes ] literal  =  ;

: word-type  (s acf -- word-type )  dup long-cf?  if  ta1+  then  token@  ;

: body>  (s apfa -- acf )
   /token -   dup /token -  long-cf?  if  /token -  then
;
: >body  (s acf -- apf )  dup long-cf?  if  ta1+  then   ta1+  ;

4 constant /user#

\ Move to a machine alignment boundary.

: aligned  (s adr -- adr' )  /n round-up  ;

code acf-aligned  (s adr -- adr' )
   tos  3   tos  addiu
   $0 -4    $at  addiu
   tos $at  tos  and
c;

\ Floored division is prescribed by the Forth 83 standard.
\ The quotient is rounded toward negative infinity, and the
\ remainder has the same sign as the divisor.

: /mod  (s dividend divisor -- remainder quotient )
  \ Check if either factor is negative
    2dup               ( n1 n2 n1 n2)
    or 0< if           ( n1 n2)
    
        \ Both factors not non-negative; do division by:
        \ Take absolute value and do unsigned division
        \ Convert to truncated signed divide by:
        \  if dividend is negative then negate the remainder
        \  if dividend and divisor have opposite signs then negate the quotient
        \ Then convert to floored signed divide by:
        \  if quotient is negative and remainder is non-zero
        \    add divisor to remainder and decrement quotient

        2dup swap abs swap abs  ( n1 n2 u1 u2)     \ Absolute values

        u/mod              ( n1 n2 urem uqout)     \ Unsigned divide
        >r >r              ( n1 n2) ( uquot urem)

        over 0< if         ( n1 n2) ( uquot urem)  
            r> negate >r                 \ Negative dividend; negate remainder
        then               ( n1 n2) ( uquot trem)
   
        swap over          ( n2 n1 n2) ( uquot trem)
        xor 0< if          ( n2) ( uquot trem)
            r> r>
            negate         ( n2 trem tquot)  \ Opposite signs; negate quotient
           -rot            ( tquot n2 trem)
            dup 0<> if 
                +          ( tquot rem) \ Negative quotient & non-zero remainder
                swap 1-    ( rem quot)  \ add divisor to rem. & decrement  quot.
            else
                nip swap   ( rem quot)
            then
        else
            drop r> r>     ( rem quot)
        then

    else   \ Both factors non-negative

        u/mod          ( rem quot)
    then
;

code u/mod  (s u.dividend u.divisor -- u.remainder u.quotient )
   sp    t0   get	\ dividend
   bubble
   t0    tos  divu	\ Calculate result
   t0         mfhi      \ Get remainder
   t0    sp   put
   tos        mflo	\ Get quotient
c;

: /     (s n1 n2 -- quot )   /mod  nip ;

: mod   (s n1 n2 -- rem )    /mod  drop  ;

: um/mod (s ul.dividend un.divisor -- un.remainder un.quotient )  u/mod  ;

: m/mod  (s l.dividend n.divisor -- n.remainder n.quotient )  /mod  ;

\ 32*32->64 bit unsigned multiply
\            y  rs2     y  rd

code um*   ( u1 u2 -- ud[lo hi] )
   sp     t0   get
   bubble
   t0     tos  multu
   t0          mflo
   t0     sp   put
   tos         mfhi
c;

code m*  ( n1 n2 -- low high )
   sp     t0   get
   bubble
   t0     tos  mult
   t0          mflo
   t0     sp   put
   tos         mfhi
c;

code *  ( n1 n2 -- n3 )
   sp     t0   pop
   t0     tos  mult
   tos         mflo
c;

: ul*  (s un1 un2 -- lproduct )  *  ;
: u*   (s un1 un2 -- uproduct )  *  ;

: d+  ( d.a d.b -- d.c )
   >r rot tuck +     ( a.hi a.lo c.lo  r: b.hi )
   tuck u> negate    ( a.hi c.lo carry  r: b.hi )
   rot + r> +        ( d.c )
;
: d-  ( d.a d.b -- d.c )
   >r swap >r     ( a.lo b.lo  r: b.hi a.hi )
   2dup u< >r     ( a.lo b.lo  r: b.hi a.hi borrow )
   -              ( c.lo  r: b.hi a.hi borrow )
   r> r> + r> -   ( d.c )
;
: d@  ( adr -- low high )  dup 4 + @  swap @  ;

\ MIPS version is dynamically relocated, so we don't need a bitmap
: clear-relocation-bits  ( adr len -- )  2drop  ;

only forth also labels also meta also assembler definitions

:-h 'user#  \ name  ( -- user# )
    [ meta ]-h  '  ( acf-of-user-variable )  >body-t
    @-t
;-h
:-h 'user  \ name  ( -- user-addressing-mode )
    [ assembler ]-h   up 'user#
;-h
:-h 'body  \ name  ( -- variable-apf )
    [ meta ]-h  '  ( acf-of-user-variable )  >body-t
;-h
:-h 'acf  \ name  ( -- variable-apf )
    [ meta ]-h  '  ( acf-of-user-variable )  >body-t
;-h
 
only forth also labels also meta also definitions

: move  ( src dst cnt -- )
   >r 2dup u<  if  r> cmove>  else  r> cmove  then
;

init-user-area constant init-user-area

code (llit)  (s -- l )
   tos sp push   ip tos get   ip ainc
c;

code (dlit)  (s -- d )
   sp -8   sp    addiu
   tos     sp 4  sw
   ip 4    t0    lw
   ip      tos   get
   t0      sp 0  sw
   ip 8    ip    addiu
c;

\ Select a vocabulary thread by hashing the lookup name.
\ Hashing function:  Use the lower bits of the first character in the
\ name to select one of #threads threads in the array pointed-to by
\ the user number in the parameter field of voc-acf.
code hash  (s str-addr voc-acf -- thread )
   \ The next 2 lines are equivalent to ">threads", which in this
   \ implementation happens to be the same as ">body >user"
   tos 8   tos   lw	\ Get the user number
   bubble
   up tos  tos   addu	\ Find the address of the threads

   sp      t0   pop
   t0 1    t0   lbu
   bubble
   t0 #threads-t 1-   t0   andi
   t0 2    t0   sll	\ Convert index to longword offset
   tos t0  tos  addu
c;

\ Search a vocabulary thread (link) for a name matching string.
\ If found, return its code field address and -1 if immediate, 1 if not
\ immediate.  If not found, return the string and 0.

\ Name field:
\     name: forth-style packed string, no tag bits
\     flag: 40 bit is immediate bit
\ Padding is optionally inserted between the name and the flags
\ so that the byte after the flag byte is on an even boundary.

[ifdef] notdef
code (find)  (s string link origin -- acf -1  |  acf 1  |  string 0 )
   tos t5   move	\ Origin in t5
   sp  tos  pop		\ link in tos
\ Registers:
\ tos    alf of word being tested
\ t0    string
\ t1    name being tested
\ t2    # of characters left to test
\ string is kept on the top of the external stack

   begin  tos t5  <> while	\ Test for end of list
      tos /token  t1  addiu	\ Get name address of word to test
      sp          t0  get    	\ Get string address
      bubble
      t0 0    t2  lbu	\ get the name field length
      begin
         t0 0  t3  lbu	\ Compare 2 characters
         t1 0  t4  lbu
         bubble
      t3 t4  = while		\ Keep looking as long as characters match
         t0 1  t0  addiu	\ Increment byte pointers
         t2 -1 t2  addiu	\ Decrement byte counter
         t2 0< if		\ If we've tested all chars, the names match.
         t1 1  t1  addiu	\ Delay slot
            t1 0   tos  lbu	\ Get flags byte into tos register

            t1 4   t1  addiu	\ Now find the code field by
            $0 -4  $at addiu
            t1 $at t1  and	\ aligning to the next 4 byte boundary

	    tos 20  $at andi	\ Test the alias flag
	    $at $0  <> if
               nop
	       t1 0     t1 lw	\ Get acf
	       bubble
               t1 base  t1 addu \ Relocate
            then

	    t1     sp   put	\ Replace string on stack with acf
	    tos 40  $at andi  	\ Test the immediate flag
	    $at $0  <> if
	       $0 -1   tos  addiu	\ Not immediate  \ Delay slot
	    ( else )
	       $0  1   tos  addiu	\ Immediate
	    then
	    next
         then
      repeat
         nop

      \ The names did not match, so check the next name in the list
      tos 0     tos  lw		\ Fetch next link
      bubble
      tos base  tos  addu	\ Relocate
   repeat
      nop			\ Delay slot

   \ If we get here, we've checked all the names with no luck
   $0  tos  move
c;
[then]

code ($find-next)  (s adr len link -- adr len alf true  |  adr len false )
\ Registers:
\ tos    alf of word being tested
\ t0     string
\ t1     anf of word being tested
\ t2     saves ctr register value
\ t3    character from string
\ t4    character from name
\ t5    string length
\ string is kept on the top of the external stack

   sp 4    t0    lw 		\ Get string address
   sp 0    t5    lw		\ get the name field length
				\ link in tos

   ahead nop			\ Branch to end of loop the first time
\ tos 0     tos  lw		\ Fetch next link  ( next acf )
\ bubble

\ tos $0 <> if		\ Until end of linked list
\ tos base  tos  addu		\ Relocate (delay slot)

   begin
      tos -4   tos  addiu	\ >link
      tos -1   t1   addiu	\ t1 points before count byte at string *end*
      t1  t5   t1   subu	\ t1 points to beginning of string
      t0       t6   move
      
      t5       $at  move	\ Set starting loop index
      begin
         t1 0  t4   lbu		\ Get character from name field
         t1 1  t1   addiu
         t6 0  t3   lbu		\ Get character from search string
         t6 1  t6   addiu
      t3 t4 =  while		\ Compare 2 characters
      $at -1 $at addiu		\ Decrement character count (delay slot)
         $at $0 =  if
         nop			\ If we've tested all name chars, we
            t1 0      t4  lbu	\ may have a match; check the count byte
            bubble
            t4 h# 1f  t4  andi  \ Remove tag bits
            t4 t5 = if		\ Compare count bytes
            nop
               tos    sp  push	\ Push alf above pstr
               $0 -1  tos addiu	\ True on top of stack means "found"
               next
            then
         then
      repeat
      nop

   but then			\ Target of "ahead" branch

      \ The names did not match, so check the next name in the list
      tos 0     tos  lw		\ Fetch next link  ( next acf )
      bubble

   tos $0 = until		\ Until end of linked list
   tos base  tos  addu		\ Relocate (delay slot)
\ then

   \ If we get here, we've checked all the names with no luck
   $0     tos  move		\ Return false
c;

: ?negate  (s n1 n2 -- n3 )  if  negate  then  ;

code wflip (s l1 -- l2 )  \ word swap
   tos      t0  move
   tos 10   tos  srl
   t0 10   t0  sll
   tos t0  tos  or
c;

: cset     (s byte-mask adr -- )  tuck c@ or swap c!  ;
: creset   (s byte-mask adr -- )  swap invert over c@ and swap c!  ;
: ctoggle  (s byte-mask adr -- )  tuck c@ xor swap c!  ;
: toggle   (s adr byte-mask -- )  swap ctoggle  ;

code s->l  (s n.signed -- l )   c;
code l->n  (s l -- n )  c;
code n->a  (s n -- a )  c;
code l->w  (s l -- w )  tos 10  tos  sll   tos 10  tos  srl  c;
code n->w  (s n -- w )  tos 10  tos  sll   tos 10  tos  srl  c;
code w->n  (s w -- n )  tos 10  tos  sll   tos 10  tos  sra  c;

code l>r   (s l -- )     tos rp push   sp tos pop    c;
code lr>   (s -- l )     tos sp push   rp tos pop    c;
code lr@   (s -- l )     tos sp push   rp tos get    c;

code /t* (s n -- n*/t )  tos 2  tos  sll  c;

#align-t     constant #align
#acf-align-t constant #acf-align
#talign-t    constant #talign

: align  (s -- )  #align (align)  ;
: taligned  (s adr -- adr' )  #talign round-up  ;
: talign  (s -- )  #talign (align)  ;

code np@  ( -- adr )  tos sp push   np tos move   c;

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
