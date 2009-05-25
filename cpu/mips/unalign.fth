purpose: Unaligned memory access operations for bi-endian MIPS
\ See license at end of file

0 value in-little-endian?

code unaligned-l@   (s adr -- l )
   'user in-little-endian?  $at  lw
   tos    t0  move	\ bubble
   $at 0 <>  if		\ Little endian
   nop			\ delay
      t0 3  tos  lwl
   else			\ Big endian
   t0 0  tos  lwr	\ delay

      t0 0  tos  lwl
      t0 3  tos  lwr
   then
c;
: unaligned-@  (s adr -- l )  unaligned-l@  ;
code unaligned-w@  (s adr -- w )
   'user in-little-endian?  $at  lw
   tos     t0  move	\ Bubble
   $at 0 <>  if		\ Little endian
   t0 1   t2  lb	\ Delay
      t0 0    t1   lb
      t2 8    tos  sll
   else			\ Big endian
   tos t1  tos  or	\ Delay

      t0 0    tos  lb
      bubble
      tos 8   tos  sll
      tos t2  tos  or
   then
c;
code unaligned-l!   (s n adr -- )
   'user in-little-endian?  $at  lw
   sp 0   t0   lw	\ Bubble
   $at 0 <>  if		\ Little endian
   nop			\ Delay
      t0    tos 3  swl
   else			\ Big endian
   t0    tos 0  swr	\ Delay

      t0    tos 0  swl
      t0    tos 3  swr
   then
   sp 4  tos    lw
   sp 8  sp     addiu
c;
: unaligned-d!  ( d adr -- )
   >r  in-little-endian?  if  swap  then
   r@ unaligned-! r> na1+ unaligned-!
;

: unaligned-!   (s n adr -- )  unaligned-l!  ;
code unaligned-w!   (s w adr -- )
   'user in-little-endian?  $at  lw
   sp 0   t0   lw	\ Bubble
   $at 0 <>  if		\ Little endian
   t0 8  t1    srl	\ Delay
      t0    tos 0  sb
   else			\ Big endian
   t1    tos 1  sb	\ Delay

      t0    tos 1  sb
      t1    tos 0  sb
   then
   sp 4  tos    lw
   sp 8  sp     addiu
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
