\ See license at end of file
purpose: Generic VGA functions

hex

\ reset attribute address flip-flop
: reset-attr-addr  ( -- )  3da ( input-status1 )  pc@ drop  ;

: video-mode!  ( b -- )  reset-attr-addr  03c0 pc!  ;
: attr!  ( b index -- )  reset-attr-addr 03c0 pc!  03c0 pc!  ;
: attr@  ( index -- b )
   reset-attr-addr  03c0 pc!  03c1 pc@  reset-attr-addr
;
: grf!   ( b index -- )  03ce pc!  03cf pc!  ;
: grf@   ( index -- b )  03ce pc!  03cf pc@  ;

: feature-ctl!  ( b -- )  03da pc!  ;

\ Misc output register bits:

\ 01: color/monochrome (00 - monochrome emulation, 01 - color)
\ 02: enable CPU access to video memory (0 - disable, 2 - enable)
\ 0c: clock source (00 - 25 MHz, 04 - 28 MHz, 08 - ?, 0c - extended)
\ 10: disable video drivers (00 - enable, 10 - disable)
\ 20: page for odd/even graphics modes(0,1,2,3,7) (00 - low page, 20 - high)
\ 40: horizontal sync polarity (00 - positive, 40 - negative)
\ 80: vertical sync polarity (00 - positive, 80 - negative)
\ Multi-sync monitors use the sync polarity to determine the display size:
\     00 - reserved, 40 - 400 lines, 80 - 350 lines, c0 - 480 lines

: misc@  ( -- b )  3cc pc@  ;
: misc!  ( b -- )  3c2 pc!  ;

: crt-setup  ( index -- data-adr )  03d4 pc!  ;
: crt-data!  ( b -- )  03d5 pc!  ;
: crt-data@  ( -- b )  03d5 pc@  ;
: crt!  ( b index -- )  crt-setup crt-data!  ;
: crt@  ( index -- b )  crt-setup crt-data@  ;
: crt-set   ( bits index -- )  crt@  or               crt-data!  ;
: crt-clear ( bits index -- )  crt@  swap invert and  crt-data!  ;

: seq-setup  ( index -- data-adr )  03c4 pc!  03c5  ;
: seq!  ( b index -- )  seq-setup pc!  ;
: seq@  ( index -- b )  seq-setup pc@  ;

\ DAC definitions. This is where the DAC access methods get plugged for this
\ specific controller

: vga-rmr@  ( -- b )  03c6 pc@ ;
: vga-rmr!  ( b -- )  03c6 pc! ;
: vga-plt@  ( -- b )  03c9 pc@ ;
: vga-plt!  ( b -- )  03c9 pc! ;
: vga-rindex!  ( index -- )  03c7 pc! ;
: vga-windex!  ( index -- )  03c8 pc! ;

: use-vga-dac  ( -- )	\ Assigns generic VGA DAC access words
   ['] vga-rmr@ to rmr@
   ['] vga-rmr! to rmr!
   ['] vga-plt@ to plt@
   ['] vga-plt! to plt!
   ['] vga-rindex! to rindex!
   ['] vga-windex! to windex!
[ifdef] rs@
   ['] noop  to rs@
   ['] 2drop to rs!
[then]
[ifdef] idac@
   ['] noop  to idac@
   ['] 2drop to idac!
[then]
;

: palette-off  ( -- )   0 video-mode!  ;
: palette-on   ( -- )  20 video-mode!  ;

: attr-table  ( -- adr len )	\ Attribute controller indices 0-14
   " "(00 01 02 03 04 05 06 07 10 11 12 13 14 15 16 17 01 00 0f 00 00)"
;
: attributes  ( adr len -- )
   reset-attr-addr  
   0  ?do  dup i + c@  i attr!  loop  drop  
;

: attr-regs  ( -- )  attr-table attributes  ;

: /string  ( adr len n -- )  tuck  2swap +  -rot -  ;
: high-attr-regs  ( -- )
   reset-attr-addr
   attr-table 10 /string  0  do  dup i + c@  i 10 + attr!  loop  drop
;

: .attrs   ( -- )  16 0  do  i . i attr@ . cr  loop  palette-on  ;
: pixel-clock/2  ( -- )  h# 10 attr@  h# 40 or  h# 10 attr!  ;

: graphics    ( adr len -- )  0  ?do  dup i + c@  i grf!   loop  drop  ;

\ Graphics controller indices 0-8
: grf-regs  ( -- )  " "(00 00 00 00 00 40 05 0f ff)"  graphics  ;

: sequencer  ( adr len -- )  0  ?do  dup i + c@  i seq!   loop  drop  ;
: seq-regs  ( -- )  " "(00 01 0f 00 0e)"  sequencer  ;
: start-seq  ( -- )  3 0 seq!	 ;	\ Start sequencer

: graphics-memory  ( -- )  e 4 seq!  ;	\ Enable graphics mode for memory
: vga-wakeup  ( -- )  1 h# 102 pc!  ;	\ Make VGA respond

: unlock-crt-regs  ( -- )  80 11 crt-clear  ;
: unlock-vsync     ( -- )  80  3 crt-set    ;
: screen-off  ( -- )  1 seq@  20 or          1 seq!  ;
: screen-on   ( -- )  1 seq@  20 invert and  1 seq!  ;
: vga-reset  ( -- )
   palette-off				\ Disable CPU access to palette RAM
   20 1 seq!				\ screen off
    0 0 seq!	3 0 seq!		\ Pulse reset
   screen-on
   2 4 seq!				\ Enable video memory past 256K
;

h# 20 buffer: crtcbuf
: crtc@  ( index -- value )  crtcbuf + c@  ;

: .vga-mode  ( -- )
   push-decimal
   ." HTotal:      "  0 crtc@  4 u.r  cr
   ." HDispEnd:    "  1 crtc@  4 u.r  cr
   ." HBlankStart: "  2 crtc@  4 u.r  cr
   ." HBlankEnd:   "  3 crtc@ h# 1f and  5 crtc@ h# 80 and 2 rshift or  4 u.r  cr
   ." HSyncStart:  "  4 crtc@  4 u.r  cr
   ." HSyncEnd:    "  5 crtc@ h# 1f and  4 u.r  cr
   ." VTotal:      "  6 crtc@  7 crtc@ 1 and 7 lshift or  7 crtc@ h# 20 and 4 lshift or  4 u.r  cr
   ." BytePan:     "  8 crtc@  5 rshift  4 u.r  cr
   ." PresetRowScn:"  8 crtc@  h# 1f and  4 u.r  cr
   ." DoubleScan:  "  9 crtc@  7 rshift  4 u.r  cr
   ." MaxScan:     "  9 crtc@  5 rshift  4 u.r  cr
   ." CursorOff:   "  h# a crtc@  5 rshift  1 and  4 u.r  cr
   ." CursorStart: "  h# a crtc@  h# 1f and  4 u.r  cr
   ." CursorSkew:  "  h# b crtc@  5 rshift  7 and  4 u.r  cr
   ." CursorEnd:   "  h# b crtc@  h# 1f and  4 u.r  cr
   ." StartAddress:"  h# d crtc@  h# c crtc@ bwjoin 4 u.r cr
   ." CursorLoc:   "  h# f crtc@  h# e crtc@ bwjoin 4 u.r cr
   ." VSyncStart:  "  h# 10 crtc@  7 crtc@ 4 and 6 lshift or  7 crtc@ h# 80 and 2 lshift or  4 u.r  cr
   ." VSyncEnd:    "  h# 11 crtc@ h# f and  4 u.r cr
   ." WriteProtect:"  h# 11 crtc@ 7 rshift  4 u.r cr
   ." VDispEnd:    "  h# 12 crtc@  7 crtc@ 2 and 7 lshift or  7 crtc@ h# 40 and 3 lshift or  4 u.r  cr
   ." Offset:      "  h# 13 crtc@  4 u.r  cr
   ." DoubleWord:  "  h# 14 crtc@  6 rshift 1 and  4 u.r  cr
   ." UnderlineLoc:"  h# 14 crtc@  h# 1f and  4 u.r  cr
   ." VBlankStart: "  h# 15 crtc@  7 crtc@ 8 and 5 lshift or  9 crtc@ h# 20 and 4 lshift or  4 u.r  cr
   ." VBlankEnd:   "  h# 16 crtc@  4 u.r  cr
   ." EnableSyncs: "  h# 17 crtc@  7 rshift 4 u.r  cr
   ." ByteMode:    "  h# 17 crtc@  6 rshift 1 and 4 u.r  cr
   ." AddressWrap: "  h# 17 crtc@  5 rshift 1 and 4 u.r  cr
   ." VCLKSelect:  "  h# 17 crtc@  2 rshift 1 and 4 u.r  cr
   ." SelectRowScn:"  h# 17 crtc@  1 rshift 1 and 4 u.r  cr
   ." SelectA13:   "  h# 17 crtc@  1 and 4 u.r  cr
   ." LineCompare: "  h# 18 crtc@  4 u.r  cr
   pop-base
;
: showmode  ( adr len -- )   crtcbuf swap move  .vga-mode  ;

instance defer crt-table
: (mode12-crt-table)
   \ AMD recommended values for mode 12
   " "(5f 4f 50 82 51 9e 0b 3e 00 40 00 00 00 00 00 00 e9 8b df 28 00 e7 04 e3 ff)"
;
: (vga-crt-table)  \ 640x480, byte mode
   " "(5f 4f 50 82 54 80 0b 3e 00 40 00 00 00 00 07 80 ea 0c df 50 00 e7 04 e3 ff)"
;
\ : vga-400-crt-table
\  " "(5f 4f 50 82 54 80 bf 1f 00 41 00 00 00 00 00 31 9c 0e 8f 28 40 96 b9 a3 ff)"
\ ;
' (vga-crt-table) to crt-table

: crt  ( adr len -- )
   unlock-crt-regs
   0  ?do  dup i + c@  i crt!  loop  drop
;

: crt-regs  ( -- )
   \ Don't program hsync (at offset 4) until later
   crt-table  0  ?do  i 4 <>  if  dup i + c@  i  crt!  then  loop  drop
;
: hsync-on  ( -- )  crt-table drop  4 +  c@  4 crt!  ;	\ Set hsync position

: vga-video-on  ( -- )  palette-on hsync-on  ;

: use-vga
   use-vga-dac
   ['] vga-video-on to video-on
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
