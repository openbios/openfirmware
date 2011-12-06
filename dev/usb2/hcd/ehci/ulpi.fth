\ See license at end of file
purpose: Support for ULPI Viewports

\ ULPI is a hardware interface between a USB controller and external PHY.
\ The semantics of the interface mimics that of the UTMI+ hardware interface,
\ but the ULPI interface has fewer pins and is thus better-suited for
\ external PHYs.  The UTMI+ interface was optimized for controller and PHY
\ on the same chip.
\ UTMI+ has a number of hardware control signals that change infrequently.
\ ULPI implements those almost-static signals with bits in PHY-resident
\ registers.  Typically that is transparent to software, as the ULPI side
\ of the hardware interface does the work of translating the UTMI hardware
\ signaling into register accesses across the ULPI interconnect.  However,
\ it is possible to read and write those registers explicitly, e.g. for
\ debugging.  The "ULPI Viewport" register in the EHCI register block lets
\ you do that

\ Low-level access to the viewport registers
: view@  ( -- n )  h# 30 op-reg@  ;
: view!  ( -- n )  h# 30 op-reg!  ;

\ Wait for the indicated viewport register bit to go to 0.
: ulpi-poll  ( bit -- )
   d# 10000 0  do         ( bit )
      dup view@ and  if   ( bit )
         drop unloop exit ( -- )
      then                ( bit )
      d# 5 us             ( bit )
   loop                   ( bit )
   drop  true abort" ULPI poll timeout"
;
\ Wakeup the ULPI interface if it is not in "synchronized" state
: ?ulpi-wakeup  ( -- )
   view@ h# 0800.0000 and  0=  if      \ SYNC state
      h# 8000.0000 view!               \ wakeup
      h# 8000.0000 ulpi-poll           \ wait for wakeup
   then
;
\ Read a register in the ULPI PHY
: ulpi@  ( reg -- n )
   ?ulpi-wakeup                        ( reg )
   d# 16 lshift h# 4000.0000 or view!  ( )  \ address and RUN bit
   h# 4000.0000 ulpi-poll              ( )
   view@ 8 rshift  h# ff and           ( n )
;
\ Write a register in the ULPI PHY
: ulpi!  ( n reg -- )
   ?ulpi-wakeup                             ( n reg )
   d# 16 lshift or  h# 4000.0000 or  view!  ( )  \ address and WRITE bit and RUN bit
   h# 4000.0000 ulpi-poll                   ( )
;

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
