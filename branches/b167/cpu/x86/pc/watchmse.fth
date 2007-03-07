\ See license at end of file
purpose: Mouse test code

: ?.  ( n mask -- n )  over and  if  ." *"  else  ." ."  then  ;
: watch-mouse  ( -- )
   " mouse" open-dev ?dup 0=  if  ." The mouse is not present" cr  exit  then
   >r

   ." Move mouse and push its buttons.  Type any key to stop." cr
   begin
      d# 100 " get-event" r@  $call-method  if
         (cr
         ." Buttons: "   1 ?. 2 ?. 4 ?.  drop
         push-decimal
         ."   DeltaX: "  4 .r
         ."   DeltaY: "  4 .r
         pop-base

      then
      key?
   until
   key drop cr

   r> close-dev
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
