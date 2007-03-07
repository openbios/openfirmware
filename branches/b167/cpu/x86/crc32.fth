\ See license at end of file
purpose: CRC-32 calculation

\ Load this before forth/lib/crc32.fth

[ifdef] notdef
code crcstep  ( crc b table-adr -- crc' )
   dx pop           \ table-adr
   ax pop           \ byte
   bx pop           \ crc
   bx ax xor        \ crc ^ byte
   h# ff # ax and   \ index
   0 [dx] [ax] *4  dx  mov
   bx  8 #  shr
   dx  bx  xor
   bx push
c;
[then]

code ($crc)  ( crc table-adr adr len -- crc' )
   cx pop         \ count
   ax pop         \ adr
   dx pop         \ table-adr
   bx pop         \ crc

   cx cx or  0=  if  bx push  next  then

   si push	  \ Save register
   ax si mov	  \ Put adr in SI

   begin
      al lods		       \ Get next byte
      bx ax xor                \ crc ^ byte
      h# ff #  ax  and         \ index
      0 [dx] [ax] *4  ax  mov  \ lookup in table
      bx  8 #  shr             \ Shift old crc
      ax  bx  xor              \ Merge new bits
   loopa   

   si pop	 \ Restore register

   bx push       \ Return CRC
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
