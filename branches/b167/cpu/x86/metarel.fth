\ See license at end of file
\ Maintain a relocation table

\ needs lbsplit ../../extend/split.fth

decimal

only forth also definitions
alias constant-h constant
alias create-h create

only forth also meta also definitions
max-kernel-t 16 /  constant-h /relocation-map-t  
					\ Number of bytes in bitmap
create-h relocation-map-t  /relocation-map-t  allot
relocation-map-t    /relocation-map-t  erase

\ The relocation map has one bit for every 16-bit word, since we assume
\ that relocated longwords must start on a 16-bit boundary
:-h >offset-t ( addr -- offset )
  2/
;

:-h meta-set-relocation-bit  ( addr -- addr )
  dup >offset-t  relocation-map-t bitset
;

:-h meta-init-relocation ( -- )
  relocation-map-t /relocation-map-t 0 fill
;
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
