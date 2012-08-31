purpose: Change the clock frequency

0 [if]
: set-pll2-520mhz  ( -- )
   \ select PLL2 frequency, 520MHz
   h# 08600322 h# 414 mpmu!  \ PMUM_PLL2_CTRL1 \ Bandgap+charge pump+VCO loading+regulator defaults, 486.3-528.55 PLL2 (bits 10:6)
   h# 00FFFE00 h#  34 mpmu!  \ PMUM_PLL2_CTRL2 \ refclk divisor and feedback divisors at max, software controls activation
   h# 0021da00 h#  34 mpmu!  \ PMUM_PLL2_CTRL2 \ refclk divisor=4, feedback divisor=0x76=118, software controls activation
   h# 0021db00 h#  34 mpmu!  \ PMUM_PLL2_CTRL2 \ same plus enable
   h# 28600322 h# 414 mpmu!  \ PMUM_PLL2_CTRL1 \ same as above plus release PLL loop filter
;
[then]
: set-pll2-910mhz  ( -- )
   \ select PLL2 frequency, 910MHz
   h# 086005a2 h# 414 mpmu!  \ PMUM_PLL2_CTRL1 \ Bandgap+charge pump+VCO loading+regulator defaults, 486.3-528.55 PLL2 (bits 10:6)
   h# 00FFFE00 h#  34 mpmu!  \ PMUM_PLL2_CTRL2 \ refclk divisor and feedback divisors at max, software controls activation
   h# 00234200 h#  34 mpmu!  \ PMUM_PLL2_CTRL2 \ refclk divisor=4, feedback divisor=0xd0=208, software controls activation
   h# 00234300 h#  34 mpmu!  \ PMUM_PLL2_CTRL2 \ same plus enable
   h# 286005a2 h# 414 mpmu!  \ PMUM_PLL2_CTRL1 \ same as above plus release PLL loop filter
;
: set-pll2-988mhz  ( -- )
   \ select PLL2 frequency, 988MHz
   h# 08600622 h# 414 mpmu!  \ PMUM_PLL2_CTRL1 \ Bandgap+charge pump+VCO loading+regulator defaults, 971.35-1011.65 PLL2 (bits 10:6)
   h# 00FFFE00 h#  34 mpmu!  \ PMUM_PLL2_CTRL2 \ refclk divisor and feedback divisors at max, software controls activation
   h# 00238a00 h#  34 mpmu!  \ PMUM_PLL2_CTRL2 \ refclk divisor=4, feedback divisor=0xe2=226, software controls activation
   h# 00238b00 h#  34 mpmu!  \ PMUM_PLL2_CTRL2 \ same plus enable
   h# 28600622 h# 414 mpmu!  \ PMUM_PLL2_CTRL1 \ same as above plus release PLL loop filter
;
: pll2-off  ( -- )
   h# 2000.0000 h#  414 +mpmu io-clr  \ PLL2_RESETB in PMUM_PLL2_CTRL1
   h#       100 h#   34 +mpmu io-clr  \ PLL2_SW_EN in PMUM_PLL2CR
;
: gate-pll2  ( -- )
   h#      4000 h# 1024 +mpmu io-clr  \ APMU_PLL2 in PMUM_CGR_PJ
   h#      4000 h#   24 +mpmu io-clr  \ APMU_PLL2 in PMUM_CGR_SP
;
: ungate-pll2  ( -- )
   h#      4000 h# 1024 +mpmu io-set  \ APMU_PLL2 in PMUM_CGR_PJ
   h#      4000 h#   24 +mpmu io-set  \ APMU_PLL2 in PMUM_CGR_SP
;
: pll2-ungated?  ( -- flag )
   h#      4000 h# 1024 +mpmu io@  and
;
: pll2-fbdiv  ( -- N )  h# 34 mpmu@ d# 10 rshift h# 1ff and  2+  ;
: pll2-refdiv  ( -- M )  h# 34 mpmu@ d# 19 rshift h# 1f and  2+  ;

: fccr@    ( -- n )  h# 05.0008 io@  ;
: fccr!    ( n -- )  h# 05.0008 io!  ;
: pj4-clksel  ( n -- )
   d# 29 lshift                               ( field )
   fccr@  h# e000.0000 invert and  or  fccr!  ( )
;
: pj4-clksel@  ( -- n )
   fccr@  h# e000.0000 and  d# 29 rshift
;

: sp-clksel  ( n -- )
   d# 26 lshift                               ( field )
   fccr@  h# 1c00.0000 invert and  or  fccr!  ( )
;

: pj4-cc!  ( n -- )  h# 28.2804 io!  ;
: pj4-cc@  ( -- n )  h# 28.2804 io@  ;
: pj4-clkdiv  ( -- n )  pj4-cc@  h# 7  and  ;

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
: pj4-910mhz ( -- )  set-pll2-910mhz ungate-pll2  2 pj4-clksel  o# 37042201100 pj4-cc!  ;  \ A 266, D 400, XP 400, B 400, P 910
: pj4-988mhz ( -- )  set-pll2-988mhz ungate-pll2  2 pj4-clksel  o# 37042201100 pj4-cc!  ;  \ A 266, D 400, XP 400, B 400, P 910
: .speed  ( -- )  t( d# 10,000,000 0 do loop )t   ;

0 [if]
\ PJ4 versions using voting           cvr52ADXBCP
: pj4-100mhz ( -- )  0 pj4-clksel  o# 21742703303 pj4-cc!  ;  \ A 100, D 400, XP 100, B 100, P 100
: pj4-200mhz ( -- )  0 pj4-clksel  o# 21742301101 pj4-cc!  ;  \ A 200, D 400, XP 200, B 200, P 200
: pj4-400mhz ( -- )  0 pj4-clksel  o# 21742301100 pj4-cc!  ;  \ A 200, D 400, XP 200, B 200, P 400
: pj4-800mhz ( -- )  1 pj4-clksel  o# 21742201100 pj4-cc!  ;  \ A 266, D 400, XP 400, B 400, P 800
: pj4-910mhz ( -- )  set-pll2-910mhz 2 pj4-clksel  o# 21742201100 pj4-cc!  ;  \ A 266, D 400, XP 400, B 400, P 910
: pj4-988mhz ( -- )  set-pll2-988mhz 2 pj4-clksel  o# 21742201100 pj4-cc!  ;  \ A 266, D 400, XP 400, B 400, P 988
[then]

: pj4-speed  ( -- frequency )
   pj4-clksel@
   case
      0  of  d# 400,000,000 pj4-clkdiv 1+ /            endof  ( hz )
      1  of  d# 800,000,000                            endof  ( hz )
      2  of  d#  26,000,000 pll2-fbdiv pll2-refdiv */  endof  ( hz )
      3  of  d# 1,063,000,000                          endof  ( hz )
   endcase
   d# 1,000,000 /                                             ( mhz )
;
\ FIXME: should be a property clock-frequency of /cpu@0
