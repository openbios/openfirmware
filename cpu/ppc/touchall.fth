purpose: Forces all translations into the HTAB
\ See license at end of file

: touch  ( -- )
   " /mmu" find-device
   " translations" get-property  abort" No translations property"  ( adr len )
   begin  dup  while
      decode-int >r    ( r: virt )
      decode-int >r    ( r: virt size )
      decode-int drop  ( r: virt size )   \ Discard phys.hi
      decode-int drop  ( r: virt size )   \ Discard phys.lo
      decode-int  h# 20 and  if   ( r: virt size )  \ I/O
         2r> 2drop
      else
         r> r> swap  bounds  ?do  i c@ drop  pagesize +loop
      then
   repeat
   2drop
;

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
