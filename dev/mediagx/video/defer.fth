\ See license at end of file
purpose: Declare defered words and some primitives

hex 
headers

true constant safe?

d# 1024 value /scanline				\ Frame buffer line width
[ifndef] 640x480
d# 1024 value /displine				\ Displayed line width
d#  768 value #scanlines			\ Screen height
[else]
d# 640 value /displine				\ Displayed line width
d# 480 value #scanlines				\ Screen height
[then]

: declare-props  ( -- )		\ Instantiate screen properties
   " width" get-my-property  if  
      /displine  encode-int " width"     property
      #scanlines encode-int " height"    property
               8 encode-int " depth"     property
      /displine  encode-int " linebytes" property
   else
      2drop
   then
;

: /fb  ( -- )  /scanline #scanlines *  ;	\ Size of framebuffer

\ Helper words...

: map-in  (   )			\ Calls parent's map-in method
   " map-in" $call-parent
;

: map-out  (   )		\ Calls parent's map-out method
   " map-out" $call-parent
;

: c-w@  ( pci-idx -- pci-idx )  ;
: c-w!  ( data pci-idx -- )  2drop  ;


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
