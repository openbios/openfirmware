\ See license at end of file
purpose: Driver for OLPC camera connected to Via VX855 Video Capture Port

headers
hex

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

0 value use-ycrcb?

: read-setup  ( -- )
   use-ycrcb? camera-config
   ctlr-config
   83 300 cl!				\ Clear pending interrupts
   1000.0000 200 cl!			\ Allow CAP0 end interrupt
   ctlr-start
   0 to next-buf
;

: soft-reset  ( -- )  ;

: ?siv120d  ( -- )
   ['] camera-config behavior ['] siv120d-config =  if
      0640.0140 314 cl!         \ Horizontal end and start cycles for siv120d
   then                         \ (a quirk specific to XO-1.5 and siv120d)
;

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
   camera-smb-setup  smb-on
;


\ =============================  read operation ==============================

0 value buf-act
: /string  ( adr len n -- adr' len' )  tuck - -rot + swap  ;
: buf-done?  ( -- done? )
   200 cl@ 1000 and dup  if
      300 cl@ 3 >> 3 and to next-buf
   then
;

: resync  ( -- )  ;

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

: start-display  ( -- )  ;
: stop-display  ( -- )  ;
: camera-blocked?  ( -- flag )
   serial-enabled?  dup  if
      ." The serial port is in use so the camera cannot be used" cr
   then
;

external

: read   ( adr len -- actual )
   buf-done?  if  (read)  else  2drop 0  then
;

: open  ( -- flag )
   init
   my-args " yuv" $=  to use-ycrcb?
   sensor-found? 0=  if  false exit  then
   ?siv120d
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
