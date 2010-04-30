\ See license at end of file
purpose: Driver/selftest for OLPC lid and ebook switches

0 0  " 0"  " /" begin-package
" switches" device-name
0 0 reg  \ So test-all will run the test
: open  ( -- okay? )  true  ;
: close  ( -- )  ;
: lid?    ( -- flag )  h# 48 acpi-l@ h#  80 and 0=  ;
: ebook?  ( -- flag )  h# 48 acpi-l@ h# 200 and 0=  ;

: ?key-abort  ( -- )  key?  if  key esc =  abort" Aborted"  then  ;
: wait-not-lid  ( -- )
   ." Deactivate lid switch" cr
   begin  ?key-abort  lid? 0=  until
;
: wait-lid  ( -- )
   ." Activate lid switch" cr
   begin  ?key-abort  lid? until
;
: wait-not-ebook  ( -- )
   ." Deactivate ebook switch" cr
   begin  ?key-abort  ebook? 0=  until
;
: wait-ebook  ( -- )
   ." Activate ebook switch" cr
   begin  ?key-abort  ebook? until
;

: all-switch-states  ( -- )
   lid?  if  wait-not-lid  else  wait-lid  then
   ebook?  if  wait-not-ebook  else  wait-ebook  then
;

: selftest  ( -- error? )
   ['] all-switch-states catch
;

end-package

\ LICENSE_BEGIN
\ Copyright (c) 2009 FirmWorks
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
