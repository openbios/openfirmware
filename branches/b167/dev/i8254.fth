\ See license at end of file
purpose: Driver for Intel 8254 Programmable Interval Timer chip

\ The parallel port register at (hex) 61 in PC I/O space controls the GATE
\ input on timer 2, enables/disables timer 2's output to the speaker, and
\ lets you read back the state of the timer 2 OUT bit.

internal
h# 40 constant timer0
\ h# 41 constant timer1
\ h# 42 constant timer2
h# 43 constant timer-ctl

\ Values for r/w field
0 constant latch
1 constant lsb
2 constant msb
3 constant lsb,msb

\ Modes
\ 0 - interrupt on count = 0
\ 1 - one-shot
\ 2 - rate generator  ( OUT goes high for one clock when count=0, reload count)
\ 3 - square wave     ( period = initial count, duty cycle = .5 )
\ 4 - software triggered strobe  ( OUT pulses low when count = 0, no reload)
\ 4 - hardware triggered strobe  ( OUT pulses low when count = 0, no reload)

: timer@  ( timer# -- byte )  timer0 + pc@  ;
: timer!  ( byte timer# -- )  timer0 + pc!  ;

: latch-counter  ( timer# -- )  3 and 6 <<  timer-ctl pc!  ;

\ The timer-ctl register looks like:
\ TTRR.MMMB
\ TT  is timer# (0-2)
\ RR  is the r/w field, with values as given above
\ MMM is the mode field, with values as given above
\ B   is 0 for binary, 1 for BCD

: set-mode  ( r/w mode bcd? timer# -- )
   3 and 6 <<  swap 1 and or  swap 7 and 1 << or  swap 3 and 4 << or
   timer-ctl pc!
;

[ifdef] not-used
: read-back  ( count? status? timer-mask -- )
   7 and 1 <<                     ( count? status? bits )
   swap  0=  if  h# 10 or  then   ( count? bits )
   swap  0=  if  h# 20 or  then   ( bits )
   h# c0 or  timer-ctl pc!
;

: get-status  ( timer# -- r/w mode bcd out stopped? )
   >r  false true  1 r@ <<  read-back   r> timer@  ( status )
   dup  4 >> 3 and  swap           ( r/w status )
   dup  1 >> 7 and  swap           ( r/w mode status )
   dup       1 and  swap           ( r/w mode bcd status )
   dup  7 >> 1 and  swap           ( r/w mode bcd out status )
        6 >> 1 and                 ( r/w mode bcd out stopped? )
;
[then]
external
: count@  ( timer# -- count )
   dup latch-counter  dup timer@  swap timer@ bwjoin
;
: count!  ( count mode timer# -- )
   >r  lsb,msb swap false r@ set-mode   ( count )
   wbsplit swap r@ timer!  r> timer!
;

\ PC speaker control; the GATE bit in the register at I/O address 0x61
\ is connected to the GATE2 input of the 8254 timer.

\ 01 bit enables counting
\ 02 bit enables output to speaker
\ 20 bit reads back speaker OUT line

: speaker!  ( xxxx|EIC|ERP|SPK|T2G -- )  h# 61 pc!  ;
: speaker@  ( -- PCK|CHKIO|T2O|RFD|EIC|ERP|SPK|T2G )   h# 61 pc@  ;

: tone  ( hz msecs -- )
   d# 1193180 rot /  3 2 count!  3 speaker!  ( msecs )
   ms
   0 speaker!
;

\ To set the tick timer
: set-tick-limit  ( #ms -- )
   d# 10000000 * d# 8381 /  h# ffff min  2 0 count!
;

\ XXX we really should map the registers
: open  ( -- flag? )  true  ;
: close  ( -- )  ;

: ring-bell  ( -- )
   open  drop
   d# 2000  d# 100  tone
   close
;

: init  ( -- )
   0 2 0 count!		\ Enable counter0 to free-run in pulse output mode
;
[ifdef] tokenizing  init  [then]
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
