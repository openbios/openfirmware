purpose: Device tree nodes for board-specific I2C buses implemented by TWSI hardware

: make-twsi-node  ( baseadr clock# irq# muxed-irq? fast? unit# -- )
   root-device
   new-device
      " linux,unit#" integer-property
      " i2c" name
      " mrvl,mmp-twsi" +compatible                    ( baseadr clock# irq# muxed-irq? fast? )
      if  0 0  " mrvl,i2c-fast-mode" property  then   ( baseadr clock# irq# muxed-irq? )
      if
          " /interrupt-controller/interrupt-controller@158" encode-phandle " interrupt-parent" property
      then                                            ( baseadr clock# irq# )
      " interrupts" integer-property                  ( baseadr clock# )
      " /apbc" encode-phandle rot encode-int encode+ " clocks" property

      h# 1000 reg                                     ( )
      1 " #address-cells" integer-property
      1 " #size-cells" integer-property
      " : open true ; : close ;" evaluate
      " : encode-unit  ( phys.. -- str )  push-hex (u.) pop-base  ;" evaluate
      " : decode-unit  ( str -- phys.. )  push-hex  $number  if  0  then  pop-base  ;" evaluate
   finish-device
   device-end
;      

\     baseadr   clk irq mux? fast? unit#
  h# d4011000     1   7 false true     2 make-twsi-node  \ TWSI1
  h# d4031000     2   0 true  true     3 make-twsi-node  \ TWSI2
\ h# d4032000     3   1 true  true     N make-twsi-node  \ TWSI3
  h# d4033000     4   2 true  true     5 make-twsi-node  \ TWSI4
\ h# d4038000 d# 30   3 true  true     N make-twsi-node  \ TWSI5
  h# d4034000 d# 31   4 true  true     4 make-twsi-node  \ TWSI6


[ifdef] soon-olpc-cl2  \ this breaks cl4-a1 boards, which ofw calls cl2.
0 0  " 30" " /i2c@d4033000" begin-package  \ TWSI4
   " touchscreen" name
   " raydium_ts" +compatible
   my-address my-space 1 reg
end-package
[else]
0 0  " 50" " /i2c@d4033000" begin-package  \ TWSI4
   " touchscreen" name
   " zforce" +compatible
   my-address my-space 1 reg
   touch-rst-gpio# 1  " reset-gpios" gpio-property
   touch-tck-gpio# 1  " test-gpios"  gpio-property
   touch-hd-gpio#  1  " hd-gpios"    gpio-property
   touch-int-gpio# 1  " dr-gpios"    gpio-property
end-package
[then]

0 0  " 19" " /i2c@d4034000" begin-package  \ TWSI6
   " accelerometer" name
   " lis3lv02d" +compatible
   my-address my-space 1 reg
end-package
