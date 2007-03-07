\ See license at end of file
purpose: Fast I/O port to/from memory copy

code pseudo-dma-in  ( adr len io-port -- )
   dx pop  cx pop  ax pop
   cx cx or  0<> if
      di push  ax di mov  cld
      cx bx mov
      cx shr			\ Convert to word count
      rep  op: ins		\ INSW ES:EDI,EDX

      1 # bx test  0<>  if  insb  then
      di pop
   then
c;

code pseudo-dma-out  ( adr len io-port -- )
   dx pop  cx pop  ax pop
   si push  ax si mov  cld
   cx inc  cx shr	\ Convert to word count
   rep  op: outs	\ OUTSW ES:EDI,EDX
   si pop
c;
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
