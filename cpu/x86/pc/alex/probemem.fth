\ See license at end of file
purpose: Create memory node properties and lists

dev /memory

: /ram  ( -- #bytes )  0  h# b0 config-w@  wljoin  ;  \ Pineview/Atom 450 chipset
: usable-ramtop  ( -- n )  h# ac config-l@  ;  \ Pineview TSEG Memory Base

: release-range  ( start-adr end-adr -- )  over - release  ;

: probe  ( -- )
   0 /ram  reg   \ Report extant memory

   \ Release some of the first meg, between the page tables and the DOS hole,
   \ for use as DMA memory.
   mem-info-pa 2 la+ l@   h# a.0000  release-range  \ Below DOS hole

   h# 10.0000  fw-pa  release-range
   fw-pa /fw-ram +  heap-base heap-size +  umax  usable-ramtop  release-range
;

[ifndef] 8u.h
: 8u.h  ( n -- )  push-hex (.8) type pop-base  ;
[then]
: .chunk  ( adr len -- )  ." Testing memory at: " swap 8u.h ."  size " 8u.h cr  ;
defer test-s3  ( -- error? )  ' false is test-s3
: selftest  ( -- error? )
   " available" get-my-property  if  ." No available property" cr true exit  then
                                         ( adr len )
   begin  ?dup  while
      2 decode-ints swap                 ( rem$ chunk$ )
      2dup .chunk                        ( rem$ chunk$ )
      \ We maintain a 1-1 convenience mapping so explicit mapping is unnecessary
      memory-test-suite  if  2drop true exit  then       ( rem$ )
   repeat  drop

   test-s3
;

device-end

also forth definitions
stand-init: Probing memory
   " probe" memory-node @ $call-method  
;
previous definitions

\ LICENSE_BEGIN
\ Copyright (c) 2011 FirmWorks
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
