purpose: Selftest for ISA timer
\ See license at end of file

dev /isa/timer

\ "0 count@" takes 4.5 uS on XO-1 and 6.3 uS on XO-1.5, due to the
\ several I/O port accesses involved.  That is longer than the per-count
\ time, so the test for rollover needs some slop ("5 <") because you can't
\ depend on being able to see any specific value.
: wait-rollover  ( -- error? )
   get-msecs  d# 100 +   begin   ( time-limit )
      0 count@  5 <  if  drop false exit  then
      dup get-msecs -            ( time-limit diff )
   0<= until
   drop true
;
: selftest  ( -- error? )
   0 count@  0=  if
      1 ms
      0 count@ 0=  if
         ." The ISA PIT timer is not ticking."  cr
         ." Possible cause: bad 14 MHz clock to CS5536 chip." cr
         true exit
      then
   then

   lock[  wait-rollover  if
      ]unlock
      ." The ISA PIT timer did not reach a count of 1."  cr
      true exit
   then

   \ Ensure that rollover has completed so the first count below
   \ is higher than the second count (the counter counts down).
   d# 10 us  

   0 count@  1 ms  0 count@  ]unlock  -   ( delta-ticks )

   d# 1150 d# 1250 between  0=  if  \ Nominal delta is 1199
      ." The ISA PIT timer is ticking at the wrong rate." cr
      true exit
   then

   false
;

device-end
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
