\ See license at end of file
purpose: CRC-32 calculation

\ Load this before forth/lib/crc32.fth

[ifdef] notdef
code crcstep  ( crc b table-adr -- crc' )
   \ tos: table-adr, r1:b, r2:crc
   ldmia   sp!,{r1,r2}
   eor     r1,r1,r2             \ r1: crc ^ byte
   and     r1,r1,#0xff          \ index
   ldr     tos,[tos,r1,lsl #2]  \ Table data
   eor     tos,tos,r2,lsr #8    \ Return crc'=table_data^(crc>>8)
c;
[then]

code ($crc)  ( crc table-adr adr len -- crc' )
   movs    r3,tos
   ldmia   sp!,{r1,r2,tos}     \ r1:adr, r2:table-adr, r3:len, tos:crc
   nxteq                       \ Bail out if len is 0

   begin
      ldrb     r4,[r1],#1         \ Get next byte
      eor      r4,r4,tos          \ r4: crc^byte
      and      r4,r4,#0xff        \ r4: index
      ldr      r4,[r2,r4,lsl #2]  \ lookup in table
      decs     r3,1               \ Decrement len
      eor      tos,r4,tos,lsr #8  \ crc' = table_data ^ (crc >> 8)
   0= until
c;

\ LICENSE_BEGIN
\ Copyright (c) 2010 FirmWorks
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
