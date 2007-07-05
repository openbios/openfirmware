purpose: TLB invalidation
\ See license at end of file

headerless
code invalidate-tlb-entry  ( virtual -- )
   sync isync
   tlbie   tos

   mfspr  tos,pvr
   rlwinm tos,tos,16,16,31
   cmpi   0,0,tos,1
   <> if
      tlbsync
   then

   lwz    tos,0(sp)
   addi   sp,sp,1cell
c;
code invalidate-tlb  ( -- )
   'user #tlb-lines  lwz t0,*

   sync isync
   rlwinm t0,t0,12,4,19

   begin
      addic.  t0,t0,h#-1000
      tlbie   t0
   0= until
   
   mfspr  t0,pvr
   rlwinm t0,t0,16,16,31
   cmpi   0,0,t0,1
   <> if
      tlbsync
   then
c;
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
