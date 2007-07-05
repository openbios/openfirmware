purpose: Fast memory scrubbing - 601 version
\ See license at end of file

\ Usage requirements:
\   adr must aligned on a cache line boundary
\   len must a multiple of the cache line size
\   the range must not overlap an 8 MB (h# 80.0000) boundary
\   the data cache must be turned on
: berase-range  ( adr len -- )
   over  h# ff80.0000 and  dup h# 80.0000  false  2 i&dbats bat!
   /dcache-block /  /dcache-block  (berase)
   0 0 2 ibat!
;
: berase-601  ( adr len -- )
   begin  dup  while                     ( adr len )
      \ Find the length of a piece that doesn't overlap a BAT boundary
      over  dup h# 7f.ffff or 1+ swap -  ( adr len len-to-boundary )
      over umin                          ( adr len piece-len )
      >r  over r@ berase-range           ( adr len )  ( r: piece-len )
      r> /string                         ( adr' len' )
   repeat                                ( adr' 0 )
   2drop
;
warning @ warning off
: berase  ( adr len -- )
   601?  if  berase-601 exit  then
   berase
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
