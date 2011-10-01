\ See license at end of file
purpose: Driver for the CMOS camera

\ =============================  cafe operations ==============================

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

: alloc-dma-bufs  ( -- )
   dma-bufs 0=  if
      \ I need to allocate 1 more buffer.  Otherwise, memory gets trashed.
      /dma-buf #dma-bufs 1+ * dup dma-alloc dup to dma-bufs
      swap false dma-map-in to dma-bufs-phys
   then
;
: free-dma-bufs  ( -- )
   dma-bufs ?dup  if
      /dma-buf #dma-bufs 1+ * 2dup dma-bufs-phys swap dma-map-out
      dma-free
      0 to dma-bufs  0 to dma-bufs-phys
   then
;

: setup-dma  ( -- )
   #dma-bufs 0  do
      i 'dma-buf-phys i 4 * cl!		\ BAR
   loop
   #dma-bufs 2 >  if
      40 dup cl@ 800.0000 invert and swap cl!	\ Use 3 DMA buffers
   else
      40 dup cl@ 800.0000 or swap cl!	\ Use only 2 DMA buffers
   then
   00 c4 cl!				\ Upper base address
;

\ VGA RGB565
: setup-image  ( -- )
   VGA_WIDTH 2* VGA_HEIGHT wljoin 34 cl!	\ Image size
   00 38 cl!					\ Image offset
   24 dup cl@ 3ffc invert and VGA_WIDTH 2* or swap cl!	\ Image pitch
   3c dup cl@ c0ff.fffc invert and ac or swap cl!	\ Control 0
;

: ctlr-config  ( -- )
   setup-dma
   setup-image
;

: ctlr-start  ( -- )  3c dup cl@ 1 or swap cl!  ;		\ Start the whole thing
: ctlr-stop   ( -- )  3c dup cl@ 1 invert and swap cl!  ;	\ Stop the whole thing

: read-setup  ( -- )
   camera-config
   ctlr-config
   3f 30 cl!				\ Clear pending interrupts
   ctlr-start
   0 to next-buf
;


: soft-reset  ( -- )  4 h# 3034 cl!  0 h# 3034 cl!  ;

: (init)  ( -- )
   0000.0008 3038 cl!		\ Turn on CaFe GPIO3 to enable power
   0008.0008 315c cl!
   0000.0005 3004 cl!		\ wake up device
   0000.000a 3004 cl!
   0000.0006 3004 cl!
   5 ms
   0000.400a 3004 cl!
   300c dup cl@ 4 or swap cl!
   40 dup cl@ 1000.0000 invert and swap cl!	\ power up
   3c dup cl@ 1 invert and swap cl!		\ disable
   0 2c cl!					\ mask all interrupts
   88 dup cl@ ffff invert and 2 or swap cl!	\ clock the sensor, 48MHz
;

: power-up  ( -- )
   40 dup cl@ 1000.0000 invert and swap cl!	\ power up
   30 b4 cl!				        \ power up, reset
   1 ms
   31 b4 cl!                                    \ release reset
   1 ms
;

: power-off  ( -- )
   30 b4 cl!					\ assert Cam_Reset   
   1 ms
   32 b4 cl!					\ assert Cam_Reset and Cam_PWRDN
   1 ms
   0008.0000 315c cl!				\ Remove VDD
   5 ms
   40 dup cl@ 1000.0000 or swap cl!		\ power off
;
: init  ( -- )
   (init)
   power-up
   camera-init
;


\ =============================  read operation ==============================

0 value buf-mask
0 value buf-act
: /string  ( adr len n -- adr' len' )  tuck - -rot + swap  ;

\ Advance next-buf - modulo #dma-bufs - by the number of bits set in buf-mask
: +next-buf  ( buf-mask -- )
   0 swap				( cnt buf-mask )
   #dma-bufs 0  do                      ( cnt buf-mask )
      dup 1 and                         ( cnt buf-mask bit  )
      rot +                             ( buf-mask cnt'  )
      swap 1 >>                         ( cnt buf-mask' )
   loop  drop                           ( cnt )
   next-buf +  #dma-bufs mod  to next-buf  ( )
;
: buf-done?  ( -- buf-mask )  28 cl@  2f 30 cl!  7 and  ;
: read-buf  ( adr len buf# -- adr' len' )
   1 over << buf-mask and 0=  if  drop exit  then
					( adr len buf# )
   'dma-buf 2 pick 2 pick		( adr len dma-buf adr len )
   /dma-buf min dup >r move r>		( adr len len' )
   buf-act over + to buf-act		( adr len len' )
   /string				( adr' len' )
;
: (read)  ( adr len buf-mask -- actual )
   to buf-mask				( adr len )
   0 to buf-act				( adr len )
   \ Read buffers from next-buf till the last dma buffer
   #dma-bufs next-buf  ?do  i read-buf  loop	( adr' len' )
   \ Then wrap around to the first dma buffer
   next-buf 0  ?do  i read-buf  loop	( adr' len' )
   2drop buf-act			( actual )
   buf-mask +next-buf
;

0 value snap-next-buf
: snap-buf-done?  ( -- false | buf true )
   1 snap-next-buf lshift     ( bitmask )
   dup  h# 28 cl@  and  if    ( bitmask )
      h# 38 or  h# 30 cl!     ( )         \ Clear interrupts
      snap-next-buf dup  1+ #dma-bufs mod  to snap-next-buf  ( buf# )
      'dma-buf  true          ( buf true )
   else                       ( bitmask )
      drop false              ( flag )
   then
;

: resync  ( -- )
   \ Wait for the current frame to be ready
   begin  snap-buf-done?  until  drop

   \ Ack any buffers that are already ready
   begin  snap-buf-done?  while  drop  repeat

   \ Now when the next buffer is ready, it will be fresh
;

\ Clear out any stale buffers
: xresync  ( -- )
   \ Ack pending end-of-frames until there are none
   begin  h# 28 cl@  7 and  dup  while  h# 30 cl!  repeat  drop

   \ Now wait for a frame to become ready and set snap-next-buf to point to it
   begin  h# 28 cl@  7 and  dup  0=  while  drop  repeat   ( mask )
   3 0  do
      dup 1 and  if
         i to snap-next-buf
         unloop exit
      then
      2/
   loop
   0 to snap-next-buf
;

external
: write  ( adr len -- actual )  2drop 0  ;

: read   ( adr len -- actual )
   buf-done? ?dup  if  (read)  else  2drop 0  then
;
: snap  ( timeout -- true | buf false )
   0  do
      snap-buf-done?  if   ( buf )
         false  unloop exit  ( -- buf false )
      then
      1 ms
   loop
   true
;

: open  ( -- flag )
   map-regs
   init
   ov7670-detected? 0=  if  unmap-regs false exit  then
   alloc-dma-bufs
   read-setup
   true
;

: close  ( -- )
   ctlr-stop
   power-off
   free-dma-bufs
   unmap-regs
;

: display-frame  ( buf -- )
   " expand-to-screen" " $call-screen" evaluate
\   test-x test-y VGA_WIDTH VGA_HEIGHT " draw-rectangle" " $call-screen" evaluate
;
: start-display  ( -- )  ;
: stop-display  ( -- )  ;
false constant camera-blocked?

\ Do this at probe time to make sure the camera power is off
map-regs
0000.0008 3038 cl!	\ Turn on CaFe GPIO3 to enable power
0008.0000 315c cl!	\ Set VDD to off
unmap-regs

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
