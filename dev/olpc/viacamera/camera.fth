\ See license at end of file
purpose: Driver for OLPC camera connected to Via VX855 Video Capture Port

headers
hex

" OV7670" " sensor" string-property

: cl!  ( l adr -- )  " mmio-base" $call-parent + rl!  ;
: cl@  ( adr -- l )  " mmio-base" $call-parent + rl@  ;

\ ======================= OV7670 SMBUS operations ==========================

h# 42 constant ov-sid
h# 31 constant sccb-port

: sccb-setup  ( -- )  sccb-port to smb-port  ov-sid to smb-slave  ;
: ov@  ( reg -- data )  sccb-setup  smb-byte@  ;
: ov!  ( data reg -- )  sccb-setup  smb-byte!  ;

: ovc  ( val adr -- )
   2dup ov@      ( val reg# val actual )
   tuck <>  if   ( val reg# actual )
      ." Bad camera I2C value at " swap 2 u.r  ( val actual )
      ."  expected " swap 2 u.r  ."  got " 2 u.r  cr    ( )
   else          ( val reg# actual )
      3drop      ( )
   then          ( )
;

\ ============================= camera operations =============================

0 value use-ycrcb?

false value ov7670-detected?

: ((camera-init)  ( -- )
   80 12 ov!  2 ms		\ reset (reads back different)
   01 11 ov!			\ 30 fps
   04 3a ov!			\ UYVY or VYUY
   00 12 ov!			\ VGA

   \ Hardware window
   13 17 ov!			\ Horiz start high bits
   01 18 ov!			\ Horiz stop high bits
   b6 32 ov!			\ HREF pieces
   02 19 ov!			\ Vert start high bits  - !! 02
   7a 1a ov!			\ Vert stop high bits
   0a 03 ov!			\ GAIN, VSTART, VSTOP pieces

   \ Mystery scaling numbers
   00 0c ov!			\ Control 3
   00 3e ov!			\ Control 14
   3a 70 ov!  35 71 ov!  11 72 ov!  f0 73 ov!
   02 a2 ov!
   00 15 ov!			\ Control 10

   \ Gamma curve values
   20 7a ov!  10 7b ov!  1e 7c ov!  35 7d ov!
   5a 7e ov!  69 7f ov!  76 80 ov!  80 81 ov!
   88 82 ov!  8f 83 ov!  96 84 ov!  a3 85 ov!
   af 86 ov!  c4 87 ov!  d7 88 ov!  e8 89 ov!

   \ AGC and AEC parameters
   e0 13 ov!			\ Control 8
   00 00 ov!			\ Gain lower 8 bits  !! Linux then sets REG_AECH to 0
   00 10 ov!
   40 0d ov!			\ Control 4 magic reserved bit
   18 14 ov!			\ Control 9: 4x gain + magic reserved bit
   05 a5 ov!			\ 50hz banding step limit
   07 ab ov!			\ 60hz banding step limit
   95 24 ov!			\ AGC upper limit
   33 25 ov!			\ AGC lower limit
   e3 24 ov!			\ AGC/AEC fast mode op region
   78 9f ov!			\ Hist AEC/AGC control 1
   68 a0 ov!			\ Hist AEC/AGC control 2
   03 a1 ov!			\ Magic
   d8 a6 ov!			\ Hist AEC/AGC control 3
   d8 a7 ov!			\ Hist AEC/AGC control 4
   f0 a8 ov!			\ Hist AEC/AGC control 5
   90 a9 ov!			\ Hist AEC/AGC control 6
   94 aa ov!			\ Hist AEC/AGC control 7
   e5 13 ov!			\ Control 8

   \ Mostly magic
   61 0e ov!  4b 0f ov!  02 16 ov!  07 1e ov!
   02 21 ov!  91 22 ov!  07 29 ov!  0b 33 ov!
   0b 35 ov!  1d 37 ov!  71 38 ov!  2a 39 ov!
   78 3c ov!  40 4d ov!  20 4e ov!  00 69 ov! 
   4a 6b ov!  10 74 ov!  4f 8d ov!  00 8e ov!
   00 8f ov!  00 90 ov!  00 91 ov!  00 96 ov!
   00 9a ov!  84 b0 ov!  0c b1 ov!  0e b2 ov!
   82 b3 ov!  0a b8 ov!

   \ More magic, some of which tweaks white balance
   0a 43 ov!  f0 44 ov!  34 45 ov!  58 46 ov!
   28 47 ov!  3a 48 ov!  88 59 ov!  88 5a ov!
   44 5b ov!  67 5c ov!  49 5d ov!  0e 5e ov!
   0a 6c ov!  55 6d ov!  11 6e ov!
   9f 6f ov!			\ 9e for advance AWB
   40 6a ov!
   40 01 ov!			\ Blue gain
   60 02 ov!			\ Red gain
   e7 13 ov!			\ Control 8

   \ Matrix coefficients
   80 4f ov!  80 50 ov!  00 51 ov!  22 52 ov!
   5e 53 ov!  80 54 ov!  9e 58 ov!

   08 41 ov!			\ AWB gain enable
   00 3f ov!			\ Edge enhancement factor
   05 75 ov!  e1 76 ov!  00 4c ov!  01 77 ov!
   c3 3d ov!			\ Control 13
   09 4b ov!  60 c9 ov!         \ Reads back differently
   38 41 ov!			\ Control 16
   40 56 ov!

   11 34 ov!
   12 3b ov!			\ Control 11
   88 a4 ov!  00 96 ov!  30 97 ov!  20 98 ov!
   30 99 ov!  84 9a ov!  29 9b ov!  03 9c ov!
   4c 9d ov!  3f 9e ov!  04 78 ov!

   \ Extra-weird stuff.  Some sort of multiplexor register
   01 79 ov!  f0 c8 ov!
   0f 79 ov!  00 c8 ov!
   10 79 ov!  7e c8 ov!
   0a 79 ov!  80 c8 ov!
   0b 79 ov!  01 c8 ov!
   0c 79 ov!  0f c8 ov!
   0d 79 ov!  20 c8 ov!
   09 79 ov!  80 c8 ov!
   02 79 ov!  c0 c8 ov!
   03 79 ov!  40 c8 ov!
   05 79 ov!  30 c8 ov!
   26 79 ov!

   \ OVT says that rewrite this works around a bug in 565 mode.
   \ The symptom of the bug is red and green speckles in the image.
\   01 11 ov!			\ 30 fps def 80  !! Linux doesn't do this
;

: config-check  ( -- )
   01 11 ovc			\ 30 fps
   04 3a ovc			\ UYVY or VYUY
   ( 00 12 ovc )		\ VGA

   \ Hardware window
   13 17 ovc			\ Horiz start high bits
   01 18 ovc			\ Horiz stop high bits
   b6 32 ovc			\ HREF pieces
   02 19 ovc			\ Vert start high bits
   7a 1a ovc			\ Vert stop high bits
   0a 03 ovc			\ GAIN, VSTART, VSTOP pieces

   \ Mystery scaling numbers
   00 0c ovc			\ Control 3
   00 3e ovc			\ Control 14
   3a 70 ovc  35 71 ovc  11 72 ovc  f0 73 ovc
   02 a2 ovc
   00 15 ovc			\ Control 10

   \ Gamma curve values
   20 7a ovc  10 7b ovc  1e 7c ovc  35 7d ovc
   5a 7e ovc  69 7f ovc  76 80 ovc  80 81 ovc
   88 82 ovc  8f 83 ovc  96 84 ovc  a3 85 ovc
   af 86 ovc  c4 87 ovc  d7 88 ovc  e8 89 ovc

   \ AGC and AEC parameters
   ( e0 13 ovc )		\ Control 8
   ( 00 00 ovc )		\ Gain lower 8 bits
   ( 00 10 ovc )                \ Automatic exposure control 9:2
   40 0d ovc			\ Control 4 magic reserved bit
   ( 18 14 ovc )		\ Control 9: 4x gain + magic reserved bit
   05 a5 ovc			\ 50hz banding step limit
   07 ab ovc			\ 60hz banding step limit
   ( 95 24 ovc )		\ AGC upper limit
   33 25 ovc			\ AGC lower limit
   e3 24 ovc			\ AGC/AEC fast mode op region
   78 9f ovc			\ Hist AEC/AGC control 1
   68 a0 ovc			\ Hist AEC/AGC control 2
   03 a1 ovc			\ Magic
   d8 a6 ovc			\ Hist AEC/AGC control 3
   d8 a7 ovc			\ Hist AEC/AGC control 4
   f0 a8 ovc			\ Hist AEC/AGC control 5
   90 a9 ovc			\ Hist AEC/AGC control 6
   94 aa ovc			\ Hist AEC/AGC control 7
   ( e5 13 ovc	)		\ Control 8

   \ Mostly magic
   61 0e ovc  4b 0f ovc  02 16 ovc  07 1e ovc
   02 21 ovc  91 22 ovc  07 29 ovc  0b 33 ovc
   0b 35 ovc  1d 37 ovc  71 38 ovc  2a 39 ovc
   78 3c ovc  40 4d ovc  20 4e ovc  00 69 ovc 
   4a 6b ovc  10 74 ovc  4f 8d ovc  00 8e ovc
   00 8f ovc  00 90 ovc  00 91 ovc  00 96 ovc
   ( 00 9a ovc )  84 b0 ovc  0c b1 ovc  0e b2 ovc
   82 b3 ovc  0a b8 ovc

   \ More magic, some of which tweaks white balance
   0a 43 ovc  f0 44 ovc  34 45 ovc  58 46 ovc
   28 47 ovc  3a 48 ovc  88 59 ovc  88 5a ovc
   44 5b ovc  67 5c ovc  49 5d ovc  0e 5e ovc
   0a 6c ovc  55 6d ovc  11 6e ovc
   9f 6f ovc			\ 9e for advance AWB
   ( 40 6a ovc )
   ( 40 01 ovc )		\ Blue gain
   ( 60 02 ovc )		\ Red gain
   e7 13 ovc			\ Control 8

   \ Matrix coefficients
   b3 4f ovc  b3 50 ovc  00 51 ovc  3d 52 ovc
   a7 53 ovc  e4 54 ovc  9e 58 ovc

   \ 08 41 ovc			\ AWB gain enable
   ( 00 3f ovc )		\ Edge enhancement factor
   05 75 ovc  e1 76 ovc  ( 00 4c ovc )  01 77 ovc
   c0 3d ovc			\ Control 13
   09 4b ovc  ( 60 c9 ovc )
   38 41 ovc			\ Control 16
   40 56 ovc

   11 34 ovc
   12 3b ovc			\ Control 11
   88 a4 ovc  00 96 ovc  30 97 ovc  20 98 ovc
   30 99 ovc  84 9a ovc  29 9b ovc  03 9c ovc
   5c 9d ovc  3f 9e ovc  04 78 ovc

;

: camera-init  ( -- )
   false to ov7670-detected?
   ((camera-init)
   1d ov@ 1c ov@  bwjoin 7fa2 <>  if  exit  then	\ Manufacturing ID
    b ov@  a ov@  bwjoin 7673 <>  if  exit  then	\ Product ID
   true to ov7670-detected?
;

\ VGA RGB565
: init-rgb565  ( -- )
   04 12 ov!				\ VGA, RGB565
   00 8c ov!				\ No RGB444
   00 04 ov!				\ Control 1: CCIR601 (H/VSYNC framing)
   10 40 ov!				\ RGB565 output
   38 14 ov!				\ 16x gain ceiling
   b3 4f ov!				\ v-red
   b3 50 ov!				\ v-green
   00 51 ov!				\ v-blue
   3d 52 ov!				\ u-red
   a7 53 ov!				\ u-green
   e4 54 ov!				\ u-blue
   c0 3d ov!				\ Gamma enable, UV saturation auto adjust

   \ OVT says that rewrite this works around a bug in 565 mode.
   \ The symptom of the bug is red and green speckles in the image.
   01 11 ov!			\ 30 fps def 80  !! Linux doesn't do this
;

: read-agc  ( -- n )
   3 ov@  h# c0 and  2 lshift  0 ov@ or
;

: read-aec  ( -- n )
   7 ov@  h# 3f and  d# 10 lshift
   h# 10 ov@  2 lshift  or
   4 ov@  3 and  or
;

: set-hw  ( vstop vstart hstop hstart -- )
   dup  3 >> 17 ov!			\ Horiz start high bits
   over 3 >> 18 ov!			\ Horiz stop high bits
   32 ov@ swap 7 and or swap 7 and 3 << or 10 ms 32 ov!	\ Horiz bottom bits

   dup  2 >> 19 ov!			\ Vert start high bits
   over 2 >> 1a ov!			\ Vert start high bits
   03 ov@ swap 3 and or swap 3 and 2 << or 10 ms 03 ov!	\ Vert bottom bits
;

: camera-config  ( -- )
   ((camera-init)
   use-ycrcb?  0=  if  init-rgb565  then
   d# 490 d# 10 d# 14 d# 158 set-hw	\ VGA window info
;

\ ==========================  video capture operations ==========================

d# 640 constant VGA_WIDTH
d# 480 constant VGA_HEIGHT

VGA_WIDTH VGA_HEIGHT * 2* constant /dma-buf
3 constant #dma-bufs
0 value dma-bufs
0 value dma-bufs-phys
0 value next-buf

: dma-sync     ( virt phys size -- )         " dma-sync"    $call-parent  ;
: dma-alloc    ( len -- adr )                " dma-alloc"   $call-parent  ;
: dma-free     ( adr len -- )                " dma-free"    $call-parent  ;
: dma-map-in   ( virt size cache? -- phys )  " dma-map-in"  $call-parent  ;
: dma-map-out  ( virt phys size -- )         " dma-map-out" $call-parent  ;

: 'dma-buf       ( i -- virt )  /dma-buf * dma-bufs      +  ;
: 'dma-buf-phys  ( i -- phys )  /dma-buf * dma-bufs-phys +  ;

: temp-buf  ( -- adr )  #dma-bufs 'dma-buf  ;


: alloc-dma-bufs  ( -- )
   dma-bufs 0=  if
      /dma-buf #dma-bufs *  " alloc-capture-buffer" $call-parent  to dma-bufs-phys  to dma-bufs
   then
;
: free-dma-bufs  ( -- )
   dma-bufs  dma-bufs-phys  /dma-buf #dma-bufs *  " free-capture-buffer" $call-parent
   0 to dma-bufs 0 to dma-bufs-phys
;

: setup-dma  ( -- )
   #dma-bufs 0  do
      i 'dma-buf-phys  340 i 4 * + cl!	\ Capture frame buffers
   loop
;

\ VGA
: setup-image  ( -- )
   0         31c cl!			\ Active video scaling control
   01e2.00f0 334 cl!			\ Maximum data count of active video
;

: ctlr-config  ( -- )
   setup-dma
   setup-image
;

: ctlr-start  ( -- )  310 dup cl@ 1 or swap cl!  ;		\ Start the whole thing
: ctlr-stop   ( -- )  310 dup cl@ 1 invert and swap cl!  ;	\ Stop the whole thing

: read-setup  ( -- )
   camera-config
   ctlr-config
   83 300 cl!				\ Clear pending interrupts
   1000.0000 200 cl!			\ Allow CAP0 end interrupt
   ctlr-start
   0 to next-buf
;

: soft-reset  ( -- )  ;

: (init)  ( -- )
   0         300 cl!		\ Mask all interrupts
   8850.2104 310 cl!		\ Enable CLK, FIFO threshold, UYVY, 8-bit CCIR601,
				\ Capture odd/even in interlace, triple buffers
   0620.0120 314 cl!            \ Horizontal end and start cycles for CCIR601
   01de.0000 318 cl!            \ Vertical end and start cycles for CCIR601
   VGA_WIDTH 2*  350 cl!	\ Disable coring and 640*2 stride
;

: power-up  ( -- )
   \ Disable UART
   8846 dup config-b@  40 invert and swap config-b!	\ Disable UART
   78 dup seq@ 80 invert and swap seq!		\ Enable VCP/DVP1 interface

   \ Setup VGPIO[2..3]
   2c dup seq@ 02 or swap seq!			\ Enable VGPIO2..3 ports
   2c dup seq@ d0 or swap seq!			\ cam_PWREN, cam_Reset
   1 ms
   2c dup seq@ f0 or swap seq!			\ Release reset
   1 ms

   \ Power on video capture port
   1e dup seq@ c0 or swap seq!			\ Pad on/off according to PMS
   1 ms
;

: power-off  ( -- )
   2c dup seq@ 20 invert and swap seq!		\ Assert cam_Reset
   1 ms
   2c dup seq@ 10 invert and swap seq!		\ Power off
;

: init  ( -- )
   (init)
   power-up
   sccb-setup  smb-on
   camera-init
;


\ =============================  read operation ==============================

0 value buf-act
: /string  ( adr len n -- adr' len' )  tuck - -rot + swap  ;
: buf-done?  ( -- done? )
   200 cl@ 1000 and dup  if
      300 cl@ 3 >> 3 and to next-buf
   then
;

: snap  ( timeout -- true | adr false )
   0  do
      buf-done?  if
         next-buf 'dma-buf  false
         300 cl@ 83 or 300 cl!		\ Clear interrupts
         unloop exit
      then
      1 ms
   loop
   true
;

: (read)  ( adr len -- actual )
   next-buf 'dma-buf -rot /dma-buf min dup >r move r>	( actual )
   300 cl@ 83 or 300 cl!		\ Clear interrupts
;

external

: read   ( adr len -- actual )
   buf-done?  if  (read)  else  2drop 0  then
;

: open  ( -- flag )
   init
   my-args " yuv" $=  to use-ycrcb?
   ov7670-detected? 0=  if  false exit  then
   alloc-dma-bufs
   read-setup
   true
;

: close  ( -- )
   ctlr-stop
   power-off
   free-dma-bufs
;


\ ============================= selftest operation ===========================

d# 5,000 constant movie-time
0 constant test-x
0 constant test-y

\ Thanks to Cortland Setlow (AKA Blaketh) for the autobrightness code
\ and the full-screen + mirrored display.

: autobright  ( -- )
   read-agc 3 + 3 rshift  h# f min  " bright!" $call-parent
;
: full-brightness  ( -- )  h# f " bright!" $call-parent  ;

: display-ycrcb-frame  ( adr -- )
   temp-buf VGA_WIDTH VGA_HEIGHT * ycbcr422>rgba8888
   temp-buf VGA_WIDTH 4*    ( src-adr src-pitch )
   0 0  d# 280 d# 210  VGA_WIDTH VGA_HEIGHT  " copy32>32" $call-parent
;

: display-rgb-frame  ( adr -- )
   VGA_WIDTH 2*    ( src-adr src-pitch )
   0 0  d# 280 d# 210  VGA_WIDTH VGA_HEIGHT  " copy16>32" $call-parent
;

: display-frame  ( adr -- )
   use-ycrcb?  if  display-ycrcb-frame  else  display-rgb-frame  then
\  autobright
;
: timeout-read  ( adr len timeout -- actual )
   >r 0 -rot r>  0  ?do			( actual adr len )
      2dup read ?dup  if  3 roll drop -rot leave  then
      1 ms
   loop  2drop
;

: shoot-still  ( -- error? )
   d# 1000 snap  if  true exit  then   ( adr )
   display-frame
   false
;

: shoot-movie  ( -- error? )
   get-msecs movie-time +			( timeout )
   begin                 			( timeout )
      shoot-still  if  drop true exit  then 	( timeout )
      dup get-msecs - 0<=                       ( timeout reached )
   until					( timeout )
   drop false
;

: mirrored  ( -- )  h# 1e ov@  h# 20 or  h# 1e ov!  ;
: unmirrored  ( -- )  h# 1e ov@  h# 20 invert and  h# 1e ov!  ;

: selftest  ( -- error? )
   serial-enabled?  if
      ." The serial port is in use so the camera cannot be used" cr
      false exit
   then
   open 0=  if  true exit  then
   d# 300 ms
   unmirrored  shoot-still  ?dup  if  close exit  then	( error? )
   d# 1,000 ms
   mirrored   shoot-movie  full-brightness		( error? )
   close						( error? )
   ?dup  0=  if  confirm-selftest?  then		( error? )
;

: dump-regs  ( run# -- )
   0 d# 16 " at-xy" eval
   ." Pass " .d
   key upc  h# 47 =  if ." Good" else  ." Bad" then cr  \ 47 is G

   ."        0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f" cr
   ."       -----------------------------------------------" cr
   h# ca 0  do
      i 2 u.r ." :  "
      i h# 10 bounds  do
         i h# ca <  if  i ov@ 3 u.r   then
      loop
      cr
   h# 10 +loop
;

: xselftest  ( -- error? )
   open 0=  if  true exit  then
   h# 10 0 do
      shoot-still  drop  d# 500 ms  camera-config  config-check
      i dump-regs
   loop
   0 close					( error? )
;


\ LICENSE_BEGIN
\ Copyright (c) 2009 FirmWorks
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
