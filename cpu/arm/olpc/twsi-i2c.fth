purpose: Device tree nodes for board-specific I2C buses implemented by TWSI hardware

: make-twsi-node  " ${BP}/cpu/arm/mmp2/twsi-node.fth" included  ;

\     baseadr   clk irq mux? fast? unit#
  h# d4011000     1   7 false true     2 make-twsi-node  \ TWSI1
  h# d4031000     2   0 true  true     3 make-twsi-node  \ TWSI2
\ h# d4032000     3   1 true  true     N make-twsi-node  \ TWSI3
  h# d4033000     4   2 true  true     5 make-twsi-node  \ TWSI4
\ h# d4038000 d# 30   3 true  true     N make-twsi-node  \ TWSI5
  h# d4034000 d# 31   4 true  true     4 make-twsi-node  \ TWSI6

[ifdef] soon-olpc-cl2  \ this breaks cl4-a1 boards, which ofw calls cl2.
dev /i2c@d4033000  \ TWSI4
new-device
   h# 30 1 reg
   " touchscreen" name
   " raydium_ts" +compatible
finish-device
device-end
[then]
