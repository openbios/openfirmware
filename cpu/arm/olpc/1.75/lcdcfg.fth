d#    4 value hsync
d# 1200 value hdisp
d# 1456 value htotal  .( HTOTAL ???) cr
d#  212 value hbp

d#    4 value vsync
d#  800 value vdisp
d#  845 value vtotal  .( VTOTAL ???) cr
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
