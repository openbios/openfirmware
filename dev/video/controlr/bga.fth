\ See license at end of file
purpose: Initialize Bochs Graphics Adapter Controllers

\ This file contains the Cirrus Controller specific code.

hex
\ headerless
: .driver-info  ( -- )
   .driver-info
   ." BGA Code Version" cr
;
\ Constants from http://wiki.osdev.org/Bochs_VBE_Extensions
\    VBE_DISPI_INDEX_ID (0)
\    VBE_DISPI_INDEX_XRES (1)
\    VBE_DISPI_INDEX_YRES (2)
\    VBE_DISPI_INDEX_BPP (3)
\    VBE_DISPI_INDEX_ENABLE (4)
\    VBE_DISPI_INDEX_BANK (5)
\    VBE_DISPI_INDEX_VIRT_WIDTH (6)
\    VBE_DISPI_INDEX_VIRT_HEIGHT (7)
\    VBE_DISPI_INDEX_X_OFFSET (8)
\    VBE_DISPI_INDEX_Y_OFFSET (9)

: vbe-w!
  h# 1ce pw!
  h# 1d0 pw!
;

\ At least under QEMU this is a write only register.
\ Reading from 1d0 just returns the last word written regardless of index.
\ For the case it works different one day
\ : vbe-w@
\   h# 1ce pw!
\   h# 1d0 pw@
\ ;

: init-bga-controller  ( -- )   \ This gets plugged into "init-controller"
  0 4 vbe-w!                                    \ Disable VBE extensions
  0 8 vbe-w! 0 9 vbe-w! 		        \ Set offsets to 0
  width 1 vbe-w! height 2 vbe-w! depth 3 vbe-w! \ Set resolution
  h# 41 4 vbe-w!                                \ Enable VBE and Linear FB
;

: set-resolution  ( width height depth -- )
   unmap-frame-buffer
   (set-resolution)
   map-io-regs
   init-bga-controller
   width height  over char-width /  over char-height /
   /scanline  depth   " fb-install" eval
   unmap-io-regs
   map-frame-buffer
   frame-buffer-adr /fb h# ff fill
;

: use-bga-words  ( -- )	\ Turns on the BGA-specific words
   ['] init-bga-controller to init-controller
   use-vga
;

: init-bga-dac ( -- )
   true to 6-bit-primaries?     \ The default BGA pallete DAC is 3x6
;

: use-bga-dac  ( -- )
   ['] init-bga-dac to init-dac
;

: probe-dac  ( -- )		\ Chained probing word...sets the dac type
   safe?  if use-bga-dac exit  then
   probe-dac				\ Try someone else's probe
;

\ LICENSE_BEGIN
\ Copyright (c) 2014 Artyom Tarasenko
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
