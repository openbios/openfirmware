purpose: Use the MIPS R4000 count/compare registers for the tick interrupt
\ See license at end of file

: tick-interrupt  ( level -- )
   drop
   tick-counts compare@ +  dup compare!	  ( next-count )  \ Setup next tick

   \ If the count is already ahead of the comparator, the ticker has slipped
   \ badly, so we advance the tick in order to avoid a really long interval.
   count@ - 0<  if  tick-counts count@ +  compare!  then

   tick-msecs ms/tick +  to tick-msecs
   ?call-os
   check-alarm
;

0 value tick-counts
: (set-tick-limit)  ( #msecs -- )
   to ms/tick
   ms/tick ms-factor *  to tick-counts
   tick-counts count@ + compare!
   ['] tick-interrupt 7 interrupt-handler!
   7 enable-interrupt
;
' (set-tick-limit) to set-tick-limit

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
