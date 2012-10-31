\ See license at end of file
purpose: Reflash a Neonode touchscreen controller

: get-touchscreen-version  ( -- version.d )
   " /touchscreen" open-dev                    ( handle )
   dup 0= abort" could not open touchscreen"
   " get-version" 2 pick $call-method          ( handle version.d )
   >r >r close-dev r> r>                       ( version.d )
;

: nn-image$  " rom:\nn.hex"  ;

: reflash-nn  ( file$ -- )
  $flash-bsl
;
: flash-nn  ( "filename" -- )  safe-parse-word  ?enough-power  reflash-nn  ;
: flash-nn! ( "filename" -- )  safe-parse-word                 reflash-nn  ;
: nn-up-to-date?  ( file$ -- flag )
   2drop  h# 0000.0000.0000.0006.  \ FIXME: get version from file
   get-touchscreen-version
   d<=
;

: update-nn-flash  ( -- )
   nn-image$  2dup nn-up-to-date?  if
      2drop
   else
      reflash-nn
   then
;

: update-nn-flash?  ( -- flag )
   \ XO-4 B1 have clear lightguides incompatible with later versions
   \ of touchscreen firmware.
   board-revision h# 4b20  <  if  false exit  then
   nn-image$  nn-up-to-date?  0=
;

\ LICENSE_BEGIN
\ Copyright (c) 2012 FirmWorks
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
