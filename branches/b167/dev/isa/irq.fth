\ See license at end of file
purpose: Interrupt dispatcher using ISA 8259 interrupt controller

0 value pic-node
: enable-interrupt   ( level -- )
   " enable-irq"  pic-node $call-method
   enable-interrupts	\ Just in case they are off
;
: disable-interrupt  ( level -- )  " disable-irq" pic-node $call-method  ;
: interrupt-mask@  ( -- mask )
   h# 21 pc@  h# a1 pc@  bwjoin  h# ffff xor  4 invert and
;
: interrupt-mask!  ( mask -- )
   4 or  h# ffff xor  wbsplit  h# a1 pc!  h# 21 pc!
;

: stray-interrupt  ( level -- )
   ." Unexpected interrupt on IRQ" dup .d cr
   disable-interrupt				\ To prevent recurrence
;

d# 16 2* /n* buffer: interrupt-handlers
: interrupt-handler!  ( xt int-level -- )
   my-self swap  interrupt-handlers swap 2* na+  2!
;
: interrupt-handler@  ( int-level -- xt )
   interrupt-handlers swap 2* na+ 2@  drop
;

[ifdef] hw-iack
: (dispatch-interrupt)  ( vector# -- )
   interrupt-handlers over 2* na+ 2@ package( execute )package   ( )
   " interrupt-done" pic-node $call-method        ( )
;
[else]
: (dispatch-interrupt)  ( -- )
   " this-interrupt" pic-node $call-method  if    ( level )
      interrupt-handlers over 2* na+ 2@ package( execute )package   ( )
   then                                               ( )
   " interrupt-done" pic-node $call-method        ( )
;
[then]
: (init-dispatcher)  ( -- )
   pic-node  0=  if
      " /isa/interrupt-controller" open-dev to pic-node
      d# 16  0  do  ['] stray-interrupt  i interrupt-handler!  loop
      ['] (dispatch-interrupt) to dispatch-interrupt
   then
;
' (init-dispatcher) to init-dispatcher
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
