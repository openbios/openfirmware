purpose: Cache driver for PowerPC 601 chip
\ See license at end of file

code stand-sync-cache-601  ( adr len -- )
   lwz   t0,0(sp)

   cmpi  0,0,t0,0
   <>  if
      addi      tos,tos,-1	\ Prevents touching the line past the end
      begin   
         dcbst  t0,tos
         sync
         icbi   t0,tos
         isync
         addic. tos,tos,-32
      0< until
      sync
   then

   lwz   tos,1cell(sp)
   addi  sp,sp,2cells
c;

warning @ warning off
: stand-init  ( -- )
   stand-init
   601?  if  ['] stand-sync-cache-601 to sync-cache  then
;
warning !

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
