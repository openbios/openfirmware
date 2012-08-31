purpose: Device tree nodes for I2C buses implemented with GPIOs

: encode-gpio  ( propval$ gpio# low? -- propval$' )
   >r >r                            ( propval$  r: low? gpio# )
   " /gpio" encode-phandle encode+  ( propval$' r: low? gpio# )
   r> encode-int encode+            ( propval$' r: low? )
   r> encode-int encode+            ( propval$' )
;

: gpio-property  ( gpionum low? gpioname$ -- )
   2>r  2>r                     ( r: gpioname$ gpionum low? )
   0 0 encode-bytes             ( propval$  r: gpioname$ gpionum low? )
   2r> encode-gpio              ( propval$' r: gpioname$ )
   2r> property                 ( )
;

: make-sensor-node  ( name$ i2c-addr -- )
   " /camera-i2c" find-device  ( name$ i2c-addr )
   new-device                  ( name$ i2c-addr )
      1 reg                    ( name$ )
      +compatible              ( )
      " image-sensor" device-name
      0 0 encode-bytes
         cam-pwr-gpio# 0 encode-gpio
         cam-rst-gpio# 0 encode-gpio
      " gpios" property
   finish-device
   device-end
;

dev /
   new-device
      " camera-i2c" device-name
      " i2c-gpio" +compatible
      1 " #address-cells" integer-property
      1 " #size-cells" integer-property
      : encode-unit  ( phys.. -- str )  push-hex (u.) pop-base  ;
      : decode-unit  ( str -- phys.. )  push-hex  $number  if  0  then  pop-base  ;
      
      0 0 encode-bytes
         cam-sda-gpio# 0 encode-gpio
          cam-scl-gpio# 0 encode-gpio
      " gpios" property

      0 instance value slave-address
      : set-address  ( slave -- )  to slave-address  ;
      : smb-setup
         1 to smb-dly-us cam-scl-gpio# to smb-clock-gpio#
         cam-sda-gpio# to smb-data-gpio#
         slave-address to smb-slave
      ;
      \ Since this I2C bus is dedicated to the camera sensor, we save space by
      \ implementing only the methods that the sensor uses
      : reg-b@  ( reg# -- b )  smb-setup smb-byte@  ;
      : reg-b!  ( b reg# -- )  smb-setup smb-byte!  ;
      : open  ( -- flag )  true  ;
      : close  ( -- )  ;

      new-device
         " image-sensor" device-name    

        \ The reg and compatible properties are set by probing, based on the actual
        \ image sensor encountered.  For example:
        \  h# 21 1 reg
        \  " omnivision,ov7670" +compatible

         0 0 encode-bytes
            cam-pwr-gpio# 0 encode-gpio
            cam-rst-gpio# 0 encode-gpio
         " gpios" property
      finish-device
   finish-device

   new-device
      " dcon-i2c" device-name
      " i2c-gpio" +compatible
      1 " #address-cells" integer-property
      1 " #size-cells" integer-property
      : encode-unit  ( phys.. -- str )  push-hex (u.) pop-base  ;
      : decode-unit  ( str -- phys.. )  push-hex  $number  if  0  then  pop-base  ;

      0 0 encode-bytes
         dcon-sda-gpio# 0 encode-gpio
         dcon-scl-gpio# 0 encode-gpio
      " gpios" property

      0 instance value slave-address
      : set-address  ( slave -- )  to slave-address  ;
      : smb-setup  ( -- )
         dcon-scl-gpio# to smb-clock-gpio#
         dcon-sda-gpio# to smb-data-gpio#
         slave-address to smb-slave
      ;

      \ Since this I2C bus is dedicated to the DCON, we save space by
      \ implementing only the methods that the DCON uses

      : reg-w@  ( reg# -- w )  smb-setup smb-word@  ;
      : reg-w!  ( w reg# -- )  smb-setup smb-word!  ;

      : bus-reset  ( -- )  smb-setup smb-stop 1 ms  smb-off  1 ms  smb-on  ;
      : bus-init  ( -- )  smb-setup  smb-on  smb-pulses  ;

      : open  ( -- flag )  true  ;
      : close  ( -- )  ;
   finish-device
device-end
