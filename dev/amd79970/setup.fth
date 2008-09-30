purpose: Properties for AMD 79970 PCI Ethernet chip
\ See license at end of file

" ethernet" device-name
" AMD,79c970" model
" AMD,79c970" encode-string " compatible" property
" network" device-type

my-address my-space               encode-phys
    0 encode-int encode+  h# 0 encode-int encode+

my-address my-space h# 100.0010 + encode-phys encode+
    0 encode-int encode+  h#  20 encode-int encode+

my-address my-space h# 200.0014 + encode-phys encode+
    0 encode-int encode+  h#  20 encode-int encode+

my-address my-space h# 200.0030 + encode-phys encode+
    0 encode-int encode+  h#  10000 encode-int encode+
" reg" property

\ LICENSE_BEGIN
\ Copyright (c) 1994 FirmWorks
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
