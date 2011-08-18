\ See license at end of file
purpose: Create memory node properties and lists

\ All RAM, including that assigned to the frame buffer
0 value total-ram-cached
: total-ram  ( -- ramsize )
   total-ram-cached ?dup  if  exit  then
   h# 385 config-b@ d# 24 lshift
   h# 48 acpi-l@ h# 1000.0000 and  if  2/  then  \ Account for possible 32-bit width
   dup to total-ram-cached
;

\ Excludes RAM assigned to the frame buffer and used by OFW page tables
: system-ram  ( -- offset )  mem-info-pa 4 + l@  ;

: fbphys  ( -- adr )
   h# 6d h# 3c4 pc! h# 3c5 pc@   ( low )
   h# 6e h# 3c4 pc! h# 3c5 pc@   ( low high )
   bwjoin d# 21 lshift
;

: fbsize  ( -- n )  total-ram fbphys -  ;

dev /memory

\ Excludes RAM already used for page tables
: ram-limit  ( -- addr )  mem-info-pa la1+ l@  ;

: release-range  ( start-adr end-adr -- )  over - release  ;

: probe  ( -- )
[ifdef] virtual-mode
   origin >physical  to fw-pa
   fw-pa /dma-extra - to dma-base
[then]

   0 total-ram  reg   \ Report extant memory

   \ Put h# 10.0000-1f.ffff and 28.0000-memsize in pool,
   \ reserving 0..10.0000 for the firmware
   \ and 20.0000-27.ffff for the "flash"

\   h#  0.0000  h# 02.0000  release   \ A little bit of DMA space, we hope
\   h# 10.0000  h# 0f.ffff  release
\   h# 28.0000  h# 80.0000  release-range

\ Release some of the first meg, between the page tables and the DOS hole,
\ for use as DMA memory.
   mem-info-pa 2 la+ l@   h# a.0000  release-range  \ Below DOS hole

[ifdef] virtual-mode
   \ Release from 1M up to the amount of unallocated (so far) memory
   dropin-base ram-limit u<   if
      \ Except for the area that contains the dropins, if they are in RAM
      h# 10.0000  dropin-base  release-range
      dropin-base dropin-size +  ram-limit  release-range
   else
      h# 10.0000  ram-limit  release-range
   then
[else]
   h# 10.0000  system-ram  release-range

   fw-pa /fw-ram 0 claim  drop

   \ Account for the dropin area if it is in RAM
   dropin-base  system-ram  u<  if
      dropin-base dropin-size 0 claim
   then

[ifdef] relocated-fw
   initial-heap  swap >physical swap  0 claim  drop
[else]
   initial-heap  0 claim  drop
[then]
[then]
;

[ifndef] 8u.h
: 8u.h  ( n -- )  push-hex (.8) type pop-base  ;
[then]
: .chunk  ( adr len -- )  ." Testing address 0x" swap 8u.h ."  length 0x" 8u.h cr  ;

defer test-s3  ( -- error? )  ' false is test-s3
false to do-random-test?  \ The random test takes a long time

: show-line  ( adr len -- )  (cr type  3 spaces  kill-line  ;
' show-line to show-status

: selftest  ( -- error? )
   " available" get-my-property  if      ( )
     ." No available property in memory node" cr  ( )
     true exit                           ( -- true )
   then                                  ( adr len )
					 ( adr len )
   begin  dup  while                     ( rem$ )
      2 decode-ints swap		 ( rem$ chunk$ )
      2dup .chunk			 ( rem$ chunk$ )
      \ We maintain a 1-1 convenience mapping so explicit mapping is unnecessary
      memory-test-suite  if                ( rem$ )
         2drop                             ( )
         "     !!Failed!!" show-status  cr ( )
        true exit                          ( -- true )
      else                                 ( rem$ )
         "     Succeeded" show-status  cr  ( rem$ )
      then                                 ( rem$ )
   repeat  2drop                           ( )

   test-s3                                 ( )
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
