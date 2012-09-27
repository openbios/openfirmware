purpose: Device tree nodes for board-specific I2C buses implemented by TWSI hardware

\ We omit nodes for unconnected TWSI channels
\ The unit# properties are chosen so that GPIO I2C nodes get lower addresses.
\ Some Linux drivers expect to find devices on specific I2C bus numbers.

\     baseadr   clk irq mux? fast? unit#
  h# d4011000     1   7 false true  2 fload ${BP}/cpu/arm/mmp2/twsi-node.fth  \ TWSI1
  h# d4031000     2   0 true  true  3 fload ${BP}/cpu/arm/mmp2/twsi-node.fth  \ TWSI2
\ h# d4032000     3   1 true  true  N fload ${BP}/cpu/arm/mmp2/twsi-node.fth  \ TWSI3
  h# d4033000     4   2 true  true  5 fload ${BP}/cpu/arm/mmp2/twsi-node.fth  \ TWSI4
\ h# d4038000 d# 30   3 true  true  N fload ${BP}/cpu/arm/mmp2/twsi-node.fth  \ TWSI5
  h# d4034000 d# 31   4 true  true  4 fload ${BP}/cpu/arm/mmp2/twsi-node.fth  \ TWSI6

devalias i2c2 /i2c@d4011000
devalias i2c3 /i2c@d4031000
devalias i2c5 /i2c@d4033000
devalias i2c4 /i2c@d4034000

[ifdef] soon-olpc-cl2  \ this breaks cl4-a1 boards, which ofw calls cl2.
dev /i2c@d4033000  \ TWSI4
new-device
   h# 30 1 reg
   " touchscreen" name
   " raydium_ts" +compatible
finish-device
device-end
[then]
