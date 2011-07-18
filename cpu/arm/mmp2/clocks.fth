purpose: Change the clock frequency

: fccr@    ( -- n )  h# 05.0008 io@  ;
: fccr!    ( n -- )  h# 05.0008 io!  ;
: pj4-clksel  ( n -- )
   d# 29 lshift                               ( field )
   fccr@  h# e000.0000 invert and  or  fccr!  ( )
;
: sp-clksel  ( n -- )
   d# 26 lshift                               ( field )
   fccr@  h# 1c00.0000 invert and  or  fccr!  ( )
;
: pj4-cc!  ( n -- )  h# 28.2804 io!  ;

: sp-cc!     ( n -- )  h# 28.2800 io!  ;
\                                     cfraaADXBpP
: sp-100mhz  ( -- )  0 sp-clksel   o# 37077703303 sp-cc!  ;  \ A 100, D 400, XP 100, B 100, P 100
: sp-200mhz  ( -- )  0 sp-clksel   o# 37077301101 sp-cc!  ;  \ A 200, D 400, XP 200, B 200, P 200
: sp-400mhz1 ( -- )  0 sp-clksel   o# 37077301100 sp-cc!  ;  \ A 200, D 400, XP 200, B 200, P 400
: sp-400mhz2 ( -- )  0 sp-clksel   o# 37077300000 sp-cc!  ;  \ A 200, D 400, XP 400, B 400, P 400
: sp-original        1 sp-clksel   o# 37077301101 sp-cc!  ;  \ A 200, D 400, XP 400, B 400, P 400

\                                     cfr52ADXBCP
: pj4-100mhz ( -- )  0 pj4-clksel  o# 37042703303 pj4-cc!  ;  \ A 100, D 400, XP 100, B 100, P 100
: pj4-200mhz ( -- )  0 pj4-clksel  o# 37042301101 pj4-cc!  ;  \ A 200, D 400, XP 200, B 200, P 200
: pj4-400mhz ( -- )  0 pj4-clksel  o# 37042301100 pj4-cc!  ;  \ A 200, D 400, XP 200, B 200, P 400
: pj4-800mhz ( -- )  1 pj4-clksel  o# 37042201100 pj4-cc!  ;  \ A 266, D 400, XP 400, B 400, P 800

0 [if]
\ PJ4 versions using voting           cvr52ADXBCP
: pj4-100mhz ( -- )  0 pj4-clksel  o# 21742703303 pj4-cc!  ;  \ A 100, D 400, XP 100, B 100, P 100
: pj4-200mhz ( -- )  0 pj4-clksel  o# 21742301101 pj4-cc!  ;  \ A 200, D 400, XP 200, B 200, P 200
: pj4-400mhz ( -- )  0 pj4-clksel  o# 21742301100 pj4-cc!  ;  \ A 200, D 400, XP 200, B 200, P 400
: pj4-800mhz ( -- )  1 pj4-clksel  o# 21742201100 pj4-cc!  ;  \ A 266, D 400, XP 400, B 400, P 800
[then]
