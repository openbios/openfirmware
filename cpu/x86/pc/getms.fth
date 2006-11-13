\ See license at end of file
purpose: Interval timing functions

headerless

\ First we define a hack version for use when the timer is off
0 value last-tick
0 value mst

: get-tick  ( -- tick-count )
   0 h# 43 pc! h# 40 pc@ h# 40 pc@ bwjoin 
; 

: (hack-get-msecs)  ( -- msecs )
   last-tick get-tick dup is last-tick - dup 0< if    
      h# 10000 + 
   then  mst + dup is mst   d# 1193 /
; 
' (hack-get-msecs) to get-msecs


0 value tick-msecs
: (get-msecs)  ( -- n )  tick-msecs  ;

d# 10 to ms/tick
\ d# 38,461 value ms-factor
0 value ms-factor	\ Set this later if we can get a calibrated value
0 value us-factor

code spins  ( #spins -- )
   cx pop  cx cx or  0<> if   begin  cx dec 0= until  then
c;

\ Delay for about 1 millisecond by taking advantage of the time
\ it takes to read the counter status register.  This is ugly
\ but it works on many or most PCs.
code stall-ms  ( -- )
   d# 760 #  cx  mov
   begin  43 # al in  cx dec  0= until
c;

: 1ms  ( -- )  ms-factor spins  ;
: us  ( #microseconds -- )  us-factor * spins  ;

: (ms)  ( #ms -- )
   dup  ms/tick 3 * u>  interrupts-enabled?  and  if  ( #ms )
      \ For relatively long durations, we use the ticker because it is
      \ presumed to be reasonably accurate over the long run.  However,
      \ if interrupts are not enabled, we can't use the ticker because
      \ it won't be ticking.

      get-msecs +           ( target )

      \ We use "- 0<" instead of "<" so that the right thing will happen
      \ when the tick count wraps around.
      \ We use "0<" instead of "0<=" so that we are sure to wait at least
      \ the requested time; otherwise we might not wait long enough if the
      \ first call to get-msecs were to occur just before the timer ticked.
      begin   dup get-msecs -  0<=  until   \ Loop until target time reached

      drop                  ( )
   else                     ( #ms )
      \ For relatively short durations, we use a timing loop because
      \ the ticker probably has rather coarse granularity.

      ms-factor  if
         0  ?do  ms-factor spins  loop
      else
         0  ?do  stall-ms  loop
      then
   then
;
' (ms) to ms

headers
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
