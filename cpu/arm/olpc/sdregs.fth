h# 200 value /regs   \ SDHCI register block
1 value #slots

0 instance value base-addr
0 instance value chip

: set-slot-address  ( slot-address -- )  to base-addr  ;
: map-regs  ( -- )
   chip  if  exit  then
   base-addr /regs " map-in" $call-parent
   to chip
;
: unmap-regs  ( -- )
   chip  0=  if  exit  then
   chip  /regs  " map-out" $call-parent
   0 to chip
;

: vendor-modes  ( -- )  ;

\ This tunes the data timing for better operation at 50 MHz
: ?cafe-fpga-quirk  ( -- )  h# 10a chip + rw@  h# 3f00 or  h# 10a chip + rw!  ;

: ?via-quirk  ( -- )  ;
