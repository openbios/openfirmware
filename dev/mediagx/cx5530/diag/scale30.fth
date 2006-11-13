\ See license at end of file
purpose: Scale operations

headers
hex

\ *********************************************************************************
\ Each scaled number, s, is represented as ww.ff.ffff.ffff.ffff.ffff.ffff.ffff.ffff b
\ where the upper 2-bits (w...w) are the whole part of the value and the lower
\ 30-bits (f...f) are the fractions of the value.
\ Each scaled double number, sd, is represented as lo hi where lo is s and hi is
\ upper 32 bits of the whole part of the value.
\ *********************************************************************************

: d.60>n.30  ( d.60 -- n.30 )
   dup 0<  2000.0000 0 rot  if  d-  else  d+  then
   2 << swap d# 30 >> or
;

: q.60>d.30  ( q.60 -- d.30 )
   dup 0<  >r  2000.0000 0 0 0  r>  if  q-  else  q+  then
   drop
   2 << over d# 30 >> or -rot
   2 << swap d# 30 >> or
   swap
;

: q.60>d.0  ( q.60 -- d.0 )
   dup 0<  >r  0 800.0000 0 0  r>  if  q-  else  q+  then
   4 << over d# 28 >> or -rot
   4 << swap d# 28 >> or
   -rot nip
;


' d.60>n.30  to  d.f2>n.f
' q.60>d.30  to  q.f2>d.f
' q.60>d.0   to  q.f2>d.0

headers
\ LICENSE_BEGIN
\ Copyright (c) 2006 FirmWorks
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
