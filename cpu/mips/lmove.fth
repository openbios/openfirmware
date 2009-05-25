purpose: Longword memory copy
\ See license at end of file

code lmove  ( from-addr to-addr cnt -- )
   sp 4    t0   lw	\ Src into t0
   sp 0    t1   lw	\ Dst into t1

   t0 tos  t2   addu	\ t2 = src limit

   t0 t2  <> if
   nop
      
      begin
         t0 0  t3     lw	\ Load word
         t0 4  t0     addiu	\ (load delay) Increment src
         t3    t1 0   sw	\ Store word
      t0 t2  = until
         t1 4  t1     addiu	\ (delay) Increment dst

   then   

   sp 8      tos  lw		\ Delay slot - Reload tos
   sp 3 /n*  sp   addiu		\   "
c;
code wmove  ( from-adr to-adr #bytes -- )
   sp 4    t0   lw	\ Src into t0
   sp 0    t1   lw	\ Dst into t1

   t0 tos  t2   addu	\ t2 = src limit

   t0 t2  <> if
   nop
      
      begin
         t0 0  t3     lhu	\ Load halfword
         t0 2  t0     addiu	\ (load delay) Increment src
         t3    t1 0   sh	\ Store halfword
      t0 t2  = until
         t1 2  t1     addiu	\ (delay) Increment dst

   then   

   sp 8      tos  lw		\ Delay slot - Reload tos
   sp 3 /n*  sp   addiu		\   "
c;

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
