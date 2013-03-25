\ See license at end of file
purpose: Linear feedback shift register code and related memory tests

0 value lfsr-poly

[ifdef] arm-assembler
code lfsr-step  ( state -- state' )
   movs   tos,tos,lsr #1
   u>=  if   \ Carry set
      set r0,`'user# lfsr-poly`
      ldr r0,[up,r0]
      eor tos,tos,r0
   then
c;
0 [if]  \ This is for testing the period of various polynomials
code lfsr-period  ( polynomial -- period )
   \ tos:polynomial
   mov  r0,#1           \ r0:seed
   mov  r2,r0           \ r2:lfsr
   mov  r1,#0           \ r1:count           
   begin
      inc   r1,#1
      movs  r2,r2,lsr #1
      eorcs r2,r2,tos
      cmp   r2,r0
   = until
   mov tos,r1
c;
[then]
[then]
[ifdef] x86-assembler
code lfsr-step  ( state -- state' )
   ax pop
   1 #  ax  shr
   carry?  if
      'user lfsr-poly  bx  mov
      bx  ax  xor
   then
   ax push
c;
[then]
[ifndef] lfsr-step
: lfsr-step  ( state -- state' )
   dup 2/  swap 1 and  if  lfsr-poly xor  then
;   
[then]

0 [if]
\ Given a list of bit numbers for the polynomial taps, compute the mask value
\ If the polynomial is x^15 + x^14 + 1, the bit numbers are 15, 14, and 0, so
\ the argument list would be  0 14 15 .  The 0 must be first to end the list.
\ The order of the others is irrelevant.
: bits>poly  ( 0 bit#0 ... bit#n -- mask )
   0  begin                ( 0 bit#0 ... bit#m mask )
      over                 ( 0 bit# ... bit#m mask bit#m )
   while                   ( 0 bit#0 ... bit#m mask )
      1 rot 1- lshift  or  ( 0 bit#0 ... bit#m-1 mask' )
   repeat                  ( 0 mask )
   nip                     ( mask )
;
[then]

\ Polynomials for maximal length LFSRs for different bit lengths
\ The values come from the Wikipedia article for Linear Feedback Shift Register and from
\ http://www.xilinx.com/support/documentation/application_notes/xapp052.pdf
create lfsr-polynomials
                   \ #bits   period
h#        0 ,      \     0        0
h#        1 ,      \     1        1
h#        3 ,      \     2        3
h#        6 ,      \     3        7
h#        c ,      \     4        f
h#       14 ,      \     5       1f
h#       30 ,      \     6       3f
h#       60 ,      \     7       7f
h#       b8 ,      \     8       ff
h#      110 ,      \     9      1ff
h#      240 ,      \    10      3ff
h#      500 ,      \    11      7ff
h#      e08 ,      \    12      fff
h#     1c80 ,      \    13     1fff
h#     3802 ,      \    14     3fff
h#     6000 ,      \    15     7fff
h#     b400 ,      \    16     ffff
h#    12000 ,      \    17    1ffff
h#    20400 ,      \    18    3ffff
h#    72000 ,      \    19    7ffff
h#    90000 ,      \    20    fffff
h#   140000 ,      \    21   1fffff
h#   300000 ,      \    22   3fffff
h#   420000 ,      \    23   7fffff
h#   e10000 ,      \    24   ffffff
h#  1200000 ,      \    25  1ffffff
h#  2000023 ,      \    26  3ffffff
h#  4000013 ,      \    27  7ffffff
h#  9000000 ,      \    28  fffffff
h# 14000000 ,      \    29 1fffffff
h# 20000029 ,      \    30 3fffffff
h# 48000000 ,      \    31 7fffffff
h# 80200003 ,      \    32 ffffffff

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
