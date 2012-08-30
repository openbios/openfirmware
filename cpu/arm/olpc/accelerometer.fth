dev /i2c@d4034000  \ TWSI6
new-device

" accelerometer" name
" lis3lv02d" +compatible

\ reg is set dynamically by probing to find which chip is present

\ This is for the stand-alone accelerometers LIS3DHTR and LIS33DETR

\ We could call this just once in open if we had a TWSI parent node
: acc-reg@  ( reg# -- b )  " byte@" $call-parent  ;
: acc-reg!  ( b reg# -- )  " byte!" $call-parent  ;
: ctl1!  ( b -- )  h# 20 acc-reg!  ;
: ctl4!  ( b -- )  h# 23 acc-reg!  ;
: accelerometer-on  ( -- )  h# 47 ctl1!  ;
: accelerometer-off  ( -- )  h# 07 ctl1!  ;  \ should this be 00?
: wext  ( b -- n )  dup h# 8000 and  if  h# ffff0000 or  then  ;
: acceleration@  ( -- x y z )
   begin  h# 27 acc-reg@  h# 08 and  until  \ wait for data available
   h# 0a8 1 6 " bytes-out-in" $call-parent ( xl xh yl yh zl zh )
   bwjoin wext 5 >>a     ( xl xh yl yh z )
   >r                    ( xl xh yl yh     r: z )
   bwjoin wext 5 >>a     ( xl xh y         r: z )
   >r                    ( xl xh           r: z y )
   bwjoin wext 5 >>a     ( x               r: z y )
   r> r> ( x y z )
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

   ." Don't move!" cr
   lis-selftest
;

: probe  ( -- )
   h# 1d " set-address" $call-parent
   d# 25,000 " set-bus-speed" $call-parent \ XO-1.75 B1 lacks pullups SCL SDA
   ['] accelerometer-on catch  if
      \ The attempt to talk at the old address failed, so we assume the new chip
      \ Support for new LIS3DHTR chip
      d# 400,000 to bus-speed
      d#  50 to min-x  d#  50 to min-y  d#  50 to min-z
      d# 150 to max-x  d# 150 to max-y  d# 450 to max-z
      h# 19 1 reg
      ['] lis3dhtr-selftest to lis-selftest
   else
      accelerometer-off
      \ Something responded to the old address, so we assume it's the old chip
      \ Support for old LIS33DE chip
      d#  25,000 to bus-speed
      d#  20 to min-x  d#  20 to min-y  d#  20 to min-z
      d# 400 to max-x  d# 400 to max-y  d# 400 to max-z
      h# 1d 1 reg
      ['] lis33de-selftest to lis-selftest
   then
;

finish-device
device-end

stand-init: Accelerometer
   " /accelerometer" " probe" execute-device-method drop
;
