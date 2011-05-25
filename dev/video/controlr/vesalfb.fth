\ See license at end of file
purpose: Display driver for VESA linear framebuffer

d# 640 instance value width			  \ Active screen width
d# 480 instance value height			  \ Active screen height
d# 32 instance value depth
d# 640 4 * instance value /scanline		  \ Active screen width
: (set-resolution)  ( width height depth -- )
   to depth  to height  to width
   width  depth 8 /  *  to /scanline
;

0 value mode#
0 value old-mode#
: set-vesa-resolution  ( -- )
   mode# vesa-mode-info
   dup h# 10 + w@  to /scanline
   dup h# 12 + w@  to width
   dup h# 14 + w@  to height
   h# 19 + c@ to depth   
;
: fb-size  ( -- len )
   height /scanline *  h# 1000 round-up
;

h# 200.0000 instance value /mem
: map-mem  ( -- )
   mode# vesa-lfb-adr  fb-size  " map-in" $call-parent  to frame-buffer-adr
;
: unmap-mem  ( -- )
   frame-buffer-adr  fb-size    " map-out" $call-parent
;

headers

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

: choose-mode  ( -- )
   mode#  if  exit  then
   \ Lower-resolution modes scroll faster.  32-bit often works better than 16
   d#  640 d# 480  d# 32  find-vesa-mode  ?dup  if  to mode#  exit  then
   d#  640 d# 480  d# 16  find-vesa-mode  ?dup  if  to mode#  exit  then
   d#  800 d# 600  d# 32  find-vesa-mode  ?dup  if  to mode#  exit  then
   d#  800 d# 600  d# 16  find-vesa-mode  ?dup  if  to mode#  exit  then
   d# 1024 d# 768  d# 32  find-vesa-mode  ?dup  if  to mode#  exit  then
   d# 1024 d# 768  d# 16  find-vesa-mode  ?dup  if  to mode#  exit  then
   d# 1280 d# 1024 d# 32  find-vesa-mode  ?dup  if  to mode#  exit  then
   d# 1280 d# 1024 d# 16  find-vesa-mode  ?dup  if  to mode#  exit  then
   -1 throw
;
: init  ( -- )
   current-vesa-mode to old-mode#
   choose-mode
   set-vesa-resolution
   mode# set-linear-mode
   map-mem
   declare-props
;

: init-hook  ( -- )  ;
: display-remove  ( -- )  unmap-mem  old-mode# set-vesa-mode  ;

hex
headers

" display"                      device-type
" ISO8859-1" encode-string    " character-set" property
0 0  encode-bytes  " iso6429-1983-colors"  property

: display-selftest  ( -- failed? )  false  ;

: display-install  ( -- )
   init
   default-font set-font
   width  height  over char-width /  over char-height /
   /scanline  depth  " fb-install" eval

;

' display-install  is-install
' display-remove   is-remove
' display-selftest is-selftest

\ We could use the hardware blitter but it's hardly worth the effort.
\ Modern CPUs can pump bits into memory at a blistering rate.

fload ${BP}/dev/video/common/rectangle16.fth

: save-rectangle  ( n x y w h -- x w y h  n  x y w h )
   4 roll >r         ( x y w h  r: n )
   swap -rot         ( x w y h  r: n )
   r>                ( x w y h  n )
   4 pick  3 pick    ( x w y h  n  x y )
   5 pick  4 pick    ( x w y h  n  x y w h )
;

: text-mode3  ( -- )  3 set-vesa-mode  ;  \ Disable SVGA, thus reverting to text mode

\ LICENSE_BEGIN
\ Copyright (c) 2011 FirmWorks
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
