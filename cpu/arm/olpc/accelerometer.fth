dev /i2c@d4034000  \ TWSI6
new-device

" accelerometer" name
" lis3lv02d" +compatible

true value hi-res?

\ reg is set dynamically by probing to find which chip is present

\ This is for the stand-alone accelerometers LIS3DHTR and LIS33DETR

\ We could call this just once in open if we had a TWSI parent node
: acc-reg@  ( reg# -- b )  " reg-b@" $call-parent  ;
: acc-reg!  ( b reg# -- )  " reg-b!" $call-parent  ;
: ctl1!  ( b -- )  h# 20 acc-reg!  ;
: ctl4!  ( b -- )  h# 23 acc-reg!  ;
: ctl4@  ( -- b )  h# 23 acc-reg@  ;
: accelerometer-on  ( -- )
   h# 47 ctl1!
   hi-res?  if  8 ctl4!  then  \ High resolution mode
;
: accelerometer-off  ( -- )  h# 07 ctl1!  ;  \ should this be 00?
: wext  ( b -- n )  dup h# 8000 and  if  h# ffff0000 or  then  ;

\ The scale factor for an acceleration component is 1 gravity = 1000 units.
: acceleration@  ( -- x y z )
   begin  h# 27 acc-reg@  h# 08 and  until  \ wait for data available
   h# 0a8 1 6 " bytes-out-in" $call-parent ( xl xh yl yh zl zh )
   bwjoin wext 4 >>a     ( xl xh yl yh z )
   >r                    ( xl xh yl yh     r: z )
   bwjoin wext 4 >>a     ( xl xh y         r: z )
   >r                    ( xl xh           r: z y )
   bwjoin wext 4 >>a     ( x               r: z y )
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
\ The vendor recommends averaging 5 samples for selftest.
: average-acceleration@  ( -- x y z )
   acceleration@        ( x y z )
   d# 4 0  do
      acceleration@ t+  ( x' y' z' )
   loop                 ( xsum ysum zsum )
   rot 5 /              ( ysum zsum x )
   rot 5 /              ( zsum x y )
   rot 5 /              ( x y z )
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

\ The vendor recommends the following min/max values for LIS3DHTR selftest:
\ X:80..1700  Y:80..1700  Z:80..1400.
\ The numbers are in units of "1LSB = 1mg", 1000 unit = 1 gravity.

d#   80 value min-x
d#   80 value min-y
d#   80 value min-z
d# 1700 value max-x
d# 1700 value max-y
d# 1400 value max-z
: range?  ( delta max-delta -- error? )  between 0=  ;

: error?  ( dx dy dz -- error? )
   min-z max-z range?  if  ." Z axis error" cr  2drop true exit  then   ( dx dy )
   min-y max-y range?  if  ." Y axis error" cr   drop true exit  then   ( dx )
   min-x max-x range?  if  ." X axis error" cr        true exit  then   ( )
   false
;

\ Lower and upper test limits for the magnitude squared of the acceleration
\ vector when the device is stationary.  The scaling is 1000 units = 1 gravity.

d#  900 dup * constant gsq-min   \ 0.9 gravity squared
d# 1100 dup * constant gsq-max   \ 1.1 gravity squared

: xyz>mag-sq  ( z y z -- magnitude-squared )
   dup *  swap dup * +  swap dup * +
;
: not1g?  ( x y z  -- error? )
   xyz>mag-sq   ( magnitude**2 )
   gsq-min gsq-max between 0=
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
   error?  if  true exit  then

   \ Use the device's selftest function to force a change in the opposite direction
   accelerometer-on  delay   ( )   \ Back to normal - STM and STP both off
   average-acceleration@     ( x y z )
   h# 57 ctl1!               ( x y z )     \ Set the STP bit
   delay
   average-acceleration@ t-  ( dx dy dz )
   \ STP applies negative bias to X and Z, but our deltas are inverted
   \ because we subtract the new measurement from the old.
   swap negate swap          ( dx dy' dz )
   error?
;
: lis3dhtr-selftest  ( -- error? )
   delay                     ( )
   average-acceleration@     ( x y z )

   \ Check that the magnitude of the acceleration vector is about 1 G
   3dup not1g?  if           ( x y z )
      3drop                  ( )
      ." Acceleration is not 1 gravity" cr   ( )
      true exit              ( -- error? )
   then                      ( x y z )

   \ Use the device's selftest function to force a change in one direction
   h# 0a ctl4!               ( x y z )     \ High res, Selftest mode 0
   delay
   average-acceleration@ t-  ( dx dy dz )
   rot negate  rot negate  rot negate
   h# 08 ctl4!               ( x y z )     \ High res, Normal mode
   error?  if  true exit  then

   \ Use the device's selftest function to force a change in the opposite direction
   accelerometer-on  delay   ( )   \ Back to normal - STM and STP both off
   average-acceleration@     ( x y z )
   h# 0c ctl4!               ( x y z )     \ High res, Selftest mode 1
   delay
   average-acceleration@ t-  ( dx dy dz )
   h# 08 ctl4!               ( x y z )     \ High res, Normal mode
   error?
;
defer lis-selftest
: selftest  ( -- error? )
   open 0=  if  true exit  then

   final-test?  if
      false
   else
      ." Don't move!" cr
      lis-selftest
   then

   close
;

: probe  ( -- )
   h# 1d " set-address" $call-parent
   d# 25,000 " set-bus-speed" $call-parent \ XO-1.75 B1 lacks pullups SCL SDA
   ['] accelerometer-on catch  if
      \ The attempt to talk at the old address failed, so we assume the new chip
      \ Support for new LIS3DHTR chip
      d# 400,000 to bus-speed
      d#   80 to min-x  d#   80 to min-y  d#   80 to min-z
      d# 1700 to max-x  d# 1700 to max-y  d# 1400 to max-z
      h# 19 1 reg
      ['] lis3dhtr-selftest to lis-selftest
      true to hi-res?
   else
      accelerometer-off
      \ Something responded to the old address, so we assume it's the old chip
      \ Support for old LIS33DE chip
      d#  25,000 to bus-speed
      d#  40 to min-x  d#  40 to min-y  d#  40 to min-z
      d# 800 to max-x  d# 800 to max-y  d# 800 to max-z
      h# 1d 1 reg
      ['] lis33de-selftest to lis-selftest
      false to hi-res?
   then
;

finish-device
device-end

stand-init: Accelerometer
   " /accelerometer" " probe" execute-device-method drop
;
