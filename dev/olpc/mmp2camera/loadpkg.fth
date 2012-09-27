" "  " d420a000" " /"  begin-package
   " camera" device-name
   " marvell,mmpcam" +compatible
   my-address my-space  h# 800  reg
   " /pmua" encode-phandle 2 encode-int encode+ " clocks" property
[ifdef] mmp3
   \ The CCIC interrupt is shared between CCIC1 and CCIC2 on MMP3
   " /interrupt-controller/interrupt-controller@1cc" encode-phandle " interrupt-parent" property
   1 " interrupts" integer-property
[else]
   d# 42 " interrupts" integer-property
[then]

   0 0 encode-bytes
      cam-pwr-gpio# 0 encode-gpio
      cam-rst-gpio# 0 encode-gpio
   " gpios" property

   " /image-sensor" encode-phandle  " image-sensor" property

0 [if]
   : alloc-capture-buffer  ( len -- vadr padr )
      \ XXX need map-in if we should use virtual mode
      dup " dma-alloc" $call-parent        ( len vadr )
      tuck swap                            ( vadr vadr len )
      false  " dma-map-in" $call-parent    ( vadr padr )
   ;
   : free-capture-buffer  ( vadr padr len -- )
      3dup " dma-map-out" $call-parent  ( vadr padr len )
      nip  " dma-free" $call-parent
   ;
[else]
   : alloc-capture-buffer  ( len -- vadr padr )
      drop load-base dup
   ;
   : free-capture-buffer  ( vadr padr len -- )
      3drop
   ;
[then]

   fload ${BP}/dev/olpc/mmp2camera/platform.fth
   fload ${BP}/dev/olpc/imagesensor.fth

   : set-sensor-properties  ( name$ i2c-addr -- )
      my-self >r  0 to my-self
      " /image-sensor" find-device  ( name$ i2c-addr )
      " reg" get-property  if       ( name$ i2c-addr )
         1 reg                      ( name$ )
         +compatible                ( )
      else                          ( name$ i2c-addr regval$ )
         2drop 3drop                ( )
      then
      device-end
      r> to my-self
   ;

   warning @ warning off
   fload ${BP}/dev/olpc/ov7670.fth
   fload ${BP}/dev/olpc/seti.fth		\ Load last; most likely to be present
   warning !
   fload ${BP}/dev/olpc/mmp2camera/ccic.fth
   fload ${BP}/dev/olpc/cameratest.fth
end-package
: probe-image-sensor  ( -- )
   " /camera" open-dev close-dev
;
