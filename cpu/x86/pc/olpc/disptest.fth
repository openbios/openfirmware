purpose: Display test
\ See license at end of file

dev /display

d# 100 constant bar-int
h# 7 constant test-colors16-mask
create test-colors16
\  white  magenta   yellow  red     green    blue    cyan    black
   ffff w, f81f w,  ffe0 w, f800 w, 07e0 w,  001f w, 07ff w, 0000 w,

: test-color16  ( n -- color )
   test-colors16 swap bar-int / test-colors16-mask and wa+ w@
;
: .horizontal-bars16  ( -- )
   dimensions				( width height )
   0  ?do				( width )
      i test-color16 0 i 3 pick bar-int " fill-rectangle" $call-screen
   bar-int +loop  drop
;
: .vertical-bars16  ( -- )
   dimensions				( width height )
   swap 0  ?do				( height )
      i test-color16 i 0 bar-int 4 pick " fill-rectangle" $call-screen
   bar-int +loop  drop
;

instance variable rn            	\ Random number
d# 60,000 constant burnin-time		\ 1 minute

: random  ( -- n )
   rn @  d# 1103515245 *  d# 12345 +   h# 7FFFFFFF and  dup rn !
;

: randomize-color  ( -- c )
   random h# 1f and d# 11 <<
   random h# 3f and d#  5 << or
   random h# 1f and          or
;
: randomize-xy  ( -- x y )
   dimensions				( width height )
   random 3ff and min swap		( y width )
   random 7ff and min swap		( x y )
;
: randomize-wh  ( x y -- w h )
   dimensions				( x y width height )
   rot - -rot				( max-h x width )
   swap - swap				( max-w max-h )
   randomize-xy				( max-w max-h w h )
   rot min -rot min swap		( w' h' )
;
: .random-rect  ( -- )
   randomize-color			( c )
   randomize-xy				( c x y )
   2dup randomize-wh			( c x y w h )
   " fill-rectangle" $call-screen	( )
;

: random-selftest  ( -- )
   get-msecs rn !
   get-msecs burnin-time +    ( limit )
   begin
      get-msecs over u<       ( limit reached? )
   while                      ( limit )
      .random-rect            ( limit )
      key?  if  key 2drop exit  then
   repeat                     ( limit )
   drop
;

: selftest  ( -- error? )
   bytes/pixel 2 <>  if  false exit  then
   .horizontal-bars16
   d# 2000 ms
   .vertical-bars16
   d# 2000 ms
   ." Press a key to stop early." cr
   d# 1000 ms
   random-selftest
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
