\ See license at end of file
purpose: Numeric display of startup progress in ARM assembly language

\ This is an ARM assembly language version of the 3x5 font numeric display
\ code, a high-level version of which is in fbnums.fth .  This assembly
\ language version uses a less-compact font encoding, because the compact
\ encoding in fbnums.fth requires more registers to display.  This version
\ trades size for reduced register use - it needs only R0-R3 and LR, so it
\ can be called with less concern for the register use of the calling point,
\ and without needing a stack.  The value of the "no stack" attribute is
\ questionable, since the frame buffer used to display the number is likely
\ to be in memory, so if memory doesn't work, this feature probably won't
\ work in any case.

label fb-adr-loc  \ Frame buffer address
diagfb-pa ,
end-code

label numerals
hex
\ 0
ffff w,
000f w,
0f0f w,
0f0f w,
0f0f w,
000f w,

\ 1
ffff w,
0fff w,
0fff w,
0fff w,
0fff w,
0fff w,

\ 2
ffff w,
000f w,
0fff w,
000f w,
ff0f w,
000f w,

\ 3
ffff w,
000f w,
0fff w,
000f w,
0fff w,
000f w,

\ 4
ffff w,
0f0f w,
0f0f w,
000f w,
0fff w,
0fff w,

\ 5
ffff w,
000f w,
ff0f w,
000f w,
0fff w,
000f w,

\ 6
ffff w,
000f w,
ff0f w,
000f w,
0f0f w,
000f w,

\ 7
ffff w,
000f w,
0fff w,
0fff w,
0fff w,
0fff w,

\ 8
ffff w,
000f w,
0f0f w,
000f w,
0f0f w,
000f w,

\ 9
ffff w,
000f w,
0f0f w,
000f w,
0fff w,
000f w,

\ a
ffff w,
000f w,
0f0f w,
000f w,
0f0f w,
0f0f w,

\ b
ffff w,
ff0f w,
ff0f w,
000f w,
0f0f w,
000f w,

\ c
ffff w,
000f w,
ff0f w,
ff0f w,
ff0f w,
000f w,

\ d
ffff w,
0fff w,
0fff w,
000f w,
0f0f w,
000f w,

\ e
ffff w,
000f w,
ff0f w,
000f w,
ff0f w,
000f w,

\ f
ffff w,
000f w,
ff0f w,
000f w,
ff0f w,
ff0f w,

end-code

[ifdef] test-me
code puthex  ( r0: nn \ kills: r1-r3 )
   mov     r0,tos
[else]
label puthex  ( r0: nn \ kills: r1-r3 )
[then]

   mov     r3,r0,lsr #4       \ r3: Hidigit
   and     r3,r3,#0xf         \ r3: Hidigit

   sub     r2,pc,`here 8 + numerals - #`  \ adr r2,=numerals  r2: 'glyphs
   
   add     r2,r2,r3,lsl #3    \ r2: 'glyph
   add     r2,r2,r3,lsl #2    \ r2: 'glyph

   ldr     r3,[pc,`fb-adr-loc  here 8 +  - #`]  \ r3: 'fb

   ldr     r1,[r2],#4         \ r1: bits
   strh    r1,[r3,#6]!        \ Write halfword
   mov     r1,r1,lsr #16
   strh    r1,[r3,#6]!        \ Write halfword
   
   ldr     r1,[r2],#4         \ r1: bits
   strh    r1,[r3,#6]!        \ Write halfword
   mov     r1,r1,lsr #16
   strh    r1,[r3,#6]!        \ Write halfword
   
   ldr     r1,[r2],#4         \ r1: bits
   strh    r1,[r3,#6]!        \ Write halfword
   mov     r1,r1,lsr #16
   strh    r1,[r3,#6]!        \ Write halfword
   
   and     r3,r0,#0xf         \ r3: Lodigit

   sub     r2,pc,`here 8 + numerals - #`  \ adr r2,=numerals  r2: 'glyphs
   \ r2 = numerals + 12*r3
   add     r2,r2,r3,lsl #3    \ r2: 'glyph
   add     r2,r2,r3,lsl #2    \ r2: 'glyph

   ldr     r3,[pc,`fb-adr-loc  here 8 +  - #`]  \ r3: 'fb
   inc     r3,#2              \ r3: 'fb

   ldr     r1,[r2],#4         \ r1: bits
   strh    r1,[r3,#6]!        \ Write halfword
   mov     r1,r1,lsr #16
   strh    r1,[r3,#6]!        \ Write halfword
   
   ldr     r1,[r2],#4         \ r1: bits
   strh    r1,[r3,#6]!        \ Write halfword
   mov     r1,r1,lsr #16
   strh    r1,[r3,#6]!        \ Write halfword
   
   ldr     r1,[r2],#4         \ r1: bits
   strh    r1,[r3,#6]!        \ Write halfword
   mov     r1,r1,lsr #16
   strh    r1,[r3,#6]!        \ Write halfword

[ifdef] test-me
   pop     tos,sp
c;
[else]
   mov     pc,lr
end-code
[then]

0 [if]
dev screen
: lcd-setup  ( -- )
   text-off

   0 h# 190 lcd!

   h# 9000c h# 104 lcd!

   \ Set the pitch to 6 bytes
   6  h# fc lcd!

   \ Graphics in 4bpp mode
   h# 8009.1100 h# 190 lcd!

   \ Set the no-display-source background color to white
\   h# ffffffff h# 124 lcd!
;
[then]


\ LICENSE_BEGIN
\ Copyright (c) 2011 FirmWorks
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
