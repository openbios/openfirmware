purpose: Interface layer to image sensor chips

\ Each sensor chip driver must define sensor-found? , chaining to the
\ previous definition if that sensor chip is not detected.  If the
\ chip is detected, the driver must set camera-config and set-mirrored
\ to implementations suitable for that chip.

defer camera-config  ( ycrcb? -- )
defer set-mirrored   ( mirrored? -- )

\ Redefine to add a new sensor
: sensor-found?  ( -- flag )
   false
;
: set-sensor-properties  ( name$ i2c-addr -- )
   my-self >r  0 to my-self
   " /image-sensor" find-device  ( name$ i2c-addr )
      " reg" get-property  if    ( name$ i2c-addr )
         1 reg                   ( name$ )
         +compatible             ( )
      else                       ( name$ i2c-addr regval$ )
         2drop 3drop             ( )
      then
   device-end
   r> to my-self
;

also forth definitions
: probe-image-sensor  ( -- )
   " /camera" open-dev close-dev
;
previous definitions
