purpose: Machine dependent support routines used for the objects package.
\ See license at end of file

\ These words know intimate details about the Forth virtual machine
\ implementation.

\ Assembles the common code executed by actions.  That code
\ extracts the next token (which is the acf of the object) from the
\ code stream and leaves the corresponding apf on the stack.

headerless

: start-code  ( -- )  code-cf  !csp  ;

\ Assembles code to begin a ;code clause
: start-;code  ( -- )  start-code  ;

\ Code field for an object action.
: doaction  ( -- )  acf-align colon-cf  ;

code >action-adr	( object-acf action# -- ... )
( ... -- object-acf action# #actions true | object-apf action-adr false )
\ !!!! the next line should ONLY be included for RiscOS Forthmacs testing
\  ldr     base,[pc,`'body origin  swap here 8 + -  swap']
   ldr     r1,[sp]		\ r1: object-acf    top: action#

   ldr     r0,[r1]		\ r0: object-code-field
   mov     r0,r0,lsl #8		\ remove opcode bits
   add     r0,r1,r0,asr #6	\ r0: adr of object ;code clause - 8

				\ adding /cell is the same as adding
				\ 8 then subtracting 4
   inc     r0,1cell		\ r0: object-#actions-adr r1: obj-acf

   ldr     r2,[r0]		\ r2: #actions
   cmp     tos,r2		\ action# greater #actions
   > if
      stmdb   sp!,{tos,r2}	\ push action# and #actions
      mvn     tos,#0		\ return true
      next
   then

   \ r0: object-#actions-adr  r1: object-acf  r2: #actions  tos: action#
   sub     r0,r0,tos,lsl #2	\ r0: adr of action cell
   ldr     r0,[r0]		\ r0: action-adr
\   add     r0,r0,base

   \ r0: object-action-adr  r1: object-acf  tos: action#
   inc     r1,1cell		\ r1: object-apf
   str     r1,[sp]		\ put object-apf on stack
   psh     r0,sp		\ push action-adr
   mov     tos,#0	\ return false
c;

headers
: action-name	\ name  ( action# -- )
	create ,
	;code
\ !!!! the next line should ONLY be included for RiscOS Forthmacs testing
\   ldr     base,[pc,`'body origin swap here 8 + - swap`]	\ Test
\   ldr     r0,[tos]		\ r0: action#

   lnk     r0
   ldr     r0,[r0]		\ r0: action#

   ldr     r2,[ip],1cell
\   add     r2,r2,base		\ r2: object-acf
   psh     tos,sp		\ make room on stack
   add     tos,r2,1cell		\ tos: object-apf

   ldr     r3,[r2]		\ r3: object-code-field
   mov     r3,r3,lsl #8		\ remove opcode bits
   add     r3,r2,r3,asr #6	\ r3: adr of object ;code clause - 8
   inc     r3,2cells		\ r3:object-code-adr

   inc     r0,#1		\ r0: index to action-cell
   sub     r3,r3,r0,lsl	#2	\ r3: adr of action cell
\ I am not sure about implementing execute, here the pc is just
\ set to token@
   ldr     pc,[r3]		\ execute action
\   add     pc,r3,base
c;

: >action#  ( apf -- action# )  @  ;
headers

\ LICENSE_BEGIN
\ Copyright (c) 1997 FirmWorks
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
