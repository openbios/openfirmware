purpose: Unaligned memory access primitives
\ See license at end of file

0 value in-little-endian?

code unaligned-l@   (s adr -- l )
   'user in-little-endian?  lwz  t1,*
   cmpi 0,0,t1,0
   <>  if	\ Little endian
      lbz    t0,0(tos)	\ low byte
      lbz    t1,1(tos)	\ next byte
      rlwimi t0,t1,8,16,23
      lbz    t1,2(tos)	\ next byte
      rlwimi t0,t1,16,8,15
      lbz    t1,3(tos)	\ High byte
      rlwimi t0,t1,24,0,7
   else		\ Big endian
      lbz    t0,3(tos)	\ low byte
      lbz    t1,2(tos)	\ next byte
      rlwimi t0,t1,8,16,23
      lbz    t1,1(tos)	\ next byte
      rlwimi t0,t1,16,8,15
      lbz    t1,0(tos)	\ High byte
      rlwimi t0,t1,24,0,7
   then
   mr tos,t0
c;
: unaligned-@  (s adr -- l )  unaligned-l@  ;
code unaligned-w@  (s adr -- w )
   'user in-little-endian?  lwz  t1,*
   cmpi 0,0,t1,0
   <>  if	\ Little endian
      lbz     t0,1(tos)	\ High byte
      lbz     t1,0(tos)	\ low byte
   else		\ Big endian
      lbz     t0,0(tos)	\ High byte
      lbz     t1,1(tos)	\ low byte
   then
   rlwimi  t1,t0,8,16,23
   mr tos,t1
c;
code unaligned-l!   (s n adr -- )
   second-to-t0	\ n in t0

   'user in-little-endian?  lwz  t1,*
   cmpi 0,0,t1,0
   <>  if	\ Little endian
      stb     t0,0(tos)
      rlwinm  t0,t0,24,0,31
      stb     t0,1(tos)
      rlwinm  t0,t0,24,0,31
      stb     t0,2(tos)
      rlwinm  t0,t0,24,0,31
      stb     t0,3(tos)
   else		\ Big endian
      \ XXX I think the hardware will do this for you
      stb     t0,3(tos)
      rlwinm  t0,t0,24,0,31
      stb     t0,2(tos)
      rlwinm  t0,t0,24,0,31
      stb     t0,1(tos)
      rlwinm  t0,t0,24,0,31
      stb     t0,0(tos)
   then

   pop1
c;

: unaligned-d!  ( d adr -- )
   >r  in-little-endian?  if  swap  then
   r@ unaligned-! r> na1+ unaligned-!
;

: unaligned-!   (s n adr -- )  unaligned-l!  ;
code unaligned-w!   (s w adr -- )
   second-to-t0	\ n in t0

   'user in-little-endian?  lwz  t1,*
   cmpi 0,0,t1,0
   <>  if	\ Little endian
      stb     t0,0(tos)
      rlwinm  t0,t0,24,24,31
      stb     t0,1(tos)
   else		\ Big endian
      \ XXX I think the hardware will do this for you
      stb     t0,1(tos)
      rlwinm  t0,t0,24,24,31
      stb     t0,0(tos)
   then
   pop1
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
