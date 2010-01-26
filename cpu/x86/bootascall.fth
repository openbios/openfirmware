\ See license at end of file
purpose: Return from "booted" programs as if they were Forth words

variable rp-var
variable sp-var
rs-size buffer: rs-buf
ps-size buffer: ps-buf

code save-forth-state  ( -- )
   cld
   \ Copy the entire Forth data stack and return stack areas to a save area.

   si  bx  mov                    \ Save SI
   di  dx  mov			  \ Save UP

   \ Data Stack
   esp  'user sp-var  mov

   'user sp0          si   mov   
   'user ps-buf       di   mov    \ Address of data stack save area
   ps-size #          si   sub    \ Bottom of data stack area (in longwords)

   ps-size 4 / #      cx   mov    \ Size of data stack area
   rep  movs

   dx  di  mov                    \ Restore DI

   \ Return Stack

   ebp  'user rp-var  mov

   'user rp0          si   mov
   'user rs-buf       di   mov    \ Address of return stack save area
   rs-size #          si   sub    \ Bottom of return stack area

   rs-size 4 / #      cx   mov    \ Size of return stack area (in longwords)
   rep  movs

   dx  di  mov                    \ Restore DI

   bx  si  mov                    \ Restore SI
c;

: undo-boot-return  ( -- )
   ['] (quit) to user-interface
;

code resume-forth-state  ( -- )
   cli  cld

   di  dx  mov			  \ Save UP

   \ Copy the entire Forth data stack and return stack areas to a save area.

   \ Data Stack  (load si first because di is the user pointer!)
   'user sp-var       esp  mov    \ Data stack pointer

   'user ps-buf       si   mov    \ Address of data stack save area
   'user sp0          di   mov    \ Top of data stack areas
   ps-size #          di   sub    \ Bottom of data stack area (in longwords)

   ps-size 4 / #      cx   mov    \ Size of data stack area
   rep  movs

   dx  di  mov			  \ Restore UP

   \ Return Stack  (load si first because di is the user pointer!)

   'user rp-var       ebp  mov    \ Return stack pointer

   'user rs-buf       si   mov    \ Address of return stack save area
   'user rp0          di   mov    \ Top of return stack area
   rs-size #          di   sub    \ Bottom of return stack area

   rs-size 4 / #      cx   mov    \ Size of return stack area (in longwords)
   rep  movs

   dx  di  mov			  \ Restore UP
   sti

   0 [ebp]   esi  mov             \ Pop the return stack into the interpreter pointer
   4 #       ebp  add             
c;

0 value saved-go-hook
: boot-as-call(  ( -- )
   ps-buf drop rs-buf drop
   ['] go-hook behavior to saved-go-hook
   ['] save-forth-state to go-hook
   ['] resume-forth-state to user-interface
;
: )boot-as-call  ( -- )
   saved-go-hook to go-hook
   ['] (quit) to user-interface
;
ps-buf drop rs-buf drop
: foo   boot-as-call(  emacs  )boot-as-call  cr ." Hello" cr ;

\ LICENSE_BEGIN
\ Copyright (c) 2010 FirmWorks
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
