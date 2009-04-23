\ See license at end of file
purpose: Main load file for Via Unichrome frame buffer driver

" display" device-name

fload ${BP}/dev/via/unichrome/pci.fth            \ PCI interfaces
fload ${BP}/dev/via/unichrome/unichrome.fth      \ Controller code
\ fload ${BP}/dev/via/unichrome/accel2d.fth      \ Accelerator
\ fload ${BP}/dev/via/unichrome/gxvga.fth          \ Text mode support
fload ${BP}/dev/video/common/rectangle16.fth     \ Rectangular graphics
fload ${BP}/cpu/x86/pc/olpc/expand16.fth         \ Expand image by 2x

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
