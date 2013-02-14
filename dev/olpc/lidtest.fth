\ See license at end of file
purpose: selftest for OLPC lid and ebook switches

: open  ( -- okay? )  true  ;
: close  ( -- )  ;

: ?key-abort  ( -- )  key?  if  key esc =  abort" Aborted"  then  ;

: wait-not-lid    ( -- )  begin  ?key-abort  lid? 0=    until  ;
: wait-lid        ( -- )  begin  ?key-abort  lid?       until  ;
: wait-not-ebook  ( -- )  begin  ?key-abort  ebook? 0=  until  ;
: wait-ebook      ( -- )  begin  ?key-abort  ebook?     until  ;

: all-switch-states  ( -- )
   lid?  if
      ." Deactivate lid switch" cr
      wait-not-lid
   else
      ." Activate lid switch" cr
      wait-lid
   then
   ebook?  if
      ." Deactivate ebook switch" cr
      wait-not-ebook
   else
      ." Activate ebook switch" cr
      wait-ebook
   then
;

: ty    ." Thank you."  cr cr  ;
: pltd  ." Please lift the display and rotate it to face you."  cr  ;

: field-switch-states  ( -- )
   cr
   ebook?  if  pltd  wait-not-ebook  ty  then

   lid?  if  ." Please open the lid."  cr  wait-not-lid  ty  then

   ." Please close the lid and then open it."  cr
   wait-lid  d# 1000 ms  wait-not-lid  ty

   ." Please rotate the lid to face away, and close it face up."  cr
   wait-ebook  d# 1000 ms  ty
   pltd  wait-not-ebook  ty
;

[ifndef] factory-test?
: factory-test?  false  ;
[then]

: selftest  ( -- error? )
   factory-test?  if
      ['] all-switch-states catch
   else
      ['] field-switch-states catch
   then
;

\ LICENSE_BEGIN
\ Copyright (c) 2013 FirmWorks
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
