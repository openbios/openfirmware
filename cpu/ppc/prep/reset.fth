purpose: Reset system - this version works on many PR*P systems
\ See license at end of file

headerless
: (reset-all)  ( -- )
   icache-off dcache-off

   \ We are about to disable translations by modifying the MSR,
   \ but we must preserve our ability to do ISA I/O cycles to the
   \ "92" register, so we have to set io-base back to the physical
   \ address of ISA space.
   h# 8000.0000 to io-base

   \ Warm reset doesn't affect all the MSR bits, so we have to
   \ explicitly set some of them to their power-up values.
   \ We want ILE (10000) off so that the reset interrupt will occur
   \ in big-endian mode, external interrupts (8000) off, machine
   \ checks (1000) off, address translation (30) off, and the
   \ interrupt prefix (40) on (to direct the reset interrupt to ROM).

   msr@  h# 19030 invert and  h# 40 or  msr!

   \ Read the old value because we must not change the
   \ endianness of the host bridge until the very last step.

   \ h# 92 pc@			( old-value )

   \ Drive the reset bit low because it's the low-to-high transition
   \ that does the work.

   \ dup 1 invert and  h# 92 pc!     ( old-value )

   \ Clear the bridge endian bit (2) and set the reset bit (1)
   \ 2 invert and 1 or  h# 92 pc!

   \ See below for the history behind the following replacement code.
   \ We first check the reset bit for 1 and reset it only if needed.

   h# 92 pc@ dup  1 and if

      \ If we must reset it, the following will get the endian bit
      \ from the msr reg for the Ultra.  The Viper will reset here.

      dup  msr@ 1 and 2* or  1 invert and  h# 92 pc!

   then  2 invert and  1 or  h# 92 pc!

   \ On some systems, it takes a while for the reset to take effect,
   \ so we wait here rather than returning to the prompt immediately,
   \ to avoid confusing the user.
   d# 3000 ms
;
' (reset-all) to reset-all
headers

\    Here's the story:
\
\    On an Ultra, the PCI bridge endian bit is driven by bit 1 (0x02) in
\    I/O port 92.  In the same port, bit 0 (0x01) making the transition
\    from 0 to 1 causes the machine to reset.  This is the standard I/O
\    port 92 reset.
\
\    On a Viper, any write to port 92 will reset the machine (apparently
\    the implementation is a PAL) and the PCI bridge endian switch is
\    controlled via the PCI configuration registers.  As it turns out,
\    the code for the Viper will work on a Ultra to control the bridge
\    (that's good, eaglele.fth is in arch/prep/) so there isn't any
\    problem until you go to mess with port 92 on the Ultra.
\
\    Here's the relevant code from arch/prep/reset.fth:
\
\    92 pc@ dup 1 invert and 92 pc! 2 invert and 1 or 92 pc!
\
\    If you try to reset the Ultra while running in little endian, it now
\    reads port 92 its endian bit as zero (meaning big endian) while the
\    Eagle bridge chip is really running in little endian (controlled
\    through the config registers).  This bit is carefully saved and
\    stored back into the port when the reset bit is forced to zero.
\    This neatly hangs the system.  From observation, bit 0 is never set
\    on entry to this code, even though it is left set.  It is probably
\    reset after it's tested in the early startup code.  We could try the
\    following for the reset code:
\
\    92 pc@ dup  1 and if
\       dup msr@ 1 and 2* or 1 invert and 92 pc!
\    then 2 invert and 1 or  h# 92 pc!
\
\    We'll have a problem with this code if we get some machine which
\    uses bit 1 (0x02) for something other than the Eagle chip endian
\    switch and it hangs the machine to set it and the machine is in
\    little endian and bit 0 of port 92 is 1 when we invoke the
\    (reset-all) word.

\ LICENSE_BEGIN
\ Copyright (c) 1997 FirmWorks
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

