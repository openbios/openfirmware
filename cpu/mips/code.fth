purpose: Assembler macros specific to the virtual machine implementation
\ See license at end of file

: assembler  ( -- )  mips-assembler  ;

: asm(  also assembler  ; immediate
: )asm  previous  ; immediate

only forth also assembler also definitions

\ Forth Virtual Machine registers

: np s1 ;  : base s2 ;  : up s3 ;  : tos s4 ;  : ip s5 ;  : rp s6 ;  : sp $sp ;

: w t0 ;

\ Macros:

\ Put a bubble in the pipeline.  Used between a load instruction and an
\ immediately-following instruction that uses the load destination register.
: bubble  ( -- )  nop  ;

: get   ( ptr dst -- )  0      swap  lw   ;
: put   ( src ptr -- )  0            sw   ;
: move  ( src dst -- )  0      swap  addu  ;
: ainc  ( ptr -- )      dup 4  swap  addiu  ;
: adec  ( ptr -- )      dup -4 swap  addiu  ;
: push  ( src ptr -- )  dup          adec  put  ;
: pop   ( ptr dst -- )  over   -rot  get   ainc  ;

: cmp   ( src dst -- )  $at     subu  ;
: cmpi  ( src imm -- )  negate  $at  addiu  ;

: apf   ( ptr dst -- )  w 4  ;

\ The next few words are already in the forth vocabulary;
\ we want them in the assembler vocabulary too
alias next  next
' previous is do-exitcode
headers
alias c;  c;

: 'user#  \ name  ( -- user# )
    '      ( acf-of-user-variable )
    >body  ( apf-of-user-variable )
    @      ( user# )
;
: 'user  \ name  ( -- user-addressing-mode )
   up  'user#
;
: 'body  \ name  ( -- variable-apf-offset )
   '  ( acf-of-user-variable )  >body  origin -
;
: 'acf  \ name  ( -- variable-acf-offset )
   '  ( acf-of-user-variable )  origin -
;
: end-code ( -- )
   [ forth ]
   previous
\   flush-cache		\ Make new code available for instruction fetches
   sp@ csp @ <>  if  last a@ .id ." : stack depth changed" cr  then
   current token@ context token!   \ go back to old context
;

also forth definitions
headerless
: entercode  ( -- )
   also assembler
   [ also assembler ]  here delay-barrier !  [ previous ]
;
' entercode is do-entercode

headers
\ "code" is defined in the kernel

: label  \ name  ( -- )
   create  !csp  entercode
;
only forth also definitions

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
