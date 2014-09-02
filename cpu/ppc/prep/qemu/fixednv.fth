purpose: Offsets of fixed areas of NVRAM
\ See license at end of file

\ d# 19
h# 400

[ifdef] /fixed-nv  to /fixed-nv  [else]  constant /fixed-nv  [then]

\ Allocate fixed regions of NVRAM from the top down
h# 2000
h#    8    -  dup   constant rtc-reg-offset  ( h# 1ff8 )  \ RTC registers
h#   10    -  dup   constant cmos-offset     ( h# 1eb8 )  \ Simulated CMOS RAM

/fixed-nv  -  dup                    ( h# 1ea5 h# 1ea5 )  \ real-base, etc.
[ifdef] fixed-nv-base  to fixed-nv-base  [else]  constant fixed-nv-base  [then]

constant env-end-offset                      ( )

\ LICENSE_BEGIN
\ Copyright (c) 1997 FirmWorks
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

