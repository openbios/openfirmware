\ See license at end of file
purpose: Layer on top of UART output to echo to the screen too

0 value ega-col#
h# b8000 constant ega-line0
d# 160 constant /ega-line
: >ega-line  ( line# -- adr )  /ega-line *  ega-line0 +  ;
d# 24 >ega-line constant ega-line24

: ega-(cr  ( -- )  0 to ega-col#  ;
: ega-lf  ( -- )
   1 >ega-line  ega-line0  d# 24 /ega-line *  move
   ega-line24  /ega-line  bounds  do   bl i c!  h# 07  i 1+ c!  2 +loop
   \  d# 2,000 0 do  h# 43 pc@ drop  loop  \ Cheesy .2 second delay
;
: ega-(emit  ( char -- )
   ega-col#  d# 80 =  if  ega-(cr  ega-lf  then
   ega-line24 ega-col# wa+  tuck c!  h# 1d swap 1+ c!
   ega-col# 1+ to ega-col#
;
: ega-emit  ( char -- )
   case
      carret    of  ega-(cr  endof
      linefeed  of  ega-lf   endof
      ( default )  dup ega-(emit
   endcase
;

: ega-uemit  ( char -- )  dup uemit ega-emit  ;
warning @ warning off
: inituarts  ( -- )  inituarts  ega-(cr  ;
: install-uart-io  ( -- )  install-uart-io  ['] ega-uemit is (emit  ;
warning !
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
