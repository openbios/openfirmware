\ See license at end of file
purpose: Polyphase audio interpolation (upsampling) filter

\needs enable fload ${BP}/cpu/arm/iwmmx.fth

d# 15 constant mulscale  \ Bits for fractional multipliers

\ Convert a decimal fraction to a scaled integer multiplier
: mul:  ( "coef" -- )
   safe-parse-word  push-decimal $number drop pop-base  ( n )
   1 mulscale lshift  d# 1,000,000,000 */               ( n' )
   w,
;

\ This is a polyphase interpolation filter that uses 16 taps per phase.
\ The upsampling ratio is equal to the number of phases.
\ The number of phases and the array of filter weights are arguments,
\ so the code could be used for different length filters, given suitable
\ weight arrays.

\ Taps/phase=16
\ Stride=2 (mono)

code 16tap-upsample  ( 'out 'in /in 'weights #phases -- )
   ldmia   sp!,{r0,r1,r2,r3}  \ r0:'weights r1:/in r2:'in r3:'out tos:#phases

   mov  r4,#15   \ Multiplier scale factor
   tmcr wcgr0,r4

\ wr0-4 - unaligned samples
\ wr5,6 - aligned samples
\ wr15  - accum
\ wr8,9 - weights
\ wcgr1 - alignment

   and    r7,r2,#7          \ Alignment shift count
   bic    r2,r2,#7          \ r5 - aligned address

   wldrd  wr0,[r2],#8
   wldrd  wr1,[r2],#8
   wldrd  wr2,[r2],#8
   wldrd  wr3,[r2],#8
   wldrd  wr4,[r2],#8

   begin
      \ r4: inner loop phase counter
      \ r5: aligned source address
      tmcr   wcgr1,r7          \ wcgr1: alignment shift count
      walignr1  wr5,wr0,wr1    \ Shift samples into place
      walignr1  wr6,wr1,wr2    \ Shift samples into place
      walignr1  wr7,wr2,wr3    \ Shift samples into place
      walignr1  wr8,wr3,wr4    \ Shift samples into place

      mov   r6,r0              \ Restore weights pointer
      mov   r4,tos             \ Restore phase counter
      begin
         wldrd     wr9,[r6],#8     \ W Get the first four weights

         wldrd     wr10,[r6],#8    \ W Get the second four weights
         wmacsz    wr15,wr5,wr9    \ First multiply-accumulate, pipelined

         wldrd     wr9,[r6],#8     \ W Get the third four weights
         wmacs     wr15,wr6,wr10   \ Second multiply-accumulate, pipelined

         wldrd     wr10,[r6],#8    \ W Get the fourth four weights
         wmacs     wr15,wr7,wr9    \ Third multiply-accumulate, pipelined

         wmacs     wr15,wr8,wr10   \ Fourth multiply-accumulate (stalls?)

         wrordg    wr15,wr15,wcgr0 \ Scale the output sample by the multiplier fraction point

         wstrh     wr15,[r3]       \ Store the output sample
         inc       r3,#2           \ This cannot be combined with the preceding because STC requires a word offset

         decs r4,#1                \ Decrement phase counter
      0= until

      inc  r7,#2                   \ Increment alignment counter
      ands r7,r7,#7                \ Check for next word needed
      0=  if
         wor     wr0,wr1,wr1       \ Shift samples
         wor     wr1,wr2,wr2
         wor     wr2,wr3,wr3
         wor     wr3,wr4,wr4
         wldrd   wr4,[r2],#8       \ Get next group of input samples
      then

      decs r1,#2                   \ Decrement input length by the sample size
   0<= until

   pop  tos,sp
c;

\ Filter coefficients for 6x upsampling.  The following filter was
\ computed with GNU Octave using the program shown at the end of the array.
\ The transition band is centered on Fs/6.  The stopband attenuation is 78dB.
\ The -3dB point is about 95% of Fs/6.
\ The coefficients are ordered by phase for easy addressing in the inner loop.
\ The coefficients are in reverse order so they can be accessed by an
\ incrementing pointer - the conventional convolutional filter algorithm
\ runs the data and filter tap pointers in opposite directions but the code
\ above runs both pointers forward for ease of use with MMX instructions.

d#  6 constant #phases

create weights-6phase
\ Phase 0
mul: -0.000631880 mul:  0.002025107 mul: -0.004881022 mul:  0.010022601
mul: -0.018817755 mul:  0.034801841 mul: -0.074732552 mul:  0.976279469
mul:  0.080446668 mul: -0.031397096 mul:  0.015062052 mul: -0.007235622
mul:  0.003214694 mul: -0.001237886 mul:  0.000375061 mul:  0.000190788

\ Phase 1
mul: -0.001092645 mul:  0.003821226 mul: -0.009784496 mul:  0.021106533
mul: -0.041296857 mul:  0.078608864 mul: -0.166749609 mul:  0.885823376
mul:  0.283737941 mul: -0.105580171 mul:  0.052425455 mul: -0.026661852
mul:  0.012716422 mul: -0.005327045 mul:  0.001786043 mul: -0.000511063

\ Phase 2
mul: -0.001079175 mul:  0.004090325 mul: -0.010977550 mul:  0.024446032
mul: -0.048873931 mul:  0.093827768 mul: -0.194040773 mul:  0.720544802
mul:  0.508384704 mul: -0.167272365 mul:  0.082398233 mul: -0.042537000
mul:  0.020831489 mul: -0.009060710 mul:  0.003214599 mul: -0.000795594

\ Phase 3
mul: -0.000795594 mul:  0.003214599 mul: -0.009060710 mul:  0.020831489
mul: -0.042537000 mul:  0.082398233 mul: -0.167272365 mul:  0.508384704
mul:  0.720544802 mul: -0.194040773 mul:  0.093827768 mul: -0.048873931
mul:  0.024446032 mul: -0.010977550 mul:  0.004090325 mul: -0.001079175

\ Phase 4
mul: -0.000511063 mul:  0.001786043 mul: -0.005327045 mul:  0.012716422
mul: -0.026661852 mul:  0.052425455 mul: -0.105580171 mul:  0.283737941
mul:  0.885823376 mul: -0.166749609 mul:  0.078608864 mul: -0.041296857
mul:  0.021106533 mul: -0.009784496 mul:  0.003821226 mul: -0.001092645

\ Phase 5
mul:  0.000190788 mul:  0.000375061 mul: -0.001237886 mul:  0.003214694
mul: -0.007235622 mul:  0.015062052 mul: -0.031397096 mul:  0.080446668
mul:  0.976279469 mul: -0.074732552 mul:  0.034801841 mul: -0.018817755
mul:  0.010022601 mul: -0.004881022 mul:  0.002025107 mul: -0.000631880

0 [if]
\ This Matlab/Octave code computes the weights.
\ The 95 is one less than the filter length 96 = 6 * 16
weights = remez(95, [0 .12 .215 1], [1 1 0 0]);
for phase=1:6
  for tap=16:-1:1
    printf("mul: %.9f ", 5.9 * weights((tap-1)*6+phase));
  end 
  printf("\n");
end
[then]

: upsample6  ( src-adr /src dst-adr -- )
   enable-iwmmx                                   ( src-adr #src-samples dst-adr )
   -rot weights-6phase #phases 16tap-upsample     ( )
;

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
