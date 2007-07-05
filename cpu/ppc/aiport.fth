purpose: Assembly-language driver for Promice Analysis Interface "serial port"
\ See copyright at end of file

\ Requires the following external definitions:
\ ai-serial  ( -- n )	\ Returns the base address of the AI port registers

label init-serial  ( -- )  \ Destroys: r3
   begin
      ai-serial  set  r3,*
      lbz     r3,3(r3)		\ Read status register
      cmpi    0,0,r3,h#cc	\ 0xcc is status_invalid
   <> until			\ Wait for port to become active

   ai-serial  set r3,*
   lbz     r3,2(r3)		\ Read data port (because the docs say to)
   bclr    20,0
end-code

label putchar  ( r3 -- )  \ Destroys: r1, r2
   ai-serial   set  r1,*
   begin
      lbz     r2,3(r1)		\ Read status register
      andi.   r0,r2,1		\ Transmitter ready bit
   0= until			\ Wait for ready

   \ send char
   lbz   r2,1(r1)		\ start bit

   andi. r3,r3,h#ff		\ Clear high bits just in case

   ori   r3,r3,h#100		\ merge in stop bit
   begin
      \ use the fact that ONE = 1 and ZERO = 0
      andi.  r2,r3,1
      lbzx   r2,r1,r2		\ send bit
      rlwinm. r3,r3,31,1,31	\ last bit will be stop bit
   0= until

   bclr  20,0
end-code

label getchar  ( -- r3 )
   begin			\ wait for byte
      ai-serial  set r3,*
      lbz     r3,3(r3)		\ Read status register
      andi.   r0,r3,2		\ Test received byte available bit
   0<> until

   ai-serial  set r3,*
   lbz     r3,2(r3)		\ Read received byte
   bclr    20,0
end-code

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
