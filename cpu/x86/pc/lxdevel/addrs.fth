\ See license at end of file
purpose: Establish address and I/O configuration definitions

[ifdef] use-meg0
h#  f0.0000 constant dropin-base
h#  08.0000 constant dropin-size
h#   0.4000 constant fw-pa
h#   f.c000 constant /fw-ram
[then]

[ifdef] rom-loaded
[ifdef] lx-devel
h# fff8.0000   constant rom-pa		\ Physical address of boot ROM
h#    8.0000   constant /rom		\ Size of boot ROM
rom-pa         constant dropin-base
[else]
h# fff0.0000   constant rom-pa		\ Physical address of boot ROM
h#   10.0000   constant /rom		\ Size of boot ROM
rom-pa  h# 1.0000 +  constant dropin-base
[then]

h#    8.0000   constant dropin-size

dropin-base h# 20 +  constant ResetBase	\ Location of "reset" dropin in ROM

h#  1c0.0000 constant fw-pa
h#   20.0000 constant /fw-ram
[then]

h#  80.0000 constant def-load-base      \ Convenient for initrd

\ The heap starts at RAMtop, which on this system is "fw-pa /fw-ram +"
h#  20.0000 constant heap-size

h# 300.0000 constant jffs2-dirent-base
h# 500.0000 constant jffs2-inode-base
h# 700.0000 constant dma-base
h# 900.0000 constant dma-size

h# f.0000 constant suspend-base      \ In the DOS hole
h# f.0008 constant resume-entry
h# f.0800 constant resume-data

fload ${BP}/cpu/x86/pc/virtaddr.fth

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
