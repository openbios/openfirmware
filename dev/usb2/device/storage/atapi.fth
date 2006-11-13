purpose: ATAPI interface
\ See license at end of file

hex

headers

d# 12 dup constant pkt-len
buffer: pkt-buf

\ ATAPI devices only accept 12 byte long commands
\ Fixup the SCSI commands before sending them out

: translate-atapi-command  ( cmd-adr,len -- pkt-buf,len )
   pkt-buf dup >r pkt-len erase			\ Zero pkt-buf
   r@ swap move					\ Copy cmd$ to pkt-buf
   r@ c@ dup h# 15 = swap h# 1a = or  if	\ Mode send or mode select command
      r@ c@ h# 40 or r@ c!			\ Fix it
      r@ 4 + c@ r@ 8 + c!
      0 r@ 4 + c!
   else
      r@ c@ dup 8 = swap h# a = or  if		\ Read or write command
         r@ c@ h# 20 or r@ c!			\ Fix it
         r@ 1+ c@ dup h# e0 and r@ 1+ c!
         r@ 4 + c@ r@ 8 + c!
         r@ 3 + c@ r@ 5 + c!
         r@ 2 + c@ r@ 4 + c!
         h# 1f and r@ 3 + c!
         0 r@ 2 + c!
      then
   then
   r> pkt-len
;

: init-atapi-execute-command  ( -- )
   " is-atapi" get-my-property 0=  if
      2drop
      ['] translate-atapi-command to execute-command-hook
   then
;
' init-atapi-execute-command  to init-execute-command

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
