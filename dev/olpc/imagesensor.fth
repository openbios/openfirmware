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
   " /image-sensor" find-package  if       ( name$ i2c-addr phandle )
      " reg" rot get-package-property  if  ( name$ i2c-addr )
         1 reg                             ( name$ )
         encode-string  " compatible" property
      else                                 ( name$ i2c-addr regval$ )
         2drop 3drop                       ( )
      then                                 ( )
   else                                    ( name$ i2c-addr )
      3drop                                ( )
   then                                    ( )
;
