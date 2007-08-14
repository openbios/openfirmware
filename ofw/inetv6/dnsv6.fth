\ See license at end of file
purpose: Domain name version 6 resolver

headerless

/ipv6 buffer: ipv6-buf

[ifndef] include-ipv4
: $>ip  ( hostname$ -- 'ip )  .ipv4-not-supported  ;
: resolvev4  ( hostname$ -- )  .ipv4-not-supported  ;
: set-dest-ip  ( buf -- )  .ipv4-not-supported  ;
: ?bad-ip  ( flag -- )  abort" Bad host name or address"  ;
[then]

: resolvev6  ( hostname$ -- )
   true to use-ipv6?
   unknown-ipv6-addr his-ipv6-addr copy-ipv6-addr
   abort" IPv6 DNS not supported yet"  
;

headers

\ XXX Try (resolve) or (resolve6) first.  If fail, try the other one.
: (resolve)  ( hostname$ -- )
   2dup ['] resolvev6  catch  if
      2drop
      false to use-ipv6?
      resolvev4
   else
      2drop
   then
   use-ipv6-ok? dup  to use-ipv6?  if     \ Make sure all the addresses are set properly
      his-ipv6-addr (set-dest-ipv6)
      bootnet-debug  if  ." Use IPv6 protocol" cr  then
   else
      his-ip-addr (set-dest-ip)
      bootnet-debug  if  ." Use IP protocol" cr  then
   then
;

: $set-host  ( hostname$ -- )
   dup 0= ?bad-ip
   2dup ['] $>ip catch  if  2drop  else  false to use-ipv6? set-dest-ip 2drop exit  then
   2dup ipv6-buf ['] $ipv6# catch  if
      3drop (resolve)
   else
      2drop
      true to use-ipv6? ipv6-buf set-dest-ipv6
   then
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
