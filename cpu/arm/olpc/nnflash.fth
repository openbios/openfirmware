\ See license at end of file
purpose: Reflash a Neonode touchscreen controller

: (nnv)  ( version.d adr -- version.d )
   2 $number abort" nn.hex, not a number"
   >r 8 dlshift swap r> or swap
;

: $nn-version  ( file$ -- version.d )
   $read-open           ( )
   3 0 do
      load-base d# 100 ifd @ read-line abort" nn.hex, read-line failed" 2drop
   loop
   load-base d# 25 +    ( adr )
   >r  0.               ( version.d  r: adr )
   r@ d#  2 + (nnv)  r@         (nnv)  r@ d#  6 + (nnv)  r@ d#  4 + (nnv)
   r@ d# 10 + (nnv)  r@ d#  8 + (nnv)  r@ d# 14 + (nnv)  r@ d# 12 + (nnv)
   r> drop              ( version.d )
   ifd @ fclose
   \ 59ms
;

: get-touchscreen-version  ( -- version.d )
   " /touchscreen" open-dev                    ( handle )
   dup 0= abort" could not open touchscreen"
   " get-version" 2 pick $call-method          ( handle version.d )
   >r >r close-dev r> r>                       ( version.d )
   \ 20ms first time, 270ms subsequent
;

: nn-up-to-date?  ( file$ -- flag )
   $nn-version                  ( version-in-file.d )
   2dup h# 0001.0000.0000.0000. d>= abort" nn.hex, major version conflict"
   get-touchscreen-version      ( version-in-file.d version-in-controller.d )
   d<=
;

: nn-image$  " rom:\nn.hex"  ;

: reflash-nn  ( file$ -- )
  $flash-bsl
;
: flash-nn  ( "filename" -- )  safe-parse-word  ?enough-power  reflash-nn  ;
: flash-nn! ( "filename" -- )  safe-parse-word                 reflash-nn  ;

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
   \ (disabled temporarily so that automatic update can be tested) 
   \ board-revision h# 4b20  <  if  false exit  then
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
