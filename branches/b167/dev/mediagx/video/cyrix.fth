\ See license at end of file
purpose: Initialize Cyrix MediaGX video Controller

hex
headers

\ XXX Need major work.

0 instance value gx-ver
: .driver-info  ( -- )
   gx-ver . ." Cyrix MediaGX Video Controller" cr
;

: map-io-regs  ( -- )  ;

: unmap-io-regs  ( -- )  ;


: map-frame-buffer  ( -- )
   fb-pa  h# 10.0000  " map-in" $call-parent  to frame-buffer-adr
   frame-buffer-adr encode-int " address" property
;

: unmap-frame-buffer  ( -- )
   frame-buffer-adr h# 10.0000  " map-out" $call-parent
   -1 to frame-buffer-adr
   " address" delete-property
;

: execute-io-companion-method  ( method$ -- )
   " /5520" open-dev
   ?dup  if
      dup >r
      $call-method
      r> close-dev
   else
      2drop
   then
;

\ Access functions for various register banks

: wakeup  ( -- )		\ Wakeup Cyrix MediaGX video controller
   exit				\ Don't know if we need to
   16 46e8 pc!
   1 102 pc!
   e 46e8 pc!
   0 4ae8 pc!
;

\ DAC definitions. This is where the DAC access methods get plugged for this
\ specific controller

: plt@  ( -- b )  74 dcr@  ;
: plt!  ( b -- )  74 dcr!  ;
: rindex!  ( index -- )  70 dcr!  ;
: windex!  ( index -- )  rindex!  ;

\ Register dump.
: reg-dump  ( base #words -- )  bounds do  i u. i rl@ u. cr 4 +loop  ;
: gpr-dump  ( -- )  gpr-base 48 reg-dump  gpr-base 100 + 18 reg-dump  ;
: dcr-dump  ( -- )  dcr-base 80 reg-dump  ;

: dcr-unlock  ( -- ) 4758 0 dcr!  ;
: dcr-lock    ( -- )  0 0 dcr!  ;

: video-off ( -- )
   dcr-unlock  0000.0000 08 dcr!  dcr-lock	\ sync lo, disable sync
   
;
: video-on  ( -- )
   dcr-unlock  0000.006f 08 dcr!  dcr-lock	\ sync lo, enable sync, enable vintr
   " video-on" execute-io-companion-method
;

: init-gpr  ( -- )
;

: init-dcr  ( -- )
   dcr-unlock
[ifndef] 640x480
   \ 1024 x 480
   0000.7681 04 dcr!		\ fifo priority, dclk*2, enable fifo
   0000.3005 0c dcr!		\ enable FP data, 8 BPP, enable PCLK
   0000.0000 10 dcr!		\ frame buffer offset
   000c.2000 14 dcr!		\ comp display buffer offset = 640
   0020.fe00 18 dcr!		\ ??? cursor offset
   001f.e372 20 dcr!		\ ??? video buffer offset
   0004.4100 24 dcr!		\ buffer line delta
   3bd4.8282 28 dcr!		\ ??? video buffer size, compressed display
				\ buffer line size, frame buffer line size
   0000.0000 10 dcr!		\ frame buffer offset

   053f.03ff 30 dcr!		\ Htotal, Hactive
   0537.0407 34 dcr!		\ Hblank end, start
   04a7.0417 38 dcr!		\ Hsync end, start
   04a7.0417 3c dcr!		\ FP Hsync end, start
   0325.02ff 40 dcr!		\ VTotal, Vactive
   0325.02ff 44 dcr!		\ Vblank end, start
   0309.0303 48 dcr!		\ Vsync end, start
   0309.0303 4c dcr!		\ FP Vsync end, start

   0000.3005 0c dcr!		\ enable FP data, 8 BPP, enable PCLK
[else]
   \ 640 x 480
   0000.7641 04 dcr!		\ fifo priority, dclk*1, enable fifo
   0000.3005 0c dcr!		\ enable FP data, 8 BPP, enable PCLK
   0000.0000 10 dcr!		\ frame buffer offset
   0000.0280 14 dcr!		\ comp display buffer offset = 640
   0026.fe00 18 dcr!		\ ??? cursor offset
   003b.0000 20 dcr!		\ ??? video buffer offset
   0010.0100 24 dcr!		\ buffer line delta
   03e8.8250 28 dcr!		\ ??? video buffer size, compressed display
				\ buffer line size, frame buffer line size
   0000.0000 10 dcr!		\ frame buffer offset

   0378.02c8 30 dcr!		\ Htotal, Hactive
   0378.02d0 34 dcr!		\ Hblank
   0350.02d8 38 dcr!		\ Hsync
   0357.02df 3c dcr!		\ FP Hsync
   020c.01df 40 dcr!		\ VTotal, Vactive
   0204.01e7 44 dcr!		\ Vblank
   01eb.01e9 48 dcr!		\ Vsync
   01eb.01e9 4c dcr!		\ FP Vsync
[then]
   dcr-lock

   0000.0000 50 dcr!		\ cursor x
   0000.0000 58 dcr!		\ cursor y
   0000.03ff 5c dcr!		\ split-screen line compare

   0000.0000 60 dcr!		\ cursor color
   0000.0000 68 dcr!		\ border color
;

\ fload ${BP}/dev/mediagx/video/bitblt.fth

: probe-dac  ( -- )			\ Chain dac prober
;

: init-controller  ( -- )
   wakeup
   video-off
   init-gpr
   init-dcr
;

: reinit-controller  ( -- )  ;

: init-hook  ( -- )
   /displine emu-bytes/line - 2/ to window-left  
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
