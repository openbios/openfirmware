\ See license at end of file
purpose: Random numbers using Marvell hardware acceleration

0 [if]
: ebg-set  ( n -- )  h# 292c00 io@  or  h# 292c00 io!  ;
: ebg-clr  ( n -- )  invert  h# 292c00 io@  and  h# 292c00 io!  ;

\ This is the procedure recommended by the datasheet, but it doesn't work
: init-entropy-digital  ( -- )
\   h# ffffffff ebg-clr   \ All off
   h# 00008000 ebg-set   \ Digital entropy mode
   h# 00000400 ebg-clr   \ RNG reset
   h# 00000200 ebg-set   \ Bias power up
   d# 400 us
   h# 00000100 ebg-set   \ Fast OSC enable
   h# 00000080 ebg-set   \ Slow OSC enable
   h# 02000000 ebg-set   \ Downsampling ratio
   h# 00110000 ebg-set   \ Slow OSC divider
   h# 00000400 ebg-set   \ RNG unreset
   h# 00000040 ebg-set   \ Post processor enable
   h# 00001000 ebg-set
;
[else]
\ This procedure works
: init-entropy  ( -- )  \ Using digital method
   h# 21117c0 h# 292c00 io!
;
[then]

: random-short  ( -- w )
   begin  h# 292c04 io@  dup 0>=  while  drop  repeat
   h# ffff and
;
: random-byte  ( -- b )  random-short 2/ h# ff and  ;
: random-long  ( -- l )
   random-short random-short wljoin
;
alias random random-long

stand-init: Random number generator
   h# 1b h# 68 pmua!   \ Ensure WTM clock is enabled
   init-entropy
;

\ LICENSE_BEGIN
\ Copyright (c) 2010 FirmWorks
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
