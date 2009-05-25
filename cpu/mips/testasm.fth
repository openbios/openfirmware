purpose: Load file for running the MIPS assembler under C Forth 83
\ See license at end of file

: l>d  0 ;

alias ul. u.
alias headerless noop
alias headerless0 noop
alias headers noop

\ cd /home/forthware/wmb/fm/extend/mips

fload assem.fth
fload disassem.fth

: label create mips-assembler  ;
: code
   create
   d# 306 here body> !   \ 305 is the primitive number for deferred words
   also mips-assembler
;
: next  [ also mips-assembler ] $31 jr  nop  [ previous ]  ;
: end-code  previous  ;
: c;  next end-code  ;

also mips-assembler definitions
alias s0 $16
alias s1 $17
alias s2 $18
alias s3 $19
alias s4 $20
alias s5 $21
alias s6 $22
alias s7 $23
alias t0 $8
alias t1 $9
alias t2 $10
alias t3 $11
alias t4 $12
alias t5 $13
alias t6 $14
alias t7 $15

.( XXX I don't know which register the compiler will use for the Forth) cr
.( stack pointer) cr

: base s2 ;  : up s3 ;  : tos s4 ;  : ip s5 ;  : rp s6 ;  : sp  ???  ;
previous definitions
hex

\ Example - this is almost 
code xcmove  ( src dst cnt -- )
   sp 0    tos  lw	\ cnt into tos
   sp 8    t0   lw	\ Src into t0
   sp 4    t1   lw	\ Dst into t1
   sp 3 /n*  sp   addiu		\ Pop stack

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
c;

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
