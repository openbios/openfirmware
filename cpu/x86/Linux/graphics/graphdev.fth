purpose: Simulation of OFW graphics using X

dev /  new-device
  " xgraphics" device-name
  : open  ( -- okay? )  d# 1200 d# 900  d# 392 syscall  2drop retval  0=  ;
  : close ( -- )   d# 396 syscall  ;

  : fill-rectangle  ( color565 x y w h -- )  d# 404 syscall  4drop drop  ;
finish-device

: get-color  ( r g b -- color )
   d# 400 syscall  3drop  retval
;
  
: open-screen
   " /xgraphics" open-dev to screen-ih
;

0 value xred
0 value xgreen
0 value xblue
0 value xmagenta
0 value xblack
0 value xmagenta

: demo  ( -- )
   open-screen

   h# ff  h# 00  h# 00  get-color to xred
   h# 00  h# ff  h# 00  get-color to xgreen
   h# 00  h# 00  h# ff  get-color to xblue
   h# ff  h# 00  h# ff  get-color to xmagenta
       0      0      0  get-color to xblack
   h# ff  h# ff  h# ff  get-color to xmagenta

   d# 500        0  do  i xred     show-state  loop
   d# 1000 d#  500  do  i xblue    show-state  loop
   d# 1500 d# 1000  do  i xgreen   show-state  loop
   d# 2000 d# 1500  do  i xmagenta show-state  loop

   xblack  d# 400 d# 300  d# 50 d# 60  " fill-rectangle" $call-screen
;
