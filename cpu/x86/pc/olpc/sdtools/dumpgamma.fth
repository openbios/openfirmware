\ See license at end of file
\ GX video processor register access routines
\ dump-gamma ( -- )    \ Displays the contents of the GAMMA RAM

\needs mmap fload ioports.fth

hex
-1 value vp-base

: vp@  ( reg -- l )  vp-base + l@  ;
: vp!  ( l reg -- )  vp-base + l!  ;

: dump-gamma  ( -- )
   ." Gamma mapping is "
   h# 50 vp@  1 and  if  ." disabled"  else  ." enabled"  then  cr

   0 h# 38 vp!
   h# 100 0 do
      i 2 u.r ." :   "
      i 8  bounds  do
         h# 40 vp@  8 u.r
      loop
      cr  exit?  if  leave then
   h# 8 +loop
;

-1 value dc-base

: dc@  ( reg -- l )  dc-base + l@  ;
: dc!  ( l reg -- )  dc-base + l!  ;

-1 value gp-base

: gp@  ( reg -- l )  gp-base + l@  ;
: gp!  ( l reg -- )  gp-base + l!  ;

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
