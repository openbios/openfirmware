\ Configuration space registers
my-address my-space encode-phys
0 encode-int encode+  0 encode-int encode+
\ EHCI operational registers
0 0    my-space  0200.0010 + encode-phys encode+
0 encode-int encode+  h# 100 encode-int encode+
" reg" property

: my-map-in  ( len -- adr )
   >r  0 0 my-space h# 0200.0010 +  r>  " map-in" $call-parent
   4 my-w@  h# 16 or  4 my-w!  \ Set MWI, bus mastering, and mem enable
;
: my-map-out  ( adr len -- )
   4 my-w@  7 invert and  4 my-w!
   " map-out" $call-parent
;
