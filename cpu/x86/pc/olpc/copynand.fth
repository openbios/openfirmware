\ See license at end of file
purpose: Copy a file onto the NAND FLASH

0 value fileih
0 value nandih
0 value /nand-block

: open-nand  ( -- )
   " /nandflash" open-dev to nandih
   nandih 0= abort" Can't open NAND FLASH device"
   " erase-size" nandih $call-method to /nand-block
   " start-copy" nandih $call-method
;

: copy-nand  ( "devspec" -- )
   open-nand
   safe-parse-word  open-dev  to fileih
   fileih 0=  if  nandih close-dev  true abort" Can't open file"  then
   ." Erasing..." cr
   " wipe" nandih $call-method
   cr ." Writing..." cr
   0
   begin
      load-base /nand-block  " read" fileih $call-method
   0> while
      (cr dup .  1+
      load-base " copy-block" nandih $call-method
   repeat
   drop
   fileih close-dev
   nandih close-dev
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
