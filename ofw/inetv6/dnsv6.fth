\ See license at end of file
purpose: Domain name version 6 resolver

headerless

/ipv6 buffer: ipv6-buf

[ifndef] include-ipv4
: $>ip  ( hostname$ -- 'ip )  .ipv4-not-supported  ;
: (resolve)  ( hostname$ -- 'ip )  .ipv4-not-supported  ;
: set-dest-ip  ( buf -- )  .ipv4-not-supported  ;
: ?bad-ip  ( flag -- )  abort" Bad host name or address"  ;
[then]

headers
: (resolvev6)  ( hostname$ -- 'ip )  ;

\ XXX Try (resolve) or (resolve6) first.  If fail, try the other one.
: (resolve)  ( hostname$ -- 'ip )
   use-ipv6?  if  (resolvev6) true  else  (resolve) false  then
   dup to use-ipv6?
   if  set-dest-ipv6  else  set-dest-ip  then
;

: $set-host  ( hostname$ -- )
   dup 0= ?bad-ip
   2dup ['] $>ip catch  if  2drop  else  false to use-ipv6? set-dest-ip 2drop exit  then
   2dup ipv6-buf ['] $ipv6# catch nip nip not  if  true to use-ipv6? ipv6-buf set-dest-ipv6 exit  then
   (resolve)
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
