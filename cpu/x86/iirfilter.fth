purpose: IIR digital filter support

\ iir-cascade implements the "Folded Cascade First Order Filters"
\ structure as shown on page 274 of _Multirate Signal Processing
\ for Communications Systems_ by fredric j harris, Prentice Hall 2004
\ ISBN 0-13-146511-2

d# 14 constant mulscale

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
      bx       0 [bp]  mov   \ Update M[i]

      8 [bp]       bp  lea   \ Point to next M[i]
   loopa

   0 [bp]       dx  mov
   dx       4 [bp]  mov
   ax       0 [bp]  mov   \ Update M[i]

   bp pop     \ Restore BP
   si pop     \ Restore SI
   ax push    \ Return value
c;

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
      d#  4 [bp]   ax  sub   \ last - M[i+1]

      0 [si]           imul  \ alpha[i] * (last - M[i+1])  (kills DX)
      4 [si]       si  lea   \ Increment alpha pointer
      mulscale #  dx  ax  shrd  \ Scale down by multiplier scale factor

      d#  0 [bp]   ax  add   \ M[i] + alpha[i] * (last - M[i+1])

      bx       0 [bp]  mov   \ Update M[i]

      4 [bp]       bp  lea   \ Point to next M[i]
   loopa
   ax          0 [bp]  mov   \ Update M[i]

   bp pop     \ Restore BP
   si pop     \ Restore SI
   ax push    \ Return value
c;

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


: mul:  ( "coef" -- )
   safe-parse-word  push-decimal $number drop pop-base  ( n )
   1 mulscale lshift  d# 1,000,000,000 */                         ( n' )
   ,
;

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

\ upsample by 4

2 constant #coefs

\ This is for a 9-pole, 9-zero 2-path all-pass halfband IIR filter
create weights0 mul: .101467517  mul: .612422841   \ Even path
create weights1 mul: .342095596  mul: .867647439   \ Odd path

0 [if]
\ This is for a 5-pole, 5-zero 2-path all-pass halfband IIR filter
create weights2 mul: .141348600   \ Even path
create weights3 mul: .589994800   \ Odd path
[then]

\ This is for a 5-pole, 5-zero 2-path all-pass third-band IIR filter
\ G0 and G1 use iir-cascade-z2g, H1 uses iir-cascade-z1
create coefg0   mul: -.605502011  mul: .211004022    \ Even path G0
create coefg1   mul: -.817448745  mul: .634897489    \ Odd path G1
create coefh1   mul: -.267949192


#coefs 1+ 2* /n* constant buflen
buflen buffer: z0  \ First upsampler even path delay buffer
buflen buffer: z1  \ First upsampler odd path delay buffer
buflen buffer: z2  \ 3x upsampler even path G0 delay buffer
buflen buffer: z3  \ 3x upsampler odd path G1 delay buffer
buflen buffer: z4  \ 3x upsampler odd path H1 delay buffer

: init-upsample
   z0 buflen erase
   z1 buflen erase
   z2 buflen erase
   z3 buflen erase
   z4 buflen erase
;

0 value lastsample

\ This is a polyphase decomposition of upsampling by 2
\ The filter prototype for each path is a polynomial in Z^2,
\ but when you apply the polyphase transform with Nobel's identity,
\ the paths split and the output summation becomes a commutation.
: up2  ( sample -- out1 out0 )
   dup weights0 z0 2 iir-cascade-z1 saturate >r
       weights1 z1 2 iir-cascade-z1 saturate r>
;

0 [if]
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

d# sample-stride
variable sample-outp
: out,  ( value -- )
   sample-outp @ w!  sample-stride  sample-out +!
;

\ Stride is 2 for mono, 4 for stereo
\ For stereo you must call it twice with an offset of 2 for
\ inbuf and outbuf on the second call
: 8khz>48khz  ( inbuf #samples stride outbuf -- )
   to sample-stride         ( inbuf #samples outbuf )
   sample-outp !            ( inbuf #samples )
   0  ?do                   ( inbuf )
      dup sample-stride +   ( inbuf inbuf' )
      swap <w@              ( inbuf' sample )
      up2                   ( inbuf s1 s0 )
      up3 out, out, out,    ( inbuf s1 )
      up3 out, out, out,    ( inbuf )
   loop                     ( inbuf )
   drop
;

: 16khz>48khz  ( inbuf #samples stride outbuf -- )
   to sample-stride         ( inbuf #samples outbuf )
   sample-outp !            ( inbuf #samples )
   0  ?do                   ( inbuf )
      dup sample-stride +   ( inbuf inbuf' )
      swap <w@              ( inbuf' sample )
      up3 out, out, out,    ( inbuf s1 )
   loop                     ( inbuf )
   drop
;
