purpose: Platform-specific parts of BIOS emulation for Windows support
\ See license at end of file

\ Workaround for problems with the way that Windows manages the
\ GPIOs for lid wakeup.  To understand this, you need to understand
\ the Geode GPIO hardware, which is confusing and poorly documented.
\ See http://wiki.laptop.org/images/4/46/GPIO.png for a diagram.

\ The following LID wakeup frobbing is not needed anymore;
\ I figured out how to do it in ACPI (which was fairly tricky)
0 [if]
0 value negedge-ena-state
0 value posedge-ena-state

h# 400 constant lid-gpio       \ GPIO 26
h# 4000.0000 constant lid-pme  \ PME mapper 6
: setup-lid-wakeup  ( -- )
   h# c0 gpio@ to posedge-ena-state
   h# c4 gpio@ to negedge-ena-state
   lid-gpio h# c8 gpio!  lid-gpio h# cc gpio!  \ Clear both edge status latches
   d# 100 us   \ Wait for the synchronizer (32 kHz clock)

   \ Empirically, Windows tries to control the wakeup policy by flipping
   \ the input invert bit.  If you suspend from the power button, the
   \ input invert is on at this point, whereas if you suspend by closing
   \ the lid, input invert is off.  That doesn't quite work right - in
   \ the power-button-suspend case, subsequently closing the lid causes
   \ a wakeup!  To fix the problem, we switch to edge-detector wakeup.
   \ We leave the invert/no-invert setting as is, and choose which edge
   \ to wakeup on.  In both cases we want to wakeup on the lid-opening
   \ event, but which edge that is depends on the inversion state.

   h# a4 gpio@ lid-gpio and  if
      \ Lid input is inverted.  Lid opening causes rising edge on pin,
      \ inverted to falling edge internally, so wakeup on negative edge.

      lid-gpio >clr h# c0 gpio!  lid-gpio h# c4 gpio!
   else
      \ Lid input is not inverted.  Lid opening causes rising edge on pin,
      \ so rising edge internally, so wakeup on positive edge.

      lid-gpio >clr h# c4 gpio!  lid-gpio h# c0 gpio!
   then
   d# 100 us   \ Wait for the synchronizer (32 kHz clock)
   lid-pme h# 18 acpi-l!   \ Clear the final latch
;
: cleanup-lid-wakeup  ( -- )
   posedge-ena-state  h# c0 gpio!
   negedge-ena-state  h# c4 gpio!
;
[then]

: suspend-ps2  ( -- )
   " default-disable-kbd" $call-keyboard   \ Stop keyboard
   1 " set-port" $call-keyboard    \ Select mouse (touchpad) port
   " default-disable-kbd" $call-keyboard   \ Stop mouse
;
: resume-ps2  ( -- )
   " enable-scan" $call-keyboard   \ Restart mouse
   0 " set-port" $call-keyboard    \ Select keyboard port
   " enable-scan" $call-keyboard   \ Restart keyboard
;

: enable-uoc  ( -- )
   uoc-pci-base h# 1000 4 h# 5151.0020 set-p2d-bm
   h# 5120.000b msr@ 2 or h# 5120.000b msr!
;
: disable-uoc  ( -- )
   h# 5120.000b msr@ 2 invert and h# 5120.000b msr!
   h# 5101.0020 p2d-bm-off
;
: xo-platform-fixup  ( -- )
   disable-uoc
   visible
   wlan-reset
;
' xo-platform-fixup to more-platform-fixup

: video-refresh-off  ( -- )
   h# 1000.002a msr@ drop d# 12 lshift   ( dc-base )
   h# 4758 over l!  0 swap 4 + l!
   d# 25 ms
;

: (suspend-devices)  ( -- )
   dcon-power-off  video-refresh-off

   wlan-freeze
   suspend-ps2
   [ifdef] setup-lid-wakeup  setup-lid-wakeup  [then]
   sci-inhibit   \ This prevents SCIs during a critical period
   0 sci-mask!   \ No SCIs during sleep
   enable-uoc    \ So resume can turn on USB power
   h# 99 h# 34 cmos!
;
: (resume-devices)  ( -- )
   disable-uoc   \ Because Windows doesn't want to see the UOC
   h# 4e sci-mask!
   sci-uninhibit
   [ifdef] cleanup-lid-wakeup  cleanup-lid-wakeup  [then]
   resume-ps2
   wlan-reset
   dcon-power-on  d# 10 ms  " dcon-restart" screen-ih $call-method
;
' (suspend-devices) to suspend-devices
' (resume-devices) to resume-devices

\ LICENSE_BEGIN
\ Copyright (c) 2009 FirmWorks
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
