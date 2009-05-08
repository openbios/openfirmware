: devfunc  ( dev func -- )
   h# 100 *  swap h# 800 * or  h# 8000.0000 or
   [ also assembler ]
   # ebp mov  " masked-config-writes" evaluate  #) call
   [ previous ]
;
: end-table  0 c,  ;

: mreg  ( reg# and or -- )  rot c, swap c, c,  ;
: wait-us  ( us -- )
   " # ax mov  usdelay #) call" evaluate
;

: showreg  ( reg# -- )
   " h# ff port80  d# 200000 wait-us" eval
   " config-rb  al 80 # out  d# 1000000 wait-us" eval
;
