purpose: Action definition for multiple-code-field words.
\ See license at end of file

\ Data structures:
\   nth-action-does-clause   acfs  unnest
\   n-1th-action-does-clause acfs  unnest
\   ...
\   1th-action-does-clause acfs  unnest
\   nth-adr
\   n-1th-adr
\   ...
\   1th-adr
\   n
\   0th-action-does-clause acfs  unnest
\   object-header  build-acfs
\   (') 0th-adr uses

needs doaction objsup.fth	\ Machine-dependent support routines

decimal
headerless

0 value action#
0 value #actions
0 value action-adr
headers
: actions  ( #actions -- )
   is #actions
   #actions 1- /token * na1+ allot    ( #actions )   \ Make the jump table
   \ The default action is a code field, which must be aligned
   align acf-align  here is action-adr
   0 is action#
   #actions  action-adr /n -  n!
;
headerless
\ Sets the address entry in the action table
: set-action  ( -- )
   action#  #actions  > abort" Too many actions defined"
   lastacf  action-adr  action# /token * -  /n -  token!
;
headers
: action:  ( -- )
   action# if   \ Not the default action
      doaction  set-action
   else \ The default action, like does>
      place-does
   then

   action# 1+ is action#
   !csp
   ]
;
: action-code  ( -- )
   action#  if   \ Not the default action
      acf-align start-code set-action
   else          \ The default action, like ;code
      start-;code
   then

   \ For the default action, the apf of the child word is found in
   \ the same way as with ;code words.

   action# 1+ is action#
   do-entercode
;
: use-actions  ( -- )
   state @  if
      compile (')  action-adr  token,  compile used
   else
      action-adr  used
   then
; immediate

headerless
: .object-error
   ( object-acf action-adr false  |  acf action# #actions true -- ... )
   ( ... -- object-acf action-adr )
   if
      ." Unimplemented action # " swap .d  ." on object " swap .name
      ." , whose maximum action # is " 1- .d cr
      abort
   then
;

headers

\ Run-time code for "to".  This is important enough to deserve special
\ optimization.
code to  ( -- )
   lwzu  t0,4(ip)	\ Object acf in t0
   add   t0,t0,base	\ Relocate

   stwu  tos,-4(sp)	\ Save the top-of-stack register on memory stack
   addi  tos,t0,8	\ Put pfa in top-of-stack register

   lwz   t1,4(t0)	\ Token of default action 
   add   t1,t1,base	\ Relocate
   lwz   w,-8(t1)	\ Token of "to" action clause

   \ Tail of "NEXT"
   lwzux t1,w,base	\ Read the contents of the code field
   add   t1,t1,base	\ Relocate
   mtspr lr,t1
   bclr	 20,0		\ Execute the code
end-code

code dispatch-action  ( acf action-adr -- )
			\ action-adr in tos
   lwz   t0,0(sp)	\ Object acf in t0
   addi  sp,sp,4

   move  w,tos		\ Token of action clause

   addi  tos,t0,8	\ Put pfa in top-of-stack register

   lwz   t1,0(w)	\ Read the contents of the code field
   \ next-tail1
   add   t1,t1,base	\ Relocate
   mtspr lr,t1
   bclr	 20,0		\ Execute the code
end-code

\ Executes the numbered action of the indicated object
\ It might be worthwhile to implement perform-action entirely in code.
: perform-action  ( object-acf action# -- )
   dup if
      >action-adr .object-error  ( object-acf action-adr )
      dispatch-action
   else
      drop execute
   then
;

: action-name  \ name  ( action-offset-adr -- )
   create   1+ /token * negate ,
   ;code

   lwzu  t0,4(ip)	\ Object acf in t0
   add   t0,t0,base	\ Relocate

   lwz   t1,4(t0)	\ Token of default action 
   add   t1,t1,base	\ Relocate
   lwz   tos,0(tos)	\ Get action offset
   lwzx  w,tos,t1	\ Token of indicated action clause

   addi  tos,t0,8	\ Put pfa in top-of-stack register

   \ Tail of "NEXT"
   lwzux t1,w,base	\ Read the contents of the code field
   add   t1,t1,base	\ Relocate
   mtspr lr,t1
   bclr	 20,0		\ Execute the code
end-code

\ 1 action-name to
2 action-name addr

: action-compiler:  \ name  ( -- )
   bl word  dup find  0=  ?missing   \ pstr acf
   swap "create  token,  immediate
   does>     ( apf )
     +level  ( apf )	\ Enter temporary compile state if necessary
     token@ (compile)	\ Compile run-time action-name word
     ' (compile)	\ Compile object acf
     -level		\ Exit temporary compile state, perhaps run word
;
\ action-compiler: to
action-compiler: addr


\ Makes "is" and "to" synonymous.  "is" first checks to see if the
\ object is of one of the kernel object types (which don't have multiple
\ code fields), and if so, compiles or executes the "(is) <token>" form.
\ If the object is not of one of the kernel object types, "is" calls
\ "to-hook" to handle the object as a multiple-code field type object.

: (to)  ( [data] acf -- )  +level  compile to  (compile) -level  ;
' (to) is to-hook
alias to is

\ 3 actions
\ action:  @  ;
\ action:  !  ; ( is )
\ action:     ; ( addr )
\ : value  \ name  ( initial-value -- )
\    create ,
\    use-actions
\ ;

\ Need inheritance

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
