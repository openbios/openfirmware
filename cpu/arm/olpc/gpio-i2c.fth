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
      : open  ( -- flag )  true  ;
      : close  ( -- )  ;
      
      0 0 encode-bytes
         cam-sda-gpio# 0 encode-gpio
          cam-scl-gpio# 0 encode-gpio
      " gpios" property

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
      : open  ( -- flag )  true  ;
      : close  ( -- )  ;

      0 0 encode-bytes
         dcon-sda-gpio# 0 encode-gpio
         dcon-scl-gpio# 0 encode-gpio
      " gpios" property
   finish-device
device-end
