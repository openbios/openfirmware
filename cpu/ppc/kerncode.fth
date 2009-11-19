purpose: Kernel code words
\ See license at end of file

\ In the portions of the code than are used while incrementally compiling on
\ the host system, we use "subfc" instead of "subf" instructions, because the
\ POWER, as opposed to PowerPC, instruction set architecture does not have
\ "subf".  This allows us to compile on POWER-based RS6000 systems.
\ In code that is only used in a target firmware environment, we can use "subf"
\ "subf" may execute somewhat faster than "subfc", because the carry bit
\ represents an interaction between the integer unit and the branch unit,
\ but the difference is likely to be insignificant in the Forth environment.
\ However, there are cases in interrupt handlers where "subfc" modification
\ of the carry bit represents an undesireable change to the value of the
\ XER register, complicating the process of restoring the state of the
\ interrupted code.

meta
hex

\ Allocate and clear the initial user area image
mlabel init-user-area
setup-user-area

extend-meta-assembler

\ ---- Assembler macros that reside in the host environment
\ and assemble code for the target environment

\ Forth Virtual Machine registers

\ Note that the Forth Stack Pointer (r31) is NOT the same register that
\ C uses for the stack frame pointer (r1).

register-names definitions

decimal
:-h t0   20 ;-h  :-h t1 21 ;-h  :-h t2  22 ;-h  :-h t3 23 ;-h
:-h t4   24 ;-h  :-h t5 25 ;-h
:-h base 26 ;-h  :-h up 27 ;-h  :-h tos 28 ;-h  :-h ip 29 ;-h
:-h rp   30 ;-h  :-h sp 31 ;-h
:-h w    t5 ;-h
:-h t6   19 ;-h
hex


\ Constants defining virtual machine implementation parameters

constant-names definitions

also meta  /n-t  previous   ( /n-t )
            constant-h  1cell	\ Offsets into the stack
1cell  -1 * constant-h -1cell
1cell   2 * constant-h  2cells
1cell   3 * constant-h  3cells
1cell   4 * constant-h  4cells
1cell   5 * constant-h  5cells

1cell       constant-h  /cf	\ Size of a code field (except for "create")
/cf    -1 * constant-h -/cf

1cell       constant-h  /token	\ Size of a compiled word reference
/token -1 * constant-h -/token

1cell       constant-h  /branch	\ Size of a branch offset

/token  2 * constant-h  /ccf	\ Size of a "create" code field

/cf 1cell + constant-h  /cf+1cell \ Location of second half of 

previous previous definitions

\ assembler macros for common sequences
extend-meta-assembler

:-h next-tail1      " add t1,t1,base  mtspr lr,t1  bclr 20,0"  evaluate  ;-h
:-h next-tail       " lwzux t1,w,base  next-tail1"             evaluate  ;-h
:-h push-tos        " stwu tos,-1cell(sp)"                     evaluate  ;-h
:-h push-t0         " stwu t0,-1cell(sp)"                      evaluate  ;-h
:-h pop-tos         " lwz  tos,0(sp)      addi sp,sp,1cell"    evaluate  ;-h
:-h pop1            " lwz  tos,1cell(sp)  addi sp,sp,2cells"   evaluate  ;-h
:-h pop2            " lwz  tos,2cells(sp) addi sp,sp,3cells"   evaluate  ;-h
:-h second-to-t0    " lwz  t0,0(sp)"                           evaluate  ;-h
:-h pop-to-t0       " second-to-t0        addi sp,sp,1cell"    evaluate  ;-h
:-h double-tos      " add  tos,tos,tos"                        evaluate  ;-h
:-h third-to-t1     " lwz  t1,1cell(sp)"                       evaluate  ;-h
:-h user#-to-t0     " lwz  t0,/cf(w)"                          evaluate  ;-h
:-h take-branch     " lwz  t0,/branch(ip)  add ip,ip,t0"       evaluate  ;-h
:-h skip-branch     " addi ip,ip,/branch"                      evaluate  ;-h
:-h literal-to-tos  " lwzu tos,/token(ip)"                     evaluate  ;-h
:-h literal-to-t0   " lwzu t0,/token(ip)"                      evaluate  ;-h
:-h rdrop           " addi rp,rp,1cell"                        evaluate  ;-h
:-h rdrop3          " addi rp,rp,3cells"                       evaluate  ;-h

\ We create the shared code for the "next" routine so that:
\ a) It will be in RAM for speed (ROM is often slow)
\ b) We can use the user pointer as its base address, for quick jumping

also forth
compilation-base  here-t			\ Save meta dictionary pointer
0 dp-t !  userarea-t is compilation-base	\ Point it to user area
previous

mlabel (next)   \ Shared code for next; will be copied into user area
   lwzu    w,/token(ip)
   next-tail
end-code

also forth
dp-t !  is compilation-base  previous		\ Restore meta dict. pointer

d# 32 equ #user-init		\ Leaves space for the shared "next"

only forth also labels also meta also assembler definitions

\ assembler macro to assemble next
:-h next   " bcctr   20,0"  evaluate  ;-h

:-h c;  next end-code  ;-h

previous definitions

code-field: docolon
   stwu  ip,-1cell(rp)	\ Push the ip register on the return stack
   mr    ip,w		\ Set ip to apf of the colon definition
c;

code-field: dovariable
   push-tos
   addi  tos,w,/cf	\ Put pfa in top-of-stack register
c;

code-field: dolabel

   push-tos
   addi  tos,w,/cf	\ Put pfa in top-of-stack register
c;

code-field: douser
   push-tos
   user#-to-t0
   add   tos,t0,up	\ Add the base address of the user area
c;

code-field: dovalue
   push-tos
   user#-to-t0
   lwzx  tos,t0,up	\ Get the contents of the user area location
c;

code-field: dodefer
   user#-to-t0
   lwzx  w,t0,up	\ Get the acf stored in that user location
   next-tail
end-code

code-field: doconstant
   push-tos
   lwz   tos,/cf(w)	\ Get the constant's value
c;

code-field: do2constant
   push-tos
   lwzu  tos,/cf(w)	\ Get the constant's value
   push-tos		\ Put it on the memory stack
   lwz   tos,1cell(w)	\ Get the top constant's value
c;

code-field: dodoes
   \ The child word's code field contains the token of dodoes, followed
   \ by the token of the does clause.

   push-tos
   addi  tos,w,/ccf		\ Put pfa in top-of-stack register
   lwz   w,/cf(w)		\ Set w to acf of the definition
   next-tail
end-code

:-h code-cf        ( -- )  here /token + aligned  token,-t  align-t  ;-h
:-h label-cf       ( -- )  dolabel    token,-t  align-t  ;-h
:-h colon-cf       ( -- )  docolon    token,-t  ;-h
:-h constant-cf    ( -- )  doconstant token,-t  ;-h
:-h variable-cf    ( -- )  dovariable token,-t  ;-h
:-h user-cf        ( -- )  douser     token,-t  ;-h
:-h value-cf       ( -- )  dovalue    token,-t  ;-h
:-h defer-cf       ( -- )  dodefer    token,-t  ;-h
:-h startdoes      ( -- )  colon-cf             ;-h
:-h start;code     ( -- )  code-cf		;-h
:-h create-cf      ( -- )  dodoes     token,-t  compile-t noop  ;-h
:-h vocabulary-cf  ( -- )  dodoes     token,-t  compile-t <vocabulary>  ;-h

meta definitions

\ dovariable constant dovariable
\ dodoes     constant dodoes

code (lit)  (s -- n )
   push-tos
   literal-to-tos
c;
code (wlit)  (s -- n )
   push-tos
   literal-to-tos
c;

\ Execute a Forth word given a code field address
code execute   (s acf -- )
   mr      w,tos
   pop-tos
   lwz     t1,0(w)	\ Read the contents of the code field
   next-tail1
end-code

\ High level branch. The branch offset is compiled in-line.
code branch (s -- )
mlabel bran1
   take-branch
c;

\ High level conditional branch.
code ?branch (s f -- )  \ Takes the branch if the flag is false
   cmpi    0,0,tos,0
   pop-tos

   bran1   0= brif

   skip-branch
c;

\ Run time word for loop
code (loop)  (s -- )
   lwz     t0,0(rp)
   addic.  t1,t0,1	\ Increment index
   stw     t1,0(rp)	\ Write back the loop index
   bran1   0>=  brif	\ Result still positive; continue looping
   cmpi    0,0,t0,0	\ Result negative, so check operand
   bran1   0<   brif	\ If operand is negative too, continue looping

   \ The internal "i" value went from positive to negative, so the loop ends
   rdrop3		\ remove loop params from stack
   skip-branch
c;

\ Run time word for +loop
code (+loop) (s increment -- )
   lwz     t0,0(rp)
   add     t1,t0,tos	\ increment loop index
   stw     t1,0(rp)	\ Write back the loop index
   xor.    t3,t0,tos	\ Compare operand signs
   pop-tos
   bran1   0<  brif	\ Operand signs different

   xor.    t2,t1,t0	\ Compare result with an operand
   bran1   0>=  brif	\ Result has same sign as operand; continue looping

   \ The result sign differs from the operand signs; so the loop ends
   rdrop3		\ remove loop params from stack
   skip-branch
c;

\ Run time word for do
code (do)  (s l i -- )
   mr      t1,tos		\ i in t1 
   second-to-t0			\ l in t0
   pop1				\ Finish popping stack
mlabel pd0 ( -- r: loop-end-offset l+0x8000 i-l-0x8000 )
   stwu    ip,-1cell(rp)	\ remember the do offset address
   addi    ip,ip,/branch	\ Skip the do offset
   addis   t0,t0,h#-8000	\ Bias by h#8000.0000
   stwu    t0,-1cell(rp)	\ Push biased limit on return stack
   subfc   t1,t0,t1		\ ( Use subfc for POWER compatibility)
   stwu    t1,-1cell(rp)	\ Push biased index on return stack
c;
meta

\ Run time word for ?do
code (?do)  (s l i -- )
   second-to-t0			\ l in t0
   mr      t1,tos		\ i in t1
   pop1				\ Finish popping stack
   cmp     0,0,t0,t1
   pd0     <>  brif

   take-branch
c;

\ Loop index for current do loop
code i  (s -- n )
   push-tos
   lwz     tos,0(rp)
   lwz     t0,1cell(rp)
   add     tos,tos,t0
c;

\ Loop limit for current do loop
code ilimit  (s -- n )
   push-tos
   lwz     tos,1cell(rp)
   addis   tos,tos,h#-8000	\ Bias by h#8000.0000
c;

\ Loop index for next enclosing do loop
code j   (s -- n )
   push-tos
   lwz     tos,12(rp)
   lwz     t0,16(rp)
   add     tos,tos,t0
c;

\ Loop limit for next enclosing do loop
code jlimit   (s -- n )
   push-tos
   lwz     tos,16(rp)
   addis   tos,tos,h#-8000	\ Bias by h#8000.0000
c;

code (leave)  (s -- )
mlabel pleave
   lwz     ip,2cells(rp)	\ Get the address of the ending offset
   rdrop3			\ get rid of the loop indices

   take-branch
c;

code (?leave)  (s f -- )
   cmpi    0,0,tos,0
   pop-tos
   pleave  0<>  brif
c;

code unloop  ( -- )  rdrop3  c;  \ Discard the loop indices

code (of)  ( selector test -- [ selector ] )
   pop-to-t0		\ Test in tos, Selector in t0
   cmp     0,0,t0,tos
   mr      tos,t0	\ Copy selector to tos
   =  if
      pop-tos		\ Overwrite tos if selector matches
      skip-branch
      next
   then

   take-branch
c;

\ (endof) is the same as branch, and (endcase) is the same as drop,
\ but redefining them this way makes the decompiler much easier.
code (endof)    (s -- )
   take-branch
c;
code (endcase)  (s n -- )
   pop-tos
c;

assembler
mlabel dofalse
   addi    tos,r0,0
   next
meta

\ Convert a character to a digit according to the current base
code digit  (s char base -- digit true | char false )
   mr      t0,tos		\ base in t0
   lwz     tos,0(sp)		\ char in tos
   addic.  tos,tos,h#-30	\ convert to number \  30 is ascii 0
   dofalse 0<  brif		\ Anything less than ascii 0 isn't a digit
   cmpi    0,0,tos,10		\ Test for >= 10
   0>=  if			\ Try for a letter representing a digit
      ascii A ascii 0 -  cmpi    0,0,tos,*
      dofalse <  brif		\ bad if > '9' and < 'A'
      ascii a ascii 0 -  cmpi    0,0,tos,*  \ >= 'a'
      >=  if
         ascii a ascii 0 -  d# 10 -  negate  addi  tos,tos,*
      else
         ascii A ascii 0 -  d# 10 -  negate  addi  tos,tos,*
      then
   then
   cmp     0,0,tos,t0		\ Compare digit to base
   dofalse 0>= brif		\ Error if digit is bigger than base
   stw     tos,0(sp)		\ Replace the char on the stack with the digit
   addi    tos,r0,-1		\ True to indicate success
c;

\ Copy cnt characters starting at from-addr to to-addr.  Copying is done
\ strictly from low to high addresses, so be careful of overlap between the
\ two buffers.

code cmove  ( src dst cnt -- )  \ Copy from bottom to top
   second-to-t0		\ Dst into t0
   third-to-t1		\ Src into t1

   cmpi  0,0,tos,0
   0<> if
      addi  t0,t0,-1    \ Account for pre-incrementing
      addi  t1,t1,-1    \ Account for pre-incrementing
      mfspr t2,ctr	\ Save count register
      mtspr ctr,tos	\ Count in count register
      begin
         lbzu  t3,1(t1)	\ Load byte
	 stbu  t3,1(t0)	\ Store byte
      countdown		\ Decrement & Branch if nonzero
      mtspr ctr,t2	\ Restore count register
   then

   pop2
c;

code cmove>  ( src dst cnt -- )  \ Copy from top to bottom
   second-to-t0		\ Dst into t0
   third-to-t1		\ Src into t1

   cmpi  0,0,tos,0
   0<> if
      add   t0,t0,tos	\ Top of dst range
      add   t1,t1,tos	\ Top of src range
      mfspr t2,ctr	\ Save count register
      mtspr ctr,tos	\ Count in count register
      begin
         lbzu t3,-1(t1)	\ Load byte
	 stbu t3,-1(t0)	\ Store byte
      countdown		\ Decrement & Branch if nonzero
      mtspr ctr,t2	\ Restore count register
   then

   pop2
c;

code lshift  (s n1 cnt -- n2 )  pop-to-t0   slw  tos,t0,tos  c;
code rshift  (s n1 cnt -- n2 )  pop-to-t0   srw  tos,t0,tos  c;
code <<      (s n1 cnt -- n2 )  pop-to-t0   slw  tos,t0,tos  c;
code >>      (s n1 cnt -- n2 )  pop-to-t0   srw  tos,t0,tos  c;
code >>a     (s n1 cnt -- n2 )  pop-to-t0   sraw tos,t0,tos  c;

code and  (s n1 n2 -- n3 )   pop-to-t0   and  tos,tos,t0  c;
code or   (s n1 n2 -- n3 )   pop-to-t0   or   tos,tos,t0  c;
code xor  (s n1 n2 -- n3 )   pop-to-t0   xor  tos,tos,t0  c;

code +    (s n1 n2 -- n3 )   pop-to-t0   add   tos,tos,t0  c;

\ ( Use subfc for POWER compatibility)
code -    (s n1 n2 -- n3 )   pop-to-t0   subfc tos,tos,t0  c;

code min   (s n1 n2 -- n3 )
   pop-to-t0   cmp  0,0,t0,tos   < if   mr tos,t0   then
c;
code max   (s n1 n2 -- n3 )
   pop-to-t0   cmp  0,0,t0,tos   > if   mr tos,t0   then
c;
code umin   (s n1 n2 -- n3 )
   pop-to-t0   cmpl  0,0,t0,tos   < if   mr tos,t0   then
c;
code umax   (s n1 n2 -- n3 )
   pop-to-t0   cmpl  0,0,t0,tos   > if   mr tos,t0   then
c;

code invert  (s n1 -- n2 )   nor tos,tos,tos  c;
code negate  (s n1 -- n2 )   neg tos,tos  c;
code abs   (s n1 -- n2 )   cmpi  0,0,tos,0   0< if  neg tos,tos  then  c;

code up@  (s -- addr )  push-tos  mr tos,up  c;
code sp@  (s -- addr )  push-tos  mr tos,sp  c;
code rp@  (s -- addr )  push-tos  mr tos,rp  c;
code up!  (s addr -- )  mr up,tos  pop-tos  c;
code sp!  (s addr -- )  mr sp,tos  pop-tos  c;
code rp!  (s addr -- )  mr rp,tos  pop-tos  c;

code >r   (s n -- )  stwu tos,-1cell(rp)  pop-tos  c;
code r>   (s -- n )  push-tos  lwz tos,0(rp)  rdrop  c;
code r@   (s -- n )  push-tos  lwz tos,0(rp)  c;

code 2>r  (s n1 n2 -- )
   second-to-t0  stwu t0,-1cell(rp)  stwu tos,-1cell(rp)  pop1
c;
code 2r>  (s -- n1 n2 )
   push-tos  lwz tos,1cell(rp)  push-tos  lwz tos,0(rp)  addi rp,rp,2cells
c;
code 2r@  (s -- n1 n2 )
   push-tos  lwz tos,1cell(rp)  push-tos  lwz tos,0(rp)
c;

code ip>  (s -- n )  push-tos  lwz tos,0(rp)  rdrop  addi tos,tos,/token  c;
code ip@  (s -- n )  push-tos  lwz tos,0(rp)         addi tos,tos,/token  c;
code >ip  (s n -- )  addi tos,tos,-/token  stwu tos,-1cell(rp)  pop-tos  c;
code ip>token  ( ip -- token-adr )  c;

code exit   (s -- )  lwz ip,0(rp)  rdrop  c;
code unnest (s -- )  lwz ip,0(rp)  rdrop  c;

code tuck  (s n1 n2 -- n2 n1 n2 )  second-to-t0  push-t0  stw tos,1cell(sp)  c;
code nip   (s n1 n2 -- n2 )  addi  sp,sp,1cell  c;
code flip  (s w1 -- w2 )  \ byte swap
   rlwinm   t0,tos,24,24,31	\ high half to low half
   rlwimi   t0,tos,8,16,23	\ low to high and insert
   mr       tos,t0
c;

assembler definitions

\ macro to assemble code to leave a flag on the stack
:-h leaveflag  (s condition -- )
  " if  addi tos,r0,-1  else  addi tos,r0,0  then" evaluate
;-h

:-h compare   " pop-to-t0  cmp  0,0,t0,tos" evaluate  ;-h
:-h compareu  " pop-to-t0  cmpl 0,0,t0,tos" evaluate  ;-h
:-h compare0  "            cmpi 0,0,tos,0"  evaluate  ;-h

meta definitions
code 0<   (s n -- f )      compare0  0<  leaveflag  c;
code 0>   (s n -- f )      compare0  0>  leaveflag  c;
code 0<=  (s n -- f )      compare0  0<= leaveflag  c;
code 0>=  (s n -- f )      compare0  0>= leaveflag  c;
code 0=   (s n -- f )      compare0  0=  leaveflag  c;
code 0<>  (s n -- f )      compare0  0<> leaveflag  c;

code =    (s n1 n2 -- f )  compare   =   leaveflag  c;
code <>   (s n1 n2 -- f )  compare   <>  leaveflag  c;

code <    (s n1 n2 -- f )  compare   <   leaveflag  c;
code >=   (s n1 n2 -- f )  compare   >=  leaveflag  c;
code >    (s n1 n2 -- f )  compare   >   leaveflag  c;
code <=   (s n1 n2 -- f )  compare   <=  leaveflag  c;
code u<   (s n1 n2 -- f )  compareu  <   leaveflag  c;
code u>=  (s n1 n2 -- f )  compareu  >=  leaveflag  c;
code u>   (s n1 n2 -- f )  compareu  >   leaveflag  c;
code u<=  (s n1 n2 -- f )  compareu  <=  leaveflag  c;

code drop  (s n -- )      pop-tos    c;
code dup   (s n -- n n )  push-tos   c;
code over  (s n1 n2 -- n1 n2 n1 )  push-tos  lwz tos,1cell(sp)  c;
code swap  (s n1 n2 -- n2 n1 )  second-to-t0  stw tos,0(sp)  mr tos,t0  c;
code rot  (s n1 n2 n3 -- n2 n3 n1 )
   second-to-t0
   third-to-t1
   stw  t0,1cell(sp)
   stw  tos,0(sp)
   mr   tos,t1
c;
code -rot  (s n1 n2 n3 -- n3 n1 n2 )
   second-to-t0
   third-to-t1
   stw  tos,1cell(sp)
   stw  t1,0(sp)
   mr   tos,t0
c;
code 2drop  (s d -- )   pop1  c;
code 2dup   (s d -- d d )  second-to-t0  push-tos  push-t0  c;
code 2over  (s d1 d2 -- d1 d2 d1 )
   push-tos
   lwz  tos,12(sp)
   push-tos
   lwz  tos,12(sp)
c;
code 2swap  (s d1 d2 -- d2 d1 )
   lwz  t2,2cells(sp)
   third-to-t1
   second-to-t0
   stw  t0,2cells(sp)
   stw  tos,1cell(sp)
   stw  t2,0(sp)
   mr   tos,t1
c;
code 3drop  (s n1 n2 n3 -- )  pop2  c;
code 3dup   (s n1 n2 n3 -- n1 n2 n3 n1 n2 n3 )
   third-to-t1
   second-to-t0
   push-tos
   stwu t1,-1cell(sp)
   push-t0
c;
code 4drop  (s n1 n2 n3 n4 -- )
   lwz  tos,3cells(sp)   addi sp,sp,4cells
c;
code 5drop  (s n1 n2 n3 n4 n5 -- )
   lwz  tos,4cells(sp)   addi sp,sp,5cells
c;

code pick   (s nm ... n1 n0 k -- nm ... n2 n0 nk )
   add   tos,tos,tos
   add   tos,tos,tos  \ Multiply by /n
   lwzx  tos,tos,sp
c;  
 
code 1+  (s n1 -- n2 )  addi  tos,tos,1   c;
code 2+  (s n1 -- n2 )  addi  tos,tos,2   c;
code 1-  (s n1 -- n2 )  addi  tos,tos,-1  c;
code 2-  (s n1 -- n2 )  addi  tos,tos,-2  c;

code 2/  (s n1 -- n2 )  srawi tos,tos,1   c;
code u2/ (s n1 -- n2 )  rlwinm tos,tos,31,1,31  c;
code 4/  (s n1 -- n2 )  srawi tos,tos,2   c;
code 2*  (s n1 -- n2 )  rlwinm tos,tos,1,0,30  c;
code 4*  (s n1 -- n2 )  rlwinm tos,tos,2,0,29  c;
code 8*  (s n1 -- n2 )  rlwinm tos,tos,3,0,28  c;

code on  (s addr -- )  addi t0,r0,-1  stw t0,0(tos)  pop-tos  c;
code off (s addr -- )  addi t0,r0,0   stw t0,0(tos)  pop-tos  c;

code +!  (s n addr -- )
   second-to-t0
   lwz  t1,0(tos)
   add  t1,t1,t0
   stw  t1,0(tos)
   pop1
c;

code @    (s adr -- n )  lwz tos,0(tos)  c; \ longword aligned
code l@   (s adr -- l )  lwz tos,0(tos)  c; \ longword aligned
code w@   (s adr -- w )  lhz tos,0(tos)  c; \ 16-bit word aligned
code <w@  (s adr -- w )  lha tos,0(tos)  c; \ with sign extension
code c@   (s adr -- c )  lbz tos,0(tos)  c;
code be-w@   ( a -- w )
   lbz t0,0(tos)
   lbz tos,1(tos)
   rlwimi tos,t0,8,16,23
c;
code le-w@   ( a -- w )
   lbz t0,1(tos)
   lbz tos,0(tos)
   rlwimi tos,t0,8,16,23
c;

code !   (s n adr -- )  second-to-t0  stw t0,0(tos)  pop1  c;
code l!  (s n adr -- )  second-to-t0  stw t0,0(tos)  pop1  c;
code w!  (s w adr -- )  second-to-t0  sth t0,0(tos)  pop1  c;
code c!  (s c adr -- )  second-to-t0  stb t0,0(tos)  pop1  c;
code be-w!   ( w a -- )
   second-to-t0
   rlwinm  t1,t0,24,24,31	\ high byte
   stb t1,0(tos)
   stb t0,1(tos)
   pop1
c;
code le-w!   ( w a -- )
   second-to-t0
   rlwinm  t1,t0,24,24,31	\ high byte
   stb t1,1(tos)
   stb t0,0(tos)
   pop1
c;

[ifdef] 64bit-hardware
[else]
\ XXX Use 64-bit oper
: d@  (s adr -- low high )  dup na1+ @  swap @  ;
: d!  (s low high adr -- )  tuck !  na1+ !  ;
[then]

: instruction!  (s n adr -- )  tuck !  /l sync-cache  ;

code 2@  (s adr -- d )  lwz t0,1cell(tos)  push-t0  lwz tos,0(tos)  c;
code 2!  (s d adr -- )
   second-to-t0
   stw  t0,0(tos)
   lwz  t0,1cell(sp)
   stw  t0,1cell(tos)
   pop2
c;

code fill (s start-adr count char -- )
			\ char in tos
   second-to-t0	\ count in t0
   third-to-t1	\ dst in t1
    
   cmpli  0,0,t0,h#1000	\ Optimize only if the count is large
   >=  if
      or    r0,t1,t0	\ Collect low bits of count and address
      andi. r0,r0,3	\ Optimize only if the address and count are aligned
      0=  if
         addi  t1,t1,-1cell		\ Account for pre-increment
         rlwinm  t0,t0,30,2,31		\ Divide count by 4
         rlwimi  tos,tos,8,16,23	\ Replicate low byte into low halfword
         rlwimi  tos,tos,16,0,15	\ Replicate low halfword into word
         mfspr t2,ctr	\ Save CTR
         mtspr ctr,t0
         begin
            stwu tos,1cell(t1)
         countdown
         mtspr ctr,t2

         pop2 next
      then

   then

   cmpi 0,0,t0,0
   0<> if
      addi  t1,t1,-1	\ Account for pre-increment
      mfspr t2,ctr	\ Save CTR
      mtspr ctr,t0
      begin
         stbu tos,1(t1)	\ Store byte
      countdown		\ Decrement and Branch if nonzero
      mtspr ctr,t2
   then

   pop2
c;

code noop (s -- )  c;

code lowbyte   (s n -- low )   andi. tos,tos,h#ff  c;

code wbsplit   (s w -- b.low b.high )   \ split a word into two bytes
   andi. t0,tos,h#ff
   push-t0
   rlwinm  tos,tos,24,24,31
c;
code bwjoin   (s b.low b.high -- w )
   pop-to-t0
   andi. t0,t0,h#ff
   rlwimi t0,tos,8,16,23
   mr     tos,t0
c;
code lwsplit   (s l -- w.low w.high )  \ split a long into two words
   andi. t0,tos,h#ffff
   push-t0
   rlwinm  tos,tos,16,16,31
c;
code wljoin   (s w.low w.high -- l )
   pop-to-t0
   rlwimi t0,tos,16,0,15
   mr     tos,t0
c;

1 constant /c
2 constant /w
4 constant /l
/l constant /n

code ca+  (s addr index -- addr+index*/c )
   pop-to-t0
   add  tos,tos,t0
c;
code wa+  (s addr index -- addr+index*/w )
   pop-to-t0
   add  tos,tos,tos
   add  tos,tos,t0
c;
code la+  (s addr index -- addr+index*/l )
   pop-to-t0
   add  tos,tos,tos
   add  tos,tos,tos
   add  tos,tos,t0
c;
code na+  (s addr index -- addr+index*/n )
   pop-to-t0
   add  tos,tos,tos
   add  tos,tos,tos
   add  tos,tos,t0
c;
code ta+  (s addr index -- addr+index*/t )
   pop-to-t0
   add  tos,tos,tos
   add  tos,tos,tos
   add  tos,tos,t0
c;

code ca1+  (s addr -- addr+/w )      addi tos,tos,1       c;
code char+ (s addr -- addr+/w )      addi tos,tos,1       c;
code wa1+  (s addr -- addr+/w )      addi tos,tos,2       c;
code la1+  (s addr -- addr+/l )      addi tos,tos,4       c;
code na1+  (s addr -- addr+/n )      addi tos,tos,1cell   c;
code cell+ (s addr -- addr+/n )      addi tos,tos,1cell   c;
code ta1+  (s addr -- addr+/token )  addi tos,tos,/token  c;

code /c*   (s n -- n*/c )  c;
code chars (s n -- n*/c )  c;
code /w*   (s n -- n*/w )  add  tos,tos,tos  c;
code /l*   (s n -- n*/l )  add  tos,tos,tos  add  tos,tos,tos  c;
code /n*   (s n -- n*/n )  add  tos,tos,tos  add  tos,tos,tos  c;
code cells (s n -- n*/n )  add  tos,tos,tos  add  tos,tos,tos  c;

code upc   (s char -- upper-case-char )
   ascii a   cmpi 0,0,tos,*  >= if
      ascii z   cmpi 0,0,tos,*  <= if
	 addi tos,tos,h#-20
      then
   then
c;
code lcc   (s char -- upper-case-char )
   ascii A   cmpi 0,0,tos,*  >= if
      ascii Z   cmpi 0,0,tos,*  <= if
	 addi tos,tos,h#20
      then
   then
c;

code c@+  (s adr -- adr' char )  addi t0,tos,1  push-t0  lbz tos,0(tos)  c;

code comp  ( addr1 addr2 len -- -1 | 0 | 1 )
   second-to-t0		\ addr2
   third-to-t1		\ addr1
   addi sp,sp,2cells
   mr t2,tos		\ len
   set tos,0		\ default result
   
   addi  t0,t0,-1    \ Account for pre-incrementing
   addi  t1,t1,-1    \ Account for pre-incrementing
   begin
      cmpi  0,0,t2,0   0<> while
      addi  t2,t2,-1
      lbzu  t3,1(t0)	\ Load byte
      lbzu  t4,1(t1)	\ Load byte
      cmp  0,0,t3,t4  <> if	\ mismatch
	 < if  addi tos,tos,1  else  addi tos,tos,-1  then
	 next
      then
    repeat
c;

: caps-comp  (s addr1 addr2 len -- -1 | 0 | 1 )
\ XXX optimize me
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

code pack  ( str-adr len dest -- dest )
   second-to-t0		\ len
   third-to-t1		\ str-adr
   addi  sp,sp,2cells
   mr  t2,tos		\ dest
   stb  t0,0(tos)	\ requires length < 256
   
   cmpi  0,0,t0,0
   0<> if
      addi  t1,t1,-1	\ Account for pre-incrementing
      mfspr t4,ctr	\ Save count register
      mtspr ctr,t0	\ Count in count register
      begin
         lbzu  t3,1(t1)	\ Load byte
	 stbu  t3,1(t2)	\ Store byte
      countdown		\ Decrement & Branch if nonzero
      set   t3,0
      stbu  t3,1(t2)	\ Store a null byte at the end
      mtspr ctr,t4	\ Restore count register
   then
c;

code (')  (s -- acf )  push-tos  literal-to-tos  add tos,tos,base  c;

\ Modifies caller's ip to skip over an in-line string
code skipstr (s -- adr len)
   push-tos
   lwz   t0,0(rp)	\ Get string address in t0
   lbzu  tos,/token(t0)	\ Get length byte in tos
   addi  t0,t0,1	\ Address of data bytes
   push-t0	\ Push adr

   \ Now we have to skip the string
   add   t0,t0,tos	\ Scr now points past the last data byte

\ ! We don't want to add 4 because IP is pre-incremented inside NEXT
\  addi  t0,t0,4	\ Round up to token boundary + null byte (4= #align)

   rlwinm t0,t0,0,0,29	\ Round down to token boundary
   stw   t0,0(rp)	\ Put the modified ip back
c;

code (")  (s -- adr len)
   push-tos
   lbzu  tos,/token(ip)	\ Get length byte in tos
   addi  ip,ip,1	\ Address of data bytes
   stwu  ip,-1cell(sp)	\ Push adr

   \ Now we have to skip the string
   add   ip,ip,tos	\ ip now points past the last data byte

\ ! We don't want to add 4 because IP is pre-incremented inside NEXT
\  addi  ip,ip,4	\ Round up to a token boundary, plus null byte (#talign

   rlwinm ip,ip,0,0,29
c;

code (n")  (s -- addr len )
   push-tos
   lwzu  tos,/token(ip)	\ Get length byte in tos
   addi  ip,ip,1cell	\ Address of data bytes
   stwu  ip,-1cell(sp)	\ Push adr

   \ Now we have to skip the string
   add   ip,ip,tos	\ ip now points past the last data byte

\ ! We don't want to add 4 because IP is pre-incremented inside NEXT
\  addi  ip,ip,4	\ Round up to a token boundary, plus null byte (#talign

   rlwinm ip,ip,0,0,29
c;

code count  (s adr -- adr+1 len )
   addi  tos,tos,1
   lbz   t0,-1(tos)
   push-tos
   mr    tos,t0
c;
code ncount  (s adr -- adr+1cell len )
   addi  tos,tos,1cell
   lwz   t0,-1cell(tos)
   push-tos
   mr    tos,t0
c;

code origin  (s -- addr )  push-tos  mr tos,base  c;

code origin+  (s n -- adr )  add  tos,base,tos  c;
code origin-  (s n -- adr )  subf tos,base,tos  c;

: acf-align  (s -- )
   begin  here #acf-align 1- and  while  0 c,  repeat
   here 'lastacf token!
;

headerless

\ Place the "standard" code field

: set-cf  (s action-adr -- )  acf-align  origin+  token,  ;

headers
\ : place-cf  (s action-adr -- )  acf-align  token,  ;
\ This is only used in action: .  We define it as a no-op so that
\ "doaction" can do all the work.
: place-cf  (s -- )  ;

\ Create code field for code word
: code-cf  (s -- )  acf-align  here ta1+  aligned token,  align  ;

: >code  ( acf-of-code-word -- address-of-start-of-machine-code )  token@  ;
: code?  ( acf -- f )  \ True if the acf is for a code word
   dup token@  swap >body =
;

\ Assemble "next" routine at the end of a code definition.
\ This is not needed for the kernel to run; it is used later
\ after the resident assembler has been loaded

: next  (s -- )
   here  /l allot  h# 4e800420 swap instruction!	( "bcctr 20,0" )
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

: branch@  ( where -- offset )  @  ;
\ >target depends on the way that branches are compiled
: >target  ( ip-of-branch-instruction -- target )  ta1+ dup branch@ +  ;
headerless

/a constant /a

headers

code a@  ( adr -- adr' )
   lwz  tos,0(tos)
   add  tos,tos,base
c;

\ R : a!  ( adr1 adr2 -- )  set-relocation-bit  l!  ;
code a!  ( adr1 adr2 -- )
   pop-to-t0
   subfc t0,base,t0	\ ( Use subfc for POWER compatibility)
   stw  t0,0(tos)
   pop-tos
c;
: a,  ( adr -- )  here  /a allot  a!  ;

/token constant /token
code token@ (s adr -- cfa )  lwz tos,0(tos)  add tos,tos,base  c;
\ R : token! (s cfa adr -- )  set-relocation-bit l!  ;
code token! (s cfa addr -- )
   second-to-t0
   subfc t0,base,t0	\ ( Use subfc for POWER compatibility)
   stw  t0,0(tos)
   pop1
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
\    false t0  mr       \ Delay slot
\ 
\       push-tos
\       true t0 mr
\    then
\    t0  tos  mr
\ c;
: get-token?     ( adr -- false | acf  true )  token@ non-null?  ;
: another-link?  ( adr -- false | link true )  link@  non-null?  ;

\ The "word type" is a number which distinguishes one type of word
\ from another.  This is highly implementation-dependent.

\ For the PowerPC implementation, the magic number returned by word-type
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
   addi  tos,tos,3
\   addi  t0,r0,-4
\   and   tos,tos,t0
   rlwinm tos,tos,0,0,29
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

\ 64-bit addition and subtraction
: dabs  ( d# -- d# )  dup 0<  if  dnegate  then  ;
: dmax  ( d1 d2 -- d3 )  2over 2over  d-  nip 0<  if  2swap  then  2drop  ;

code d+  ( d1 d2 -- d3 )
   lwz    t1,0(sp)	\ d2.low
   lwz    t3,2cells(sp)	\ d1.low
   lwz    t2,1cell(sp)	\ d1.high
   addi   sp,sp,2cells	\ Pop args
   addc   t1,t1,t3	\ d3.low
   adde   tos,tos,t2	\ d3.high
   stw    t1,0(sp)	\ Push result (d3.high already in tos)
c;
code d-  ( d1 d2 -- d3 )
   lwz    t1,0(sp)	\ x2.low
   lwz    t2,1cell(sp)	\ x1.high
   lwz    t3,2cells(sp)	\ x1.low
   addi   sp,sp,2cells	\ Pop args
   subfc  t1,t1,t3	\ x3.low
   subfe  tos,tos,t2	\ x3.high
   stw    t1,0(sp)	\ Push result (x3.high already in tos)
c;
code s>d  ( n -- d )  push-tos  srawi tos,tos,31  c;
code dnegate  ( d -- -d )
   second-to-t0
   subfic t0,t0,0
   stw    t0,0(sp)
   subfze tos,tos
c;

only forth also labels also meta also assembler definitions

:-h 'user#  \ name  ( -- user# )
    [ meta ]-h  '  ( acf-of-user-variable )  >body-t
    @-t
;-h
:-h 'user  \ name  ( -- user-addressing-mode )
    [ also assembler also register-names ]-h   'user#  up 
    [ previous previous ]-h
;-h
:-h 'body  \ name  ( -- variable-apf )
    [ meta ]-h  '  ( acf-of-user-variable )  >body-t
;-h
:-h 'acf  \ name  ( -- variable-apf )
    [ meta ]-h  '  ( acf-of-user-variable )  >body-t
;-h
 
only forth also labels also meta also definitions

: m+    ( d1|ud1 n -- )  s>d  d+  ;

fload ${BP}/forth/kernel/dmuldiv.fth

: m/mod   (s l.dividend n.divisor -- n.remainder n.quotient )    fm/mod  ;

code *  ( n1 n2 -- n3 )  pop-to-t0  mullw tos,t0,tos  c;

: ul*    (s un1 un2 -- lproduct )  *  ;
: u*     (s un1 un2 -- uproduct )  *  ;


\ PowerPC version is dynamically relocated, so we don't need a bitmap
: clear-relocation-bits  ( adr len -- )  2drop  ;

: move  ( src dst cnt -- )
   >r 2dup u<  if  r> cmove>  else  r> cmove  then
;

init-user-area constant init-user-area

code (llit)  (s -- l )  push-tos  literal-to-tos  c;
code (dlit)  (s -- d )  push-tos  literal-to-tos  literal-to-t0  push-t0  c;

\ Select a vocabulary thread by hashing the lookup name.
\ Hashing function:  Use the lower bits of the first character in the
\ name to select one of #threads threads in the array pointed-to by
\ the user number in the parameter field of voc-acf.
code hash  (s str-addr voc-acf -- thread )
   \ The next 2 lines are equivalent to ">threads", which in this
   \ implementation happens to be the same as ">body >user"
   lwz  tos,/ccf(tos)	\ Get the user number
   add  tos,tos,up	\ Find the address of the threads

   pop-to-t0	\ str-adr in t0
   lbz  t0,1(t0)	\ First byte of string
   #threads-t 1-  andi. t0,t0,*	\ Extract low bits
   add  t0,t0,t0
   add  t0,t0,t0	\ Convert index to longword offset
   add  tos,tos,t0
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
   pop-tos	\ link in tos

\ Registers:
\ tos    alf of word being tested
\ t0    string
\ t1    name being tested
\ t2    # of characters left to test
\ string is kept on the top of the external stack

\   1 F: always brif		\ Branch to test at end of list
\   begin
    begin   cmp   0,0,tos,base <> while  
      addi  t1,tos,/token	\ Get name address of word to test
      second-to-t0	   	\ Get string address
      lbz   t2,0(t0)		\ get the name field length
      addi  t0,t0,-1		\ Account for pre-increment
      addi  t1,t1,-1		\ Account for pre-increment
      begin
         lbzu  t3,1(t0)		\ Compare 2 characters
         lbzu  t4,1(t1)
      cmp 0,0,t3,t4  = while	\ Keep looking as long as characters match
         addic. t2,t2,-1	\ Decrement byte counter
         0< if			\ If we've tested all chars, the names match.
            lbzu  tos,1(t1)	\ Get flags byte into tos register

            addi  t1,t1,/cf	\ Now find the code field by
\           addi  t2,r0,-/cf
\           and   t1,t1,t2	\ aligning to the next 4 byte boundary
	    rlwinm t1,t1,0,0,29

	    andi. t2,tos,h#20	\ Test the alias flag
	    0<> if
	       lwz  t1,0(t1)	\ Get acf
               add  t1,t1,base	\ Relocate
            then

            stw   t1,0(sp)	\ Replace string on stack with acf
	    andi. t2,tos,h#40	\ Test the immediate flag
	    0<> if
	       addi tos,r0,1	\ Immediate
	    else
               addi tos,r0,-1	\ Not immediate
	    then
	    next
         then
      repeat

      \ The names did not match, so check the next name in the list
      lwz  tos,0(tos)		\ Fetch next link  ( next acf )
      add  tos,tos,base		\ Relocate
1 L:
\      cmp   0,0,tos,base
\   = until
repeat

   \ If we get here, we've checked all the names with no luck
   addi  tos,r0,0
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

   lwz   t0,1cell(sp)		\ Get string address
   lwz   t5,0(sp)		\ get the name field length
   addi  t0,t0,-1		\ Account for pre-increment

   mfspr  t2,ctr		\ Save CTR register

   ahead
   begin
      addi   tos,tos,-/token	\ >link
      addi   t1,tos,-2		\ t1 points before count byte at string *end*
      subfc  t1,t5,t1		\ t1 points to beginning of string
				\ ( Use subfc for POWER compatibility)
      mr     t6,t0
      
      mtspr  ctr,t5		\ Set starting loop index
      begin
         lbzu  t4,1(t1)		\ Get character from name field
         lbzu  t3,1(t6)		\ Get character from search string
         cmp   0,0,t3,t4	\ Compare 2 characters
      bc 8,2,*			\ Branch while characters match and count non0

      = if			\ If we've tested all name chars, we
         lbzu  t4,1(t1)		\ may have a match; check the count byte
         andi. t4,t4,h#1f
         cmp   0,0,t4,t5	\ Compare count bytes
         = if
            push-tos		\ Push alf above pstr
            addi   tos,r0,-1	\ True on top of stack means "found"
            mtspr  ctr,t2	\ Restore CTR register
            next
         then
      then

   but then
      \ The names did not match, so check the next name in the list
      lwz   tos,0(tos)		\ Fetch next link  ( next acf )
      add   tos,tos,base	\ Relocate
      cmp   0,0,tos,base
   = until

   \ If we get here, we've checked all the names with no luck
   addi   tos,r0,0
   mtspr  ctr,t2		\ Restore CTR register
c;

: ?negate  (s n1 n2 -- n3 )  if  negate  then  ;

code wflip (s l1 -- l2 )  \ word swap
   rlwinm  t0,tos,16,16,31	\ high half to low half
   rlwimi  t0,tos,16,0,15	\ low to high and insert
   mr      tos,t0
c;

code lwflip  ( l -- l' )
   rlwinm t0,tos,16,0,15
   rlwimi t0,tos,16,16,31
   mr     tos,t0
c;

code lbflip  ( l -- l' )
   rlwinm t0,tos,24,0,7
   rlwimi t0,tos,8,8,15
   rlwimi t0,tos,24,16,23
   rlwimi t0,tos,8,24,31
   mr     tos,t0
c;

code wbflip  ( w -- w' )
   rlwinm t0,tos,8,16,23
   rlwimi t0,tos,24,24,31
   mr     tos,t0
c;

code lwflips  ( adr len -- )
   lwz     t0,0(sp)	\ adr in t0, len in tos

   addi    tos,tos,3		\ Round up to longword boundary
   rlwinm. tos,tos,30,2,31	\ Divide by 4

   0<>  if
      addi    t0,t0,-4		\ Account for pre-increment
      addi    r0,r0,0

      mtspr   ctr,tos

      begin
         lwzu   t1,4(t0)		\ Load one way
         rlwinm t2,t1,16,0,15
	 rlwimi t2,t1,16,16,31
         stw    t2,0(t0)		\ Store the other
      countdown

      mtspr   ctr,up
   then

   lwz     tos,1cell(sp)
   addi    sp,sp,2cells
c;

code lbflips  ( adr len -- )
   lwz     t0,0(sp)	\ adr in t0, len in tos

   addi    tos,tos,3		\ Round up to longword boundary
   rlwinm. tos,tos,30,2,31	\ Divide by 4

   0<>  if
      addi    t0,t0,-4		\ Account for pre-increment
      addi    r0,r0,0

      mtspr   ctr,tos

      begin
         lwzu   t1,4(t0)		\ Load one way
         stwbrx t1,r0,t0		\ Store the other
      countdown

      mtspr   ctr,up
   then

   lwz     tos,1cell(sp)
   addi    sp,sp,2cells
c;

code wbflips  ( adr len -- )
   lwz     t0,0(sp)		\ adr in t0, len in tos

   addi    tos,tos,1		\ Round up to longword boundary
   rlwinm. tos,tos,31,1,31	\ Divide by 4

   0<>  if
      addi    t0,t0,-2		\ Account for pre-increment
      addi    r0,r0,0

      mtspr   ctr,tos

      begin
         lhzu   t1,2(t0)	\ Load one way
         sthbrx t1,r0,t0	\ Store the other
      countdown

      mtspr   ctr,up
   then

   lwz     tos,1cell(sp)
   addi    sp,sp,2cells
c;

\ these are not used. remove?
: cset     (s byte-mask adr -- )  tuck c@ or swap c!  ;
: creset   (s byte-mask adr -- )  swap invert over c@ and swap c!  ;
: ctoggle  (s byte-mask adr -- )  tuck c@ xor swap c!  ;
: toggle   (s adr byte-mask -- )  swap ctoggle  ;


code s->l  (s n.signed -- l )   c;
code n->l  (s n.unsigned -- l )  c;
code n->a  (s n -- a )  c;
code l->n  (s l -- n )  c;
code l->w  (s l -- w )  andi.  tos,tos,h#ffff  c;
code n->w  (s n -- w )  andi.  tos,tos,h#ffff  c;
code w->l  (s w -- l )
   andi.  t0,tos,h#8000   0<> if
      set  t1,h#ffff.0000
      or   tos,tos,t1
   then
c;


code l>r   (s l -- )    stwu  tos,-1cell(rp)  pop-tos  c;
code lr>   (s -- l )    push-tos  lwz tos,0(rp)  rdrop  c;
code lr@   (s -- l )    push-tos  lwz tos,0(rp)  c;

code /t* (s n -- n*/t )  add  tos,tos,tos   add  tos,tos,tos   c;

[ifdef] oldmeta
: >name   ( acf -- anf )
   1- begin  1-  dup c@  bl >  until	\ Find the end of the name
   /token 1- invert and			\ Move to token boundary
   begin  dup c@  bl >=  while  /token -  repeat
;
[then]
#align-t     constant #align
#acf-align-t constant #acf-align
#talign-t    constant #talign

: align  (s -- )  #align (align)  ;
: taligned  (s adr -- adr' )  #talign round-up  ;
: talign  (s -- )  #talign (align)  ;

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
