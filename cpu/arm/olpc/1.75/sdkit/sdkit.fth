fload mmap.fth
0 constant acgr-pa \ Dummy definition
fload mfpr.fth
apb-pa h# 40.0000 mmap to io-va
fload gpio.fth
: us  ( n -- )  d# 40 *  0  do loop  ;
: ms  ( n -- )  0  ?do  d# 1000 us  loop  ;
fload smbus.fth
fload camera-test.fth
fload twsi.fth
fload accelerometer.fth
.( See http://wiki.laptop.org/go/Forth_Lesson_22) cr
hex
