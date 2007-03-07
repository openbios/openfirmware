\ See license at end of file
purpose: Main load file for MediaGX video driver

\ mediagx\reg.fth must have been included

" display" device-name

fload ${BP}/dev/mediagx/video/reg.fth		 \ reg property
fload ${BP}/dev/mediagx/video/defer.fth          \ Defered words
fload ${BP}/dev/mediagx/video/cyrix.fth          \ Controller code
fload ${BP}/dev/mediagx/video/dacs.fth	         \ DAC routines
fload ${BP}/dev/mediagx/video/graphics.fth       \ Graphics and color routines
fload ${BP}/dev/video/common/init.fth		 \ Init code
fload ${BP}/dev/video/common/display.fth	 \ High level interface code

[ifdef] 640x480
external
: dimensions  ( -- width height )
   /displine	( width )
   #scanlines	( width height )
;
headers
[then]\ LICENSE_BEGIN
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
