purpose: Integer square-root for ARM processors
\ See license at end of file

0 [if]
\       u1 -- 32-bit unsigned
\       n  -- significant digits
\             16 -> sqrt-integer
\             32 -> fractional integer 16/16bits

code (sqrt      \ ( u1 n -- u2 ) 
                r0      sp      pop
                r1      0 #     mov
                r2      0 #     mov
        begin   r3      r1      mov
                r0      r0      1 #lsl s mov
                r2      r2      r2 adc
                r0      r0      1 #lsl s mov
                r2      r2      r2 adc
                r1      r1      2 #lsl mov
                r1      1       incr
                r2      r2      r1 s sub        \ get C-flag
                r2      r2      r1 lt add
                r1      r3      1 #lsl mov
                r1      r1      1 # ge orr      \ bit0 = not-C
                top     1       s decr
        eq until
                top     r1      mov c;

: sqrt          ( u1 -- u2 )    td 16 (sqrt ;
[then]

\ 32bit -> 16bit fixed point square root
\ see http://www.finesse.demon.co.uk/steven/sqrt.html
code sqrt  ( n -- root )
   mov   r0, tos                 \ n
   mov   tos, `1 d# 30 <<`       \ root
   mov   r1, `3 d# 30 <<`        \ offset
   mov   r2, 0                   \ loop count
   begin
      cmp   r0, tos, ror r2
      subhs r0, r0, tos, ror r2
      adc   tos, r1, tos, lsl #1
      inc   r2, #2
      cmp   r2, #32
   = until
   bic      tos, tos, `3 d# 30 <<`
c;

\ LICENSE_BEGIN
\ Copyright (c) 2008 FirmWorks
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
