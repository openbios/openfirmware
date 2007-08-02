\ See license at end of file
purpose: Support functions for IP stack

true value friendly?                \ True for verbose messages

[ifdef] include-ipv4 false [else] true [then]
instance value use-ipv6?

0 instance value the-struct
: set-struct  ( adr -- )  to the-struct  ;
: +struct  ( offset -- )  the-struct + set-struct  ;

: payload  ( length header-length -- contents-adr,len )
   the-struct  -rot /string
;   

: sfield  ( offset size -- new-offset )
   create over , +
   does> @ the-struct +
;

\ Access to composite data in Internet byte order (big-endian)

alias xc!  c!
alias xw!  be-w!
alias xw@  be-w@
\ : xw!  ( w adr -- )  >r wbsplit  r@ c!  r> 1+ c!  ;
\ : xw@  ( adr -- w )  dup 1+ c@ swap c@ bwjoin  ;
alias xl!  be-l!
alias xl@  be-l@

instance variable alarmtime
headers
: current-timeout  ( -- n )  alarmtime @  ;
: restore-timeout  ( n -- )  alarmtime !  ;
: set-timeout  ( interval -- )
   dup  if  get-msecs  +  then  alarmtime !
;

headerless

: timeout?  ( -- flag )
   alarmtime @  if  get-msecs  alarmtime @ >=  else  true  then
;
: ipv4?  ( ip-adr -- flag )  2 - xw@ h# 800 =  ;

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
