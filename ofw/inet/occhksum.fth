\ See license at end of file
purpose: Internet checksum (one's complement of 16-bit words)

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
[ifndef] (oc-checksum)
\ High-level version, in case an optimized version is not available.

\ This algorithm depends on the assumption that the buffer is
\ short enough so that we never have a carry out of the high
\ 16 bit word.  Assuming worst case data (all bytes ff), the
\ buffer would have to be 128K + 3 bytes long for this to happen.
\ The maximum length of an IP packet is 64K bytes, so we are safe.
\ This allows us to accumulate the end-around carries in the high
\ 16-bit word and add them in one operation at the end.

: (oc-checksum) ( accumulator addr count -- checksum )
   2dup 2>r  bounds  do  i  xw@ +  /w  +loop  ( sum r: adr,len )
   \ Subtract the extra byte at the end  
   2r> dup  1 and  if  + c@  -  else  2drop  then
;
[then]

: oc-checksum  ( accumulator addr count -- checksum )
   (oc-checksum)                       ( checksum' )
   lwsplit + lwsplit +                 ( checksum" )
   invert  h# 0.ffff and               ( checksum )
   \ Return ffff if the checksum is 0
   ?dup 0=  if  h# 0.ffff  then        ( checksum )
;
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
