\ See license at end of file
purpose: Main init routine

\ This part of the driver is the main flow of control. All of the
\ defered word will have been filled in before getting here. The
\ init method has been genericized sch that this file should not
\ have to change as support for new controllers is added.

hex 
headers

: init  ( -- )			\ Initializes the controller

   safe? 0=  if			\ safe? set during probe by pci.fth
      ." Do not know this controller type" cr exit
   then

   map-io-regs			\ Enable IO registers
   init-controller		\ Setup the video controller
   declare-props		\ Setup properites
   probe-dac			\ Sets the dac type
   init-dac			\ Initialize the DAC
   reinit-controller		\ 2nd pass controller init, after DAC probing
   reinit-dac			\ Second pass at DAC
   set-dac-colors		\ Set up initial color map
   video-on			\ Turn on video
   unmap-io-regs		\ Disables IO registers

   map-frame-buffer
   frame-buffer-adr /fb 0f fill		\ Apple does not init frame buffer...
;

: display-remove  ( -- )
   unmap-frame-buffer 
   4 c-w@ 1 invert and  4 c-w!		\ Can finally disable IO accesses...
;

0 instance value displ-ver
: .driver-info  ( -- )
   .driver-info
   displ-ver . ." Display Code Version" cr
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
