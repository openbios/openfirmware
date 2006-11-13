\ See license at end of file
purpose: Scale operations

headers
decimal

\ *********************************************************************************
\ Each scaled number, s, is represented as wwwwwwwwwwwwwwww.ffffffffffffffff b
\ where the upper 16-bits (w...w) are the whole part of the value and the lower
\ 16-bits (f...f) are the fractions of the value.
\ Each scaled double number, sd, is represented as lo hi where lo is s and hi is
\ upper 32 bits of the whole part of the value.
\ *********************************************************************************

: d>>16  ( fraction whole -- n.16 )  d# 16 <<  swap d# 16 >>  or  ;

: q.32>d.16  ( q > d )
   drop				( sd.0 sd.1 sd.2 )
   rot d# 16 >>			( sd.1 sd.2 sd.l )
   2 pick d# 16 << + -rot	( sd.l' sd.1 sd.2 )
   d# 16 <<			( sd.l sd.1 sd.2' )
   swap d# 16 >> +		( sd.l sd.h )
;

: q.32>d.0  ( q > d )  drop rot drop  ;

' d>>16     to  d.f2>n.f
' q.32>d.16 to  q.f2>d.f
' q.32>d.0  to  q.f2>d.0

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
