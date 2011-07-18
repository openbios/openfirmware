\ ==========================  video capture operations ==========================

d# 640 constant VGA_WIDTH
d# 480 constant VGA_HEIGHT

VGA_WIDTH VGA_HEIGHT * 2* constant /dma-buf
3 constant #dma-bufs
0 value dma-bufs
0 value dma-bufs-phys
0 value next-buf

: 'dma-buf       ( i -- virt )  /dma-buf * dma-bufs      +  ;
: 'dma-buf-phys  ( i -- phys )  /dma-buf * dma-bufs-phys +  ;

: alloc-dma-bufs  ( -- )
   dma-bufs 0=  if
      /dma-buf #dma-bufs *  alloc-capture-buffer  to dma-bufs-phys  to dma-bufs
   then
;
: free-dma-bufs  ( -- )
   dma-bufs  dma-bufs-phys  /dma-buf #dma-bufs *  free-capture-buffer
   0 to dma-bufs 0 to dma-bufs-phys
;

: setup-dma  ( -- )
   h# 0440.003c h# 40 cl!   \ posted writes, 3 buffers, 256 byte burst, reserved field

   0 'dma-buf-phys  h# 00 cl!
   1 'dma-buf-phys  h# 04 cl!
   2 'dma-buf-phys  h# 08 cl!
;

\ c000.0000 = 0000.0000 for HSYNC/VSYNC format
\ 0400.0000 for falling vclk
\ 0200.0000 for VSYNC active low
\ 0100.0000 for HSYNC active low
\ 0080.0000 for VSYNC falling edge
h# 0000.0000 constant polarities  
h#        20 constant rgb-sensor
h#       080 constant rgb-fb
h#        00 constant rgb-endian  \ 0c bits

\ VGA RGB565
: setup-image  ( -- )
   VGA_WIDTH 2*  h# 24 cl!	\ 640*2 stride, UV stride in high bits = 0

   VGA_WIDTH 2*  VGA_HEIGHT wljoin  h# 34 cl!   \ Image size register
   0             0          wljoin  h# 38 cl!	\ Image offset

   polarities  rgb-fb or  rgb-sensor or  rgb-endian or  h# 3c cl!  \ CTRL0
;

: interrupts-off  ( -- )  0 h# 2c cl!  h# ffffffff h# 30 cl!  ;
: interrupts-on  ( -- )  7 h# 2c cl!  h# ffffffff h# 30 cl!  ;

: ctlr-config  ( -- )

   interrupts-off
   setup-dma
   setup-image
;

: ctlr-start  ( -- )  h# 3c dup cl@  1 or          swap cl!  ;  \ Enable
: ctlr-stop   ( -- )  h# 3c dup cl@  1 invert and  swap cl!  ;	\ Disable

: read-setup  ( -- )
   camera-config
   ctlr-config
     \ Clear all interrupts
   interrupts-on          \ Enable frame done interrupts
   ctlr-start
   0 to next-buf
;

: power-on  ( -- )
   \ Enable clocks
   h# 3f h# 282828 io!  \ Clock gating - AHB, Internal PIXCLK, AXI clock always on
   h# 0003.805b h# 282850 io!  \ PMUA clock config for CCIC - /1, PLL1/16, AXI arb, AXI, perip on

\  h# 0000.0002 h# 88 cl!   \ Clock select - PIXMCLK, 797/2 (PLL1/16) / 2 -> 24.9 MHz
\  h# 4000.0002 h# 88 cl!   \ Clock select -     AXI, 797/2 (PLL1/16) / 2 -> 24.9 MHz
   h# 6000.0002 h# 88 cl!   \ Clock select -    core, 797/2 (PLL1/16) / 2 -> 24.9 MHz

   sensor-power-on  1 ms
   h# 40 cl@  h# 1000.0000 invert and  h# 40 cl!  \ Enable pads

   reset-sensor
   1 ms
;

: power-off  ( -- )
   reset-sensor
   h# 40 cl@  h# 1000.0000 or  h# 40 cl!  \ Disable pads
   sensor-power-off
;

: init  ( -- )
   power-on
   ov-smb-setup smb-on
   camera-init
;


\ =============================  read operation ==============================

0 value buf-act
: /string  ( adr len n -- adr' len' )  tuck - -rot + swap  ;
: buf-done?  ( -- false | buf# true )
   h# 30 cl@  dup 1 next-buf lshift  and   if  ( value )
      h# 30 cl!                ( )
      next-buf true            ( buf# true )
   else                        ( value )
      drop false               ( false )
   then
;


: snap  ( timeout -- true | buf# false )
   0  do
      buf-done?  if   ( buf# )
         false  unloop exit  ( -- buf# false )
      then
      1 ms
   loop
   true
;

external

: read   ( adr len -- actual )
   buf-done?  if          ( adr len buf# )
      'dma-buf -rot       ( buf-adr adr len )
      /dma-buf min        ( buf-adr adr actual )
      dup >r  move  r>    ( actual )
   else
      2drop -2
   then
;

: open  ( -- flag )
   init
   ov7670-detected? 0=  if  false exit  then
   alloc-dma-bufs
   read-setup
   true
;

: start-display  ( -- )
   0 'dma-buf-phys VGA_WIDTH VGA_HEIGHT " start-video" $call-screen
;
: stop-display  ( -- )
   " stop-video" $call-screen
;

: close  ( -- )
   stop-display
   ctlr-stop
   interrupts-off
   power-off
   free-dma-bufs
   camera-base h# 1000 " map-out" $call-parent
;


\ ============================= selftest operation ===========================

d# 5,000 constant movie-time
0 constant test-x
0 constant test-y

\ Thanks to Cortland Setlow (AKA Blaketh) for the autobrightness code
\ and the full-screen + mirrored display.

: autobright  ( -- )
   read-agc 3 + 3 rshift  h# f min  " bright!" $call-screen
;
: full-brightness  ( -- )  h# f " bright!" $call-screen  ;

code copy16>24-line  ( src-adr dst-adr #pixels -- )
   mov     r2,tos            \ #pixels in r2
   ldmia   sp!,{r0,r1,tos}   \ r0: src, r1: dst, r2: #pixels
   begin
      ldrh  r3,[r1]
      inc   r1,2

      mov   r4,r3,lsr #8
      and   r4,r4,#0xf8
      strb  r4,[r0],#1

      mov   r4,r3,lsr #3
      and   r4,r4,#0xfc
      strb  r4,[r0],#1

      mov   r4,r3,lsl #3
      and   r4,r4,#0xf8
      strb  r4,[r0],#1

      decs  r2,1
   0= until
c;

VGA_WIDTH  value rect-w
VGA_HEIGHT value rect-h

d# 1200 3 *  value dst-pitch
d# 1200 VGA_WIDTH  - 2/ value dst-x
d#  800 VGA_HEIGHT - 2/ value dst-y

: >dst-adr  ( adr -- adr' )  dst-y dst-pitch *  dst-x +  3 *  +  ;

VGA_WIDTH 2* value src-pitch

: copy16>24  ( src-adr dst-base -- )
   >dst-adr             ( src-adr dst-adr )
   rect-h 0  ?do        ( src-adr dst-adr )
      2dup rect-w copy16>24-line          ( scr-adr dst-adr )
      swap src-pitch +  swap dst-pitch +  ( scr-adr' dst-adr' )
   loop                 ( src-adr dst-adr )
   2drop                ( )
;

: display-frame  ( buf# -- )
   'dma-buf-phys " set-video-dma-adr" $call-screen
\  'dma-buf fb-pa copy16>24
\   autobright
;

: timeout-read  ( adr len timeout -- actual )
   >r 0 -rot r>  0  ?do			( actual adr len )
      2dup read ?dup  if  3 roll drop -rot leave  then
      1 ms
   loop  2drop
;

: shoot-still  ( -- error? )
   d# 1000 snap  if  true exit  then   ( buf# )
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
   open 0=  if  true exit  then
   my-address my-space  h# 1000  " map-in" $call-parent  to camera-base
   d# 300 ms
   start-display
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
\ Copyright (c) 2010 FirmWorks
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
