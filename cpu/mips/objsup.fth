purpose: MIPS support routines for the objects package.
\ See license at end of file

\ implementation.

\ Assembles the common code executed by actions.  That code
\ extracts the next token (which is the acf of the object) from the
\ code stream, and leaves the corresponding apf in scr

headerless

: start-code ( -- )  code-cf !csp  ;

\ Assembles the code which begins a ;code clause
\ For MIPS, the acf of the child word is left in w
: start-;code  ( -- )  start-code  ;

\ Code for executing an object action.  Extracts the next token
\ (which is the apf of the object) from the code stream and pushes
\ it on the stack.  Then performs the action of "docolon".

\ The Forth token stream contains a pointer to the code:
\ doaction call    sp adec
: doaction  ( -- )  acf-align colon-cf  ;

\ Returns the address of the code executed by the word whose code field
\ address is acf
: >code-adr  ( acf -- code-adr )  token@  ;

code >action-adr  ( object-acf action# -- )
  ( ... -- object-acf action# #actions true | object-apf action-adr false )
                          \ action# in tos
      sp       t0   get   \ object-acf in scr
      bubble
      \ Make sure it's a does> word
      t0 0     t1   lw    \ code-field token
      t1  ' forth @ cmpi
      $at $0 <>  if  nop
         sp -4    sp    addiu \ Make room on stack
         sp -4    sp    addiu \ The error case needs more room on the stack
         tos      sp 4  sw    \ Place action# on stack
         $0       sp 0  sw    \ Place #actions on stack
         next
      then

      t0 4     t1   lw    \ code offset in t1
      bubble
      t1 base  t1   addu  \ code address in t1 
      t1 -4    t2   lw	  \ #actions in t2 
      bubble
      t2       tos  cmp   \ Test action 
      $at 0<= if		      \ "true" branch is error
         sp -4    sp    addiu \ Make room on stack (delay slot)
         sp -4    sp    addiu \ The error case needs more room on the stack
         tos      sp 4  sw    \ Place action# on stack
         t2       sp 0  sw    \ Place #actions on stack
      else
         true     tos   move  \ Return true for error  (delay)

         t0 /token 2*  t0  addiu \ Compute action-apf from action-acf
         t0       sp 4  sw    \ Put action-apf on stack

         tos 2    tos   sll   \ Convert #actions to token offset
         t1 tos   t1    subu  \ Skip back several tokens
         t1 -4    t1    lw    \ Get action-adr token, -4 skips action# field
         t1 base  t1    addu  \ Relocate
         t1       sp 0  sw    \ Put action-adr on stack
         false    tos   move  \ Return false for no error
      then
c;

headers
: action-name  \ name  ( action# -- )
   create  		\ Store action number in data field
      l,
   ;code               ( -- object-pfa )
      tos 0       t0   lw	\ Action# in t0 


      ip  0       t1   lw   	\ Object acf in t1 
      ip  /token  ip   addiu	\ Advance to next token
      t1  base    t1   addu	\ Relocate object acf

      t1  /token 2*  tos  addiu	\ Compute and push object-apf

      t1  /token  t1   lw   	\ relative version of ..
      t1  base    t1   addu	\ default action code address

      t0  2       t0   sll      \ Convert action# to token offset
      t1  t0      t1   subu     \ Skip back action# tokens
      t1  -1 /n*  w    lw       \ Get action-adr token

      w   base    w    addu     \ Tail of "next"
      w   0       t1   lw
      bubble
      t1  base    t1   addu
      t1               jr
      nop
end-code

: >action#  ( apf -- action# )  l@  ;

\ Some examples of object actions defined in code.
\ 3 actions
\ action-code
\    apf w lw   bubble  w  base w  addu
\    w 0 t1 lw  bubble  t1 base t1 addu
\    t1 jr      nop
\ end-code
\ action:  token!  ;  \ is
\ action:          ;  \ addr
\ : defer  \ name  ( -- )
\    create ['] crash token,
\    use-actions
\ ;
\ 3 actions
\ action-code  tos sp push  apf tos lw     c;     \ Default; fetch
\ action-code  tos apf sw   sp tos pop     c;     \ to
\ action-code  tos sp push  apf tos addiu  c;     \ addr
\ : value  \ name  ( initial-value -- )
\    create ,
\    use-actions
\ ;

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
