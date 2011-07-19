\ See license at end of file
purpose: Put message codes out on the frame buffer

h# 40 value the-debug-code
: next-debug-code  ( -- n )
   the-debug-code  dup 1+           ( n )
   dup h# f and  h# a =  if  6 +  then  ( n )  \ Use BCD
   to the-debug-code
;

: show-debug-code  ( adr len code# -- )
   ." Msg#: " push-hex <# u# u# u#> type pop-base  space type  cr
;
: put-fbmsg  ( msg$ -- )
   next-debug-code dup >r show-debug-code  r> ( adr len b )
   postpone literal  postpone puthex          ( adr len )
;

\ Automatically insert port80 codes in named stand-init: words
: fbmsg  ( msg$ -- msg$ )  2dup put-fbmsg  ;
' fbmsg to check-message

\ LICENSE_BEGIN
\ Copyright (c) 2011 FirmWorks
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
