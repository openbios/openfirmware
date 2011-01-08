0 0  " "  " /" begin-package
" compass" name

: set-compass-slave  ( -- )
   4 to smb-clock-gpio#
   5 to smb-data-gpio#
   h# 3c to smb-slave
   5 smb-data-gpio# gpio-dir-out
;
: smb-init    ( -- )  set-compass-slave  smb-on  smb-pulses  ;

: compass@  ( reg# -- byte )  set-compass-slave  smb-byte@  ;
: compass!  ( byte reg# -- )  set-compass-slave  smb-byte!  ;
: open  ( -- okay? )
   0 0 ['] compass! catch  if  false exit  then
   h# a  compass@  [char] H  =  if
      0 2 compass!   \ Continuous conversion mode
      true
   else
      false
   then
;
: close  ( -- )
   2 2 compass!  \ Idle mode
;
: dir@  ( reg# -- n )
   dup compass@  swap 1+ compass@   swap  bwjoin  wextend
;
: direction@  ( -- x y z )
   begin  9 compass@ 1 and  until
   3 dir@  5 dir@  7 dir@  ( x y z )
;
end-package

0 0  " "  " /" begin-package
" combo-accelerometer" name

\ : set-sensor-slave  ( -- )  h# 30 6 set-twsi-target  ;
: set-sensor-slave  ( -- )
   4 to smb-clock-gpio#
   5 to smb-data-gpio#
   h# 30 to smb-slave
   5 smb-data-gpio# gpio-dir-out
;

: sensor@  ( reg# -- byte )  set-sensor-slave  smb-byte@  ;
: sensor!  ( byte reg# -- )  set-sensor-slave  smb-byte@  ;

: accelerometer-on   ( -- )   h# 27 h# 20 sensor!  ;
: accelerometer-off  ( -- )   h# 07 h# 20 sensor!  ;
: acceleration@  ( -- x y z )
   set-sensor-slave
   6 h# 28 smb-read-n  ( xl xh yl yh zl zh )
   2>r 2>r             ( xl xh )
   bwjoin wextend      ( x r: zl,zh yl,yh )
   2r> bwjoin wextend  ( x y r: zl,zh )
   2r> bwjoin wextend  ( x y z )
;   

: open  ( -- okay? )
   ['] accelerometer-on catch  0=
;   
: close  ( -- )  ;

end-package
