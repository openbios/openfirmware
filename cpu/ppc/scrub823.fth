purpose: Fast memory scrubbing
\ See license at end of file

headerless
code (berase)  ( adr #cache-blocks /dcache-block -- )
				\ /dcache-block is already in tos
   lwz     t1,0(sp)		\ #cache-blocks in t1
   lwz     t0,1cell(sp)		\ Address in t0

   mfspr   t2,ctr
   mtspr   ctr,t1
   begin
      dcbz  r0,t0
      dcbf  r0,t0
      add   t0,t0,tos
   countdown
   mtspr   ctr,t2

   lwz     tos,2cells(sp)
   addi    sp,sp,3cells
c;

headers
\ Usage requirements:
\   adr must aligned on a cache line boundary
\   len must a multiple of the cache line size
\   the range must not overlap a 256 MB (h# 1000.0000) boundary
\   the data cache must be turned on
: berase  ( adr len -- )
   dcache-on?  0=  dup >r  if  dcache-on  then
   /dcache-block /  /dcache-block  (berase)		( )
   r>  if  dcache-off  then   
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
