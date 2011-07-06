
hex
0 0  " 6,3a"  " /twsi" begin-package
" accelerometer" name

my-address my-space encode-phys  " reg" property

\ This is for the stand-alone accelerometer chip LIS33DETR

\ We could call this just once in open if we had a TWSI parent node
: set-address  ( -- )  h# 3a 6 set-twsi-target  ;
: acc-reg@  ( reg# -- b )  1 1 " smbus-out-in" $call-parent  ;
: acc-reg!  ( b reg# -- )  2 0 " smbus-out-in" $call-parent  ;
: ctl1!  ( b -- )  h# 20 acc-reg!  ;
: accelerometer-on  ( -- )  h# 47 ctl1!  ;
: accelerometer-off  ( -- )  h# 07 ctl1!  ;

: bext  ( b -- n )  dup h# 80 and  if  h# ffffff00 or  then  ;
: acceleration@  ( -- x y z )
   h# 29 acc-reg@ bext
   h# 2b acc-reg@ bext
   h# 2d acc-reg@ bext
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
   d# 127 0  do
      acceleration@ t+  ( x' y' z' )
   loop
   rot 7 >>a
   rot 7 >>a
   rot 7 >>a
;

: delay  ( -- )  d# 30 ms  ;
: open  ( -- flag )
   my-address my-space " set-address" $call-parent
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
d# 50 value max-delta
: out-of-range?  ( delta -- error? )  3  max-delta between 0=  ;

: error?  ( dx dy dz -- error? )
   out-of-range?  if  ." X axis error" cr  2drop true exit  then   ( dx dy )
   out-of-range?  if  ." Y axis error" cr   drop true exit  then   ( dx )
   out-of-range?  if  ." X axis error" cr        true exit  then   ( )
   false
;

: selftest  ( -- error? )
   open 0=  if  true exit  then

   final-test?  if  accelerometer-off false  exit  then

   \ Use the device's selftest function to force a change in one direction
   delay                     ( )
   average-acceleration@     ( x y z )
   h# 4f ctl1!  delay        ( x y z )     \ Set the STM bit
   average-acceleration@ t-  ( dx dy dz )
   \ STM applies negative bias to Y, but our deltas are inverted
   \ because we subtract the new measurement from the old.
   rot negate -rot           ( dx' dy dz )
   negate                    ( dx dy dz' )
   error?  if  accelerometer-off  true exit  then

   \ Use the device's selftest function to force a change in the opposite direction
   accelerometer-on  delay   ( )   \ Back to normal - STM and STP both off
   average-acceleration@     ( x y z )
   h# 57 ctl1!  delay        ( x y z )     \ Set the STP bit
   average-acceleration@ t-  ( dx dy dz )
   \ STP applies negative bias to X and Z, but our deltas are inverted
   \ because we subtract the new measurement from the old.
   swap negate swap          ( dx dy' dz )
   error?  if  accelerometer-off  true exit  then
   
   accelerometer-off
   false
;

end-package
