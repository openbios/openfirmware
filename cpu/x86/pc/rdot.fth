\ See license at end of file
purpose: Real-mode low-level numeric output for tracing startup code

\ Requires a stack

real-mode
label remit  ( al: char -- )
   cx push  dx push

   al cl mov
   begin   3fd # dx mov  dx al in   40 # al and  0<> until
   cl al mov   3f8 # dx mov  al dx out
   begin   3fd # dx mov  dx al in   40 # al and  0<> until

   dx pop  cx pop
   ret
end-code

label rputdigit  ( al: digit -- )
   h# f # al and
   d# 10 #  al  cmp
   >=  if
      ascii a d# 10 - #  al  add
   else
      ascii 0 #  al  add
   then
   remit #) call
   ret
end-code

label rpdot  ( ax: n -- )
   bx push
   ax bx mov
   bx 4 # rol  bx ax mov  rputdigit #) call
   bx 4 # rol  bx ax mov  rputdigit #) call
   bx 4 # rol  bx ax mov  rputdigit #) call
   bx 4 # rol  bx ax mov  rputdigit #) call
   bx pop
   ret
end-code

label rdot  ( ax: n -- )
   op: ax push
   rpdot #) call
   h# 20 # al mov  remit #) call
   op: ax pop
   ret
end-code

label rldot  ( ax: n -- )
   op: ax push
   op: ax  d# 16 #  rol
   rpdot #) call
   op: ax  d# 16 #  rol
   rpdot #) call
   h# 20 # al mov  remit #) call
   op: ax pop
   ret
end-code
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
