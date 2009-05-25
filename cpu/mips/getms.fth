purpose: Interval timing functions
\ See license at end of file

headerless

: ticks-enabled?  ( -- flag )  sr@ h# 8001 tuck and  =  ;

0 value tick-msecs
: (get-msecs)  ( -- n )  tick-msecs  ;
' (get-msecs) to get-msecs

d# 10 value ms/tick
d# 50,000 constant ms-factor
d# 50 value us-factor

: ticks  ( #ticks -- )
   count@ +    ( target )

   \ We use "- 0<" instead of "<" so that the right thing will happen
   \ when the tick count wraps around.
   \ We use "0<" instead of "0<=" so that we are sure to wait at least
   \ the requested time; otherwise we might not wait long enough if the
   \ first call to get-msecs were to occur just before the timer ticked.
   begin   dup count@ -  0<=  until   \ Loop until target time reached
   drop                  ( )
;
: us  ( #microseconds -- )  us-factor *  ticks ;

: (ms)  ( #ms -- )
   dup  ms/tick 3 * u>  ticks-enabled?  and  if  ( #ms )
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

      ms-factor *  ticks
   then
;
' (ms) to ms

" calibrate ticker in cpu/mips/getms.fth" ?reminder

d# 33,333,333 constant cpu-clock-speed

\ The way to do this is to determine the internal clock frequency
\ by multiplying 33.3 MHz by the multiplier value derived from the
\ CP0 config register, then dividing by two to get the number of ticks
\ per second, from which us-factor and ms-factor can be derived.
: calibrate-ticker  ( -- )
   cpu-clock-speed			( bus-clock-Hz )
   config@ d# 28 rshift 7 and  case
      0 of  2 *  endof		\ 2:1
      1 of  3 *  endof		\ 3:1
      2 of  4 *  endof		\ 4:1
      6 of       endof		\ 1:1
      7 of  3 *  2 /  endof		\ 3:2
   endcase                         	( processor-clock-Hz )
   1+ 2/				( count-Hz )
   d# 1000 /  dup to ms-factor          ( ms-counts )
   d# 1000 /      to us-factor
;

headers
stand-init: Calibrate
   calibrate-ticker
;

\ LICENSE_BEGIN
\ Copyright (c) 2009 FirmWorks
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
