purpose: FIR polyphase digital 6x upsampling filter

d# 15 constant mulscale  \ Bits for fractional multipliers

\ Upsample, expanding one input sample to #phases output samples
\ outptr  - where to put the output samples; updated to the next location
\ stride  - the distance between successive input samples - 2 for mono, 4 for stereo
\ inptr   - pointer into array of input samples
\ weights - pointer to filter weights, sorted by phase
\ taps/phase - the number of filter taps per phase
\ #phases - the number of filter phases, equal to the upsampling ratio

code fir-upsample  ( outptr stride inptr weights taps/phase #phases -- outptr' stride )
                   \ 20     16     12    08      04         00
                   \ 24     20     16    12      08         04       00:DI

   d# 08 [sp]   si  xchg  \ SI: weights (old value stored on stack)
   di               push  \ Save DI

   begin
      d# 16 [sp]   bx  mov    \ BX: inptr
      di           di  xor    \ Accumulator

      d# 08 [sp]   cx  mov    \ taps/phase
      begin      
         op:  0 [bx]    ax  mov
         cwde
         0 [si]             imul
         4 [si]         si  lea    \ Update weight pointer
         mulscale #  dx ax  shrd   \ Scale down by multiplier scale factor         
         ax             di  add    \ Accumulate

         d# 20 [sp]     bx  sub    \ Update inbuf ptr
      loopa

      di           ax  mov

      \ Saturate
      d# 32767 # ax cmp  >  if
         d# 32767 # ax mov
      else
         d# -32767 # ax cmp  <  if
            d# -32767 # ax mov
         then
      then

      d# 24 [sp]   di  mov   \ Output pointer
      op:          ax  stos  \ Store output value
      di   d# 24 [sp]  mov   \ Update output pointer

   d# 04 [sp] dec            \ Phase counter
   0= until

   di               pop   \ Restore DI
   d# 08 [sp]   si  mov   \ Restore SI
   d# 16 [sp]   sp  lea   \ Remove stuff from stack 
c;

\ Convert a decimal fraction to a scaled integer multiplier
: mul:  ( "coef" -- )
   safe-parse-word  push-decimal $number drop pop-base  ( n )
   1 mulscale lshift  d# 1,000,000,000 */                         ( n' )
   ,
;

\ Filter coefficients for 6x upsampling.  The following filter was
\ computed with GNU Octave, using the program shown at the end of this file.
\ The coeeficients are ordered by phase for easy addressing in the inner loop.
\ The transition band is centered on Fs/6.  The stopband attenuation is 78dB.
\ The -3dB point is about 95% of Fs/6.

d#  6 constant #phases
d# 16 constant taps/phase

create weights
\ Phase 0
mul:  0.000190788 mul:  0.000375061 mul: -0.001237886 mul:  0.003214694
mul: -0.007235622 mul:  0.015062052 mul: -0.031397096 mul:  0.080446668
mul:  0.976279469 mul: -0.074732552 mul:  0.034801841 mul: -0.018817755
mul:  0.010022601 mul: -0.004881022 mul:  0.002025107 mul: -0.000631880

\ Phase 1
mul: -0.000511063 mul:  0.001786043 mul: -0.005327045 mul:  0.012716422
mul: -0.026661852 mul:  0.052425455 mul: -0.105580171 mul:  0.283737941
mul:  0.885823376 mul: -0.166749609 mul:  0.078608864 mul: -0.041296857
mul:  0.021106533 mul: -0.009784496 mul:  0.003821226 mul: -0.001092645

\ Phase 2
mul: -0.000795594 mul:  0.003214599 mul: -0.009060710 mul:  0.020831489
mul: -0.042537000 mul:  0.082398233 mul: -0.167272365 mul:  0.508384704
mul:  0.720544802 mul: -0.194040773 mul:  0.093827768 mul: -0.048873931
mul:  0.024446032 mul: -0.010977550 mul:  0.004090325 mul: -0.001079175

\ Phase 3
mul: -0.001079175 mul:  0.004090325 mul: -0.010977550 mul:  0.024446032
mul: -0.048873931 mul:  0.093827768 mul: -0.194040773 mul:  0.720544802
mul:  0.508384704 mul: -0.167272365 mul:  0.082398233 mul: -0.042537000
mul:  0.020831489 mul: -0.009060710 mul:  0.003214599 mul: -0.000795594

\ Phase 4
mul: -0.001092645 mul:  0.003821226 mul: -0.009784496 mul:  0.021106533
mul: -0.041296857 mul:  0.078608864 mul: -0.166749609 mul:  0.885823376
mul:  0.283737941 mul: -0.105580171 mul:  0.052425455 mul: -0.026661852
mul:  0.012716422 mul: -0.005327045 mul:  0.001786043 mul: -0.000511063

\ Phase 5
mul: -0.000631880 mul:  0.002025107 mul: -0.004881022 mul:  0.010022601
mul: -0.018817755 mul:  0.034801841 mul: -0.074732552 mul:  0.976279469
mul:  0.080446668 mul: -0.031397096 mul:  0.015062052 mul: -0.007235622
mul:  0.003214694 mul: -0.001237886 mul:  0.000375061 mul:  0.000190788

taps/phase 2* /n* buffer: zbuf

\ Stride is 2 for mono, 4 for stereo
\ For stereo you must call it twice with an offset of 2 for
\ inbuf and outbuf on the second call
: 8khz>48khz  ( inbuf /inbuf outbuf stride -- )
   2swap                                  ( outbuf stride inbuf /inbuf )

   \ First compute half a phase worth of samples with leading zeros
   2 pick taps/phase * >r                 ( outbuf stride inbuf /inbuf r: span )
   zbuf  r@ 2/  erase                     ( outbuf stride inbuf /inbuf )

   over  zbuf r@ 2/ +  r@  move           ( outbuf stride inbuf /inbuf )
   r@ /string                             ( outbuf stride inbuf' /inbuf' )

   2swap  zbuf  r@ +  r@ 2/  bounds  ?do  ( inbuf /inbuf outbuf stride )
      i weights taps/phase #phases  fir-upsample  ( inbuf /inbuf outbuf' strid )
   dup +loop                              ( inbuf /inbuf outbuf stride )

   \ Compute the bulk of the samples where the filter taps fit entirely
   \ within the input buffer
   2over bounds  ?do                      ( inbuf /inbuf outbuf stride )
      i weights taps/phase #phases  fir-upsample  ( inbuf /inbuf outbuf' stride )
   dup +loop                              ( inbuf /inbuf outbuf stride )

   \ Finally compute half a phase worth of samples with trailing zeros
   2swap                                  ( outbuf stride inbuf /inbuf )
   +  r@ -  zbuf  r@  move                ( outbuf stride )
   zbuf r@ +  r@ 2/  erase                ( outbuf stride )
   zbuf r@ +  r@ 2/  bounds  ?do          ( outbuf stride )
      i weights taps/phase #phases  fir-upsample  ( outbuf' stride )
   dup +loop                              ( outbuf stride )

   r> 3drop                               ( )
;

0 [if]
\ Here is some Matlab/Octave code to compute the weights
weights = remez(95, [0 .12 .215 1], [1 1 0 0]);
for phase=1:6
  for tap=1:16
    printf("mul: %.9f ", 5.9 * weights((tap-1)*6+phase));
  end 
end
[then]
