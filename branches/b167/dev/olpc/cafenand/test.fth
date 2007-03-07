\ See license at end of file
patch 20000110 68000110 pio-write  \ Turn off auto-ECC

load-base constant ib
load-base h# 100000 +  constant ob

/page h# 40 + constant /full-page

: mismatch?  ( -- flag )  ob ib /full-page  comp 0<>  ;
: .where  ( -- )
   ." Bad at offset "

   /full-page  0  do
      ob i + l@  ib i + l@  <>  if
         i u.  leave
      then
   /l +loop
   cr
;

: fill-eb  ( page# -- )
   pages/eblock bounds  do
      ob  /full-page  i 0  pio-write
   loop
;

: check-eb  ( page# -- )
   pages/eblock bounds  do
      ib  /full-page  i 0  pio-read
      mismatch?  if  i .  .where  leave  then
   loop
;

\ Display progress every so often
: ?.  ( n -- )  dup h# fff and  if  (cr .  else  drop  then  ;

: test-eb  ( page# -- )
   ." E"
   dup erase-block
   ob /full-page h# ff fill
   dup check-eb

   ." 5"
   ob /full-page h# 55 fill
   dup fill-eb
   dup check-eb

   ." E"
   dup erase-block
   ob /full-page h# ff fill
   dup check-eb

   ." A"
   ob /full-page h# aa fill
   dup fill-eb
   dup check-eb

   drop
;

: test-all  ( -- )
   pages/chip 0  do
      (cr i .
      i test-eb
      key? ?leave
   pages/eblock +loop
;

\ XXX skip mfg bad blocks
: erase-all  ( -- )
   pages/chip 0  do
      (cr i .
      i erase-block
      key? ?leave
   pages/eblock +loop
;
: fix-bb-table
 ob 40 0 fill
 ob 40 2c340 800 pio-write
 ob 40 2c341 800 pio-write
 ob 40 39840 800 pio-write
 ob 40 39841 800 pio-write
;

: scan-all
   cr
   pages/chip 0  do
      i ?.
      ib  /full-page  i 0  pio-read
      mismatch?  if  i .  .where  then
   loop
;

: scan-ff  ( -- )
   \ Something to compare against
   ob /full-page  h# ff fill

   scan-all
;

: block-bad?  ( page# -- flag )
   ib 1  rot  h# 800  pio-read
   ib c@  h# ff <>
;
: .bad  ( page# -- )  .x ." bad" cr  ;
: initial-badblock-scan  ( -- )
   pages/chip 0  do
      i block-bad?  if
         i .bad
      else
         i 1+ block-bad?  if  i .bad  then
      then
   pages/eblock +loop
;


\ Non-blank block list
\ All-0 erase-blocks
\ 4e40 117c0 12280 1a880 1ac00 1c340 1c880 1ffc0 
\ 22640 25880 26580 313c0 35300 3ffc0 

\ Not found in read/write test...
\ 2c340 Bad at offset 800  All extra bytes 0
\ 2c341 Bad at offset 800

\ 39840 Bad at offset 800
\ 39841 Bad at offset 800

[ifdef] notdef
h# 840 constant /buf  \ 2K data bytes + 64 extra bytes

0 instance value ibuf  \ For testing
0 instance value obuf  \ For testing
: allocate-dma-buffers  ( -- )
   ibuf  if  exit  then
   /buf " dma-alloc" $call-parent  to ibuf
   /buf " dma-alloc" $call-parent  to obuf
;

: dma-test  ( -- )
   allocate-dma-buffers
   ibuf /buf erase
   obuf /buf bounds ?do  i i /l +loop
   obuf /buf 0 0 dma-write
   ibuf /buf 0 0 dma-read
;
[then]

: scan-bad  ( -- )
   pages/chip 0  do
      bbbuf 4  i     h# 800  pio-read  i    .bad
      bbbuf 4  i 1+  h# 800  pio-read  i 1+ .bad
   pages/eblock  +loop
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
