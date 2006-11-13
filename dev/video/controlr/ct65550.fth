\ See license at end of file
purpose: Initialize Cirrus CT65550 Controller

\ This file contains Cirrus CT65550 initialization code

hex
headers

0 instance value ct-ver
: .driver-info  ( -- )
   .driver-info
   ct-ver . ." CT6555x Code Version" cr
;

: xr-setup  ( index -- data-adr )  3d6 pc!  3d7  ;
: xr!  ( b index -- )  xr-setup pc!  ;
: xr@  ( index -- b )  xr-setup pc@  ;

: fr-setup  ( index -- data-adr )  3d0 pc!  3d1  ;
: fr@  ( index -- b )  fr-setup pc@  ;
: fr!  ( b index -- )  fr-setup pc!  ;

: size-memory  ( -- )
   \ Need to determine of this is a 1 or 2 MByte frame buffer
   \ to program xr43 properly.

   \ For now, the following code is commented out until we can
   \ test it on hardware. The bits to worry about are bits 2:1
   \ of xr43. The encodeing is:
   \	00 - 1MB
   \	01 - 2MB
   \	10 - Rsvd
   \	11 - Rsvd

   \ When dealing with xr43, bits 7:4 and 0 are supposed to be 
   \ written with 0, the only bit we need to preserve is bit 3.

\   map-frame-buffer			\ Map in the frame-buffer
\   h# a5a5a5a5 h#  8.0000 l!		\ Write test pattern at 512K
\   h# 5a5a5a5a h# 18.0000 l!		\ Write new pattern at 1512K
\   h# a5a5a5a5 h#  8.0000 l!		\ Write test pattern at 512K
\   h# 18.0000 l@ h# 5a5a5a5a =  if  2  else  0  then
\   h# 43 xr@ 8 and or h# 43 xr!
\   unmap-frame-buffer

   \ Curent systems use 2MBytes, so the following is the short term hack
   h# 43  dup xr@  8 and  2 or  swap xr!	\ Set for 2 MByte
;

fload ${BP}/dev/video/controlr/bitblt.fth

: probe-dac  ( -- )			\ Chain dac prober
   ct?  if  use-ct-dac  exit  then
   probe-dac
;

: ct-textmode  ( -- )
   0 h# a  xr!			\ Disable Linear Mapping
   0 h# 81 xr!			\ Pipeline control = text mode
   0 h# 40 xr!			\ Memory Access Width = 16-bit, No address wrap
;
: ct-linear  ( -- )
   2 h# a  xr!			\ Enable Linear Mapping
   2 h# 81 xr!			\ Pipeline control = 8 bpp
   3 h# 40 xr!			\ Memory Access Width = 64-bit, Address wrap
;

: init-ct-controller  ( -- )	\ This gets plugged into "init-controller"
   vga-wakeup
   1  h# 3c3  pc!		\ Set VSE bit
   h# e3 misc!			\ Init misc reg

   h# 12  6 seq!		\ Unlock cirrus extension registers
   unlock-vsync
   unlock-crt-regs

   vga-reset
   seq-regs  start-seq
   attr-regs
   grf-regs graphics-memory crt-regs

   ct-linear
   1 h# 41 xr!			\ EDO DRAM
   h# 80 h# 44 xr!		\ Short RAS cycle

   size-memory
   hsync-on
[ifdef] 8-bit-primaries
   h# 80 dup xr@ h# 80 or swap xr!	\ Turn on 8-bit DAC
[else]
   true to 6-bit-primaries?		\ Configure driver for 6 bits/color
[then]
   h# ff rmr!
;

: use-ct-words  ( -- )			\ Turns on the <name> specific words
   ['] init-ct-controller       to init-controller
   ['] install-blitter          to init-hook
   ['] ct-textmode              to ext-textmode
   use-vga-dac
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
