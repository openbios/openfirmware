\ See license at end of file
purpose: Add properties describing the IPv6 network to /chosen

headerless
[ifndef] include-ipv4
: (setup-ip-attr)  ( -- )  ;

: set-chosen-property  ( adr,len prop,len -- )
   2dup  " /chosen" find-package drop		( ip-adr$ prop$ prop$ phandle )
   dup >r  get-package-property  if		( ip-adr$ prop$ )
      \ Create new property
      r>  0 package(  push-package		( ip-adr$ prop$ )
      2>r encode-bytes  2r> property            ( )
      pop-package )package
   else                                 	( ip-adr$ prop$ xdr,len )
      \ Replace existing property
      2swap 2drop  rot drop  move		(  )
      r> drop
   then
;
[then]

: (setup-ipv6-attr)  (  --  ) 	\ set tftp ip addresses
   (setup-ip-attr)

   my-ipv6-addr /ipv6        " client-ipv6"     set-chosen-property
   his-ipv6-addr /ipv6       " server-ipv6"     set-chosen-property
   router-ipv6-addr /ipv6    " gateway-ipv6"    set-chosen-property
   my-mc-ipv6-addr /ipv6     " multicast-ipv6"  set-chosen-property
;

['] (setup-ipv6-attr) is setup-ip-attr

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
