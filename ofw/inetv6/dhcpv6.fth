\ See license at end of file
purpose: Dynamic Host Configuration Protocol for IPv6 (DHCPv6) (RFC 3315)

[ifndef] include-ipv4
d# 256 buffer: 'root-path
d# 256 buffer: 'client-name
d# 256 buffer: 'vendor-options
headers
' 'client-name     " client-name"    chosen-string
' 'vendor-options  " vendor-options" chosen-string
' 'root-path       " root-path"      chosen-string
: domain-name  ( -- adr len )  'domain-name cscount  ;
[then]

\ tubes.laptop.org
create default-name-server-ipv6 h# 20 c, 1 c, h# 48 c, h# 30 c, h# 24 c, h# 46 c, h# ff c, 0 c, 0 l, 0 w, 0 c, 1 c,

: init-dhcpv6  ( -- )
[ifndef] include-ipv4
   0 'domain-name c!
   0 'root-path   c!
   0 'client-name c!
   0 'vendor-options c!
\   0 file-name-buf c!
[then]
   default-name-server-ipv6 name-server-ipv6 copy-ipv6-addr
;

also forth definitions
stand-init:  DHCPv6 init
   init-dhcpv6
;
previous definitions

: do-dhcp  ( -- )
;

\ LICENSE_BEGIN
\ Copyright (c) 2007 FirmWorks
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
