purpose: Read the endian flag byte from the NVRAM
\ See license at end of file

\needs get-nv-byte  fload ${BP}/cpu/ppc/prep/nv7x.fth

\ Destroys:  r1,r4
\ Out:       r3: le-flag

label read-le-flag  ( -- r3: le-flag )
   mfspr   r4,lr

   \ Read the big/little endian flag from location 9 of the NVRAM.
   set  r3,9   get-nv-byte bl *

   cmpi  0,0,r3,h#4c		\ Compare to 'L'
   0<> if			\ Set r3 only if the byte is exactly 'L'
      set  r3,0
   else
      set  r3,-1
   then

\   set  r3,0			\ Big-endian
\   set  r3,1			\ Little-endian

   mtspr  lr,r4
   bclr 20,0
end-code

\ LICENSE_BEGIN
\ Copyright (c) 1997 FirmWorks
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

