purpose: Machine dependent support routines for multiple-code-field "objects"
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

\ Returns the address of the code executed by the word whose code field
\ address is acf
: >code-adr  ( acf -- code-adr )  token@  ;

code >action-adr  ( object-acf action# -- )
  ( ... -- object-acf action# #actions true | object-apf action-adr false )
				\ action# in tos
   lwz  t0,0(sp)		\ object-acf in t0 
   lwz  t1,1cell(t0)		\ code offset in t1
   add  t1,t1,base		\ Relocate; code address in t1
   lwz  t2,-1cell(t1)		\ #actions in t2 
   cmp  0,0,t2,tos		\ Test action number
   <= if			\ "true" branch is error
      stwu  tos,-1cell(sp)	\ Push action#
      stwu  t2,-1cell(sp)	\ Push #actions
      addi  tos,r0,-1		\ Return true for error
   else
      addi  t0,t0,/cf+1cell	\ Compute object-apf from object-acf
      stw   t0,0(sp)		\ Put action-apf on stack

      rlwinm tos,tos,2,0,29	\ Convert index to byte offset
      subfc t1,tos,t1		\ Skip back #actions tokens
				\ ( Use subfc for POWER compatibility)
      lwz   t1,-1cell(t1)	\ Get token, accounting for action# field
      add   t1,t1,base		\ Relocate
      stwu  t1,-1cell(sp)	\ Push action-adr
      addi  tos,r0,0		\ Return false for no error
   then
c;

headers
: action-name  \ name  ( action# -- )
   create  ,		\ Store action number in data field
   ;code               ( -- object-pfa )
      lwz    t0,0(tos)		\ Action# in t0 

      lwzu   t1,/token(ip)	\ Object acf in t1 
      add    t1,t1,base		\ Relocate

      addi   tos,t1,/cf+1cell	\ Compute and push object-apf

      lwz    t1,1cell(t1)	\ relative version of ..
      add    t1,t1,base		\ default action code address
   
      rlwinm t0,t0,2,0,29	\ Convert index to byte offset
      subfc  t1,t0,t1		\ Skip back action# tokens
				\ ( Use subfc for POWER compatibility)

      lwz    w,-1cell(t1)	\ Get token, accounting for action# field

      lwzux  t1,w,base		\ next-tail ...
      add    t1,t1,base
      mtspr  lr,t1
      bclr   20,0
end-code

: >action#  ( apf -- action# )  @  ;
headers

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
