\ See license at end of file
purpose: Driver for DS1385 Real-time clock and NVRAM chip

\ Define this to latch the bad-battery indication
\ -- The "sticky battery" feature has turned out to be annoying,
\ so it is probably best to leave it off.
\ create sticky-battery

" rtc" device-name
" rtc" device-type
" pnpPNP,b00" " compatible" string-property
my-address my-space  2  reg 

headerless
0 instance value rtc-adr

h#  2 constant regb-mode
h# 26 constant rega-mode

\ Register B (offset d# 11) bits
\ 80 - Set
\ 40 - Periodic Interrupt Enable
\ 20 - Alarm Interrupt Enable
\ 10 - Update Ended Interrupt Enable
\ 08 - Square Wave Enable
\ 04 - Binary mode (vs. BCD)
\ 02 - 24-hour mode (vs. 12-hour)
\ 01 - Daylight Savings Enable

headers		\ For convenience
: rtc@  ( offset -- n )  lock[  rtc-adr rb!  rtc-adr 1+  rb@  ]unlock  ;
: rtc!  ( n offset -- )  lock[  rtc-adr rb!  rtc-adr 1+  rb!  ]unlock  ;

headerless

[ifdef] sticky-battery
: rtc-error@  ( -- b )  d# 14 rtc@  ;
: rtc-error!  ( b -- )  d# 14 rtc!  ;
h# 80 constant battery-error-bit
[then]

\ make sure that the battery is charged - reg D/13 should be 80x
: check-battery  ( -- error? )

   \ Reding this register unlocks this device for writes later.
   d# 13 rtc@  h# 80 and  0=               ( error? )

   \ The battery status indicator is only valid the first time you
   \ read it after power-on, so we have to save the information
   \ in a property.
   " status" get-my-property  0=  if
      decode-string 2nip  " bad battery" $=  nip exit
   then
					     ( error? )

[ifdef] sticky-battery
   \ If we don't have a "status" property, determine the battery
   \ state and create one.
   \ First check for a latched battery state bit.  The battery indication
   \ in register d# 13 is only valid just after power-up, so in order to
   \ retain its value across a warm boot, we must store the information
   \ elsewhere.  We put it in register d# 14, which is a CMOS RAM location.
   rtc-error@ battery-error-bit and  if       ( error? )
      drop true                               ( error? )
   then                                       ( error? )
[then]

   dup  if                                    ( error? )
[ifdef] sticky-battery
      rtc-error@  h# 80 or  rtc-error!        ( error? )
[then]
      " bad battery"                          ( error? $ )
   else                                       ( error? )
      " okay"                                 ( error? $ )
   then                                       ( error? $ )
   encode-string  " status"  property
;
: battery-message  ( flag -- flag )
   dup  if
   ." The time has not been set since the real-time clock battery was replaced"
   cr  
   then
;
true value first-open?
headers
: open  ( -- true )
   my-unit  2  " map-in" $call-parent  is rtc-adr
   first-open?  if
      rega-mode d# 10 rtc!
      regb-mode d# 11 rtc!
      \ If the battery is bad, display a message, but go open the device anyway
      check-battery battery-message drop
      false to first-open?
   then
   true
;
: close  ( -- )
   rtc-adr 2  " map-out" $call-parent
;

headerless
: bcd>  ( bcd -- binary )  dup h# f and  swap 4 >>  d# 10 *  +  ;
: >bcd  ( binary -- bcd )  d# 10 /mod  4 << +  ;

: bcd-time&date  ( -- s m h d m y century )
   begin
      lock[
      h# a rtc@  h# 80 and   \ Wait for update-in-progress bit to go low
   while
      ]unlock
   repeat

   \ Having seen the UIP bit low, we are guaranteed a consistent
   \ sample if we read all the registers within 244 usecs.

   0 rtc@  2 rtc@  4 rtc@  7 rtc@  8 rtc@  9 rtc@  h# 1a rtc@ ( s m h d m y c )
   ]unlock
;
: bcd!  ( n offset -- )  swap >bcd  swap rtc!  ;

headers
: get-time  ( -- s m h d m y )
   bcd-time&date  >r >r >r >r >r >r
   bcd>  r> bcd>  r> bcd>  r> bcd>  r> bcd>  r> bcd>  r> bcd> ( s m h d m y c )

   \ We allow the century byte to force the year to 20xx, but not to force
   \ it to 19xx, because that would cause a problem when the century
   \ rolls over.
   dup  d# 20 <>  if
      drop  dup d# 94 <  if  d# 20  else  d# 19  then
   then

   d# 100 * +  		\ Merge century with year
;
: set-time  ( s m h d m y -- )
   d# 11 rtc@ dup >r  h# 80 or  d# 11 rtc!  ( r: old-regb )  \ Turn on SET bit
   d# 100 /mod  h# 1a bcd!  9 bcd!  8 bcd!  7 bcd!  4 bcd!  2 bcd!  0 bcd!
   r> d# 11 rtc!                            ( )

[ifdef] sticky-battery
   \ Clear error flags
   rtc-error@  h# 80 invert and  rtc-error!
   " status" get-my-property  0=  if			( adr len )
      2drop  " okay" encode-string  " status" property	( )
   then
[then]
;

: selftest  ( -- flag )
   open drop
   check-battery  \ Don't display the message here because "open" will do it
   close
;

: which-interrupt  ( -- value )  d# 12 rtc@  ;

\ set-tick-usecs
: set-tick-usecs  ( usecs -- usecs' )
   d# 122 3                 ( target-usecs rtc-usecs code )
   h# f 3  do               ( target-usecs rtc-usecs code )
      3dup drop 2*  <  if   ( target-usecs rtc-usecs code )
         leave              ( target-usecs rtc-usecs code )
      then                  ( target-usecs rtc-usecs code )
      swap 2* swap 1+       ( target-usecs rtc-usecs' code' )
   loop                     ( target-usecs rtc-usecs' code' )
   rot drop                 ( rtc-usecs code )
   d# 10 rtc@  h# f invert and  or  d# 10 rtc!   ( rtc-usecs )
   d# 11 rtc@  h# 40 or  d# 11 rtc!              ( rtc-usecs )
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
