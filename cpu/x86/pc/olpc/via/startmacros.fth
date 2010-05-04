: devfunc  ( dev func -- )
\   ." Device " over .d  ." function " dup .d  cr
   h# 100 *  swap h# 800 * or  h# 8000.0000 or
   [ also assembler ]
   # ebp mov  " masked-config-writes" evaluate  #) call
   [ previous ]
;
: end-table  0 c,  ;

: mreg  ( reg# and or -- )
\   2 pick .2  over .2  dup .2  cr  \ Display the setup values at compile time
   rot c, swap c, c,
;
: wait-us  ( us -- )
   " # ax mov  usdelay #) call" evaluate
;

: showreg  ( reg# -- )
   " h# ff port80  d# 200000 wait-us" eval
   " config-rb  al 80 # out  d# 1000000 wait-us" eval
;

: index-table  ( index-register -- )
   [ also assembler ]
   # dx mov  " indexed-writes" evaluate  #) call
   [ previous ]
;
: crtc-table  ( -- )  h# 3d4 index-table  ;
: seq-table  ( -- )  h# 3c4 index-table  ;
: grf-table  ( -- )  h# 3ce index-table  ;

: seq-setup  ( index -- )
   [ also assembler ]
   # al mov
   h# 3c4 # dx mov
   al dx out
   dx inc
   [ previous ]
;
   
: seq-rb  ( index -- )  seq-setup  " dx al in" evaluate  ;
: seq-wb  ( data index -- )  seq-setup  "  # al mov  al dx out" evaluate  ;
: seq-set  ( bitmask index -- )
   seq-rb      ( index bitmask )
   \ Depends on index register already being set and dx already containing 3c5
   " # al or  al dx out" evaluate
;
: seq-clr  ( bitmask index -- )
   seq-rb      ( index bitmask )
   \ Depends on index register already being set and dx already containing 3c5
   invert  " # al and  al dx out" evaluate
;

: crt-setup  ( index -- )
   [ also assembler ]
   # al mov
   h# 3d4 # dx mov
   al dx out
   dx inc
   [ previous ]
;
: crt-rb  ( index -- )  crt-setup  " dx al in" evaluate  ;
: crt-wb  ( data index -- ) crt-setup  " al dx out" evaluate  ;
: crt-set  ( bitmask index -- )
   crt-rb      ( bitmask )
   \ Depends on index register already being set and dx already containing 3c5
   " # al or  al dx out" evaluate
;
: crt-clr  ( bitmask index -- )
   crt-rb      ( bitmask )
   \ Depends on index register already being set and dx already containing 3c5
   invert  " # al and  al dx out" evaluate
;

: ireg  ( value reg# -- )  c, c,  ;
