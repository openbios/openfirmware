screen-ih iselect  stdout off

2000.0000.000f.ff80. 1000.0020 msr!  \ Shrink low mem from 1M to 80000
2000.0000.080f.ffe0. 1000.0025 msr!  \ Add back 80000-9ffff
\ 2000.0000.0c0f.ffc0. 1000.0026 msr!  \ Add back c0000-fffff \ 26 is a BMO type descriptor
8000.0000.0a0f.ffe0. 1000.0021 msr!  \ Enable VGA frame buffer

8000.0000.3c0f.ffe0. 1000.00e0 msr!  \ Enable VGA I/O regs

0101.0101.0101.0101. 0000.180b msr!  \ Uncache frame buffer
\ 1919.1919.1919.1919. 0000.180b msr!  \ Write-burstable frame buffer



unlock
\ 45681 4 dc!  \ Enable vga with fixed timing
5600 4 dc!  \ Enable vga with fixed timing
45680 4 dc!  \ Enable vga with fixed timing
45681 4 dc!  \ Enable vga with fixed timing
c200.0019 8 dc!  \ drop down to 8bpp mode


dl
vh
^D
dl
tm
^D


\ XX 3 3c2 pc!    \ map some registers at 3dx  \ 67 misc! instead
: seq!  3c4 pc! 3c5 pc!  ;
: seq@  3c4 pc! 3c5 pc@  ;
3 0 seq!  \ display enable
f 2 seq!  \ enable writing to frame buffer

: crt! 3d4 pc! 3d5 pc! ;
: crt@ 3d4 pc! 3d5 pc@ ;

uncache this
  msr: 0000.180b 00000000.00000000.  \ Cache a0000-bffff


: mode3-crtc
     \  0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f 10 11 12 13 14 15 16 17 18
   " "(5f 4f 50 82 51 9e bf 1f 00 4f 0d 0e 00 00 00 00 9b 8d 8f 28 1f 97 b9 a3 ff)"  ;
: set-crcs  ( -- )
   mode3-crtc  0  do  dup i + c@  i crt!  loop
;

: vga@ 3ce pc! 3cf pc@ ;
: vga! 3ce pc! 3cf pc! ;

c0 6 vga!

: attr@  3da pc@ drop  3c0 pc! 3c1 pc@  ;
: attr!  3da pc@ drop  3c0 pc! 3c0 pc!  ;

set ega colors with 10 0 do nn i attr! 
: en-palette  20 3c0 pc!  ;



000E0h = 1000|0000|0000|0000|0000|0000|0000|0000|0011|1100|0000|1111|1111|1111|1111|0000b
