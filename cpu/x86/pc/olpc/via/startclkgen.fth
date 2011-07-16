\ We depend on ioinit.fth having already established the following settings 
\ D17F0 Rx04[0]=1  I/O space enable
\ D17F0 Rx94[7]=0  Clock from 14 MHz divider
\ D17F0 Rxd2[2]=1  Clock divider
\ D17F0 Rxd2[0]=1  Enable SMBus host controller
\ D17F0 Rxd0,d1 set to smbus-io-base

h# de smbus-io-base 0 + port-wb   \ Clear all errors
\ We assume that the SMBus controller is not busy
h# d2 smbus-io-base 4 + port-wb   \ Target address of clock generator chip and WRITE mode
h# 05 smbus-io-base 3 + port-wb   \ Register number inside clock generator (output config)
h# 01 smbus-io-base 5 + port-wb   \ Byte count
      smbus-io-base 2 + port-rb   \ Read to reset the byte counter for the next write
h# 03 smbus-io-base 7 + port-wb   \ Value to put in the clock generator output config reg - turns off PCIe clocks
h# 54 smbus-io-base 2 + port-wb   \ Fire off the command.  40 is the start bit, 14 is the "SMBus block data" command
\ We don't wait for it to finish
