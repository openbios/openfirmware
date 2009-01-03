\ See license at end of file
purpose: Display driver for VMware virtual SVGA

\ The VMware virtual SVGA is a large linear framebuffer that can
\ support 8, 16, 24, and 32-bit pixels.  We use it in 8-bit mode.
\
\ The only complication is that you have to tell it which areas
\ of the framebuffer you have written to before it displays the changes.
\ You can punt and always tell it to update the whole screen, but
\ that performs poorly for character I/O.
\
\ This driver is a set of wrappers around the standard fb8 support package.
\ Each wrapper updates the current change box to include the operation
\ that was jusr performed.  At appropriate times - usually when you
\ restore the cursor to the screen, but also for each rectangular graphics
\ operation - it transmits the current change box to the virtual hardware,
\ thus telling it to update the physical display on the host system.

d# 640 instance value width			  \ Active screen width
d# 480 instance value height			  \ Active screen height
8 instance value depth
d# 640 instance value /scanline			  \ Active screen width
: (set-resolution)  ( width height depth -- )
   to depth  to height  to width
;

: 640-resolution  ( -- )  d# 640 d# 480 8 (set-resolution)  ;

: 1024-resolution  ( -- )  d# 1024 d# 768 8 (set-resolution)  ;
: 1024x768x16  ( -- )  d# 1024 d# 768 d# 16 (set-resolution)  ;
: 1200x900x16  ( -- )  d# 1200 d# 900 d# 16 (set-resolution)  ;
: 1200x900x32  ( -- )  d# 1200 d# 900 d# 32 (set-resolution)  ;
: 640x480x32  ( -- )  d# 640 d# 480 d# 32 (set-resolution)  ;

0 instance value regs   \ Base address of index/data registers

\ It seems strange to access a 32-bit port at an odd address (1+),
\ but that's the way it works.  It's not a real hardware port.
: reg@  ( index -- value )  regs rl!  regs 1+ rl@  ;
: reg!  ( value index -- )  regs rl!  regs 1+ rl!  ;

\ Here are the register numbers.  Most of these registers are
\ accessed only once, so I don't define access words for many of them.
\ (W) means that it is meaningful for you to write to this register

\  0 ID 
\  1 ENABLE           0: VGA emulation  1: SVGA/linear FB (W)
\  2 WIDTH            current screen width in pixels (W)
\  3 HEIGHT           current screen height in pixels (W)
\  4 MAX_WIDTH        maximum supported screen width
\  5 MAX_HEIGHT       maximum supported screen height
\  6 DEPTH            log2(number of colors) (24)
\  7 BITS_PER_PIXEL   current pixel organization (W)
\  8 PSEUDOCOLOR      1 if color lookup table in current mode
\  9 RED_MASK         bits in current mode for red
\ 10 GREEN_MASK       bits in current mode for green
\ 11 BLUE_MASK        bits in current mode for blue
\ 12 BYTES_PER_LINE   bytes per scanline for current mode
\ 13 FB_START         physical address of framebuffer
\ 14 FB_OFFSET        offset to start of displayed image (R/O ?)
\ 15 FB_MAX_SIZE      maximum framebuffer size in bytes
\ 16 FB_SIZE          framebuffer size for current mode
\ 17 CAPABILITIES     bitmask of supported accelerations
\ 18 MEM_START        Memory for command FIFO and bitmaps
\ 19 MEM_SIZE         Size of that memory
\ 20 CONFIG_DONE      Write 1 after you configure the memory area(W)
\ 21 SYNC             Write 1 to force FIFO synchronization (W)
\ 22 BUSY             Reads 1 when busy, 0 when sync is done
\ 23 GUEST_ID 	      Set guest OS identifier (W)
\ 24 CURSOR_ID 	      ID of cursor (W)
\ 25 CURSOR_X 	      Set cursor X position (W)
\ 26 CURSOR_Y 	      Set cursor Y position (W)
\ 27 CURSOR_ON 	      Turn cursor on/off (W)
\
\ 1024 PALETTE_BASE	Base of SVGA color map - R0 G0 B0 R1 G1 B1 ...

-1 value fifo
: /fb    ( -- #bytes )  d# 15 reg@  ;
: /fifo  ( -- #bytes )  d# 19 reg@  ;

\ 1200x900x32
\ 640x480x32
1024x768x16

h# 200.0000 instance value /mem
: map-regs  ( -- )
   0 0 my-space h# 0100.0010 +  h# 10  " map-in" $call-parent to regs
;
: map-mem  ( -- )
   my-space h# 14 +  " config-l@" $call-parent   if
      0 0 my-space  h# 0200.0014 +  /fb    " map-in" $call-parent  to frame-buffer-adr
      0 0 my-space  h# 0200.0018 +  /fifo  " map-in" $call-parent  to fifo
   else
      0   0 my-space  h# 0200.0018 +  /fb    " map-in" $call-parent  to frame-buffer-adr
      /fb 0 my-space  h# 0200.0018 +  /fifo  " map-in" $call-parent  to fifo
   then
   3  my-space   h# 04 + " config-w!" $call-parent
;
: unmap-regs  ( -- )  regs  h# 10  " map-out" $call-parent  ;
: unmap-mem  ( -- )
   fifo              /fifo  " map-out" $call-parent
   frame-buffer-adr  /fb    " map-out" $call-parent
;

\ Min and Max are the static limits of the FIFO area.
\ Next is the driver-maintained pointer to the next available slot.
\ Stop is the VMware-maintained read pointer; it chases Next
: fifo-min@  ( -- n ) fifo l@  ;       : fifo-min!  ( n -- )  fifo l!  ;
: fifo-max@  ( -- n ) fifo la1+ l@  ;  : fifo-max!  ( n -- )  fifo la1+ l!  ;
: fifo-next@ ( -- n ) fifo 2 la+ l@  ; : fifo-next! ( n -- ) fifo 2 la+ l!  ;
: fifo-stop@ ( -- n ) fifo 3 la+ l@  ; : fifo-stop! ( n -- ) fifo 3 la+ l!  ;

: detect-version  ( -- )
   h# 9000.0002 dup 0 reg!  0 reg@ =  if  exit  then
   h# 9000.0001 dup 0 reg!  0 reg@ =  if  exit  then
   unmap-regs
   abort  \ We don't support version 0
;
: init-fb  ( -- )
   depth 7 reg!  7 reg@ depth <>  if  7 reg@  to depth  then
   
   width 2 reg!  height 3 reg!  \ Dimensions
   d# 12 reg@ to /scanline

   1 1 reg!           \ Enable SVGA
;
: init-fifo  ( -- )
   \ The FIFO data starts at offset 16 because the first 16 bytes of the
   \ address space are used for the Min, Max, Next, and Stop pointers
   d# 16  fifo-min!
   d# 16 d# 10 d# 1024 * +  fifo-max!
   d# 16  fifo-next!
   d# 16  fifo-stop!
   1 d# 20 reg!       \ Config done; adapter accepts fifo values
;
: sync-fifo  ( -- )  1 d# 21 reg!  begin  d# 22 reg@  0=  until  ;
: fifo-full?  ( -- flag )  fifo-next@ la1+  fifo-stop@  =  ;
: fifo-empty?  ( -- )  fifo-next@  fifo-min@  =  ;
: ?sync-fifo  ( -- )
   \ The documentation says to sync the FIFO when Next+4 = Max, but the
   \ XFree86 driver syncs it in these other cases too.
   fifo-next@ la1+  fifo-stop@  =  if  sync-fifo exit  then
   fifo-next@ la1+  fifo-max@   =  if  sync-fifo exit  then
   fifo-stop@       fifo-min@   =  if  sync-fifo exit  then
;
: fifo-put  ( cmd -- )
   ?sync-fifo                   ( cmd )
   fifo-next@ tuck  fifo +  l!  ( next )         \ Put the word in the FIFO
   la1+ dup fifo-next!          ( next' )        \ Update the pointer
   fifo-max@ =  if  fifo-min@ fifo-next!  then   \ Wrap back at the end
;

: +fifo  ( offset -- offset' )
   fifo-next@ swap la+  dup  fifo-max@  >=  if  ( n fifo-offset )
      fifo-max@ -  fifo-min@ +                  ( n fifo-offset' )
   then                                         ( n fifo-offset )
;
: fifo!  ( n offset -- )  +fifo  fifo + l!  ;

: need-fifo-entries  ( n -- )
   fifo-next@ swap la+                 ( next+ )
   fifo-stop@ dup fifo-next@ <  if     ( next+ stop )
      fifo-max@ +  fifo-min@ -         ( next+ stop' )
   then                                ( next+ stop )
   <  if  sync-fifo  then              ( )
;

\ Pass the change box to the display engine
: fb-update  ( xmin xlen ymin ylen -- )
   5 need-fifo-entries

   1 0 fifo!  ( xmin xlen ymin ylen )  \ command 
   4 fifo!  2 fifo!  3 fifo!  1 fifo!  ( )
   5 +fifo fifo-next!
;

: cursor-x  ( -- n )  column# char-width   *  window-left +  ;
: cursor-y  ( -- n )  line#   char-height  *  window-top  +  ;

: char-changed  ( -- )
   cursor-x char-width  cursor-y char-height  fb-update
;

\ For a whole-screen update we set the box to emcompass the entire screen
: screen-changed  ( -- )  0  width  0 height  fb-update  ;

\ Extend by the size of a character at the current position
: char-changed  ( -- )
   cursor-x char-width   cursor-y char-height  fb-update
;
\ Extend to include the remainder of the current line 
: line-changed  ( -- )
   cursor-x   width   cursor-y   char-height  fb-update
;
\ Extend from the current line to the bottom of the screen, full width
: changed-to-end  ( -- )
   0 width  cursor-y height  fb-update
;

\ Color map (palette) access words
headerless

: >palette  ( index -- reg# )  3 * d# 1024 +  ;

external

: color@  ( index -- r g b )  3 *  d# 1024 +  3 bounds  do  i reg@  loop  ;
: color!  ( r g b index -- )
   2swap swap rot                        ( b g r index )
   >palette  3 bounds  do  i reg!  loop  ( )
;
: set-colors  ( adr index #indices -- )
   swap  >palette         ( adr #indices reg# )
   swap 3 *  bounds  do   ( adr )
      dup c@  i reg!  1+  ( adr' )
   loop                   ( adr )
   drop                   ( )
;
: get-colors  ( adr index #indices -- )
   swap  >palette         ( adr #indices reg# )
   swap 3 *  bounds  do   ( adr )
      i reg@ over c!  1+  ( adr' )
   loop                   ( adr )
   drop                   ( )
;

: default-colors  ( -- adr index #indices )
   " "(00 00 00  00 00 aa  00 aa 00  00 aa aa  aa 00 00  aa 00 aa  aa 55 00  aa aa aa  55 55 55  55 55 ff  55 ff 55  55 ff ff  ff 55 55  ff 55 ff  ff ff 55  ff ff ff)"
   0 swap 3 /
;

headers

: set-dac-colors  ( -- )
   default-colors set-colors
   h# 0f color@  h# ff color!   \ Set color ff to white (same as color 15)
;

: declare-props  ( -- )		\ Instantiate screen properties
   " width" get-my-property  if  
      width  encode-int " width"     property
      height encode-int " height"    property
      depth  encode-int " depth"     property
      /scanline  encode-int " linebytes" property
   else
      2drop
   then
;

: init  ( -- )
   map-regs
   detect-version
   map-mem
   init-fb
   init-fifo
   declare-props
;

: init-hook  ( -- )  ;
: display-remove  ( -- )  0 1 reg!  unmap-mem unmap-regs  ;

hex
headers

" display"                      device-type
" ISO8859-1" encode-string    " character-set" property
0 0  encode-bytes  " iso6429-1983-colors"  property

: display-selftest  ( -- failed? )  false  ;

\ Override the generic version with one that does the necessary syncing
\ If we really wanted to be ambitious we could maintain an update rectangle
\ to avoid redrawing everything.
: vm-toggle-cursor  ( -- )  sync-fifo fb8-toggle-cursor char-changed  ;

\ Extend the standard drawing primitives to keep track of what changed
: vm-erase-screen      ( -- ) sync-fifo fb8-erase-screen      screen-changed  ;
: vm-blink-screen      ( -- ) sync-fifo fb8-blink-screen      screen-changed  ;
: vm-invert-screen     ( -- ) sync-fifo fb8-invert-screen     screen-changed  ;
: vm-insert-lines      ( -- ) sync-fifo fb8-insert-lines      changed-to-end  ;
: vm-delete-lines      ( -- ) sync-fifo fb8-delete-lines      changed-to-end  ;
: vm-insert-characters ( -- ) sync-fifo fb8-insert-characters line-changed    ;
: vm-delete-characters ( -- ) sync-fifo fb8-delete-characters line-changed    ;
: vm-draw-character    ( -- ) sync-fifo fb8-draw-character    char-changed    ;
\ This change box is excessiv, but draw-logo is not worth optimizing
: vm-draw-logo         ( -- ) sync-fifo fb8-draw-logo         screen-changed  ;

: display-install  ( -- )
   init
   set-dac-colors
   default-font set-font
   width  height  over char-width /  over char-height /
   /scanline  depth  " fb-install" eval

   \ Replace the fb8-version of toggle-cursor with the wrapped version
   ['] vm-toggle-cursor to toggle-cursor
   ['] vm-erase-screen to erase-screen
   ['] vm-blink-screen to blink-screen
   ['] vm-invert-screen to invert-screen
   ['] vm-insert-lines to insert-lines
   ['] vm-delete-lines to delete-lines
   ['] vm-insert-characters to insert-characters
   ['] vm-delete-characters to delete-characters
   ['] vm-draw-character to draw-character
   ['] vm-draw-logo to draw-logo
;

' display-install  is-install
' display-remove   is-remove
' display-selftest is-selftest

\ We could use the hardware blitter but it's hardly worth the effort.
\ Modern CPUs can pump bits into memory at a blistering rate.

fload ${BP}/dev/video/common/rectangl.fth

: save-rectangle  ( n x y w h -- x w y h  n  x y w h )
   4 roll >r         ( x y w h  r: n )
   swap -rot         ( x w y h  r: n )
   r>                ( x w y h  n )
   4 pick  3 pick    ( x w y h  n  x y )
   5 pick  4 pick    ( x w y h  n  x y w h )
;

\ Redefine these methods to maintain the change box
: fill-rectangle  ( index x y w h -- )
   save-rectangle fill-rectangle  fb-update
;
: draw-rectangle  ( adr x y w h -- )
   save-rectangle draw-rectangle  fb-update
;

: text-mode3  ( -- )  0 1 reg!  ;  \ Disable SVGA, thus reverting to text mode

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
