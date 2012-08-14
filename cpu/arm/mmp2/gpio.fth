create gpio-offsets
\  0     1     2        3         4         5
   0 ,   4 ,   8 , h# 100 ,  h# 104 ,  h# 108 ,

: >gpio-pin ( gpio# -- mask pa )
   dup h# 1f and    ( gpio# bit# )
   1 swap lshift    ( gpio# mask )
   swap 5 rshift  gpio-offsets swap na+ @  gpio-base +  ( mask pa )
;
: gpio-pin@     ( gpio# -- flag )  >gpio-pin io@ and  0<>  ;

: >gpio-dir     ( gpio# -- mask pa )  >gpio-pin h# 0c +  ;
: gpio-out?     ( gpio# -- out? )  >gpio-dir io@ and  0<>  ;

: gpio-set      ( gpio# -- )  >gpio-pin h# 18 +  io!  ;
: gpio-clr      ( gpio# -- )  >gpio-pin h# 24 +  io!  ;

: >gpio-rer     ( gpio# -- mask pa )  >gpio-pin h# 30 +  ;
: gpio-rise@    ( gpio# -- flag )  >gpio-rer io@ and  0<>  ;

: >gpio-fer     ( gpio# -- mask pa )  >gpio-pin h# 3c +  ;
: gpio-fall@    ( gpio# -- flag )  >gpio-fer io@ and  0<>  ;

: >gpio-edr     ( gpio# -- mask pa )  >gpio-pin h# 48 +  ;
: gpio-edge@    ( gpio# -- flag )  >gpio-edr io@ and  0<>  ;
: gpio-clr-edge ( gpio# -- )  >gpio-edr io!  ;

: gpio-dir-out  ( gpio# -- )  >gpio-pin h# 54 + io!  ;
: gpio-dir-in   ( gpio# -- )  >gpio-pin h# 60 + io!  ;
: gpio-set-rer  ( gpio# -- )  >gpio-pin h# 6c + io!  ;
: gpio-clr-rer  ( gpio# -- )  >gpio-pin h# 78 + io!  ;
: gpio-set-fer  ( gpio# -- )  >gpio-pin h# 84 + io!  ;
: gpio-clr-fer  ( gpio# -- )  >gpio-pin h# 90 + io!  ;

: >gpio-mask    ( gpio# -- mask pa )  >gpio-pin h# 9c +  ;
: gpio-set-mask ( gpio# -- )  >gpio-mask tuck io@  or  swap io!  ;
: gpio-clr-mask ( gpio# -- )  >gpio-mask tuck io@  swap invert and  swap io!  ;

: >gpio-xmsk     ( gpio# -- mask pa )  >gpio-pin h# a8 +  ;
: gpio-set-xmsk ( gpio# -- )  >gpio-xmsk tuck io@  or  swap io!  ;
: gpio-clr-xmsk ( gpio# -- )  >gpio-xmsk tuck io@  swap invert and  swap io!  ;

\ See <Linux> Documentation/devicetree/bindings/gpio/mrvl-gpio.txt
0 0  " d4019000" " /" begin-package
   " gpio" name

   " mrvl,mmp-gpio" encode-string +compatible

   my-address my-space  h# 1000 reg

   d# 49  encode-int  " interrupts" property
   " gpio_mux"  " interrupt-names" string-property
   " " " gpio-controller" property
   2 " #gpio-cells" integer-property
   " " " interrupt-controller" property
   1 " #interrupt-cells" integer-property

   " /apbc" encode-phandle d# 13 encode-int encode+ " clocks" property
   " GPIO" " clock-names" string-property


   1 " #address-cells" integer-property
   1 " #size-cells" integer-property
   : encode-unit  ( phys.. -- str )  push-hex (u.) pop-base  ;
   : decode-unit  ( str -- phys.. )  push-hex  $number  if  0  then  pop-base  ;

   : make-gpio-mux-node  ( offset -- )
      new-device
      " gpio" name
      4 reg
      finish-device
   ;
   h#  00 make-gpio-mux-node
   h#  04 make-gpio-mux-node
   h#  08 make-gpio-mux-node
   h# 100 make-gpio-mux-node
   h# 104 make-gpio-mux-node
   h# 108 make-gpio-mux-node
end-package

: gpio-property  ( gpionum low? gpioname$ -- )
   2>r swap                     ( low? gpionum           r: gpioname$ )
   " /gpio"  encode-phandle     ( low? gpionum propval$  r: gpioname$ )
   rot encode-int encode+       ( low? propval$'         r: gpioname$ )
   rot encode-int encode+       ( propval$'              r: gpioname$ )
   2r> property                 ( )
;
