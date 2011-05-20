purpose: Generic USB device stub driver, useful for client programs

external
: open   ( -- flag )  set-device?  if  false exit  then  device set-target  true  ;
: close  ( -- )  ;

: init   ( -- )  init device set-target  ;
init

