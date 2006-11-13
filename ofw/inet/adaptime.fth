\ See license at end of file
purpose: Adaptive retry timeouts

d# 200 constant min-timeout
d# 5000 constant max-timeout
0 instance value srtt
0 instance value time0
d# 4000 instance value next-timeout  \ First timeout is 4 seconds

\ Smoothed round-trip-time (srtt) = (ALPHA * old SRTT) + ((1-ALPHA) * RTT)
\ where alpha in this case is 4/5
: compute-srtt  ( -- )
   srtt 4 * get-msecs time0 -  +  5 /  to srtt
   bootnet-debug 0=  if
      \ If netword debugging is on, don't shorten the timeout, because
      \ the time to display the debugging messages can exceed the round-trip
      \ time, thus causing false timeouts.
      srtt 3 * 2/  min-timeout max  max-timeout min  to next-timeout
   then
;

\ Randomize the timeout by a uniformly-distributed random number in
\ the range +-63 msecs.
: randomize  ( msecs -- msecs' )
   random  dup h# 3f and  swap h# 40 and  if negate  then  +
;

\ Timeout starts at a value that depends on the smoothed round-trip time,
\ and doubles on each consecutive missed packet.  Successful reception
\ of a tftp data packet resets it to the (newly-recomputed) starting value.

: update-timeout  ( -- )
   get-msecs to time0
   next-timeout randomize set-timeout
   next-timeout 2*  max-timeout min  to next-timeout
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
