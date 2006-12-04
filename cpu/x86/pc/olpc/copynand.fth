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

0 value #nand-pages
0 value nand-pages/block
0 value /nand-page

: written?  ( adr len -- flag )
   false -rot   bounds  ?do            ( flag )
      i @ -1 <>  if  0= leave  then    ( flag )
   /n +loop                            ( flag )
;

true value dump-oob?
: dump-nand  ( "devspec" -- )
   open-nand
   safe-parse-word   ( name$ )

   cr ." Dumping to " 2dup type  cr

   2dup ['] $delete  catch  if  2drop  then  ( name$ )
   $create-file to fileih

   fileih 0=  if  nandih close-dev  true abort" Can't open file"  then

   " block-size" nandih $call-method to /nand-page
   " size" nandih $call-method  /nand-page  um/mod nip to #nand-pages
   /nand-block /nand-page /  to nand-pages/block
   
   \ The stack is empty at the end of each line unless otherwise noted
   #nand-pages  0  do
      (cr i .
      load-base  i  nand-pages/block  " read-blocks" nandih $call-method
      nand-pages/block =  if
         load-base /nand-block  written?  if
            load-base /nand-block  " write" fileih $call-method drop
            dump-oob?  if
               i  nand-pages/block  bounds  ?do
                  i " read-oob" nandih $call-method  h# 40  ( adr len )
                  " write" fileih $call-method drop
                  i pad !  pad 4 " write" fileih $call-method drop
               loop
            then
         then
      then
   nand-pages/block +loop
   cr  ." Done" cr

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
