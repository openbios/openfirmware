purpose: IIR digital filter support

\ iir-cascade implements the "Folded Cascade First Order Filters"
\ structure as shown on page 274 of _Multirate Signal Processing
\ for Communications Systems_ by fredric j harris, Prentice Hall 2004
\ ISBN 0-13-146511-2

code iir-cascade  ( sample weights z #coefs -- out )
   cx pop     \ CX: Number of coefficients

   bp bx mov  \ Save
   bp pop     \ BP: Z list
   si dx mov  \ Save SI
   si pop     \ SI: Filter weights
   ax pop     \ AX: current value
   dx push    \ Saved SI on stack
   bx push    \ Saved BP on stack
   begin
      ax       bx  mov   \ Save last value
      4 [bp]   ax  sub   \ last - M[i+1]
      0 [si]   ax  imul  \ alpha[i] * (last - M[i+1])  (kills DX)
      4 [si]   si  lea   \ Increment alpha pointer
      d# 14 #  ax  shr   \ Scale down by multiplier scale factor
      0 [bp]   ax  add   \ M[i] + alpha[i] * (last - M[i+1])
      bx   0 [bp]  mov   \ Update M[i]
      4 [bp]   bp  lea   \ Point to next M[i]
   loopa

   bp pop     \ Restore BP
   si pop     \ Restore SI
   ax push    \ Return value
c;

\ upsample by 4

2 constant #coefs

create weights0 mul14: .101467517  mul14: .612422841
create weights1 mul14: .342095596  mul14: .867647439

#coefs 1+ /n* constant buflen
buflen buffer: z0
buflen buffer: z1
buflen buffer: z2
buflen buffer: z3

: init-upsample
   z0 buflen erase
   z1 buflen erase
   z2 buflen erase
   z3 buflen erase
;

0 [if]
for each input sample
   sample weights0 z0 #coefs iir-cascade  dup to int0  ( out0 )  int1 +
   dup weights0 z2 #coefs iir-cascade  dup to out0  out1 + ,next-output
       weights1 z3 #coefs iir-cascade  dup to out1  out0 + ,next-output

   sample weights0 z1 #coefs iir-cascade  dup to int1  ( out1 )  int0 +
   dup weights0 z2 #coefs iir-cascade  dup to out0  out1 + ,next-output
       weights1 z3 #coefs iir-cascade  dup to out1  out0 + ,next-output
[then]
