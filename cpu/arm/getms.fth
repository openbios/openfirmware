purpose: Interval timing functions
\ See license at end of file

headerless

0 value tick-msecs
: (get-msecs)  ( -- n )  tick-msecs  ;
' (get-msecs) to get-msecs

d# 10 value ms/tick
d# 78,764 constant ms-factor
0 value us-factor

code spins  ( count -- )
   cmp     tos,#0
   <>  if
      begin
         subs    tos,tos,#1
      0= until
   then
   pop     tos,sp 
c;
: 1ms  ( -- )  ms-factor spins  ;

: (us)  ( #microseconds -- )  us-factor * spins  ;
' (us) to us

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

      0  ?do  ms-factor spins  loop
   then
;
' (ms) to ms

headers

\ LICENSE_BEGIN
\ Copyright (c) 1997 FirmWorks
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
