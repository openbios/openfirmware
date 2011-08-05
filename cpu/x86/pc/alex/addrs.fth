\ See license at end of file
purpose: Establish address and I/O configuration definitions

\ Dropin-base is where the set of dropin modules, the verbatim
\ image of what is stored in ROM or on disk, ends up in memory.
\ If OFW is in FLASH, dropin-base can just be the FLASH address.
\ If OFW is pulled in from disk, dropin-base is where the very
\ early startup code - the first few instructions in the image -
\ copies it to get it out of the way of things like OS load areas.

h# 198.0000 constant dropin-base        \ Location of payload in RAM
dropin-base h# 20 +  constant ResetBase	\ Location of "reset" dropin in RAM
h#   8.0000 constant dropin-size

\needs fw-pa      h# 7f00.0000 constant fw-pa     \ OFW dictionary location
\needs /fw-ram    h#   20.0000 constant /fw-ram

\needs heap-base  h# 7f20.0000 constant heap-base \ Dynamic allocation heap
\needs heap-size  h#   20.0000 constant heap-size

\needs dma-base   h# 7ee0.0000 constant dma-base  \ DMA heap
\needs dma-size   h#   20.0000 constant dma-size

\ Where OFW initially loads an OS that is is going to boot

h# 100.0000 constant def-load-base      \ Convenient for initrd

fload ${BP}/cpu/x86/pc/virtaddr.fth

[ifdef] virtual-mode
h#        3 constant pte-control	\ Page table entry attributes
[then]

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
