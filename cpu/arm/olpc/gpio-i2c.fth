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

      0 0 reg  \ So linux will assign a static device name

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

      0 0 reg  \ So linux will assign a static device name

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

[ifdef] hdmi-sda-gpio#
   new-device
      " hdmi-i2c" device-name
      " i2c-gpio" +compatible
      1 " #address-cells" integer-property
      1 " #size-cells" integer-property
      : encode-unit  ( phys.. -- str )  push-hex (u.) pop-base  ;
      : decode-unit  ( str -- phys.. )  push-hex  $number  if  0  then  pop-base  ;
      
      0 0 encode-bytes
         hdmi-sda-gpio# 0 encode-gpio
         hdmi-scl-gpio# 0 encode-gpio
      " gpios" property

      h# 50 instance value slave-address
      : set-address  ( slave -- )  to slave-address  ;
      : smb-setup
         1 to smb-dly-us hdmi-scl-gpio# to smb-clock-gpio#
         hdmi-sda-gpio# to smb-data-gpio#
         slave-address to smb-slave
      ;
      \ Since this I2C bus is dedicated to HDMI, we save space by
      \ implementing only the methods that HDMI DDC uses
      : reg-b@  ( reg# -- b )  smb-setup smb-byte@  ;
      : reg-b!  ( b reg# -- )  smb-setup smb-byte!  ;
      : i2c-read  ( adr len reg# -- )  smb-setup smb-read  ;
      : open  ( -- flag )  true  ;
      : close  ( -- )  ;

      new-device
         " hdmi-ddc" device-name    
         h# 50 1 reg
         : close  ( -- )  ;
         h# 80 constant /edid-chunk
         0 value edid
         0 value /edid

         : release-edid  ( -- )  
            edid /edid free-mem    ( )
            0 to /edid  0 to edid  ( )
         ;

         : open  ( -- okay? )
            my-unit " set-address" $call-parent
            /edid-chunk to /edid
            /edid alloc-mem to edid

            edid /edid 0  " i2c-read" ['] $call-parent catch  if  ( x x x x x )
               2drop 3drop                          ( )
               release-edid  false  exit            ( -- false )
            then

            \ Basic sanity check to make sure it's an EDID
            edid  " "(00ffffffffffff00)" comp  if   ( )
               release-edid  false  exit            ( -- false )
            then

            \ We could (should) do a checksum here...

            \ If there are no extensions, exit now, successfully
            edid d# 126 + c@  dup 0= over h# ff = or  if  ( #exts )
               drop true exit                       ( -- true )
            then                                    ( #exts )

            \ Otherwise make the buffer larger to accomodate the extensions ...
            1+ /edid-chunk * to /edid               ( )
            edid /edid  resize-memory  if           ( adr' )
               drop                                 ( )
               0 to /edid  0 to edid                ( )
               false exit                           ( )
            then                                    ( adr )
            to edid                                 ( )

            \ ... and read the extensions
            edid /edid /edid-chunk /string  /edid-chunk   ( adr len offset )
            " i2c-read" ['] $call-parent catch  if  ( x x x x x )
               2drop 3drop                          ( )
               release-edid  false  exit            ( -- false )
            then

            true
         ;
         : edid$  ( -- adr len )  edid /edid  ;
      finish-device
   finish-device
[then]
device-end

devalias i2c6 /hdmi-i2c
