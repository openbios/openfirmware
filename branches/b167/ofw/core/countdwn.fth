\ See license at end of file
purpose: Check for auto-boot interruption

headerless
: get-countdown   ( -- #seconds )
   \ Use the default value "6" if there is no COUNTDOWN variable or if its
   \ value cannot be parsed as a number.
   " auto-boot-countdown" $getenv  if
      6		\ No such environment variable
   else
      base @ >r decimal  $number  r> base !  if  6  then
   then
;
: show-countdown   ( #seconds -- interrupted? )
   1 swap  do
      i .d  (cr
      d# 10 0  do 
         d# 100 ms
         
         key?  if
            key drop  true unloop unloop exit
         then
[ifdef] ukey
         ukey? if
            ukey drop
            com1 io
            true unloop unloop exit
         then
[then]

      loop
   -1 +loop
   space (cr
   false
;
: (interrupt-auto-boot?)  ( -- flag )
   get-countdown  dup 0=  if  exit  then		( #seconds )

   ." Type any key to interrupt automatic startup" cr
   \ XXX should sound a beep here in case the screen hasn't warmed up
   show-countdown
;
' (interrupt-auto-boot?) to interrupt-auto-boot?

headers
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
