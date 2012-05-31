\ See license at end of file
purpose: lid close triggers power off

false value lid-already-down?
0 value lid-down-time
d# 10000 constant lid-shutdown-ms
d#  2000 constant lid-warning-ms
0 value lid-warned?

: ?lid-shutdown  ( -- )
   lid?  if
      lid-already-down?  if
         get-msecs lid-down-time -               ( ms )

	 dup lid-warning-ms >=  lid-warned? 0=  and  if
	    cr
            ." Lid switch is active - powering off in 8 seconds" cr
            ." Type  lid-off  to disable this" cr
            true to lid-warned?
         then                                    ( ms )

         lid-shutdown-ms >=  if
            ." Powering off after 10 seconds of lid down" cr
            power-off
         then
      else
         get-msecs to lid-down-time
         true to lid-already-down?
      then
   else
      false to lid-already-down?
      false to lid-warned?
   then
;

[ifndef] do-lid
defer do-lid
[then]

: lid-on  ( -- )  ['] ?lid-shutdown to do-lid  ;
[ifndef] lid-off
: lid-off ( -- )  ['] noop to do-lid  ;
[then]
' lid-on to do-lid

\ LICENSE_BEGIN
\ Copyright (c) 2011 FirmWorks
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
