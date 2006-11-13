\ See license at end of file
purpose: Place deferred error code call-outs into driver.

\ Some customers want error codes printed rather than "ok" or "not ok".
\ This code creates the framework for doing this.  A bunch of defferred
\ error code calls are made that can be patched up later (by a customer
\ specific file) to plug error code calls into the defferred calls.

\ The basic list of error code calls and when they would be called.

\ There are 5 tests (S/N, Loss, Freq Resp, Distortion, Cross Talk)
\ And each of them are run in two modes, left and right channel. each
\ test can be run in any of three loops, line-out to line-in, or
\ line-out to mike1-in or line-out to mike2-in.  Lots of cases to deal
\ with...

\ External code (machine specifc can plug er1 - er20 for error code
\ printing

\ line-out to line-in cass:
\ Left channel
defer er1   ['] noop to er1	\ S/N failure
defer er2   ['] noop to er2	\ Loss failure
defer er3   ['] noop to er3	\ Freq Resp
defer er4   ['] noop to er4	\ Distortion
defer er5   ['] noop to er5	\ Cross talk

\ Right channel
defer er6   ['] noop to er6	\ S/N failure
defer er7   ['] noop to er7	\ Loss failure
defer er8   ['] noop to er8	\ Freq Resp
defer er9   ['] noop to er9	\ Distortion
defer er10  ['] noop to er10	\ Cross talk


\ Line-out to Mic1-in cases:	( sub-testing of left channel )
defer er11  ['] noop to er11	\ S/N failure
defer er12  ['] noop to er12	\ Loss failure
defer er13  ['] noop to er13	\ Freq Resp
defer er14  ['] noop to er14	\ Distortion
defer er15  ['] noop to er15	\ Cross talk

\ Line-out to Mic1-in cases:	( sub-testing of right channel )
defer er16  ['] noop to er16	\ S/N failure
defer er17  ['] noop to er17	\ Loss failure
defer er18  ['] noop to er18	\ Freq Resp
defer er19  ['] noop to er19	\ Distortion
defer er20  ['] noop to er20	\ Cross talk

\ The following code is called from the driver sode to swap the
\ appropriate error codes in and out as needed.  Machine side code
\ should not have to mess with this part.

defer ec1
defer ec2
defer ec3
defer ec4
defer ec5

: set-line-in-errors-left
   ['] er1 to ec1
   ['] er2 to ec2
   ['] er3 to ec3
   ['] er4 to ec4
   ['] er5 to ec5
;
set-line-in-errors-left			\ Init ec1..5

: set-line-in-errors-right
   ['] er6 to ec1
   ['] er7 to ec2
   ['] er8 to ec3
   ['] er9 to ec4
   ['] er10 to ec5
;

: set-mic1-in-errors
   ['] er11 to ec1
   ['] er12 to ec2
   ['] er13 to ec3
   ['] er14 to ec4
   ['] er15 to ec5
;

: set-mic2-in-errors
   ['] er16 to ec1
   ['] er17 to ec2
   ['] er18 to ec3
   ['] er19 to ec4
   ['] er20 to ec5
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
