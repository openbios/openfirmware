0 0  " "  " /" begin-package
" accelerometer" name

\ This is for the stand-alone accelerometer chip LIS33DETR

\ We could call this just once in open if we had a TWSI parent node
: set-address  ( -- )  h# 3a 6 set-twsi-target  ;
: accelerometer-on  ( -- )
   set-address
   h# 47 h# 20 twsi-b!     \ Power up, X,Y,Z
;
: accelerometer-off  ( -- )
   set-address
   h# 07 h# 20 twsi-b!     \ Power up, X,Y,Z
;

: bext  ( b -- n )  dup h# 80 and  if  h# ffffff00 or  then  ;
: acceleration@  ( -- x y z )
   set-address
   h# 29 twsi-b@ bext
   h# 2b twsi-b@ bext
   h# 2d twsi-b@ bext
;
: open  ( -- flag )
   ['] accelerometer-on catch 0=   
;
: close  ( -- )
   accelerometer-off
;
end-package
