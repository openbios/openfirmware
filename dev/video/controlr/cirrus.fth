\ See license at end of file
purpose: Initialize Cirrus Controllers

\ This file contains the Cirrus Controller specific code.

hex
\ headerless
: .driver-info  ( -- )
   .driver-info
   ." Cirrus Code Version" cr
;

\ The Cirrus BIOS extension stores a code indicating the memory size
\ in sequencer register 15.  That register doesn't do anything to the
\ hardware, but OS drivers sometimes use that memory size information.
: cirrus-memsize  ( -- )
   \  2 15 seq!  \ Don't need to do this for QEMU
;

: cirrus-hidden@  ( b -- )
   0 vga-rmr!   \ Clear DAC index and hidden DAC index
   vga-rmr@ drop  vga-rmr@ drop  vga-rmr@ drop  vga-rmr@ drop
   vga-rmr@
;

: cirrus-hidden!  ( b -- )
   0 vga-rmr!       \ 0 to pixel mask
   h# 3c8 pc@ drop  \ Read pixel address
   vga-rmr@ drop  vga-rmr@ drop  vga-rmr@ drop  vga-rmr@ drop
   vga-rmr!
;

d# 25 instance buffer: crt-buf

: cirrus-crt-table  \ 640x480, byte mode
   " "(5f 4f 50 82 54 80 0b 3e 00 40 00 00 00 00 07 80 ea 0c df 50 00 e7 04 e3 ff)"
;
: set-geom  ( -- )
   width 8 / 1-  crt-buf 1 + c!
   height 1 -                              ( n )
   dup 3 rshift h# 40 and                  ( n bits )
   over 7 rshift 2 and or  crt-buf 7 + c!  ( n )
   crt-buf h# 12 + c!                      ( )   
;

: set-offset  ( offset -- )
   dup  crt-buf h# 13 + c!  ( offset )
   h# 100 and  if  h# 32  else  h# 22  then  h# 1b crt!
;

\ Set linear addressing
: cirrus-linear  ( -- )
   cirrus-crt-table  crt-buf  swap move

   \ ef: c0 - 480 lines, 20 - high page, 0c - ext clock, 2 - ena RAM, 1 - color
   \ For higher resolutions (1024x768, 1280x1024, 1600x1200),
   \ the appropriate value is 2f

   \ ef misc!

   depth case
      d# 32  of
         h# 29 7 seq!
         h# c5 cirrus-hidden!
         width 2 /  set-offset
      endof

      d# 16  of
         h# 27 7 seq!
         h# c0 cirrus-hidden!
\         1 cirrus-hidden!
         width 4 /  set-offset
      endof
      8 of
         h# 11  7 seq!
         width 8 /  set-offset
      endof
   endcase
   set-geom
;
: cirrus-textmode  ( -- )  0  7 seq!  ;

: init-cirrus-controller  ( -- )   \ This gets plugged into "init-controller"
   vga-wakeup

   67 misc!
   
   12  6 seq!			\ unlock cirrus extension registers

   unlock-vsync
   unlock-crt-regs

   vga-reset

   seq-regs   cirrus-linear start-seq  cirrus-memsize start-seq

   high-attr-regs

   grf-regs graphics-memory
   crt-buf  d# 25  (crt-regs)

\   55 f seq!  \ Don't need this for QEMU
\   2 1b crt!  \ set-offset handles this

   0 feature-ctl!		\ Vertical sync ctl

   \ XXX should size-memory here

   hsync-on
;
: set-resolution  ( width height depth -- )
   unmap-frame-buffer
   (set-resolution)
   map-io-regs
   cirrus-linear
   crt-buf  d# 25  (crt-regs)
   width height  over char-width /  over char-height /
   /scanline  depth   " fb-install" eval
   unmap-io-regs
   map-frame-buffer
   frame-buffer-adr /fb h# ff fill
;

: use-cirrus-words  ( -- )	\ Turns on the Cirrus-specific words
   ['] init-cirrus-controller to init-controller
   ['] cirrus-textmode        to ext-textmode
   use-vga
;

: probe-dac  ( -- )		\ Chained probing word...sets the dac type
   cirrus?  if    use-cirrus-dac exit  then
   probe-dac				\ Try someone else's probe
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
