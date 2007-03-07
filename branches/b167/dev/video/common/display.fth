\ See license at end of file
purpose: Package methods for display controller

hex
headers

" display"                      device-type
" ISO8859-1" encode-string    " character-set" property
0 0  encode-bytes  " iso6429-1983-colors"  property

: display-install  ( -- )
   init
   default-font set-font
   /scanline #scanlines over char-width / over char-height / fb8-install
   init-hook
;

\ display-remove is elsewhere (e.g. init.fth) because it has no
\ generic semantics with respect to the FB8 package.

: display-selftest  ( -- failed? )  false  ;

fload ${BP}/dev/video/common/rectangl.fth

headers

' display-install  is-install
' display-remove   is-remove
' display-selftest is-selftest
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
