purpose: Register access words for PowerPC
\ See license at end of file

code rl!  ( l addr -- )
   lwz    t0,0(sp)	\ value
   'user in-little-endian?  lwz  t1,*
   cmpi 0,0,t1,0
   0<>  if
      stw    t0,0(tos)
   else
      stwbrx t0,r0,tos
   then
   eieio sync
   lwz    tos,1cell(sp)
   addi   sp,sp,2cells
c;
code rl@  ( addr -- l )
   'user in-little-endian?  lwz  t1,*
   cmpi 0,0,t1,0
   0<>  if
      lwz    tos,0(tos)
   else
      lwbrx  tos,r0,tos
   then
c;
code rw!  ( w addr -- )
   lwz    t0,0(sp)	\ value
   'user in-little-endian?  lwz  t1,*
   cmpi 0,0,t1,0
   0<>  if
      sth    t0,0(tos)
   else
      sthbrx t0,r0,tos
   then
   eieio sync
   lwz    tos,1cell(sp)
   addi   sp,sp,2cells
c;
code rw@  ( addr -- w )
   'user in-little-endian?  lwz  t1,*
   cmpi 0,0,t1,0
   0<>  if
      lhz    tos,0(tos)
   else
      lhbrx  tos,r0,tos
   then
c;
code rb@  ( addr -- b )
   lbz    tos,0(tos)
c;
code rb!  ( b addr -- )
   lwz    t0,0(sp)
   stb    t0,0(tos)
   eieio sync
   lwz    tos,1cell(sp)
   addi   sp,sp,2cells
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
