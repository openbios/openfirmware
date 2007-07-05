purpose: Switch to little-endian after the firmware is already running
\ See license at end of file

code lbflips  ( adr len -- )
   mfspr  r10,ctr

   mr         r6,tos
   rlwinm     r6,r6,30,2,31	\ Divide by /l
   mtspr      ctr,r6

   lwz        r5,0(sp)
   addi       sp,sp,1cell

   begin
      lwz     r4,0(r5)
      stwbrx  r4,r0,r5
      addi    r5,r5,4
   countdown
   mtspr  ctr,r10
c;

code wbflips  ( adr len -- )
   mfspr  r10,ctr

   mr         r6,tos
   rlwinm     r6,r6,31,1,31	\ Divide by /w
   mtspr      ctr,r6

   lwz        r5,0(sp)
   addi       sp,sp,1cell

   begin
      lhz     r4,0(r5)
      sthbrx  r4,r0,r5
      addi    r5,r5,2
   countdown
   mtspr  ctr,r10
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
