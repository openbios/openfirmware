purpose: YUY2 to RGB-565 conversion
\ See license at end of file

\ B = 1.164(Y - 16)                   + 2.018(U - 128)
\ G = 1.164(Y - 16) - 0.813(V - 128)  - 0.391(U - 128)
\ R = 1.164(Y - 16) + 1.596(V - 128)

[ifdef] 386-assembler

\ This code operates on pixel values in memory using scaler of 128
\ Src bytes are Y0 U Y1 V
\ Dst bytes are 565RGB  565RGB (2 16-bit pixels)

code yuv2>rgb  ( src dst count -- )
   4 [sp] di xchg    \ di: dst
   8 [sp] si xchg    \ si: src

   ax push  ax push  ax push   \ Save space on stack for V U Y0

   begin
      \ Get Y0, make signed, multiply by 1.164 * 128, save on stack
      ax ax xor  al lods  d#  16 # ax sub  d# 149 # ax ax imul-imm  ax 0 [sp] mov
      ax ax xor  al lods  d# 128 # ax sub  ax 4 [sp] mov  \ Get U, make signed, save on stack
      \ Get Y1, make signed, multiply by 1.164 * 128, save in BX
      ax ax xor  al lods  d#  16 # ax sub  d# 149 # ax bx imul-imm
      ax ax xor  al lods  d# 128 # ax sub  ax 8 [sp] mov  \ Get V, make signed, save on stack

      \ Generate R
      d# 204 #  8 [sp]  ax imul-imm    \ Multiply V by 1.596 * 128
      bx        ax  add                \ Add Y1
      d# 7 #    ax  sar                \ Scale down by 128

      0<  if  ax ax xor  then          \ Clip to 0
      d# 255 #  ax  cmp  >  if  d# 255 # ax mov  then   \ Clip to 255

      h# f8 #   ax  and                \ Use upper 5 bits only
      d#  8 #   ax  shl                \ Shift R into position
      ax        cx  mov                \ Save it

      \ Generate B
      d# 258 #  4 [sp] ax imul-imm     \ Multiply U by 2.018 * 128
      bx        ax  add                \ Add Y1
      d# 7 #    ax  sar                \ Scale down by 128

      0<  if  ax ax xor  then          \ Clip to 0
      d# 255 #  ax  cmp  >  if  d# 255 # ax mov  then   \ Clip to 255

      h# f8 #   ax  and                \ Use upper 5 bits only
      d#  3 #   ax  shr                \ Shift B into position
      ax        cx  or                 \ Save it

      \ Generate G
      d# -104 #  8 [sp]  dx imul-imm   \ Multiply V by -0.813 * 128
      d#  -50 #  4 [sp]  ax imul-imm   \ Multiply U by -0.391 * 128
      dx        ax  add                \ Add
      ax        dx  mov                \ Save to be used for the 2nd RGB
      bx        ax  add                \ Add Y1
      d# 7 #    ax  sar                \ Scale down by 128

      0<  if  ax ax xor  then          \ Clip to 0
      d# 255 #  ax  cmp  >  if  d# 255 # ax mov  then   \ Clip to 255

      h# fc #   ax  and                \ Use upper 6 bits only
      d#  3 #   ax  shl                \ Shift G into position
      ax        cx  or                 \ Save it
      d# 16 #   cx  shl                \ Save second RGB

      \ Generate 2nd R
      0 [sp]    bx  mov	               \ Work on Y0
      d# 204 #  8 [sp] ax imul-imm     \ Multiply V by 1.596 * 128
      bx        ax  add                \ Add Y0
      d# 7 #    ax  sar                \ Scale down by 128

      0<  if  ax ax xor  then          \ Clip to 0
      d# 255 #  ax  cmp  >  if  d# 255 # ax mov  then   \ Clip to 255

      h# f8 #   ax  and                \ Use upper 5 bits only
      d#  8 #   ax  shl                \ Shift R into position
      ax        cx  or                 \ Save it

      \ Generate 2nd B
      d# 258 #  4 [sp] ax imul-imm     \ Multiply U by 2.018 * 128
      bx        ax  add                \ Add Y0
      d# 7 #    ax  sar                \ Scale down by 128

      0<  if  ax ax xor  then          \ Clip to 0
      d# 255 #  ax  cmp  >  if  d# 255 # ax mov  then   \ Clip to 255

      h# f8 #   ax  and                \ Use upper 5 bits only
      d#  3 #   ax  shr                \ Shift B into position
      ax        cx  or                 \ Save it

      \ Generate 2nd G
      dx        ax  mov                \ v*0.813+u*0.391
      bx        ax  add                \ Add Y-
      d# 7 #    ax  sar                \ Scale down by 128

      0<  if  ax ax xor  then          \ Clip to 0
      d# 255 #  ax  cmp  >  if  d# 255 # ax mov  then   \ Clip to 255

      h# fc #   ax  and                \ Use upper 6 bits only
      d#  3 #   ax  shl                \ Shift G into position
      cx        ax  or                 \ Save it

      ax stos                          \ Output both RGB

      d# 4 # h# c [sp]  sub
   0= until

   d# 16 [sp]  sp  lea   \ Clean stack
   di pop
   si pop
c;
[then]

[ifndef]  yuv2>rgb

\ Forth code: no division; use scaler of 128
0 value y1
0 value v  0 value v*0.813+u*0.391  0 value v*1.596
0 value u  0 value u*2.018

: do-uv-comp  ( -- )
   u d# 258 * to u*2.018
   v d# -104 * u d# -50 * + to v*0.813+u*0.391
   v d# 204 * to v*1.596
;
: y>rgb  ( y -- rgb )
   d# 16 - d# 149 * ( 1.164 )		   ( y' )
   dup  u*2.018         + 7 >>a  0 max d# 255 min  h# f8 and 3 >>      ( y b )
   over v*0.813+u*0.391 + 7 >>a  0 max d# 255 min  h# fc and 3 << or   ( y gb )
   swap v*1.596         + 7 >>a  0 max d# 255 min  h# f8 and 8 << or   ( rgb )
;
: yuyv>rgb  ( y0uy1v -- rgb0 rgb1 )
   lbsplit    	     	     	           ( v y1 u y0 )
   swap d# 128 - to u  rot d# 128 - to v   ( y1 y0 )
   do-uv-comp         	      	       	   ( y1 y0 )
   y>rgb 				   ( y1 rgb0 )
   swap y>rgb 				   ( rgb0 rgb1 )
;

: yuv2>rgb  ( src dst len -- )
   4 / 0  do                         ( src dst )
      over i la+ be-l@  yuyv>rgb     ( src dst rgb0 rgb1 )
      wljoin over i la+ le-l!        ( src dst )
   loop  2drop
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

