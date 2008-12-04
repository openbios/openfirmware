purpose: Internet checksum (one's complement of 16-bit words) primitive
\ See license at end of file

\ The complete checksum calculation consists of:
\ a) add together all the 16-bit big-endian words in the buffer, with
\    wrap-around carry (i.e. a carry out of the high bit is added back
\    in at the low bit).
\ b) Take the one's complement of the result, preserving only the
\    least-significant 16 bits.
\ c) If the result is 0, change it to ffff.

\ The process of computing a checksum for UDP packets involves the
\ creation of a "pseudo header" containing selected information
\ from the IP header, and checksumming the combination of that pseudo
\ header and the UDP packet.  To do so, it is convenient to perform
\ step (a) of the calculation separately on the two pieces (pseudo header
\ and UDP packet).  Thus we factor the checksum calculation code with
\ a separate primitive "(oc-checksum)" that performs step (a).  That
\ primitive is worth optimizing; steps (b) and (c) are typically not.

headerless
\ This computation depends on some properties of one's complement
\ summation.  The computation can be done in either endianness,
\ so we do it in little-endian, swapping at the end, to save time
\ on x86.  We also do it 32 bits at a time, folding the result
\ at the end.

code (oc-checksum)  ( accum adr len -- checksum )
   bx          pop     \ bx: len
   ax          pop     \ ax: adr
   dx          pop     \ dx: accum
   si          push    \ save si
   ax   si     mov     \ si: adr  ax: dead
   bx   cx     mov     \ cx:len
   2 #  cx     shr     \ cx:#shortwords

   dl dh xchg  \ Byte swap into LE form
   clc         \ Initial carry is 0
   cx cx or  0<>  if
      begin
         ax lods
         ax dx adc
      loopa
   then

   0 # dx adc   \ Final carry

   2 # bx test  0<>  if      \ Leftover short?
      ax ax xor
      op: ax lods
      ax dx add
      0 # dx adc  \ Possible carry
   then

   1 # bx test  0<>  if      \ Leftover byte?
      ax ax xor
      al lodsb
      ax dx add
      0 # dx adc  \ Possible carry
   then

   dx ax mov  d# 16 # ax shr  h# ffff # dx and  ax dx add  \ Add two halves
   dx ax mov  d# 16 # ax shr  h# ffff # dx and  ax dx add  \ Again for carry
   dl dh xchg   \ Byte swap

   si pop
   dx push
c;

\ LICENSE_BEGIN
\ Copyright (c) 2008 FirmWorks
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
