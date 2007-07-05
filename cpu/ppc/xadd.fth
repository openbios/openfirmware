purpose: 64-bit addition and subtraction
\ See license at end of file

code x+  ( x1 x2 -- x3 )
   lwz    t1,0(sp)	\ x2.low
   lwz    t3,8(sp)	\ x1.low
   lwz    t2,4(sp)	\ x1.high
   addi   sp,sp,8	\ Pop args
   addc   t1,t1,t3	\ x3.low
   adde   tos,tos,t2	\ x3.high
   stw    t1,0(sp)	\ Push result (x3.high already in tos)
c;
code x-  ( x1 x2 -- x3 )
   lwz    t1,0(sp)	\ x2.low
   lwz    t2,4(sp)	\ x1.high
   lwz    t3,8(sp)	\ x1.low
   addi   sp,sp,8	\ Pop args
   subfc  t1,t1,t3	\ x3.low
   subfe  tos,tos,t2	\ x3.high
   stw    t1,0(sp)	\ Push result (x3.high already in tos)
c;

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
