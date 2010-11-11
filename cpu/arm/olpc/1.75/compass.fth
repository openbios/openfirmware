0 0  " "  " /" begin-package
" compass" name

: set-compass-slave  ( -- )
   4 to smb-clock-gpio#
   5 to smb-data-gpio#
   h# 3c to smb-slave
;
: smb-init    ( -- )  set-compass-slave  smb-on  smb-pulses  ;

: compass@  ( reg# -- byte )  set-compass-slave  smb-byte@  ;
: compass!  ( byte reg# -- )  set-compass-slave  smb-byte!  ;
: open  ( -- okay? )
   0 0 ['] compass! catch  if  false exit  then
   h# a  compass@  [char] H  <>
;
: close  ( -- )
;
\ XXX need some words to take compass readings

end-package

0 0  " "  " /" begin-package
" combo-accelerometer" name

: set-sensor-slave  ( -- )  h# 30 6 set-twsi-target  ;
: sensor@  ( reg# -- byte )  set-sensor-slave  twsi-b@  ;
: sensor!  ( byte reg# -- )  set-sensor-slave  twsi-b@  ;

: accelerometer-on   ( -- )   h# 27 h# 20 sensor!  ;
: accelerometer-off  ( -- )   h# 07 h# 20 sensor!  ;
: wext  ( w -- l )  dup h# 8000 and  if  h# ffff0000 or  then  ;
: acceleration@  ( -- x y z )
   set-sensor-slave
   h# 28 1 6 twsi-get  ( xl xh yl yh zl zh )
   2>r 2>r             ( xl xh )
   bwjoin wext         ( x r: zl,zh yl,yh )
   2r> bwjoin wext     ( x y r: zl,zh )
   2r> bwjoin wext     ( x y z )
;   

: open  ( -- okay? )
   ['] accelerometer-on catch  0=
;   
: close  ( -- )  ;

end-package
