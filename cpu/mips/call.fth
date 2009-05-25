purpose: C subroutine call interface for MIPS
\ See license at end of file

code sp-call  ( [ arg5 .. arg0 ] adr sp -- [ arg5 .. arg0 ] result )

   sp   t0   pop		\ Get the subroutine address

   sp   'user saved-sp  sw	\ Save for callbacks
   rp   'user saved-rp  sw	\ Save for callbacks

   tos  h# -10 /n*  t1   addiu	\ Point to the new stack, leaving some extra
				\ room since the compiler preamble stores
				\ things above the stack pointer

   \ Pass up to 6 arguments (first 0-3 in registers, 4 and 5 on the stack)
   sp 0 /n*   $a0  lw
   sp 1 /n*   $a1  lw
   sp 2 /n*   $a2  lw
   sp 3 /n*   $a3  lw
   sp 4 /n*   t2  lw    t2  t1 0 /n*  sw
   sp 5 /n*   t2  lw    t2  t1 1 /n*  sw

   t1  sp  move			\ Switch to the new stack

   t0 ra jalr  nop		\ Call the subroutine

   'user saved-rp  rp  lw	\ Restore the return stack pointer
   'user saved-sp  sp  lw	\ Restore the stack pointer
   v0   tos   move		\ Return subroutine result
c;
: call  ( [ arg5 .. arg0 ] adr -- [ arg5 .. arg0 ] result )  sp@ sp-call  ;

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
