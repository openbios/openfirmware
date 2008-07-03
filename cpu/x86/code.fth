\ See license at end of file
purpose: Defining words for code definitions

only forth also assembler also forth definitions
: entercode  ( -- ) !csp also assembler  protected-mode  ;
: code   \ name  ( -- )
   create  here here 4 - token!  do-entercode
;
: label  \ name  ( -- adr )
   create  do-entercode
;
: use-postfix-assembler  ( -- )  ['] entercode is do-entercode  ;
use-postfix-assembler

assembler definitions
\ We redefine the Registers that FORTH uses to implement its
\ virtual machine.

ebp constant rp   [ebp] constant [rp]   \ Rreturn stack pointer
esi constant ip   [esi] constant [ip]   \ Interpreter pointer
eax constant w    [eax] constant [w]    \ Working register
edi constant up   [edi] constant [up]   \ User pointer

: next    up jmp   ;
: ainc   ( ptr -- )  /n # rot add  ;
: adec   ( ptr -- )  /n # rot sub  ;
: [apf]  ( -- mode )  4 [w]    ;
: 1push  ( -- )  ax push  ;
: 2push  ( -- )  dx push  ax push  ;
: end-code  ( -- )  previous  ?csp  ;
: c;  ( -- )  next  end-code  ;
: 'user#  \ name  ( -- n )
   ' >body @
;
: 'user   \ name  ( -- mode )
   'user# [up]
;
: 'body   \ name  ( -- adr )
   ' >body
;

\ for relocation, addresses must be word-aligned
\ make-even is used with two-byte op-codes
\ make-odd is used with one-byte op-codes

: make-even 	( -- )	\ pad code with noop to reach word boundary
   here 
   [ also forth ]
   1 and if
      h# 90 asm8,
   then 
   [ previous ]
;
   
: make-odd 	( -- )	\ pad code with noop to be between word boundaries 
   here 
   [ also forth ]
   1 and 0= if
      h# 90 asm8,
   then 
   [ previous ]
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
