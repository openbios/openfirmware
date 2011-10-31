hex
0 0  " "  " /twsi" begin-package
" accelerometer" name

\ my-address my-space encode-phys  " reg" property

\ This is for the stand-alone accelerometers LIS3DHTR and LIS33DETR

\ We could call this just once in open if we had a TWSI parent node
: acc-reg@  ( reg# -- b )  1 1 " smbus-out-in" $call-parent  ;
: acc-reg!  ( b reg# -- )  2 0 " smbus-out-in" $call-parent  ;
: ctl1!  ( b -- )  h# 20 acc-reg!  ;
: ctl4!  ( b -- )  h# 23 acc-reg!  ;
: accelerometer-on  ( -- )  h# 47 ctl1!  ;
: accelerometer-off  ( -- )  h# 07 ctl1!  ;

0 [if]

select /accelerometer

: temperature-on  ( -- )  h# c0 h# 1f acc-reg!  ;
: bdu  ( -- )  h# 23 acc-reg@  h# 80 or  h# 23 acc-reg!  ;
: adc1@  ( -- )  h# 08 acc-reg@ h# 09 acc-reg@ bwjoin wext 5 >>a  ;
: adc2@  ( -- )  h# 0a acc-reg@ h# 0b acc-reg@ bwjoin wext 5 >>a  ;

: wait-adc3  begin  h# 07 acc-reg@ h# 04 and until  ;
: adc3@  ( -- l h )
    h# 0c acc-reg@ h# 0d acc-reg@ bwjoin wext 5 >>a
;
: 1hz  ( -- )  h# 20 acc-reg@  h# 0f and  h# 10 or  h# 20 acc-reg!  ;

: .xr  ( n -- )  push-hex      2 .r  pop-base  space ;
: .dr  ( n -- )  push-decimal  3 .r  pop-base  space ;
: .br  ( n -- )
   push-binary  0  <# # # # # [char] . hold # # # # #>  type  pop-base  space ;
: .status-aux  h# 07 acc-reg@  .br  ;

: .reg  ( register -- value )
   space
   dup .xr ."  : "       ( register )
   acc-reg@              ( value )
   dup .br
   dup .xr
   dup .dr
;

: .ureg  ( register -- )
    ."              " .reg drop
;

: .regs  ( -- )
    h# 07 h# 00  do i  .ureg cr  loop

    ." STATUS_AUX   " h# 07 .reg
    dup h# 80 and if ." 321OR " then
    dup h# 40 and if ." 3OR " then
    dup h# 20 and if ." 2OR " then
    dup h# 10 and if ." 1OR " then
    dup h# 08 and if ." 321DA " then
    dup h# 04 and if ." 3DA " then
    dup h# 02 and if ." 2DA " then
    dup h# 01 and if ." 1DA " then
    drop cr

    ." OUT_1_L      " h# 08 .reg cr
    ." OUT_1_H      " h# 09 .reg
    bwjoin wext 5 >>a ." ( " .d ." )" cr

    ." OUT_2_L      " h# 0A .reg cr
    ." OUT_2_H      " h# 0B .reg
    bwjoin wext 5 >>a ." ( " .d ." )" cr

    ." OUT_3_L      " h# 0C .reg cr
    ." OUT_3_H      " h# 0D .reg
    bwjoin wext 5 >>a ." ( " .d ." )" cr

    ." INT_COUNTER  " h# 0E .reg drop cr
    ." WHO_AM_I     " h# 0F .reg b# 0011.0011 = if ." ok" else ." bad" then cr

    h# 1f h# 10  do  i .ureg cr  loop

    ." TEMP_CFG_REG " h# 1F .reg
    dup h# 80 and if ." ADC_PD " then
    dup h# 40 and if ." TEMP_EN " then
    dup h# 3f and if ." mbz " then
    drop cr

    ." CTRL_REG1    " h# 20 .reg
    dup h# f0 and 4 rshift
    dup h# 00 = if ." [power-down] " then
    dup h# 01 = if ." [1 Hz] " then
    dup h# 02 = if ." [10 Hz] " then
    dup h# 03 = if ." [25 Hz] " then
    dup h# 04 = if ." [50 Hz] " then
    dup h# 05 = if ." [100 Hz] " then
    dup h# 06 = if ." [200 Hz] " then
    dup h# 07 = if ." [400 Hz] " then
    dup h# 08 = if ." [1.6 kHz] " then
    dup h# 09 = if ." [1.25 kHz / 5 kHz] " then
    drop
    dup h# 08 and if ." LPen " then
    dup h# 04 and if ." Zen " then
    dup h# 02 and if ." Yen " then
    dup h# 01 and if ." Xen " then
    drop cr

    ." CTRL_REG2    " h# 21 .reg
    dup h# 80 and if ." HPM1 " then
    dup h# 40 and if ." HPM0 " then
    dup h# 20 and if ." HPCF2 " then
    dup h# 10 and if ." HPCF1 " then
    dup h# 08 and if ." FDS " then
    dup h# 04 and if ." HPCLICK " then
    dup h# 02 and if ." HPIS2  " then
    dup h# 01 and if ." HPIS1 " then
    drop cr

    ." CTRL_REG3    " h# 22 .reg
    dup h# 80 and if ." I1_CLICK " then
    dup h# 40 and if ." I1_AOI1 " then
    dup h# 20 and if ." I1_AOI2 " then
    dup h# 10 and if ." I1_DRDY1 " then
    dup h# 08 and if ." I1_DRDY2 " then
    dup h# 04 and if ." I1_WTM " then
    dup h# 02 and if ." I1_OVERRUN  " then
    dup h# 01 and if ." rsvd " then
    drop cr

    ." CTRL_REG4    " h# 23 .reg
    dup h# 80 and if ." BDU " then
    dup h# 40 and if ." BLE " then
    dup h# 20 and if ." FS1 " then
    dup h# 10 and if ." FS2 " then
    dup h# 08 and if ." HR " then
    dup h# 04 and if ." ST1 " then
    dup h# 02 and if ." ST0 " then
    dup h# 01 and if ." SIM " then
    drop cr

    ." CTRL_REG5    " h# 24 .reg
    dup h# 80 and if ." BOOT " then
    dup h# 40 and if ." FIFO_EN " then
    dup h# 20 and if ." rsvd " then
    dup h# 10 and if ." rsvd " then
    dup h# 08 and if ." LIR_INT1 " then
    dup h# 04 and if ." D4D_INT1 " then
    dup h# 02 and if ." mbz " then
    dup h# 01 and if ." mbz " then
    drop cr

    ." CTRL_REG6    " h# 25 .reg
    dup h# 80 and if ." I2_CLICKen " then
    dup h# 40 and if ." I2_INT1 " then
    dup h# 20 and if ." mbz " then
    dup h# 10 and if ." BOOT_I1 " then
    dup h# 08 and if ." mbz " then
    dup h# 04 and if ." rsvd " then
    dup h# 02 and if ." H_LACTIVE " then
    dup h# 01 and if ." rsvd " then
    drop cr

    ." REFERENCE    " h# 26 .reg drop cr

    ." STATUS_REG   " h# 27 .reg
    dup h# 80 and if ." ZYXOR " then
    dup h# 40 and if ." ZOR " then
    dup h# 20 and if ." YOR " then
    dup h# 10 and if ." XOR " then
    dup h# 08 and if ." ZYXDA " then
    dup h# 04 and if ." ZDA " then
    dup h# 02 and if ." YDA " then
    dup h# 01 and if ." ZDA " then
    drop cr

    ." OUT_X_L      " h# 28 .reg cr
    ." OUT_X_H      " h# 29 .reg
    bwjoin wext 5 >>a ." ( " .d ." )" cr

    ." OUT_Y_L      " h# 2a .reg cr
    ." OUT_Y_H      " h# 2b .reg
    bwjoin wext 5 >>a ." ( " .d ." )" cr

    ." OUT_Z_L      " h# 2c .reg cr
    ." OUT_Z_H      " h# 2d .reg
    bwjoin wext 5 >>a ." ( " .d ." )" cr

    ." FIFO_CTRL_REG" h# 2e .reg
    dup h# 80 and if ." FM1 " then
    dup h# 40 and if ." FM0 " then
    dup h# 20 and if ." TR " then
    dup h# 10 and if ." FTH4 " then
    dup h# 08 and if ." FTH3 " then
    dup h# 04 and if ." FTH2 " then
    dup h# 02 and if ." FTH1 " then
    dup h# 01 and if ." FTH0 " then
    drop cr

    ." FIFO_SRC_REG " h# 2f .reg
    dup h# 80 and if ." WTM " then
    dup h# 40 and if ." OVRN_FIFO " then
    dup h# 20 and if ." EMPTY " then
    dup h# 10 and if ." FSS4 " then
    dup h# 08 and if ." FSS3 " then
    dup h# 04 and if ." FSS2 " then
    dup h# 02 and if ." FSS1 " then
    dup h# 01 and if ." FSS0 " then
    drop cr

    ." INT1_CFG     " h# 30 .reg
    dup h# 80 and if ." AOI " then
    dup h# 40 and if ." 6D " then
    dup h# 20 and if ." ZHIE/ZUPE " then
    dup h# 10 and if ." ZLIE/ZDOWNE " then
    dup h# 08 and if ." YHIE/YUPE " then
    dup h# 04 and if ." YLIE/YDOWNE " then
    dup h# 02 and if ." XHIE/XUPE " then
    dup h# 01 and if ." XLIE/XDOWNE " then
    drop cr

    ." INT1_SRC     " h# 31 .reg
    dup h# 80 and if ." mbz " then
    dup h# 40 and if ." IA " then
    dup h# 20 and if ." ZH " then
    dup h# 10 and if ." ZL " then
    dup h# 08 and if ." YH " then
    dup h# 04 and if ." YL " then
    dup h# 02 and if ." XH " then
    dup h# 01 and if ." XL " then
    drop cr

    ." INT1_THS     " h# 32 .reg drop cr
    ." INT1_DURATION" h# 33 .reg drop cr

    h# 38 h# 34  do  i .ureg cr  loop

    ." CLICK_CFG    " h# 38 .reg
    dup h# 80 and if ." rsvd " then
    dup h# 40 and if ." rsvd " then
    dup h# 20 and if ." ZD " then
    dup h# 10 and if ." ZS " then
    dup h# 08 and if ." YD " then
    dup h# 04 and if ." YS " then
    dup h# 02 and if ." XD " then
    dup h# 01 and if ." XS " then
    drop cr

    ." CLICK_SRC    " h# 39 .reg
    dup h# 80 and if ." rsvd " then
    dup h# 40 and if ." IA " then
    dup h# 20 and if ." DCLICK " then
    dup h# 10 and if ." SCLICK " then
    dup h# 08 and if ." Sign " then
    dup h# 04 and if ." Z " then
    dup h# 02 and if ." Y " then
    dup h# 01 and if ." X " then
    drop cr

    ." CLICK_THS    " h# 3a .reg drop cr
    ." TIME_LIMIT   " h# 3b .reg drop cr
    ." TIME_LATENCY " h# 3c .reg drop cr
    ." TIME_WINDOW  " h# 3d .reg drop cr
    h# 3e .ureg cr
    h# 3f .ureg cr

    \ register decode window is 00-7f, then 80-ff is a mirror
;
[then]

: bext  ( b -- n )  dup h# 80 and  if  h# ffffff00 or  then  ;
: wext  ( b -- n )  dup h# 8000 and  if  h# ffff0000 or  then  ;
: acceleration@  ( -- x y z )
   h# 28 acc-reg@ h# 29 acc-reg@ bwjoin wext 5 >>a
   h# 2a acc-reg@ h# 2b acc-reg@ bwjoin wext 5 >>a
   h# 2c acc-reg@ h# 2d acc-reg@ bwjoin wext 5 >>a
;

: t+  ( x1 y1 z1 x2 y2 z2 -- x3 y3 z3 )
   >r >r >r        ( x1 y1 z1  r: z2 y2 x2 )
   rot r> +        ( y1 z1 x3  r: z2 y2 )
   rot r> +        ( z1 x3 y3  r: z2 )
   rot r> +        ( x3 y3 z3 )
;
: t-  ( x1 y1 z1 x2 y2 z2 -- x3 y3 z3 )
   >r >r >r        ( x1 y1 z1  r: z2 y2 x2 )
   rot r> -        ( y1 z1 x3  r: z2 y2 )
   rot r> -        ( z1 x3 y3  r: z2 )
   rot r> -        ( x3 y3 z3 )
;
\ Averaging a lot of samples reduces the effect of vibration
: average-acceleration@  ( -- x y z )
   acceleration@        ( x y z )
   d# 64 0  do
      acceleration@ t+  ( x' y' z' )
   loop
   rot 6 >>a
   rot 6 >>a
   rot 6 >>a
;

: delay  ( -- )  d# 30 ms  ;
d# 25,000 value bus-speed
: open  ( -- flag )
   my-unit " set-address" $call-parent
   bus-speed " set-bus-speed" $call-parent
   ['] accelerometer-on catch 0=   
;
: close  ( -- )
   accelerometer-off
;

\ The datasheet says the selftest change range is 3 to 32, but we
\ give a little headroom on the high end to allow for external
\ vibration.  Typical is supposed to be 19.
\ Empirically, measured maximums were:
\ - Mitch's unit, 32
\ - James' A3, 41 (on rubber mat on bare ground)
\ - James' A2, 39

d#  50 value min-x
d#  50 value min-y
d# 150 value min-z
d# 150 value max-x
d# 150 value max-y
d# 450 value max-z
: range?  ( delta max-delta -- error? )  between 0=  ;

: error?  ( dx dy dz -- error? )
   min-z max-z range?  if  ." Z axis error" cr  2drop true exit  then   ( dx dy )
   min-y max-y range?  if  ." Y axis error" cr   drop true exit  then   ( dx )
   min-x max-x range?  if  ." X axis error" cr        true exit  then   ( )
   false
;

: lis33de-selftest  ( -- error? )
   \ Use the device's selftest function to force a change in one direction
   delay                     ( )
   average-acceleration@     ( x y z )
   h# 4f ctl1!               ( x y z )     \ Set the STM bit
   delay
   average-acceleration@ t-  ( dx dy dz )
   \ STM applies negative bias to Y, but our deltas are inverted
   \ because we subtract the new measurement from the old.
   rot negate -rot           ( dx' dy dz )
   negate                    ( dx dy dz' )
   error?  if  accelerometer-off  true exit  then

   \ Use the device's selftest function to force a change in the opposite direction
   accelerometer-on  delay   ( )   \ Back to normal - STM and STP both off
   average-acceleration@     ( x y z )
   h# 57 ctl1!               ( x y z )     \ Set the STP bit
   delay
   average-acceleration@ t-  ( dx dy dz )
   \ STP applies negative bias to X and Z, but our deltas are inverted
   \ because we subtract the new measurement from the old.
   swap negate swap          ( dx dy' dz )
   error?  if  accelerometer-off  true exit  then
   false
;
: lis3dhtr-selftest  ( -- )
   \ Use the device's selftest function to force a change in one direction
   delay                     ( )
   average-acceleration@     ( x y z )
   h# 0a ctl4!               ( x y z )     \ High res, Selftest mode 0
   delay
   average-acceleration@ t-  ( dx dy dz )
   rot negate  rot negate  rot negate
   h# 08 ctl4!               ( x y z )     \ High res, Normal mode
   error?  if  accelerometer-off  true exit  then

   \ Use the device's selftest function to force a change in the opposite direction
   accelerometer-on  delay   ( )   \ Back to normal - STM and STP both off
   average-acceleration@     ( x y z )
   h# 0c ctl4!               ( x y z )     \ High res, Selftest mode 1
   delay
   average-acceleration@ t-  ( dx dy dz )
   h# 08 ctl4!               ( x y z )     \ High res, Normal mode
   error?  if  accelerometer-off  true exit  then
   
   accelerometer-off
   false
;
defer lis-selftest
: selftest  ( -- error? )
   open 0=  if  true exit  then

   final-test?  if  accelerometer-off false  exit  then

   lis-selftest
;

: probe  ( -- )
   h# 3a 6 " set-address" $call-parent
   d# 25,000 " set-bus-speed" $call-parent \ XO-1.75 B1 lacks pullups SCL SDA
   ['] accelerometer-on catch  if
      \ The attempt to talk at the old address failed, so we assume the new chip
      \ Support for new LIS3DHTR chip
      d# 100,000 to bus-speed
      d#  50 to min-x  d#  50 to min-y  d#  50 to min-z 
      d# 150 to max-x  d# 150 to max-y  d# 450 to max-z 
      h# 32 6 encode-phys " reg" property
      ['] lis3dhtr-selftest to lis-selftest
   else
      accelerometer-off
      \ Something responded to the old address, so we assume it's the old chip
      \ Support for old LIS33DE chip
      d# 25,000 to bus-speed
      d#  20 to min-x  d#  20 to min-y  d#  20 to min-z 
      d# 400 to max-x  d# 400 to max-y  d# 400 to max-z 
      h# 3a 6 encode-phys " reg" property
      ['] lis33de-selftest to lis-selftest
   then
;   

end-package

stand-init: Accelerometer
   " /accelerometer" " probe" execute-device-method drop
;
