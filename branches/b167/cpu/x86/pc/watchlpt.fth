\ See license at end of file
purpose: Parallel printer test

0 value lpt-ih
: printer-ready?  ( -- ready? )
   " stat@" lpt-ih $call-method
   dup 80 and  if
      dup 20 and  if
         drop ." Out of paper" cr  false
      else
          dup 8 and  if
             10 and 0=  if
                ." Printer off-line" cr  false
             else  true  then
          else
             drop ." Printer errror" cr  false
          then
      then
   else
      drop ." Printer not connected, off-line, or error"  cr  false
   then
;

: watch-lpt  ( -- )
   ." Testing parallel port, be sure printer is connected..." cr
   " /parallel" open-dev dup 0= abort" Can't open parallel device"
   to lpt-ih
   printer-ready?  if
      collect( banner )collect
      " write" lpt-ih $call-method drop
   then
   lpt-ih close-dev  0 to lpt-ih
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
