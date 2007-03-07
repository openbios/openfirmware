\ See license at end of file
\ Maintain a byte swap table

decimal

only forth also meta also definitions
h# 10000 constant max-kernel-t

\ The swap map has one bit for every 32-bit word, since we assume
\ that relocated longwords must start on a 32-bit boundary
d# 32 constant bits/swapbit-t

\ Number of bytes in bitmap
: >swap-map-size-t  ( end-adr -- )
   origin-t -  bits/swapbit-t /mod  swap  if  1+  then
;

max-kernel-t >swap-map-size-t constant /swap-map-t  \ Number of bytes in bitmap
/swap-map-t buffer: swap-map-t

: set-swap-bit-t  ( addr -- )  origin-t -  2 >>  swap-map-t bitset  ;
: note-string-t  ( adr len -- adr len )
   2dup bounds  ?do  i set-swap-bit-t  /n +loop
;

: init-swap-t  ( -- )  swap-map-t /swap-map-t erase  ;
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
