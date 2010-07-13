d#    4 value hsync
d#  800 value hdisp
d# 1056 value htotal
d#  212 value hbp

d#    4 value vsync
d#  480 value vdisp
d#  525 value vtotal
d#   31 value vbp

: hfp  ( -- n )  htotal hdisp -  hsync -  hbp -  ;
: vfp  ( -- n )  vtotal vdisp -  vsync -  vbp -  ;

2 constant #lanes
3 constant bytes/pixel
d# 24 constant bpp

: >bytes   ( pixels -- chunks )  bytes/pixel *  ;
: >chunks  ( pixels -- chunks )  >bytes #lanes /  ;

alias width  hdisp
alias height vdisp
alias depth  bpp
width >bytes constant /scanline  
