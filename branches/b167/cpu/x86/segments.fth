\ See license at end of file
\ Access to alternate segments

code spacec@  ( adr space -- byte )
   ax pop   ax fs mov   bx pop   ax ax sub  fs: 0 [bx] al mov  1push
c;

code spacec!  ( byte adr space -- )
   ax pop   ax fs mov   bx pop   ax pop  fs: al 0 [bx] mov
c;

code spacel@  ( adr space -- byte )
   ax pop   ax fs mov   bx pop   fs: 0 [bx] ax mov  1push
c;

code spacel!  ( byte adr space -- )
   ax pop   ax fs mov   bx pop   ax pop  fs: ax 0 [bx] mov
c;

\ I/O space access via IN and OUT instructions

code pc@  ( b adr -- )  dx pop  ax ax xor      dx al in  ax push   c;
code pw@  ( adr -- w )  dx pop  ax ax xor  op: dx ax in  ax push  c;
code pl@  ( adr -- l )  dx pop                 dx ax in  ax push  c;
code pc!  ( adr -- b )  dx pop  ax pop         al dx out  c;
code pw!  ( w adr -- )  dx pop  ax pop     op: ax dx out  c;
code pl!  ( l adr -- )  dx pop  ax pop         ax dx out  c;
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
