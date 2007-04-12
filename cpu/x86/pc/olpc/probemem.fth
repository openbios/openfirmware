\ See license at end of file
purpose: Create memory node properties and lists

dev /memory

h# f70.0000 constant /ram   \ 256 MB

: release-range  ( start-adr end-adr -- )  over - release  ;

: ram-limit  ( -- addr )  mem-info-pa la1+ l@  ;

: ram-range  ( -- extant avail )
[ifdef] lx-devel
   h# 1000.0000  h# f70.0000 exit
[then]
   gpio-data@ 4 and  if
      h#  800.0000  h# 770.0000
   else
      h# 1000.0000  h# f70.0000
   then
;

: probe  ( -- )
   ram-range to /ram    ( total-ram )

   0 swap  reg   \ Report extant memory

   \ Put h# 10.0000-1f.ffff and 28.0000-memsize in pool,
   \ reserving 0..10.0000 for the firmware
   \ and 20.0000-27.ffff for the "flash"

\   h#  0.0000  h# 02.0000  release   \ A little bit of DMA space, we hope
\   h# 10.0000  h# 0f.ffff  release
\   h# 28.0000  h# 80.0000 h# 28.0000 -  release

\ Release some of the first meg, between the page tables and the DOS hole,
\ for use as DMA memory.
   mem-info-pa 2 la+ l@   h# a.0000  release-range  \ Below DOS hole

[ifdef] virtual-mode
   \ Release from 1M up to the amount of unallocated (so far) memory
   dropin-base ram-limit u<   if
      \ Except for the area that contains the dropins, if they are in RAM
      h# 10.0000  dropin-base over -  release
      dropin-base dropin-size +  ram-limit  over -  release
   else
      h# 10.0000  ram-limit  over -  release
   then
[else]
   h# 10.0000                             ( free-bot )
   fw-pa                                  ( free-bot free-top )

   \ Account for the dropin area if it is in RAM
   dropin-base  /ram  u<  if              ( free-bot free-top )
      dropin-base umin                    ( free-bot free-top' )
   then                                   ( free-bot free-top )

   over -  release

   fw-pa /fw-ram +                        ( piece2-base )

   \ Account for the dropin area if it is in RAM
   dropin-base  /ram u<  if               ( piece2-base )
      dropin-base dropin-size +  umax     ( piece2-base' )
   then                                   ( piece2-base )

   /ram  over -  release
[then]
;

[ifndef] 8u.h
: 8u.h  ( n -- )  push-hex (.8) type pop-base  ;
[then]
: .chunk  ( adr len -- )  ." Testing memory at: " swap 8u.h ."  size " 8u.h cr  ;
: selftest  ( -- error? )
   " available" get-my-property  if  ." No available property" cr true exit  then
					 ( adr len )
   begin  ?dup  while
      2 decode-ints swap		 ( rem$ chunk$ )
      2dup .chunk			 ( rem$ chunk$ )
      2dup over swap 3 mmu-map		 ( rem$ chunk$ )
      memory-test-suite  if  2drop true exit  then	 ( rem$ )
   repeat  drop
   false
;

device-end

also forth definitions
stand-init: Probing memory
   " probe" memory-node @ $call-method  
;
previous definitions

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
