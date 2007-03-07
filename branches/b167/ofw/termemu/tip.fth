\ See license at end of file
purpose: Use firmware console as terminal connected to serial line

\ tip ( "devspec" -- )
\    If a device specifier appears on the command line after "tip",
\    open that device and transfer characters between the device
\    and the console until "^]" (control-]) is typed.  If "tip" appears
\    at the end of the command line, use the device that was opened
\    by the previous invocation of "tip" (this is useful for continuing
\    a tip session that you interrupted with ^] without hanging up.
\
\ itip  ( -- )
\    Similar to "tip" but uses the current instance as the device.

headerless
1 buffer: tip-ch
0 value tip-ih
: close-tip  ( -- )  tip-ih close-dev  0 to tip-ih  ;
: (tip)  ( -- )
   ." Interrupt character is ^]" cr
   begin
      key?  if
         key  dup control ] =  if  drop exit  then
         tip-ch c!  tip-ch 1 " write" tip-ih $call-method drop
      then
      tip-ch 1 " read" tip-ih $call-method  case
         -2  of  endof		\ No characters
         -1  of  cr ." Line dropped" cr exit  endof    \ Link dead
         ( default )  tip-ch c@  emit
      endcase
   again
;

headers
: itip  ( -- )  tip-ih >r  my-self to tip-ih  (tip)  r> to tip-ih  ;

: tip  ( "name" -- )
   parse-word  dup  if                     ( devspec$ )
      tip-ih  if  close-tip  then          ( devspec$ )
      open-dev to tip-ih                   ( )
   then                                    ( )
   tip-ih 0= abort" Device not open"       ( )
   (tip)                                   ( )
   " Hangup?" confirmedn?  if  close-tip  then
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
