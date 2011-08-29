purpose: Defining words for code definitions
\ See license at end of file

\ These words are specific to the virtual machine implementation
: assembler  ( -- )  arm-assembler  ;

variable pre-asm-base
: stash-base    base @ pre-asm-base ! ;
: restore-base  pre-asm-base @ base ! ;

only forth also arm-assembler also helpers also arm-assembler also definitions

\ Forth Virtual Machine registers

\ also register-names definitions
\ Convenient register names for portable programming
: base  r7  ;
: up    r9  ;
: tos   r10 ;
: rp    r11 ;
: ip    r12 ;
: sp    r13 ;
: lk    r14 ;
: lr    r14 ;
: pc    r15 ;
\ previous definitions

\ also constant-names definitions
\ also register-names definitions

: asm-con:  ( n "name" -- )  create ,  does> @ adt-immed  ;
/n               asm-con:  1cell	\ Offsets into the stack
1cell drop  -1 * asm-con: -1cell
1cell drop  -1 * asm-con: ~1cell
1cell drop   2 * asm-con:  2cells
1cell drop   3 * asm-con:  3cells
1cell drop   4 * asm-con:  4cells

1cell drop       asm-con:  /cf	\ Size of a code field (except for "create")
/cf   drop  -1 * asm-con: -/cf
/cf   drop  -1 * asm-con: ~/cf

1cell drop       asm-con:  /token	\ Size of a compiled word reference
/token drop -1 * asm-con: -/token
/token drop -1 * asm-con: ~/token

1cell drop       asm-con:  /branch	\ Size of a branch offset

/token drop  2 * asm-con:  /ccf	\ Size of a "create" code field

/cf drop  1cell drop  + asm-con:  /cf+1cell \ Location of second half of 
previous definitions

\ The next few words are already in the forth vocabulary;
\ we want them in the assembler vocabulary too
alias next  next
headerless
: exitcode  ( -- )
   ['] $interpret-do-undefined is $do-undefined
   previous
   restore-base
;
' exitcode is do-exitcode
headers
alias c;  c;

: set-offset  ( offset -- )  d# 12 ?#bits iop  ;
: 'body   ( "name" -- variable-apf  adt-immed )  ' >body    adt-immed  ;
: 'code   ( "name" -- code-word-acf adt-immed )  '          adt-immed  ;
: 'user#  ( "name" -- user#         adt-immed )  ' >body @  adt-immed  ;
: 'user  ( "name" -- )
\   [ also register-names ] up [ previous ] drop  ( reg# )
   up drop rb-field
   'user#				     ( value adt-immed )
   drop  set-offset
;
\ lnk{cond}{s}      rN
\ is equivalent to
\ mov{cond}         rN,lk
: lnk  ( -- )
\   [ also register-names ] lk [ previous ]  drop  ( reg# )
   lk drop  ( reg# )
   01a0.0000 or  {cond/s}  op( get-r12 )op
;

: (incdec)  ( op-template -- )
   {cond/s}
   op(
   get-register  dup rd-field  rb-field
   get-opr2
   )op
;

\ inc{cond}{s}      rN,<immed>
\ is equivalent to
\ add{cond}{s}      rN,rN,<immed>
: inc  ( -- )  0080.0000  (incdec)  ;

\ dec{cond}{s}      rN,<immed>
\ is equivalent to
\ sub{cond}{s}      rN,rN,<immed>
: dec  ( -- )  0040.0000  (incdec)  ;

: (pshpop)  ( op-template -- )  {cond}  op( get-r12 get-r16 )op  ;
\ psh{cond}      rN,rM
\ is equivalent to
\ str{cond}      rN,[rM,-1cell]!
: psh  ( -- )  0520.0004 (pshpop)  ;

\ pop{cond}      rN,rM
\ is equivalent to
\ ldr{cond}      rN,[rM],1cell
: pop  ( -- )  0490.0004 (pshpop)  ;

\ nxt{cond}
\ is equivalent to
\ mov{cond}      pc,up
: nxt  ( -- )
\   [ also register-names ] up [ previous ]  drop  ( reg# )
   up drop
   01a0.f000 or  {cond/s}  op( )op
;

also forth definitions
headerless
: entercode  ( -- )
   stash-base
   decimal
   also assembler
\   false is disassembling?
   [ also helpers ]
   ['] $arm-assem-do-undefined is $do-undefined   
   [ previous ]
;
' entercode is do-entercode

headers
\ "code" is defined in the kernel

: label  \ name  ( -- )
   create  !csp  entercode
;
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
