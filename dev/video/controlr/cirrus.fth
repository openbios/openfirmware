\ See license at end of file
purpose: Initialize Cirrus Controllers

\ This file contains the Cirrus Controller specific code.

hex
headerless
: .driver-info  ( -- )
   .driver-info
   ." Cirrus Code Version" cr
;

\ The Cirrus BIOS extension stores a code indicating the memory size
\ in sequencer register 15.  That register doesn't do anything to the
\ hardware, but OS drivers sometimes use that memory size information.
: cirrus-memsize  ( -- )  2 15 seq!  ;

\ Set linear addressing
: cirrus-linear  ( -- )
   \ ef: c0 - 480 lines, 20 - high page, 0c - ext clock, 2 - ena RAM, 1 - color
   \ For higher resolutions (1024x768, 1280x1024, 1600x1200),
   \ the appropriate value is 2f

   \ ef misc!

   11  7 seq!
;
: cirrus-textmode  ( -- )  0  7 seq!  ;

: init-cirrus-controller  ( -- )   \ This gets plugged into "init-controller"
   vga-wakeup

   67 misc!
   
   12  6 seq!			\ unlock cirrus extension registers

   unlock-vsync
   unlock-crt-regs

   vga-reset

   seq-regs   cirrus-linear start-seq   cirrus-memsize start-seq

   high-attr-regs

   grf-regs graphics-memory crt-regs

   55 f seq!
   2 1b crt!

   0 feature-ctl!		\ Vertical sync ctl

   \ XXX should size-memory here

   hsync-on
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
