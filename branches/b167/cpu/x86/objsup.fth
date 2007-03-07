\ See license at end of file

\ Machine dependent support routines used for the objects package.
\ These words know intimate details about the Forth virtual machine
\ implementation.

\ Assembles the common code executed by actions.  That code
\ extracts the next token (which is the acf of the object) from the
\ code stream and leaves the corresponding apf on the stack.

: start-code  ( -- )  code-cf  !csp  ;

\ Assembles the code which begins a ;code clause
\ For this version, the acf of the child word is left in w
: start-;code  ( -- )  start-code  ;

\ Code field for an object action.
: doaction  ( -- )  acf-align colon-cf  ;
   
\ Returns the address of the code executed by the word whose code field
\ address is acf
: >code-adr  ( acf -- code-adr )  token@  ;

code >action-adr  ( object-acf action# -- )
  ( ... -- object-acf action# #actions true | object-apf action-adr false )
   cx           pop		\ action# in cx
   ax           pop		\ object-acf in ax 
    0 [ax]  bx  mov		\ code address in bx
   -4 [bx]  cx  cmp		\ Test action number
   > if				\ "true" branch is error
      cx          push		\ Push action#
      -4 [bx]     push		\ Push #actions
      true #  ax  mov		\ Return true for error
      1push
      next
   then
   4 #          ax  add		\ Push object-apf
   ax               push
   cx               neg		\ Index backwards into action table
   -4 [bx] [cx] *4  push	\ Push action-adr
   ax           ax  xor		\ Return false for no error
   1push
c;

: action-name  \ name  ( action# -- )
   create ,		\ Store action number in data field
   ;code
   4 [ax]  cx  mov	\ Action# in cx

   ax          lods	\ Object acf in ax
   4 #     ax  add	\ Compute pfa
   ax          push	\ and push it

   -4 [ax] ax  mov	\ Token of default action 
   
   cx          neg	\ Index backwards into action table
   -4 [ax] [cx] *4  ax  mov	\ Address of action code

   0 [ax]      jmp	\ Tail of "NEXT"
end-code
: >action#  ( apf -- action# )  @  ;

headers

\ Some examples of object actions defined in code.
\ 3 actions
\ action-code
\    apf w lw   bubble  w  base w  addu
\    w 0 bx lw  bubble  bx base bx addu
\    bx jr      nop
\ end-code
\ action:  token!  ;  \ is
\ action:          ;  \ addr
\ : defer  \ name  ( -- )
\    create ['] crash token,
\    use-actions
\ ;
\ 3 actions
\ action-code  cx sp push  apf cx lw     c;     \ Default; fetch
\ action-code  cx apf sw   sp cx pop     c;     \ to
\ action-code  cx sp push  apf cx addiu  c;     \ addr
\ : value  \ name  ( initial-value -- )
\    create ,
\    use-actions
\ ;
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
