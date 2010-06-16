h# 100 value /regs   \ Standard size of SDHCI register block
4 value #slots

0 instance value slot
0 instance value chip

0 0 encode-bytes
h# d4280000 encode-phys encode+  /regs encode-int encode+
h# d4280800 encode-phys encode+  /regs encode-int encode+
h# d4281000 encode-phys encode+  /regs encode-int encode+
h# d4281800 encode-phys encode+  /regs encode-int encode+
" reg" property

: map-regs  ( -- )
   chip  if  exit  then
   slot 1-  h# 800 *  my-space +  /regs " map-in" $call-parent
   to chip
;
: unmap-regs  ( -- )
   chip  0=  if  exit  then
   chip  /regs  " map-out" $call-parent
   0 to chip
;

: vendor-modes  ( -- )  ;
: ?cafe-fpga-quirk  ( -- )  ;
: ?via-quirk  ( -- )  ;
