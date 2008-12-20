purpose: Bit operations
\ See license at end of file

hex
code bitset  ( bit# array -- )
   mov     r0,tos                  \ r0 array
   ldmia   sp!,{r1,tos}            \ r1 bit#
   and     r2,r1,#7
   mov     r3,#0x80
   ldrb    r4,[r0,r1,asr #3]
   orr     r4,r4,r3,ror r2
   strb    r4,[r0,r1,asr #3]
c;

code bitclear  ( bit# array -- )
   mov     r0,tos                  \ r0 array
   ldmia   sp!,{r1,tos}            \ r1 bit#
   and     r2,r1,#7
   mvn     r3,#0x80
   ldrb    r4,[r0,r1,asr #3]
   and     r4,r4,r3,ror r2
   strb    r4,[r0,r1,asr #3]
c;

code bittest  ( bit# array -- flag )
   pop     r1,sp                   \ r1 bit#
   and     r2,r1,#7
   mov     r3,#0x80
   ldrb    r4,[tos,r1,asr #3]
   ands    r4,r4,r3,ror r2
   mvnne   tos,#0
   moveq   tos,#0
c;

\ LICENSE_BEGIN
\ Copyright (c) 1997 FirmWorks
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
