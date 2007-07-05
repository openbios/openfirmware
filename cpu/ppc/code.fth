purpose: Assembler extensions to create Forth words
\ See license at end of file

\ These words are specific to the virtual machine implementation
: assembler  ( -- )  ppc-assembler  ;

only forth also assembler also definitions

\ Forth Virtual Machine registers

also register-names definitions
decimal
: t0   20 ;  : t1 21 ;  : t2  22 ;  : t3 23 ;  : t4 24 ;  : t5 25 ;
: t6   19 ;  : t7 18 ;  : t8  17 ;  : t9 16 ;
: base 26 ;  : up 27 ;  : tos 28 ;  : ip 29 ;  : rp 30 ;  : sp 31 ;
: w    t5 ;
previous definitions

also constant-names definitions

/n          constant  1cell	\ Offsets into the stack
1cell  -1 * constant -1cell
1cell   2 * constant  2cells
1cell   3 * constant  3cells
1cell   4 * constant  4cells

1cell       constant  /cf	\ Size of a code field (except for "create")
/cf    -1 * constant -/cf

1cell       constant  /token	\ Size of a compiled word reference
/token -1 * constant -/token

1cell       constant  /branch	\ Size of a branch offset

/token  2 * constant  /ccf	\ Size of a "create" code field

/cf 1cell + constant  /cf+1cell \ Location of second half of 
previous definitions

\ The next few words are already in the forth vocabulary;
\ we want them in the assembler vocabulary too
alias next  next
headerless
: exitcode  ( -- )
   ['] $interpret-do-undefined is $do-undefined
   previous
;
' exitcode is do-exitcode
headers
alias c;  c;

: 'user#  \ name  ( -- user# )
   '  ( acf-of-user-variable )  >body @
;
: 'user  \ name  ( -- user-addressing-mode )
   [ also ppc-assembler also register-names ]
   'user#  up    
   [ previous previous ]
;
: 'body  \ name  ( -- variable-apf-offset )
   '  ( acf-of-user-variable )  >body  origin -
;
: 'acf  \ name  ( -- variable-acf-offset )
   '  ( acf-of-user-variable )  origin -
;

also forth definitions
: entercode  ( -- )
   also assembler
   false is disassembling?
   ['] $ppc-assem-do-undefined is $do-undefined   
;
' entercode is do-entercode

\ "code" is defined in the kernel

: label  \ name  ( -- )
   create  !csp  entercode
;
only forth also definitions

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
