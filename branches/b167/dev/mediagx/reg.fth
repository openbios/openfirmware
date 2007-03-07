\ See license at end of file
purpose: Configuration register routines for MediaGX

hex
headers

0 value gx-base

4000.0000 constant gx-pa		\ ??? gx-base 100.0000 0 claim
0000.0c00 constant /scratchpad		\ scratchpad size

\ Constants for 3KB scratchpad
/scratchpad c00 =  if  d# 1328  else  d# 816  then  constant /blt

code cpu-write  ( l adr -- )  bx pop  ax pop  h# f c, h# 3c c,  c;
code cpu-read  ( adr -- l )  bx pop  h# f c, h# 3d c,  ax push  c;

h# ffffff0c constant bb0-base
h# ffffff1c constant bb1-base
h# ffffff2c constant bb0-pointer
h# ffffff3c constant bb1-pointer
h# ffffff6c constant pm-base
h# ffffff7c constant pm-mask

d# 128  constant /drv-scratch
: drv-scratch  ( -- adr )  gx-base e60 +  ;
: blt0    ( -- adr )  drv-scratch /blt -  ;
: blt1    ( -- adr )  blt0        /blt -  ;

\ Other gx-based regions
: ibiur-base  ( -- adr )  gx-base 8000 +  ; 	\ Internal bus unit registers
: gpr-base    ( -- adr )  gx-base 8100 +  ; 	\ Graphics pipeline registers
: dcr-base    ( -- adr )  gx-base 8300 +  ; 	\ Display controller registers
: mcr-base    ( -- adr )  gx-base 8400 +  ; 	\ Memory controller registers
: pmr-base    ( -- adr )  gx-base 8500 +  ; 	\ Power management registers
gx-pa 80.0000 + constant fb-pa	\ Frame buffer

: (cfg@)  ( idx -- b )  22 pc! 23 pc@  ;
: (cfg!)  ( b idx -- )  22 pc! 23 pc!  ;

: unlock-cfg  ( -- )  c3 (cfg@) 10 or c3 (cfg!)  ;
: lock-cfg    ( -- )  c3 (cfg@) 10 invert and c3 (cfg!)  ;

: cfg@  ( idx -- b )  unlock-cfg  (cfg@)  lock-cfg  ;	\ for regs 20,Bx,Ex
: cfg!  ( b idx -- )  unlock-cfg  (cfg!)  lock-cfg  ;	\ for regs 20,Bx,Ex

: ibiur@  ( idx -- l )  ibiur-base + rl@  ;
: ibiur!  ( l idx -- )  ibiur-base + rl!  ;

: gpr@  ( idx -- l )  gpr-base + rl@  ;
: gpr!  ( l idx -- )  gpr-base + rl!  ;

: dcr@  ( idx -- l )  dcr-base + rl@  ;
: dcr!  ( l idx -- )  dcr-base + rl!  ;

: mcr@  ( idx -- l )  mcr-base + rl@  ;
: mcr!  ( l idx -- )  mcr-base + rl!  ;

: pmr@  ( idx -- l )  pmr-base + rl@  ;
: pmr!  ( l idx -- )  pmr-base + rl!  ;

create mhz d# 133 w, d# 333 w, d# 300 w, d# 166 w, d# 133 w,
           d# 200 w, d# 233 w, d# 266 w,
: cpu-mhz  ( -- mhz )
   fe cfg@ 7 and /w * mhz + w@
;
: cpu-hz  ( -- hz )  cpu-mhz  d# 1,000,000 *  ;
: cpu-rev  ( -- rev )  ff cfg@  ;

h# 20.0000 config-int graphics-memory-size
: set-graphics-base  ( adr -- )
   h# 8.0000 round-down             ( adr' )
   dup d# 19 rshift  h# 14 mcr!     ( adr )  \ Frame buffer base
   1- 0 ibiur!                      ( )      \ Top of RAM
;
: resize-graphics-memory  ( -- )
   graphics-memory-size  h# 10.0000 max  h# 40.0000 min   ( size )
   h# 8.0000 round-up                                     ( size' )

   " size" $call-mem-method drop                          ( size memsize )

   swap -                                                 ( newtop )
   0 ibiur@ 1+                                            ( newtop oldtop )

   2dup u<=  if  2drop exit  then                         ( newtop oldtop )

   swap set-graphics-base                                 ( oldtop )

   \ Get the value from the register in case it had to be rounded
   0 ibiur@ 1+                                            ( oldtop newtop )

   \ Restore memory to page pool
   over -  mem-release                                    ( )
;

stand-init: CPU
   gx-pa  h# 9000  root-map-in  to gx-base
;
\ LICENSE_BEGIN
\ Copyright (c) 2006 FirmWorks
\ 
\ Permission is hereby granted, free of charge, to any person obtaining
\ a copy of this software and associated documentation files (the
\ "Software"), to deal in the Software without restriction, including
\ without limitation the rights to use, copy, modify, merge, publish,
\ distribute, sublicense, and/or sell copies of the Software, and to
\ permit persons to whom the Software is furnished to do so, subject to
\ the following conditions:
\ 
\ The above copyright notice and this permission notice shall be
\ included in all copies or substantial portions of the Software.
\ 
\ THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
\ EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
\ MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
\ NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
\ LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
\ OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
\ WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
\
\ LICENSE_END
