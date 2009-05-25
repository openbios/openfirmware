purpose: Cache operations for MIPS
\ See license at end of file

h#     8000 constant /dcache
h#     8000 constant /icache

d# 32 constant /cache-line
: cache-bounds  ( adr len -- end start )
   bounds  swap /cache-line round-up  swap /cache-line round-down
;

\ TLB cache operations
\ XXX secondary cache operations depends on processor
code invalidate-i$-entry  ( adr -- )
   tos 0  h# 12  cache	\ Invalidate secondary I$
   tos 0  h# 10  cache	\ Invalidate primary I$
   sp tos pop
c;
code write-d$-entry  ( adr -- )
   tos 0  h# 19  cache     \ WriteBack primary D$
   tos 0  h# 1b  cache     \ WriteBack secondary D$
   sp tos pop
c;
code flush-d$-entry  ( adr -- )
   tos 0  h# 15  cache     \ WriteBack&Invalidate primary D$
   tos 0  h# 17  cache     \ WriteBack&Invalidate secondary D$
   sp tos pop
c;

\ KSEG0 cache operations
code invalidate-i$-index  ( -- )
   kseg0   t0    set
   /icache t1    set
   t0      t1 t1 addu

   begin
      t0 0  0  cache	   \ Index Invalidate primary I$
      nop
      t0 /cache-line t0 addiu
   t0 t1 =  until
      nop
c;
code flush-d$-index  ( -- )
   kseg0   t0    set
   /dcache t1    set
   t0      t1 t1 addu

   begin
      t0 0  1  cache	   \ Index WriteBack&Invalidate primary D$
      nop
      t0 /cache-line t0 addiu
   t0 t1 =  until
      nop
c;



: flush-d$-range  ( adr len -- )
   over h# f000.0000 and dup
   kseg1 =  if  3drop exit  then
   kseg0 =  if
      2drop  flush-d$-index
   else
      cache-bounds  ?do  i flush-d$-entry  /cache-line +loop
   then
;

: stand-sync-cache  ( adr len -- )
   over h# f000.0000 and dup
   kseg1 =  if  3drop exit  then
   kseg0 =  if
      2drop  flush-d$-index  invalidate-i$-index
   else
      cache-bounds  ?do
          i write-d$-entry
          i invalidate-i$-entry
      /cache-line +loop
   then
;
: stand-init-io  ( -- )
   stand-init-io
   ['] stand-sync-cache to sync-cache
;

code get-dtag ( index -- )
   tos 0 5 cache
   sp tos pop
c;
code get-itag ( index -- )
   tos 0 4 cache
   sp tos pop
c;

: (.tag)  ( -- )
   taglo@  h# c0 and if  taglo@ h# ffff.ff00 and 4 << u.  then
;
defer .tag  ' (.tag) to .tag
: .dtags  ( -- )
   kseg0 /dcache bounds do
     i get-dtag .tag
   /cache-line +loop
;
: .itags  ( -- )
   kseg0 /icache bounds do
     i get-itag .tag
   /cache-line +loop
;



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
