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
