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
\ This algorithm depends on the assumption that the buffer is
\ short enough so that we never have a carry out of the high
\ 16 bit word.  Assuming worst case data (all bytes ff), the
\ buffer would have to be 128K + 3 bytes long for this to happen.
\ The maximum length of an IP packet is 64K bytes, so we are safe.
\ This allows us to accumulate the end-around carries in the high
\ 16-bit word and add them in one operation at the end.

code (oc-checksum)  ( accum adr len -- checksum )
   mr     t1,tos		\ t1: len
   lwz    t0,0(sp)		\ t0: adr
   lwz    tos,4(sp)		\ tos: accum
   addi   sp,sp,8		\ clean up stack

   mr     t2,t1			\ t2: copy of len
   cmpi   0,0,t1,2		\ Are there any complete words to do?
   >=  if

      mfspr  t5,ctr			\ Save counter

      rlwinm t1,t1,31,1,31		\ Convert to word count
      mtspr  ctr,t1

      'user in-little-endian?  lwz  t3,*	\ Which endian
      0=  if				\ If BE, use word accesses
         addi    t0,t0,-2		\ Account for pre-increment

         begin
            lhzu  t3,2(t0)		\ Read word and increment pointer
            add   tos,tos,t3		\ Update checksum
         countdown

         addi    t0,t0,2		\ Point to next byte
      else				\ If LE, use byte accesses
         addi    t0,t0,-1		\ Account for pre-increment

         begin
            lbzu   t4,1(t0)		\ Read high byte and increment pointer
            lbzu   t3,1(t0)		\ Read low byte and increment pointer
            rlwimi t3,t4,8,16,23	\ Merge high and low bytes into t3
            add    tos,tos,t3		\ Update checksum
         countdown

         addi    t0,t0,1		\ Point to next byte
      then

      mtspr   ctr,t5			\ Restore counter
   then

   andi.   r0,t2,1		\ Is there a leftover byte?
   0<>  if
      lbz    t3,0(t0)		\ Get the byte      
      rlwinm t3,t3,8,16,23	\ Move it to the correct position in the word
      add    tos,tos,t3		\ Update checksum
   then

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
