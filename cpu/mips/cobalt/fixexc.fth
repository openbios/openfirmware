purpose: Personalize the exception handler for this environment
\ See license at end of file

stand-init:
   kseg0 to vector-base
;

\ Disable exponential backoff for DHCP.  We are running on point-to-point
\ links, so there is no need to avoid flooding the net.
dev /obp-tftp
decimal patch 1000 8000 init-backoff hex  \ Initially 1 second instead of 8
decimal patch 1 5000 ?try-broadcast hex   \ Waiting stops REL "Hello" packets
-1 to tftp-retries			  \ Close enough to forever
patch noop 2* next-backoff                \ Don't double the interval
dend

0 value trapped?

\ Set aborted? so save-state will be called, instead of re-executing the
\ instruction.  Set trapped? so "Keyboard interrupt" won't be displayed.
: (.exception1)  ( exc-code -- )
   (.exception) 1 aborted? !  true to trapped?
;

\ Suppress the display of "Keyboard interrupt" if trapped? is set
: .entry1  ( -- )  trapped?  if  false to trapped?  else  .entry  then  ;

: bpon  bpon state-valid off  ;

: (init-dispatcher)  ( -- )
   ['] getmsecs is get-msecs
   sr@  h# 200.00000  or  sr!  \ Enable CP1
;
' (init-dispatcher) to init-dispatcher
\ base @
\ decimal patch cpu-clock-frequency 33333333 calibrate-ticker
\ base !

' (.exception1) to dispatch-exceptions
' .entry1 to .exception
' ge-preamble to tlb-handler
' ge-preamble to xtlb-handler
' ge-preamble to cache-handler

defer user-interface ' quit to user-interface
also client-services definitions
: exit  ( -- )
   \ Reinstate our exception handlers
   h# 2000.8080 sr!  \ CP1 on, enable tick interrupt, enable XKseg
   disable-interrupts
   catch-exceptions
   ms/tick set-tick-limit

   [ also hidden ] breakpoints-installed off  [ previous ]
   [ifdef] vector  vector off  [then]

   " restore"  stdout @  ['] $call-method  catch  if  3drop  then
   " restore"  stdin  @  ['] $call-method  catch  if  3drop  then
   enable-interrupts

   user-interface
;
: enter  ( -- )
   sr@ >r  disable-interrupts
   ." Type 'resume' to return to the operating system." cr
   interact
   r> sr!
;
previous definitions

: (lock[)  ( -- r: inten )  r> sr@ >r >r  disable-interrupts  ;
: (]unlock)  ( r: inten -- )  r> r> sr! >r  ;
' (lock[) to lock[
' (]unlock) to ]unlock

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
