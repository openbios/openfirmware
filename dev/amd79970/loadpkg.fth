purpose: Load file for driver for AMD 79970 PCI Ethernet chip
\ See license at end of file

5 value #rmdsfactor   \ #rmds = 2 ** #rmdsfactor

fload ${BP}/dev/amd79970/setup.fth
fload ${BP}/dev/amd7990/lancevar.fth
fload ${BP}/dev/amd79970/79c970.fth 
fload ${BP}/dev/amd7990/regbits.fth
fload ${BP}/dev/amd7990/lance32.fth
fload ${BP}/dev/amd7990/lancecom.fth
 
fload ${BP}/dev/amd7990/timedrec.fth
fload ${BP}/dev/amd7990/lancetst.fth
fload ${BP}/dev/amd79970/methods.fth

: close  ( -- )
   obp-tftp ?dup if close-package then
   net-off

   la h# 14 + rw@ drop                   \ Reset
   h# 200 d# 20 bcr!  h# 200 d# 58 csr!  \ Force some modes
   h# 9060 h# 12 bcr! 	2 2 bcr! 	 \ and some more

   unmap-lance-buffers
   unmap-chips
;

map-chips
get-mac-address						( b0 ... b5 )
6 alloc-mem 						( b0 ... b5 adr )
dup 5 bounds swap  do  swap i c! -1  +loop		( adr )
dup 6 encode-bytes  " local-mac-address" property	( adr )
6 free-mem
unmap-chips

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
