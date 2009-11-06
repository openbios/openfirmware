d#   5.00 value Tck
0 value #ranks
0 value #banks
0 value #row-bits 
0 value #col-bits 

\ Compute ceil(ns/tck)
: ns>tck  ( ns -- tck )  Tck + 1-  Tck /  ;

: ma-type  ( -- ma-type-code )
   #banks 8 =  if     ( )
      #col-bits 5 -   ( ma-type )
      dup 7 u>        ( ma-type error? )
   else               ( )
      #col-bits 9 -   ( ma-type )
      dup 3 u>        ( ma-type error? )
   then
   abort" Invalid MA type"
;

\ The 3 << is because of the 64-bit data width, i.e. 8 bytes, i.e. 1 << 3
\ We compute carefully to prevent overflow or underflow
: rank-size  ( -- rank-64mb )
   1  #row-bits #col-bits + 3 + d# 20 - <<   ( bank-mb )
   #banks *                                  ( rank-mb )
   6 >>                                      ( rank-64mb )
;

[ifdef] xo-board
.( Using XO timings) cr

\ DDR-400 timings for HY5PS1G4831C
d#   5.00 to Tck

\ d# 127.50 constant Trfc
d# 125.00 constant Trfc  \ Fudged to get same setting as Phoenix
d#   7.50 constant Trrd
\ d#  10.00 constant Trrd
d#      3 constant TCL
\ d#  40.00 constant Tras
 d#  45.00 constant Tras
d#  15.00 constant Twr
 d#   7.50 constant Trtp
\  d#  10.00 constant Trtp
d#  10.00 constant Twtr
d#  15.00 constant Trp
d#  15.00 constant Trcd

1 to #ranks
8 to #banks
d# 10 to #col-bits
d# 14 to #row-bits

0 constant rank-base0  rank-size constant rank-top0
0 constant rank-base1  0 constant rank-top1
0 constant rank-base2  0 constant rank-top2
0 constant rank-base3  0 constant rank-top3

rank-size #ranks * constant total-size
[then]

[ifdef] demo-board
\ DDR-533 timings for Micron MT8HTF6464HDY DIMM
d#   3.75 to Tck

d# 105.00 constant Trfc
d#  10.00 constant Trrd
d#      4 constant TCL
d#  45.00 constant Tras
d#  15.00 constant Twr
d#   7.50 constant Trtp
d#   7.00 constant Twtr
d#  15.00 constant Trp
d#  15.00 constant Trcd

2 to #ranks
4 to #banks
d# 10 to #col-bits
\ d# 14 to #row-bits

0         constant rank-base0  rank-size              constant rank-top0
rank-top0 constant rank-base1  rank-base0 rank-size + constant rank-top1

0 constant rank-base2  0 constant rank-top2
0 constant rank-base3  0 constant rank-top3

rank-size #ranks * constant total-size
[then]

\ h# 400.0000 constant /fbmem
h# 1000.0000 constant /fbmem
: >fbmem-base  ( size/64M -- low high )
   d# 26 lshift           ( memsize-in-bytes )
   /fbmem -               ( memsize-less-framebuf-size )
   d# 21 rshift wbsplit   ( low high )
;

: dblfudge32  2/  ;
