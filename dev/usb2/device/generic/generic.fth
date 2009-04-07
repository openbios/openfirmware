purpose: Generic USB device stub driver, useful for client programs

external
: open   ( -- flag )  device set-target  true  ;
: close  ( -- )  ;

: init   ( -- )  init device set-target  ;
init

