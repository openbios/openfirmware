purpose: Video streaming test helper words
\ See license at end of file

hex
headers

load-base value vs-adr
0 value vs-/frame
0 value vs-height
0 value vs-width
0 value vs-x
0 value vs-y
d# 16 buffer: vs-guid
\ XXX Need support for other format than YUV2 frames.
: vs>screen  ( -- )
   vs-adr dup vs-/frame yuv2>rgb
   vs-adr vs-x vs-y vs-width vs-height " draw-rectangle" $call-screen
;

: cfg-vs-test  ( guid w h /frame -- xt adr )
   to vs-/frame  to vs-height  to vs-width
   vs-guid d# 16 move

   ." Press a key to exit"
   cursor-off
   " dimensions" $call-screen      ( w h )
   vs-height - 2/ to vs-y
   vs-width  - 2/ to vs-x

   ['] vs>screen  vs-adr
;


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

