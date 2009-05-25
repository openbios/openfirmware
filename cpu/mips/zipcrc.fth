purpose: ZIP CRC calculation
\ See license at end of file

\ Load this before pkg/zipcrc.ftg

headers

transient
only forth also assembler also definitions
alias blen  t0
alias badr  t1
alias table t2
alias crc   tos
alias eadr  t3
alias i     t4
alias crc'  t5
only forth also definitions
resident

code ($crc)  ( crc table-adr adr len -- crc' )
   tos  blen  move
   sp   badr  pop
   sp   table pop
   sp   crc   pop

   blen 0 =  if  nop next  then	\ Exit if len=0

   badr blen eadr addu		\ Compute end loop condition
   begin
      badr 0      i     lbu	\ Get next byte
      crc  i      i     xor	\ crc ^ byte
      i    h# ff  i     andi	\ index
      i    2      i     sll	\ index * 4
      i    table  i     add
      i    0      crc'  lw	\ Lookup in table
      crc  8      crc   srl	\ Shift old crc
      badr 1      badr  addiu	\ Increment address
   badr eadr =  until
      crc' crc    crc   xor	\ Merge new bits

c;


\ LICENSE_BEGIN
\ Copyright (c) 2009 FirmWorks
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
