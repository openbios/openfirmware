purpose: Driver for SDHCI (Secure Digital Host Controller)
\ See license at end of file

headers

0 instance value sbuf
0 instance value ibuf
0 instance value obuf
: alloc-test-bufs  ( -- )
   ibuf  if  exit  then
   /block dma-alloc to ibuf
   /block dma-alloc to obuf
   /block dma-alloc to sbuf
;
: free-test-bufs  ( -- )
   ibuf 0=  if  exit  then
   ibuf /block dma-free  0 to ibuf
   obuf /block dma-free  0 to obuf
   sbuf /block dma-free  0 to sbuf
;
: read-block  ( adr block# -- error? )  1 true  r/w-blocks 1 <>  ;
: write-block ( adr block# -- error? )  1 false r/w-blocks 1 <>  ;
: test-block  ( block# pattern -- error? )
   obuf /block 2 pick     fill  obuf 2 pick write-block  if  true exit  then
   ibuf /block rot invert fill  ibuf swap   read-block   if  true exit  then
   ibuf obuf /block comp
;

: (selftest)  ( -- error? )
   sbuf 0  read-block  if  true exit  then
   0 h# 5a test-block  if  true exit  then
   0 h# a5 test-block  if  true exit  then
   sbuf 0 write-block	   	        \ Restore original content
;
external
: selftest  ( -- error? )
   open 0=  if  ." Open /sd failed" cr true exit  then
   attach-card 0=  if  ." No card inserted" cr close false exit  then
   alloc-test-bufs
   ['] (selftest) catch  if  true  then
   free-test-bufs
   close
;
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
