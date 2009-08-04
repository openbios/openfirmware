purpose: IIR digital upsampling filter

\ This file implements x2 and x3 upsampling filters using techniques
\ described in chapter 10 of _Multirate Signal Processing for Communications
\ Systems_ by fredric j harris, Prentice Hall 2004, ISBN 0-13-146511-2
\ The filters may be cascaded for x6 upsampling (e.g. for 8kHz -> 48kHz)

d# 15 constant mulscale  \ Bits for fractional multipliers

0 [if]

\ iir-cascade-z2 implements a folded cascade of multiple sections
\ of a second-order IIR filter block in a polynomial in Z^2.
\ This is the basic building block for half-band all-pass
\ recursive filters, as described in section 10.2 of the book
\ cited above.   
\ This code is commented out because we don't use it directly,
\ instead using the -z1 variant below in a polyphase structure.

code iir-cascade-z2 ( sample weights z #sections -- out )
   cx pop     \ CX: Number of sections

   bp bx mov  \ Save
   bp pop     \ BP: Z list
   si dx mov  \ Save SI
   si pop     \ SI: Filter weights
   ax pop     \ AX: current value
   dx push    \ Saved SI on stack
   bx push    \ Saved BP on stack
   begin
      ax           bx  mov   \ Save last value
      d# 12 [bp]   ax  sub   \ last - Z[i+1]
      0 [si]           imul  \ alpha[i] * (last - Z[i+1])  (kills DX)
      4 [si]       si  lea   \ Increment alpha pointer
      mulscale #   dx  ax  shrd  \ Scale down by multiplier scale factor

      d#  4 [bp]   ax  add   \ Z[i] + alpha[i] * (last - Z[i+1])

      0 [bp]       dx  mov
      dx       4 [bp]  mov
      bx       0 [bp]  mov   \ Update Z[i]

      8 [bp]       bp  lea   \ Point to next Z[i]
   loopa

   0 [bp]       dx  mov
   dx       4 [bp]  mov
   ax       0 [bp]  mov   \ Update Z[i]

   bp pop     \ Restore BP
   si pop     \ Restore SI
   ax push    \ Return value
c;
[then]

\ iir-cascade-z1 is the same basic structure as iir-cascade-z2,
\ but the Z^-2 delays have been replaced by Z^-1.  It is used
\ in the polyphase upsampler "up2".  When the rate is doubled,
\ a zero sample is inserted between each pair of input samples,
\ causing every other computation of the Z^-2 polynomial to be
\ unnecessary.  The basic block can thus be restructured to have
\ a single delay element, and the block only has to run at half
\ the rate.  See section 10.6 (figure 10.48) of the book.

code iir-cascade-z1 ( sample weights z #sections -- out )
   cx pop     \ CX: Number of sections

   bp bx mov  \ Save
   bp pop     \ BP: Z list
   si dx mov  \ Save SI
   si pop     \ SI: Filter weights
   ax pop     \ AX: current value
   dx push    \ Saved SI on stack
   bx push    \ Saved BP on stack
   begin
      ax           bx  mov   \ Save last value
      d#  4 [bp]   ax  sub   \ last - Z[i+1]

      0 [si]           imul  \ alpha[i] * (last - Z[i+1])  (kills DX)
      4 [si]       si  lea   \ Increment alpha pointer
      mulscale #  dx  ax  shrd  \ Scale down by multiplier scale factor

      d#  0 [bp]   ax  add   \ Z[i] + alpha[i] * (last - Z[i+1])

      bx       0 [bp]  mov   \ Update Z[i]

      4 [bp]       bp  lea   \ Point to next Z[i]
   loopa
   ax          0 [bp]  mov   \ Update Z[i]

   bp pop     \ Restore BP
   si pop     \ Restore SI
   ax push    \ Return value
c;

\ iir-cascade-z2g implements the generalized second-order
\ low pass filter cascade as shown in section 10.5.1 (figure 10.35)
\ of the book.  The generalized form allows arbitrary bandwidths
\ as opposed to the half-band restriction of the simplifed form.
\ We use this form for 3x upsampling so we can set the lowpass
\ frequency to Fnyquist/3.

code iir-cascade-z2g  ( sample weights z #sections -- out )
   cx pop     \ CX: Number of sections

   bp bx mov  \ Save
   bp pop     \ BP: Z list
   si dx mov  \ Save SI
   si pop     \ SI: Filter weights
   ax pop     \ AX: current value
   dx push    \ Saved SI on stack
   bx push    \ Saved BP on stack
   di push    \ Saved DI on stack
   begin
      ax           bx  mov   \ Save last value
      d# 12 [bp]   ax  sub   \ last - Z[3]

      4 [si]           imul  \ c2 * (last - Z[3])  (kills DX)
      mulscale #   dx  ax  shrd  \ Scale down by multiplier scale factor

      d#  4 [bp]   ax  add   \ next += Z[1]

      ax           di  mov   \ Save next in di to free up ax

      d#  0 [bp]   ax  mov   \ AX: Z[0]
      ax   d#  4 [bp]  mov   \ Z[1] = Z[0]
      bx   d#  0 [bp]  mov   \ Z[0] = sample

      d#  8 [bp]   ax  sub   \ Z[0] - Z[2]

      0 [si]           imul  \ c1 * (Z[0] - Z[2])
      mulscale #   dx  ax  shrd  \ Scale down by multiplier scale factor

      di           ax  add   \ AX: next

      8 [si]       si  lea   \ Increment coefficient pointer
      8 [bp]       bp  lea   \ Increment Z pointer
   loopa

   0 [bp]       dx  mov
   dx       4 [bp]  mov      \ Z[1] = Z[0]
   ax       0 [bp]  mov      \ Z[0] = next

   di pop     \ Restore DI
   bp pop     \ Restore BP
   si pop     \ Restore SI
   ax push    \ Return value
c;


\ Convert a decimal fraction to a scaled integer multiplier
: mul:  ( "coef" -- )
   safe-parse-word  push-decimal $number drop pop-base  ( n )
   1 mulscale lshift  d# 1,000,000,000 */                         ( n' )
   ,
;

\ Clip too-large sample values to +- 15 bits
code saturate  ( s -- s' )
   ax pop
   d# 32767 # ax cmp  >  if
      d# 32767 # ax mov
   else
      d# -32767 # ax cmp  <  if
         d# -32767 # ax mov
      then
   then
   ax push
c;

0 [if]
: saturate  ( n -- )
   dup d#  32767 >  if  drop d#  32767  then
   dup d# -32767 <  if  drop d# -32767  then
;
[then]

2 constant #coefs

\ This is for a 9-pole, 9-zero 2-path all-pass halfband IIR filter
\ From page 278 of the book
create weights0 mul: .101467517  mul: .612422841   \ Even path
create weights1 mul: .342095596  mul: .867647439   \ Odd path

0 [if]
\ This is for a 5-pole, 5-zero 2-path all-pass halfband IIR filter
\ From page 276 of the book
create weights2 mul: .141348600   \ Even path
create weights3 mul: .589994800   \ Odd path
[then]

\ This is for a 5-pole, 5-zero 2-path all-pass third-band IIR filter
\ G0 and G1 use iir-cascade-z2g, H1 uses iir-cascade-z1
\ This is derived from the 5-pole halfband coefficients according
\ to the formulas on page 291, with fb/fs = 1/6 (fb/fnyquist = 1/3).
\ The book has a missing sign somewhere, because without the minus
\ signs on c1 and b, you end up with the corner frequency at 2/6
\ instead of 1/6.  I had to figure that out the hard way, by trial
\ and error (looking at spectra of impulse responses).  If you
\ replace b with -b in equation 10.25, the c1's work out automatically.

\               c1                c2
create coefg0   mul: -.605502011  mul: .211004022    \ Even path G0
create coefg1   mul: -.817448745  mul: .634897489    \ Odd path G1
\               b
create coefh1   mul: -.267949192


2 1+ /n* constant buflen0  \ 2 stages of Z^-1 plus final feedback

buflen0 buffer: z0  \ First upsampler even path delay buffer
buflen0 buffer: z1  \ First upsampler odd path delay buffer

1 1+ 2* /n* constant buflen1  \ 1 stage of Z^-2 plus final feedback

buflen1 buffer: z2  \ 3x upsampler even path G0 delay buffer
buflen1 buffer: z3  \ 3x upsampler odd path G1 delay buffer
buflen1 buffer: z4  \ 3x upsampler odd path H1 delay buffer

: init-upsample  ( -- )
   z0 buflen0 erase
   z1 buflen0 erase
   z2 buflen1 erase
   z3 buflen1 erase
   z4 buflen1 erase
;

\ This is a polyphase decomposition of upsampling by 2
\ The filter prototype for each path is a polynomial in Z^2,
\ but when you apply the polyphase transform with Nobel's identity,
\ the paths split and the output summation becomes a commutation.
: up2  ( sample -- out1 out0 )
   dup weights0 z0 2 iir-cascade-z1 saturate >r
       weights1 z1 2 iir-cascade-z1 saturate r>
;

0 [if]
0 value lastsample

\ This is the base rate (non-polyphase) version of up2
\ Both paths run for each sample, with Z^-1 between the
\ paths, summing the paths to get a lowpass output.
: filter2  ( sample -- out )
   lastsample weights1 z3 2 iir-cascade-z2  >r  ( sample r: out1 )
   to lastsample
   lastsample weights0 z2 2 iir-cascade-z2  r>  ( out0 out1 )
   + saturate                                   ( out )
;
[then]

\ Third-band interpolation filter.  You have to run this once
\ for each output sample, with 0-stuffing between input samples.
\ It would be nice to polyphase this, but doing so requires a
\ complex design methodology for the IIR filter sections that
\ I haven't mastered.
: interp3  ( sample -- out )
   dup  coefg0 z2 1 iir-cascade-z2g     ( sample out0 )
   swap coefh1 z4 1 iir-cascade-z1      ( out0 outh )
        coefg1 z3 1 iir-cascade-z2g     ( out0 out1 )
   + saturate                           ( )
;

\ Upsample by a factor of 3
: up3  ( sample -- out2 out1 out0 )
   interp3 >r  0 interp3 >r  0 interp3  r> r>
;

0 value sample-stride
variable sample-outp
: out,  ( value -- )
   sample-outp @ w!  sample-stride  sample-outp +!
;

\ Stride is 2 for mono, 4 for stereo
\ For stereo you must call it twice with an offset of 2 for
\ inbuf and outbuf on the second call
: 8khz>48khz  ( inbuf #samples outbuf stride -- )
   to sample-stride         ( inbuf #samples outbuf )
   sample-outp !            ( inbuf #samples )
   init-upsample            ( inbuf #samples )
   0  ?do                   ( inbuf )
      dup sample-stride +   ( inbuf inbuf' )
      swap <w@              ( inbuf' sample )
      up2                   ( inbuf s1 s0 )
      up3 out, out, out,    ( inbuf s1 )
      up3 out, out, out,    ( inbuf )
   loop                     ( inbuf )
   drop
;

: 16khz>48khz  ( inbuf #samples outbuf stride -- )
   to sample-stride         ( inbuf #samples outbuf )
   sample-outp !            ( inbuf #samples )
   init-upsample            ( inbuf #samples )
   0  ?do                   ( inbuf )
      dup sample-stride +   ( inbuf inbuf' )
      swap <w@              ( inbuf' sample )
      up3 out, out, out,    ( inbuf s1 )
   loop                     ( inbuf )
   drop
;

0 [if]
\ Here is some Matlab/Octave code to do the "coefg.." coefficient
\ transformations
function retval = c1(a, b)
   retval = 2 * b * (1 + a) / (1 + a * b * b);
end
function retval = c2(a, b)
   retval = ((b * b) + a) / (1 + a * b * b);
end
function retval = cvtb(frac)
   retval = (1 - tan(pi * frac)) / (1 + tan(pi * frac));
end
function cvtfilt (bw) % bw is fb/fs
  a0 = .141348600
  a1 = .589994800

  b = cvtb(bw)
  c10 = c1(a0, b)
  c20 = c2(a0, b)
  c11 = c1(a1, b)
  c21 = c2(a1, b)
end
cvtfilt(1/6);
[then]
