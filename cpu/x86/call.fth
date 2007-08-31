\ See license at end of file
purpose: From Forth, call the C subroutine whose address is on the stack

code sp-call  ( [ arg7 .. arg0 ] adr sp -- [ arg5 .. arg0 ] result )
   bx  pop			\ Get the new stack pointer
   ax  pop			\ Get the subroutine address

   sp  'user saved-sp  mov	\ Save for callbacks
   rp  'user saved-rp  mov	\ Save for callbacks

   sp  bx  xchg			\ Switch to new SP, with EBX set to old SP
   7 /n* [ebx]  push		\ Copy the arguments to the new stack
   6 /n* [ebx]  push
   5 /n* [ebx]  push
   4 /n* [ebx]  push
   3 /n* [ebx]  push
   2 /n* [ebx]  push
   1 /n* [ebx]  push
   0 /n* [ebx]  push

   bp  bp  xor			\ Set the frame pointer to null

   ax  call			\ Call the subroutine

   'user saved-rp  rp  mov	\ Restore the return stack pointer
   'user saved-sp  sp  mov	\ Restore the stack pointer
   ax  push			\ Return subroutine result
c;

code call  ( [ arg5 .. arg0 ] adr -- [ arg5 .. arg0 ] result )
   ax pop
   sp  'user saved-sp  mov	\ Save for callbacks
   rp  'user saved-rp  mov	\ Save for callbacks
   rp  rp  xor			\ Set the frame pointer to null
   ax call
   'user saved-rp  rp  mov	\ Restore the return stack pointer
   'user saved-sp  sp  mov	\ Restore the stack pointer
   ax push
c;
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
