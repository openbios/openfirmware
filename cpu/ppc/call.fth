purpose: Call C subroutines from Forth
\ See license at end of file

\ From Forth, call the C subroutine whose address is on the stack

code call  ( [ arg5 .. arg0 ] adr -- [ arg5 .. arg0 ] result )
   'user saved-sp   stw  sp,*	\ Save for callbacks
   'user saved-rp   stw  rp,*	\ Save for callbacks

   \ Pass up to 6 arguments
   lwz  r3,h#00(sp)
   lwz  r4,h#04(sp)
   lwz  r5,h#08(sp)
   lwz  r6,h#0c(sp)
   lwz  r7,h#10(sp)
   lwz  r8,h#14(sp)

   mtspr lr,tos
   bclrl 20,0

   mr    tos,r3		\ Return subroutine result
   mtspr ctr,up		\ Restore "next" pointer
c;

headerless
code r1!  ( adr -- )  mr r1,tos  lwz tos,0(sp)  addi sp,sp,1cell  c;

headers
: sp-call  ( [ arg5 .. arg0 ] adr sp -- [ arg5 .. arg0 ] result )
   h# 10 - r1! call
;

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
