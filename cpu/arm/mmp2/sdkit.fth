fload mmap.fth
0 constant acgr-pa \ Dummy definition
fload mfpr.fth
mfpr-base h# 1000 mmap to mfpr-base
h# d4019000 h# 1000 mmap constant gpio-base
fload gpio.fth
: us  ( n -- )  d# 40 *  0  do loop  ;
: ms  ( n -- )  0  ?do  d# 1000 us  loop  ;
fload smbus.fth
fload camera-test.fth
fload twsi.fth
fload accelerometer.fth
.( See http://wiki.laptop.org/go/Forth_Lesson_22) cr
hex
