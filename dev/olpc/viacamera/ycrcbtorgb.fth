\ See license at end of file
purpose: Color space conversion from YCbCr to RGB

\ R = clip (Y + 1.402 * Cr)
\ G = clip (Y - 0.344 * Cb - 0.714 * Cr)
\ B = clip (Y + 1.772 * Cb)

\ This is for full-range YCbCr, where the Y anc Cb/Cr values ranges from 0-255.
\ For restricted-range YCbCr (16 <= Y <= 235, 16 <= Cr,Cb <= 240), the Y value
\ would need to be adjusted to Ysc = (Y - 16) * 1.164  (1.164 = 298 / 256 = 149 / 128)
\ and the multipliers change from (1.402, -0.343, -0.711, 1.765) to (1.596, -0.392, -0.813, 2.017)

code ycrcb444>rgb888  ( y cr cb -- r g b )
   \ y: 8 [sp]
   \ u: 4 [sp]  = Cr
   \ v: 0 [sp]  = Cb

   d# 128 #  0 [sp]  sub   \ convert Cb to signed
   d# 128 #  4 [sp]  sub   \ convert Cr to signed
   8 [sp]  bx  mov       \ Get Y into register

   d#  90 #  4 [sp]  ax  imul-imm   \ Multiply Cr by 1.402 * 64 (actually 1.406)
   d#   6 #          ax  sar    \ Scale down by 64
   bx                ax  add    \ Add to Y
   0<  if  ax ax xor  then      \ Clip to 0
   d# 255 #  ax  cmp  >  if  d# 255 # ax mov  then   \ Clip to 255
   
   ax            8 [sp]  mov    \ Put R in place on stack

   d# -46 #  4 [sp]  ax  imul-imm   \ Multiply Cr by -0.714 * 64 (actually -0.719)
   d#   6 #          ax  sar    \ Scale down by 64
   ax cx mov
   d# -22 #  0 [sp]  ax  imul-imm   \ Multiply Cr by -0.344 * 64 (actually -0.344)
   d#   6 #          ax  sar    \ Scale down by 64
   ax cx add
   bx cx add                    \ Now we have G
   0<  if  cx cx xor  then      \ Clip to 0
   d# 255 #  cx  cmp  >  if  d# 255 # cx mov  then   \ Clip to 255
   
   d# 113 #  0 [sp]  ax  imul-imm   \ Multiply Cr by 1.772 * 64 (actually 1.766)
   d#   6 #          ax  sar    \ Scale down by 64
   bx                ax  add    \ Add to Y
   0<  if  ax ax xor  then      \ Clip to 0
   d# 255 #  ax  cmp  >  if  d# 255 # ax mov  then   \ Clip to 255
   ax            0 [sp]  mov    \ Put B in place on stack

   cx            4 [sp]  mov    \ Put G in place on stack
c;


\ This version operates on pixel values in memory
\ Src bytes are Cb Y1 Cr Y2 (2 pixels)
\ Dst bytes are R G B A  R G B A (2 pixels)

code ycbcr422>rgba8888  ( src dst count -- )
   4 [sp] di xchg    \ di: dst
   8 [sp] si xchg    \ si: src

   ax push  ax push   \ Space on stack for Cr and Cb values

   begin
      \ src: Cb Y1 Cr Y2     dst: R1 G1 B1 A1  R2 G2 B2 A2
      ax ax xor   al lods  d# 128 # ax sub  ax 0 [sp] mov  \ Get Cb, make signed, save on stack
      ax ax xor   al lods  ax bx mov                    \ Get Y1, save in BX
      ax ax xor   al lods  d# 128 # ax sub  ax 4 [sp] mov  \ Get Cr, make signed, save on stack

      d#  90 #  4 [sp]  ax  imul-imm   \ Multiply Cr by 1.402 * 64 (actually 1.406)
      d#   6 #          ax  sar        \ Scale down by 64
      bx                ax  add        \ Add to Y

      0<  if  ax ax xor  then          \ Clip to 0
      d# 255 #  ax  cmp  >  if  d# 255 # ax mov  then   \ Clip to 255
   
      al stos                          \ Output R

      d# -46 #  4 [sp]  ax  imul-imm   \ Multiply Cr by -0.714 * 64 (actually -0.719)
      d#   6 #          ax  sar        \ Scale down by 64
      ax dx mov
      d# -22 #  0 [sp]  ax  imul-imm   \ Multiply Cr by -0.344 * 64 (actually -0.344)
      d#   6 #          ax  sar        \ Scale down by 64
      dx ax add
      bx ax add                        \ Now we have G

      0<  if  ax ax xor  then          \ Clip to 0
      d# 255 #  ax  cmp  >  if  d# 255 # ax mov  then   \ Clip to 255
   
      al stos                          \ Output G

      d# 113 #  0 [sp]  ax  imul-imm   \ Multiply Cr by 1.772 * 64 (actually 1.766)
      d#   6 #          ax  sar        \ Scale down by 64
      bx                ax  add        \ Add to Y

      0<  if  ax ax xor  then          \ Clip to 0
      d# 255 #  ax  cmp  >  if  d# 255 # ax mov  then   \ Clip to 255

      al stos                          \ Output B
      d# 255 #  al mov
      al stos                          \ Output A

      ax ax xor   al lods  ax bx mov   \ Get Y2 into BX

      d#  90 #  4 [sp]  ax  imul-imm   \ Multiply Cr by 1.402 * 64 (actually 1.406)
      d#   6 #          ax  sar        \ Scale down by 64
      bx                ax  add        \ Add to Y

      0<  if  ax ax xor  then          \ Clip to 0
      d# 255 #  ax  cmp  >  if  d# 255 # ax mov  then   \ Clip to 255
   
      al stos                          \ Output R

      d# -46 #  4 [sp]  ax  imul-imm   \ Multiply Cr by -0.714 * 64 (actually -0.719)
      d#   6 #          ax  sar        \ Scale down by 64
      ax dx mov
      d# -22 #  0 [sp]  ax  imul-imm   \ Multiply Cr by -0.344 * 64 (actually -0.344)
      d#   6 #          ax  sar        \ Scale down by 64
      dx ax add
      bx ax add                        \ Now we have G

      0<  if  ax ax xor  then          \ Clip to 0
      d# 255 #  ax  cmp  >  if  d# 255 # ax mov  then   \ Clip to 255
   
      al stos                          \ Output G

      d# 113 #  0 [sp]  ax  imul-imm   \ Multiply Cr by 1.772 * 64 (actually 1.766)
      d#   6 #          ax  sar        \ Scale down by 64
      bx                ax  add        \ Add to Y

      0<  if  ax ax xor  then          \ Clip to 0
      d# 255 #  ax  cmp  >  if  d# 255 # ax mov  then   \ Clip to 255

      al stos                          \ Output B
      d# 255 #  al mov
      al stos                          \ Output A

      8 [sp] dec
   0= until

   d# 12 [sp]  sp  lea   \ Clean stack
   0 [sp] di xchg    \ Restore EDI
   4 [sp] si xchg    \ Restore ESI
c;
