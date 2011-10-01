\ See license at end of file
purpose: Common code for OLPC Camera selftest

d# 5,000 constant movie-time
0 constant test-x
0 constant test-y

\ Thanks to Cortland Setlow (AKA Blaketh) for the autobrightness code
\ and the full-screen + mirrored display.

: autobright  ( -- )
   read-agc 3 + 3 rshift  h# f min  " bright!" " $call-screen" evaluate
;
: full-brightness  ( -- )  h# f " bright!" " $call-screen" evaluate  ;

: timeout-read  ( adr len timeout -- actual )
   >r 0 -rot r>  0  ?do			( actual adr len )
      2dup read ?dup  if  3 roll drop -rot leave  then
      1 ms
   loop  2drop
;

: shoot-still  ( -- error? )
   d# 1000 snap  if  true exit  then   ( buf )
   display-frame  ( autobright )
   false
;

: shoot-movie  ( -- error? )
   get-msecs movie-time +			( timeout )
   begin                 			( timeout )
      shoot-still  if  drop true exit  then 	( timeout )
      dup get-msecs - 0<=                       ( timeout reached )
   until					( timeout )
   drop false
;

: selftest  ( -- error? )
   camera-blocked?  if  false exit  then
   open 0=  if  true exit  then
   d# 300 ms
   start-display
   unmirrored  resync                                   ( )
   shoot-still  ?dup  if  stop-display close exit  then	( error? )
   d# 1,000 ms
   mirrored  resync  shoot-movie  full-brightness	( error? )
   stop-display close					( error? )
   ?dup  0=  if  confirm-selftest?  then		( error? )
;

: xselftest  ( -- error? )
   open 0=  if  true exit  then
   h# 10 0 do
      shoot-still  drop  d# 500 ms  camera-config  config-check
      i dump-regs
   loop
   0 close					( error? )
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
