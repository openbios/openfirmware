\ See license at end of file
purpose: Cyrix 5530 I/O Companion Function 4 driver

hex headers

" video" device-name

d# 1024 4 * constant /chipbase

0 value chipbase

: +int   ( $1 n -- $2 )   encode-int encode+  ;

\ Configuration space registers
my-address my-space        encode-phys          0 +int          0 +int

\ Memory mapped I/O space registers
4001.0000 0  my-space  8200.0010 + encode-phys encode+  0 +int  /chipbase +int

" reg" property

: my-b@  ( offset -- b )  my-space +  " config-b@" $call-parent  ;
: my-b!  ( b offset -- )  my-space +  " config-b!" $call-parent  ;

: my-w@  ( offset -- w )  my-space +  " config-w@" $call-parent  ;
: my-w!  ( w offset -- )  my-space +  " config-w!" $call-parent  ;

: my-l@  ( offset -- l )  my-space +  " config-l@" $call-parent  ;
: my-l!  ( offset -- l )  my-space +  " config-l!" $call-parent  ;

: map-in   " map-in"  $call-parent  ;
: map-out  " map-out" $call-parent  ;

: map-regs    ( -- )  0 0  my-space h# 0200.0010 +  /chipbase map-in  to  chipbase ;
: unmap-regs  ( -- )  chipbase /chipbase map-out  ;

external

: open  ( -- ok? )  map-regs true  ;

: close  ( -- )  unmap-regs  ;

headers

: video-l@  ( idx -- data )  chipbase + rl@  ;
: video-l!  ( data idx -- )  chipbase + rl!  ;

: init-pci  ( -- )
   4001.0000 10 my-l!			\ program BAR
   3 4 my-w!				\ enable memory mapped I/O
;

[ifdef] 640x480
23e3.6802 constant dot-clock		\ 640 x 480
[else]
3791.1801 constant dot-clock		\ 1024 x 768
[then]
: init-video-clock  ( clkreg -- )
   dup 8000.0000 or 24 video-l!		\ reset dot clock
   dup 100 or 24 video-l!		\ bypass pll
   d# 10 ms
   24 video-l!				\ pll normal operation
;
: init-video  ( -- )
   map-regs
   0000.0000 00 video-l!                \ video config register
   0031.0100 04 video-l!                \ display config register
   dot-clock init-video-clock		\ init dot clock
   04 video-l@ 2f or 04 video-l!        \ power DAC, enable sync, enable display
   unmap-regs
;

: init  ( -- )
   init-pci
   make-properties
   init-video
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
