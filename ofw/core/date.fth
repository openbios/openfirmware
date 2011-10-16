\ See license at end of file
purpose: Time and date decoding functions

variable clock-node  ' clock-node  " clock" chosen-variable

: ofw-time&date  ( -- s m h d m y )
   " get-date" clock-node @ ihandle>phandle find-method  if
      drop
      " get-time" clock-node @  $call-method  swap rot
      " get-date" clock-node @  $call-method  swap rot
   else
      " get-time" clock-node @  $call-method
   then
;
stand-init:
   ['] ofw-time&date to time&date
;

headerless
: 2.d  ( n -- )   push-decimal  (.2)  type  pop-base  ;
: 4.d  ( n -- )   push-decimal  <# u# u# u# u# u#>  type  pop-base  ;

headers
: .date  ( d m y -- )   4.d ." -" 2.d ." -" 2.d  ;
: .time  ( s m h -- )   2.d ." :" 2.d ." :" 2.d  ;

\ Interactive diagnostic
: watch-clock  ( -- )
   ." Watching the 'seconds' register of the real time clock chip."  cr
   ." It should be 'ticking' once a second." cr
   ." Type any key to stop."  cr
   -1
   begin    ( old-seconds )
      begin
         key?  if  key drop  drop exit  then
         now 2drop
      2dup =  while   ( old-seconds old-seconds )
         drop
      repeat          ( old-seconds new-seconds )
      nip (cr now .time
   again
   drop
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
